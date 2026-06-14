import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/models/meeting_item_model.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:brokkerspot/views/user/announcements/announcement_chat_view.dart';
import 'package:brokkerspot/views/user/meeting/announcement_conversations_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:brokkerspot/views/user/meeting/chat_view.dart';
import 'package:brokkerspot/views/user/meeting/controller/meeting_controller.dart';
import 'package:brokkerspot/views/user/meeting/repo/meeting_repo.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/widgets/common/custom_primary_button.dart';
import 'package:brokkerspot/widgets/meeting/meeting_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class MeetingView extends StatefulWidget {
  const MeetingView({super.key});

  @override
  State<MeetingView> createState() => _MeetingViewState();
}

class _MeetingViewState extends State<MeetingView> {
  // Default to the Announcement tab — that's the one wired to fetch-meetings.
  bool _isBookingSelected = false;
  final _ctrl = MeetingController.to;
  final _profile = Get.isRegistered<ProfileController>()
      ? Get.find<ProfileController>()
      : Get.put(ProfileController());

  final List<({String label, MeetingFilter filter})> _filters = const [
    (label: 'ALL', filter: MeetingFilter.all),
    (label: 'BUY', filter: MeetingFilter.buy),
    (label: 'RENT', filter: MeetingFilter.rent),
    (label: 'OWN', filter: MeetingFilter.own),
  ];

  // Booking still uses the old mock data — no API for it yet.
  final List<Map<String, String>> _bookingList = const [
    {
      'name': 'Aman',
      'subtitle': 'SAFA/TWO\nFrom AED 99,000',
      'time': '2 min ago',
    },
  ];

  // Saved so we can dispose; pre-warms avatar images the moment a meetings
  // page arrives so the conversations screen opens with photos already loaded.
  Worker? _precacheWorker;

  @override
  void initState() {
    super.initState();
    _ctrl.load();
    _precacheWorker = ever(_ctrl.meetings, (_) => _precacheAvatars());
  }

  @override
  void dispose() {
    _precacheWorker?.dispose();
    super.dispose();
  }

