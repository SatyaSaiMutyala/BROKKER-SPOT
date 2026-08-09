import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/models/meeting_item_model.dart';
import 'package:brokkerspot/views/user/announcements/announcement_chat_view.dart';
import 'package:brokkerspot/views/user/meeting/announcement_conversations_view.dart';
import 'package:brokkerspot/views/user/meeting/controller/meeting_controller.dart';
import 'package:brokkerspot/views/user/meeting/repo/meeting_repo.dart';
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
    _precacheWorker = ever(_ctrl.brokerMeetings, (_) => _precacheAvatars());
    // Defer so loadBroker()'s sync Rx mutations don't run while an ancestor
    // is still mid-build (same post-login race as the user-side tabs).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.loadBroker();
    });
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

  bool _isOwn(MeetingItem m) {
    final myId = LocalStorageService.getUserIdFromToken() ??
        LocalStorageService.getUser()?.data?.id ??
        '';
    // True only when the user created this as an OWNER (user_role == 1).
    // A broker-posted announcement (user_role == 2) has userId == myId but
    // the logged-in user is the broker, not the owner.
    return myId.isNotEmpty &&
        m.announcement.userId == myId &&
        (m.announcement.userRole ?? 1) == 1;
  }

  Future<void> _onTap(MeetingItem m) async {
    final myId = LocalStorageService.getUserIdFromToken() ??
        LocalStorageService.getUser()?.data?.id ??
        '';
    final isOwner = myId.isNotEmpty &&
        m.announcement.userId == myId &&
        (m.announcement.userRole ?? 1) == 1;

    debugPrint('📋 [BrokerMeeting] tap ann=${m.announcementId}');
    debugPrint(
        '📋 [BrokerMeeting]   myId=$myId  ann.userId=${m.announcement.userId}  userRole=${m.announcement.userRole}  isOwner=$isOwner');
    debugPrint(
        '📋 [BrokerMeeting]   chatProfiles=[${m.chatProfiles.map((p) => "${p.name}(${p.id})").join(", ")}]');

    if (isOwner) {
      // My announcement — show everyone who chatted with me.
      debugPrint(
          '📋 [BrokerMeeting]   → owner path: opening AnnouncementConversationsView');
      await Get.to(() => AnnouncementConversationsView(meeting: m));
    } else {
      // I initiated a chat about someone else's announcement — go directly to
      // chat with the owner. chat:announcement:conversations returns MY own
      // profile in this case, so skip that screen entirely.
      final peers = myId.isNotEmpty
          ? m.chatProfiles.where((p) => p.id != myId).toList()
          : List<ChatProfileSummary>.from(m.chatProfiles);
      final peer = peers.isNotEmpty ? peers.first : null;
      final ownerId = peer?.id ?? m.announcement.userId ?? '';
      if (ownerId.isEmpty || ownerId == myId) {
        debugPrint(
            '📋 [BrokerMeeting]   → non-owner path: no valid peer found, aborting');
        return;
      }
      final annRole = m.announcement.userRole ?? 1;
      final chatUserRole = 3 - annRole;
      debugPrint(
          '📋 [BrokerMeeting]   → non-owner path: peer=${peer?.name}($ownerId) chatUserRole=$chatUserRole');
      await AnnouncementChatView.open(
        announcementId: m.announcementId,
        brokerName: peer?.name ?? m.announcement.ownerName ?? 'User',
        brokerAvatar: peer?.profileImageUrl ?? m.announcement.ownerAvatarUrl,
        peerUserId: ownerId,
        userRole: chatUserRole,
      );
    }
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 350));
    if (mounted) _ctrl.loadBroker(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme),
                _buildFilterChips(theme),
                Expanded(child: _buildList(theme)),
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

  // ─── Header ───
  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
      child: Text(
        'Client Meetings',
        style: GoogleFonts.poppins(
          fontSize: 24.sp,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  // ─── Filter chips (ALL / BUY / RENT / OWN) ───
  // Identical UI to the user-side meeting screen; taps switch the broker
  // slot's filter and re-fetch (cache-first per filter).
  Widget _buildFilterChips(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
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
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : isDark
                            ? const Color(0xFF2A2A2A)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: isDark
                                ? Colors.grey.shade700
                                : Colors.grey.shade300,
                          ),
                  ),
                  child: Text(
                    f.label,
                    style: GoogleFonts.poppins(
                      fontSize: 12.sp,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : isDark
                              ? Colors.white70
                              : Colors.black87,
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

  Widget _buildList(ThemeData theme) {
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
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: theme.brightness == Brightness.dark
                  ? Colors.grey.shade800
                  : Colors.grey.shade200,
            ),
          ),
          itemBuilder: (_, i) {
            final m = _ctrl.brokerMeetings[i];
            return BrokerMeetingCard(
              meeting: m,
              isOwn: _isOwn(m),
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
