import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/widgets/common/custom_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

/// Centered notification-permission popup that gently **slides up from the
/// bottom** (not a docked bottom sheet).
///
/// Call [showIfNeeded] from a home screen after it's settled — it shows only
/// when permission isn't already granted, so it never blocks app startup.
class NotificationPermissionDialog extends StatelessWidget {
  const NotificationPermissionDialog({super.key});

  static bool _isShowing = false;

  static Future<void> showIfNeeded(BuildContext context) async {
    if (_isShowing) return;
    final status = await Permission.notification.status;
    if (status.isGranted || status.isLimited) return;
    if (!context.mounted) return;

    _isShowing = true;
    try {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Notifications',
        barrierColor: Colors.black.withValues(alpha: 0.45),
        // Slow, even, gentle rise from the bottom. easeInOutCubic glides
        // smoothly without the abrupt slow-down tail of easeOut.
        transitionDuration: const Duration(milliseconds: 1100),
        pageBuilder: (_, __, ___) => const NotificationPermissionDialog(),
        transitionBuilder: (_, anim, __, child) {
          final curved =
              CurvedAnimation(parent: anim, curve: Curves.easeInOutCubic);
          return FadeTransition(
            opacity: curved,
            // Rises from below the screen up to the center.
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      );
    } finally {
      _isShowing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 20.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76.w,
                  height: 76.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                  child: Icon(Icons.notifications_active_rounded,
                      size: 38.sp, color: AppColors.primary),
                ),
                SizedBox(height: 18.h),
                Text(
                  'Stay in the loop',
                  style: GoogleFonts.poppins(
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'Turn on notifications to get instant updates about new '
                  'proposals, messages, and deals on your announcements.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: Colors.black54,
                    height: 1.55,
                  ),
                ),
                SizedBox(height: 26.h),
                CustomPrimaryButton(
                  title: 'Allow Notifications',
                  backgroundColor: AppColors.primary,
                  defaultColor: Colors.white,
                  height: 52.h,
                  radius: 30,
                  fontWeight: FontWeight.w600,
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final current = await Permission.notification.status;
                    if (current.isPermanentlyDenied) {
                      await openAppSettings();
                    } else {
                      await Permission.notification.request();
                    }
                    navigator.pop();
                  },
                ),
                SizedBox(height: 6.h),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Maybe later',
                    style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black45),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