  Future<void> _openConversations(MeetingItem m) async {
    // Use JWT as the authoritative source for the logged-in user's id.
    final myId = LocalStorageService.getUserIdFromToken() ??
        LocalStorageService.getUser()?.data?.id ?? '';
    final isOwner = myId.isNotEmpty && m.announcement.userId == myId;

    debugPrint('📋 [Meeting] tap ann=${m.announcementId}');
    debugPrint('📋 [Meeting]   myId=$myId  ann.userId=${m.announcement.userId}  isOwner=$isOwner');
    debugPrint('📋 [Meeting]   chatProfiles=[${m.chatProfiles.map((p) => "${p.name}(${p.id})").join(", ")}]');

    if (isOwner) {
      // My announcement — show everyone who chatted with me.
      debugPrint('📋 [Meeting]   → owner path: opening AnnouncementConversationsView');
      await Get.to(() => AnnouncementConversationsView(meeting: m));
    } else {
      // I initiated a chat about someone else's announcement.
      // chat:announcement:conversations returns MY own profile as the peer in
      // this case (server perspective is the owner's), so skip it entirely and
      // go straight to chat with the announcement owner.
      final peers = myId.isNotEmpty
          ? m.chatProfiles.where((p) => p.id != myId).toList()
          : List<ChatProfileSummary>.from(m.chatProfiles);
      final peer = peers.isNotEmpty ? peers.first : null;
      final ownerId = peer?.id ?? m.announcement.userId ?? '';
      if (ownerId.isEmpty || ownerId == myId) {
        debugPrint('📋 [Meeting]   → non-owner path: no valid peer found, aborting');
        return;
      }
      final annRole = m.announcement.userRole ?? 1;
      final chatUserRole = 3 - annRole;
      debugPrint('📋 [Meeting]   → non-owner path: peer=${peer?.name}($ownerId) chatUserRole=$chatUserRole');
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
    if (mounted) _ctrl.load(force: true);
  }

  void _precacheAvatars() {
    // Warm the image cache for every peer avatar + announcement thumbnail in
    // the list. precacheImage uses the same network/disk cache CachedNetwork
    // Image reads from, so re-displaying these is instant.
    if (!mounted) return;
    final urls = <String>{};
    for (final m in _ctrl.meetings) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            const CustomHeader(title: 'Meeting'),
            _buildTopTabs(),
            if (_isBookingSelected)
              Expanded(child: _buildBookingList())
            else
              Expanded(
                child: Column(
                  children: [
                    _buildFilterChips(),
                    Expanded(child: _buildMeetingList()),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Booking / Announcement top tabs ───
  Widget _buildTopTabs() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: CustomPrimaryButton(
              title: 'Booking',
              defaultColor: _isBookingSelected ? Colors.white : Colors.black,
              backgroundColor: _isBookingSelected
                  ? AppColors.primary
                  : Colors.grey.shade300,
              fontWeight: _isBookingSelected ? FontWeight.bold : FontWeight.normal,
              onPressed: () => setState(() => _isBookingSelected = true),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: CustomPrimaryButton(
              title: 'Announcement',
              defaultColor: !_isBookingSelected ? Colors.white : Colors.black,
              backgroundColor: !_isBookingSelected
                  ? AppColors.primary
                  : Colors.grey.shade300,
              fontWeight: !_isBookingSelected ? FontWeight.bold : FontWeight.normal,
              onPressed: () => setState(() => _isBookingSelected = false),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Filter chips for the Announcement tab ───
  Widget _buildFilterChips() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Obx(() {
        final current = _ctrl.filter.value;
        return Row(
          children: _filters.map((f) {
            final isSelected = current == f.filter;
            return Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: GestureDetector(
                onTap: () => _ctrl.load(f: f.filter),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 24.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey.shade300,
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

  // ─── Meeting list (real data) ───
  Widget _buildMeetingList() {
    return Obx(() {
      if (_ctrl.isLoading.value && _ctrl.meetings.isEmpty) {
        return const _MeetingShimmer();
      }
      if (_ctrl.error.value != null && _ctrl.meetings.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Text(
                  _ctrl.error.value!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, color: Colors.grey.shade500),
                ),
              ),
              SizedBox(height: 12.h),
              TextButton(
                onPressed: () => _ctrl.load(force: true),
                child: Text('Retry',
                    style: GoogleFonts.inter(
                        fontSize: 14.sp, color: AppColors.primary)),
              ),
            ],
          ),
        );
      }
      if (_ctrl.meetings.isEmpty) {
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _ctrl.load(force: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [SizedBox(height: 200.h), _buildEmptyState()],
          ),
        );
      }
      final myId = _profile.currentUserId;
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _ctrl.load(force: true),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(vertical: 8.h),
          itemCount: _ctrl.meetings.length,
          separatorBuilder: (_, __) => Divider(
            height: 1.5,
            thickness: 1,
            color: Colors.grey.shade200,
            indent: 16.w,
            endIndent: 16.w,
          ),
          itemBuilder: (_, i) {
            final m = _ctrl.meetings[i];
            final isOwn = myId != null && m.announcement.userId == myId;
            return MeetingCard(
              meeting: m,
              isOwn: isOwn,
              onTap: () => _openConversations(m),
            );
          },
        ),
      );
    });
  }

  // ─── Booking (unchanged mock for now) ───
  Widget _buildBookingList() {
    if (_bookingList.isEmpty) return _buildEmptyState();
    return ListView.builder(
      itemCount: _bookingList.length,
      itemBuilder: (context, index) {
        final item = _bookingList[index];
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset('assets/images/rent1.png',
                width: 60, height: 60, fit: BoxFit.cover),
          ),
          title: Text(item['name']!,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(item['subtitle']!),
          trailing: Text(item['time']!),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatView()),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.info_outline, size: 48, color: Colors.grey),
          SizedBox(height: 10),
          Text('No data found',
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }
}

class _MeetingShimmer extends StatelessWidget {
  const _MeetingShimmer();

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
                    Container(
                        width: 120.w, height: 12.h, color: Colors.white),
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
