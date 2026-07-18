import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/models/meeting_item_model.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:brokkerspot/views/user/announcements/announcement_chat_view.dart';
import 'package:brokkerspot/views/user/meeting/announcement_conversations_view.dart';
import 'package:brokkerspot/views/user/meeting/controller/meeting_controller.dart';
import 'package:brokkerspot/views/user/meeting/repo/meeting_repo.dart';
import 'package:brokkerspot/widgets/meeting/meeting_card.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class MeetingView extends StatefulWidget {
  const MeetingView({super.key});

  @override
  State<MeetingView> createState() => _MeetingViewState();
}

class _MeetingViewState extends State<MeetingView> {
  final _ctrl = MeetingController.to;
  final _profile = Get.isRegistered<ProfileController>()
      ? Get.find<ProfileController>()
      : Get.put(ProfileController());

  static final _filters = [
    (label: 'ALL', filter: MeetingFilter.all),
    (label: 'BUY', filter: MeetingFilter.buy),
    (label: 'RENT', filter: MeetingFilter.rent),
    (label: 'OWN', filter: MeetingFilter.own),
  ];

  Worker? _precacheWorker;

  @override
  void initState() {
    super.initState();
    _precacheWorker = ever(_ctrl.meetings, (_) => _precacheAvatars());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.load();
    });
  }

  @override
  void dispose() {
    _precacheWorker?.dispose();
    super.dispose();
  }

  Future<void> _openConversations(MeetingItem m) async {
    final myId = LocalStorageService.getUserIdFromToken() ??
        LocalStorageService.getUser()?.data?.id ??
        '';
    final isOwner = myId.isNotEmpty && m.announcement.userId == myId;

    if (isOwner) {
      await Get.to(() => AnnouncementConversationsView(meeting: m));
    } else {
      final peers = myId.isNotEmpty
          ? m.chatProfiles.where((p) => p.id != myId).toList()
          : List<ChatProfileSummary>.from(m.chatProfiles);
      final peer = peers.isNotEmpty ? peers.first : null;
      final ownerId = peer?.id ?? m.announcement.userId ?? '';
      if (ownerId.isEmpty || ownerId == myId) return;
      final annRole = m.announcement.userRole ?? 1;
      await AnnouncementChatView.open(
        announcementId: m.announcementId,
        brokerName: peer?.name ?? m.announcement.ownerName ?? 'User',
        brokerAvatar: peer?.profileImageUrl ?? m.announcement.ownerAvatarUrl,
        peerUserId: ownerId,
        userRole: 3 - annRole,
      );
    }
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 350));
    if (mounted) _ctrl.load(force: true);
  }

  void _precacheAvatars() {
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF090B11) : theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomHeader(title: 'Broker Meetings', showBackButton: false),
            SizedBox(height: 20.h),
            _buildFilterRow(theme),
            SizedBox(height: 12.h),
            Divider(
                height: 1,
                thickness: 1,
                color:
                    isDark ? const Color(0xFF3D3D3D) : const Color(0xFFECECEC)),
            Expanded(child: _buildBody(theme, isDark)),
          ],
        ),
      ),
    );
  }

  // ── Filter chips — ALL / BUY / RENT / OWN ────────────────────────────────────

  Widget _buildFilterRow(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Obx(() {
      final current = _ctrl.filter.value;
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        child: Row(
          children: _filters.map((f) {
            final isSelected = current == f.filter;
            return Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: GestureDetector(
                onTap: () => _ctrl.load(f: f.filter),
                child: Container(
                  height: 34.h,
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : isDark
                            ? const Color(0xFF3D3D3D)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(62.r),
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
                      fontWeight: FontWeight.w400,
                      color: isSelected
                          ? Colors.white
                          : isDark
                              ? Colors.white70
                              : Colors.black87,
                      height: 1.0,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      );
    });
  }

  // ── Body ──────────────────────────────────────────────────────────────────────

  Widget _buildBody(ThemeData theme, bool isDark) {
    final dividerColor =
        isDark ? const Color(0xFF3D3D3D) : const Color(0xFFECECEC);
    return Obx(() {
      if (_ctrl.isLoading.value && _ctrl.meetings.isEmpty) {
        return _buildShimmer(theme);
      }
      if (_ctrl.error.value != null && _ctrl.meetings.isEmpty) {
        return _buildError();
      }
      if (_ctrl.meetings.isEmpty) {
        return _buildEmpty();
      }
      final myId = _profile.currentUserId;
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _ctrl.load(force: true),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _ctrl.meetings.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            thickness: 1,
            color: dividerColor,
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

  Widget _buildError() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _ctrl.load(force: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 200.h),
          Center(
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
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => _ctrl.load(force: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 200.h),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.forum_outlined,
                    size: 48.sp, color: Colors.grey.shade300),
                SizedBox(height: 12.h),
                Text(
                  'No meetings yet',
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final shimmerColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final dividerColor =
        isDark ? const Color(0xFF3D3D3D) : const Color(0xFFECECEC);
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 1,
        color: dividerColor,
      ),
      itemBuilder: (_, __) => SizedBox(
        height: 89.h,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          child: Row(
            children: [
              // Thumb placeholder
              Container(
                width: 65.w,
                height: 65.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: shimmerColor,
                ),
              ),
              SizedBox(width: 13.w),
              // Text placeholders
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                        height: 14.h,
                        width: 90.w,
                        decoration: BoxDecoration(
                            color: shimmerColor,
                            borderRadius: BorderRadius.circular(4.r))),
                    Container(
                        height: 14.h,
                        width: 130.w,
                        decoration: BoxDecoration(
                            color: shimmerColor,
                            borderRadius: BorderRadius.circular(4.r))),
                    Container(
                        height: 14.h,
                        width: 150.w,
                        decoration: BoxDecoration(
                            color: shimmerColor,
                            borderRadius: BorderRadius.circular(4.r))),
                  ],
                ),
              ),
              // Avatar placeholder
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: shimmerColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
