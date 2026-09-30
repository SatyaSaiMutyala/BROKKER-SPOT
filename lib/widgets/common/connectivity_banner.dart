import 'package:brokkerspot/core/services/connectivity_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

/// App-wide "offline" popup — a dimmed, centered card that appears the
/// moment the device loses network connectivity, and disappears the moment
/// it's restored, so the user is never left acting on a dead connection
/// without knowing it. Mounted once above the whole app (see [MyApp]'s
/// `builder`), not per-screen.
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      final isOnline = ConnectivityService.to.isOnline.value;
      return IgnorePointer(
        ignoring: isOnline,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: isOnline ? 0 : 1,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black.withValues(alpha: 0.55),
            alignment: Alignment.center,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              scale: isOnline ? 0.85 : 1,
              child: Container(
                width: 260.w,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(18.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56.w,
                      height: 56.w,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.wifi_off_rounded,
                          color: Colors.red.shade600, size: 28.w),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'No Internet Connection',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w700,
                        fontSize: 16.sp,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Please check your connection.\nWe\'ll reconnect automatically.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        fontSize: 13.sp,
                        height: 1.4,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
