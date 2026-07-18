import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/constants/flutter_toast.dart';
import 'package:brokkerspot/models/notification_model.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:brokkerspot/views/brokker/project/broker_announcement_detail_view.dart';
import 'package:brokkerspot/views/notifications/controller/notification_controller.dart';
import 'package:brokkerspot/views/user/announcements/announcement_detail_view.dart';
import 'package:brokkerspot/views/user/announcements/repo/announcement_repo.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/widgets/notifications/notification_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class NotificationsView extends StatefulWidget {
  const NotificationsView({super.key});

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  final _ctrl = NotificationListController.to;
  final _announcementRepo = AnnouncementRepository();

  @override
  void initState() {
    super.initState();
    // Defer so load()'s sync Rx mutations can't fire while an ancestor is
    // still mid-build. Cache-first: still a no-op when already loaded.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.load();
    });
  }

  Future<void> _onTap(NotificationModel n) async {
    final id = n.id;
    if (id == null) return;
    // Mark viewed + fetch fresh server copy.
    _ctrl.openDetail(id);
    // Deep-link by category/path. Only `/announcements/<id>` is supported
    // right now; extend this switch as new categories come from backend.
    final announcementId = n.announcementId;
    if (announcementId == null) return;

    final overlay = _showLoader();
    try {
      final a = await _announcementRepo.fetchAnnouncementDetail(announcementId);
      overlay.remove();
      final isBroker = (Get.isRegistered<ProfileController>()
                  ? Get.find<ProfileController>()
                  : null)
              ?.isOnBrokerSide ==
          true;
      if (isBroker) {
        Get.to(() => BrokerAnnouncementDetailView(announcement: a));
      } else {
        // a.isOwner comes from the backend's `is_owner` flag — the
        // "interested brokers" row is gated behind `isOwner`, so hardcoding
        // false here was hiding it even when this account owns the listing.
        Get.to(() => AnnouncementDetailView(
              announcement: a,
              isOwner: a.isOwner ?? false,
            ));
      }
    } catch (e) {
      overlay.remove();
      AppToast.error("Couldn't open this announcement");
    }
  }

  OverlayEntry _showLoader() {
    final entry = OverlayEntry(
      builder: (_) => Container(
        color: Colors.black.withValues(alpha: 0.2),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(entry);
    return entry;
  }

  Future<void> _onMarkAllRead() async {
    if (_ctrl.unseenCount.value == 0) return;
    final ok = await _ctrl.markAllRead();
    AppToast.success(ok ? 'All notifications marked as read' : 'Try again');
  }

  Future<bool> _confirmDelete(NotificationModel n) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ok = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text('Delete notification?',
            style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87)),
        content: Text(
          n.subject ?? 'This notification will be removed.',
          style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel',
                style: GoogleFonts.inter(
                    fontSize: 13.sp, color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('Delete',
                style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (ok != true) return false;
    return _ctrl.delete(n.id!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            CustomHeader(
              title: 'Notifications',
              showBackButton: true,
              trailing: Obx(() {
                final hasUnseen = _ctrl.unseenCount.value > 0;
                return TextButton(
                  onPressed: hasUnseen ? _onMarkAllRead : null,
                  child: Text(
                    'Mark all read',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color:
                          hasUnseen ? AppColors.primary : Colors.grey.shade400,
                    ),
                  ),
                );
              }),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Obx(() {
      // First-time loading shimmer (only when nothing cached).
      if (_ctrl.isLoading.value && _ctrl.notifications.isEmpty) {
        return const _NotificationsShimmer();
      }
      if (_ctrl.error.value != null && _ctrl.notifications.isEmpty) {
        return _ErrorState(
          message: _ctrl.error.value!,
          onRetry: () => _ctrl.load(force: true),
        );
      }
      if (_ctrl.notifications.isEmpty) {
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _ctrl.load(force: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: 200.h),
              Center(
                child: Text(
                  'No notifications yet',
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, color: Colors.grey.shade400),
                ),
              ),
            ],
          ),
        );
      }
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => _ctrl.load(force: true),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _ctrl.notifications.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final n = _ctrl.notifications[i];
            return Dismissible(
              key: ValueKey(n.id ?? i.toString()),
              direction: DismissDirection.endToStart,
              confirmDismiss: (_) => _confirmDelete(n),
              background: Container(
                color: Colors.red.shade500,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              child: NotificationCard(
                notification: n,
                onTap: () => _onTap(n),
              ),
            );
          },
        ),
      );
    });
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                  fontSize: 14.sp, color: Colors.grey.shade500)),
          SizedBox(height: 12.h),
          TextButton(
            onPressed: onRetry,
            child: Text('Retry',
                style: GoogleFonts.inter(
                    fontSize: 14.sp, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _NotificationsShimmer extends StatelessWidget {
  const _NotificationsShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300,
      highlightColor: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade100,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey.shade200),
        itemBuilder: (_, __) => Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 160.w, height: 12.h, color: Colors.white),
                    SizedBox(height: 8.h),
                    Container(
                        width: double.infinity,
                        height: 10.h,
                        color: Colors.white),
                    SizedBox(height: 8.h),
                    Container(width: 80.w, height: 9.h, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
