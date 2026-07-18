import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class AppToast {
  static void _show({
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    if (Get.isSnackbarOpen) Get.closeAllSnackbars();
    Get.showSnackbar(
      GetSnackBar(
        messageText: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18.sp),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        borderRadius: 14.r,
        margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
        forwardAnimationCurve: Curves.easeOutBack,
        reverseAnimationCurve: Curves.easeIn,
        animationDuration: const Duration(milliseconds: 350),
        boxShadows: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
    );
  }

  static void show(String message) {
    _show(
      message: message,
      backgroundColor: const Color(0xFF1A1A2E),
      icon: Icons.info_outline_rounded,
    );
  }

  static void success(String message) {
    _show(
      message: message,
      backgroundColor: const Color(0xFF1B6B3A),
      icon: Icons.check_circle_rounded,
    );
  }

  static void error(String message) {
    _show(
      message: message,
      backgroundColor: const Color(0xFFC0392B),
      icon: Icons.cancel_rounded,
    );
  }

  static void warning(String message) {
    _show(
      message: message,
      backgroundColor: const Color(0xFFB8600A),
      icon: Icons.warning_amber_rounded,
    );
  }

  static void topToast(String message, {IconData icon = Icons.check_circle_rounded, Color? color}) {
    if (Get.isSnackbarOpen) Get.closeAllSnackbars();
    Get.showSnackbar(
      GetSnackBar(
        messageText: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: color ?? const Color(0xFF1B6B3A),
        borderRadius: 12.r,
        margin: EdgeInsets.fromLTRB(16.w, 48.h, 16.w, 0),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        snackPosition: SnackPosition.TOP,
        duration: const Duration(milliseconds: 800),
        isDismissible: true,
        dismissDirection: DismissDirection.horizontal,
        animationDuration: const Duration(milliseconds: 250),
      ),
    );
  }
}
