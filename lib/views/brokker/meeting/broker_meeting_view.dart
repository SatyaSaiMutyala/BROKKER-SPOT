import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/models/meeting_item_model.dart';
import 'package:brokkerspot/views/user/announcements/announcement_chat_view.dart';
import 'package:brokkerspot/views/user/meeting/announcement_conversations_view.dart';
import 'package:brokkerspot/views/user/meeting/controller/meeting_controller.dart';
import 'package:brokkerspot/views/user/meeting/repo/meeting_repo.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/widgets/common/support_fab.dart';
import 'package:brokkerspot/widgets/meeting/broker_meeting_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

/// Broker-side Meeting screen.
///
/// Reuses [MeetingController] (same `fetch-meetings` endpoint — the backend
/// returns broker-relevant data when currentRole=2) and the same
/// [MeetingCard] widget. Two screens only on broker side: this list and a
/// direct chat — no middle "conversations" screen.
class BrokerMeetingView extends StatefulWidget {
  const BrokerMeetingView({super.key});

  @override
  State<BrokerMeetingView> createState() => _BrokerMeetingViewState();
}

class _BrokerMeetingViewState extends State<BrokerMeetingView> {
  final _ctrl = MeetingController.to;

  // Same filter set + labels as the user-side meeting screen.
  final List<({String label, MeetingFilter filter})> _filters = const [
    (label: 'ALL', filter: MeetingFilter.all),
    (label: 'BUY', filter: MeetingFilter.buy),
    (label: 'RENT', filter: MeetingFilter.rent),
    (label: 'OWN', filter: MeetingFilter.own),
  ];

  Worker? _precacheWorker;

  @override
  void initState() {
    super.initState();
    _ctrl.loadBroker();
    _precacheWorker = ever(_ctrl.brokerMeetings, (_) => _precacheAvatars());
  }

  @override
  void dispose() {
    _precacheWorker?.dispose();
    super.dispose();
  }

  void _precacheAvatars() {
    if (!mounted) return;
    final urls = <String>{};
    for (final m in _ctrl.brokerMeetings) {
      final thumb = m.announcement.propertyMedia?.thumbnail;
      if (thumb != null && thumb.isNotEmpty) urls.add(thumb);
      for (final p in m.chatProfiles) {
        final u = p.profileImageUrl;
        if (u != null && u.isNotEmpty) urls.add(u);
      }
    }
    for (final u in urls) {
      precacheImage(CachedNetworkImageProvider(u), context).catchError((_) {});
    }
  }

  /// Broker side jumps straight into 1:1 chat when there is exactly one peer.
  ///
  /// The meetings API returns chat_profiles that include the broker's own
  /// profile for user announcements (since the server lists the broker
  /// participants from the announcement owner's perspective). We filter out
  /// self using the JWT-derived user id, then fall back to announcement.userId
  /// (the announcement owner/user) if no external peers remain.
  Future<void> _onTap(MeetingItem m) async {
    // Use the JWT payload as the authoritative source for the logged-in user's
    // id — more reliable than user_data which can be stale after account switch.
    final myId = LocalStorageService.getUserIdFromToken() ??
        LocalStorageService.getUser()?.data?.id ?? '';

    // Filter out own profile from the list (for user announcements the server
    // puts the broker's own profile in chat_profiles, not the peer's).
    final peers = myId.isNotEmpty
        ? m.chatProfiles.where((p) => p.id != myId).toList()
        : List<ChatProfileSummary>.from(m.chatProfiles);

    if (peers.isEmpty) {
      // Only our own profile was in chat_profiles — this is a user announcement
      // where we (the broker) initiated contact. The peer = the announcement owner.
      final ownerId = m.announcement.userId ?? '';
      if (ownerId.isEmpty || ownerId == myId) return;
      await AnnouncementChatView.open(
        announcementId: m.announcementId,
        brokerName: m.announcement.ownerName ?? 'User',
        brokerAvatar: m.announcement.ownerAvatarUrl,
        peerUserId: ownerId,
      );
    } else if (peers.length == 1) {
      final peer = peers.first;
      final peerId = peer.id ?? '';
      if (peerId.isEmpty) return;
      await AnnouncementChatView.open(
        announcementId: m.announcementId,
        brokerName: peer.name ?? 'User',
        brokerAvatar: peer.profileImageUrl,
        peerUserId: peerId,
      );
    } else {
      await Get.to(() => AnnouncementConversationsView(meeting: m));
    }
    if (!mounted) return;
    // Tiny delay so the server has time to persist the just-sent message
    // before we re-fetch — same trick as the user side.
    await Future.delayed(const Duration(milliseconds: 350));
    if (mounted) _ctrl.loadBroker(force: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                CustomHeader(
                  title: 'MEETING',
                  trailing: GestureDetector(
                    onTap: () => _ctrl.loadBroker(force: true),
                    child: Icon(Icons.refresh,
                        size: 22.sp, color: AppColors.goldAccent),
                  ),
                ),
                _buildFilterChips(),
                Expanded(child: _buildList()),
              ],
            ),
            Positioned(
              right: 20.w,
              bottom: 20.h,
              child: SupportFab(onTap: () {}),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Filter chips (ALL / BUY / RENT / OWN) ───
  // Identical UI to the user-side meeting screen; taps switch the broker
  // slot's filter and re-fetch (cache-first per filter).
  Widget _buildFilterChips() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Obx(() {
        final current = _ctrl.brokerFilter.value;
        return Row(
          children: _filters.map((f) {
            final isSelected = current == f.filter;
            return Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: GestureDetector(
                onTap: () => _ctrl.loadBroker(f: f.filter),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    f.label,
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }),
    );
  }

  Widget _buildList() {
    return Obx(() {
      if (_ctrl.isLoadingBroker.value && _ctrl.brokerMeetings.isEmpty) {
        return const _BrokerMeetingShimmer();
      }
      if (_ctrl.brokerError.value != null && _ctrl.brokerMeetings.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Text(
                  _ctrl.brokerError.value!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, color: Colors.grey.shade500),
                ),
              ),
              SizedBox(height: 12.h),
              TextButton(
                onPressed: () => _ctrl.loadBroker(force: true),
                child: Text('Retry',
                    style: GoogleFonts.inter(
                        fontSize: 14.sp, color: AppColors.primary)),
              ),
            ],
          ),
        );
      }
      if (_ctrl.brokerMeetings.isEmpty) {
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _ctrl.loadBroker(force: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: 200.h),
              Center(
                child: Text('No meetings yet',
                    style: GoogleFonts.inter(
                        fontSize: 14.sp, color: Colors.grey.shade400)),
              ),
            ],
          ),
        );
      }
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _ctrl.loadBroker(force: true),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(vertical: 8.h),
          itemCount: _ctrl.brokerMeetings.length,
          separatorBuilder: (_, __) => Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child:
                Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200),
          ),
          itemBuilder: (_, i) {
            final m = _ctrl.brokerMeetings[i];
            return BrokerMeetingCard(
              meeting: m,
              onTap: () => _onTap(m),
            );
          },
        ),
      );
    });
  }
}

class _BrokerMeetingShimmer extends StatelessWidget {
  const _BrokerMeetingShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(vertical: 8.h),
        itemCount: 5,
        itemBuilder: (_, __) => Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              Container(
                width: 60.w,
                height: 60.w,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 120.w, height: 12.h, color: Colors.white),
                    SizedBox(height: 6.h),
                    Container(width: 80.w, height: 10.h, color: Colors.white),
                    SizedBox(height: 6.h),
                    Container(width: 140.w, height: 10.h, color: Colors.white),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                width: 46.w,
                height: 46.w,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
