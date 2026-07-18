import 'package:brokkerspot/core/common_widget/shimmer_box.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared home-screen app bar: avatar + greeting/location on the left,
/// a notification+search pill on the right. Used by both the user and
/// broker home screens so they stay visually identical.
class HomeAppBar extends StatelessWidget {
  final String avatarUrl;
  final bool isAvatarLoading;
  final String greetingName;
  final bool isGreetingLoading;
  final String location;
  final int notificationCount;
  final VoidCallback? onAvatarTap;
  final VoidCallback? onLocationTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onSearchTap;

  const HomeAppBar({
    super.key,
    required this.avatarUrl,
    this.isAvatarLoading = false,
    required this.greetingName,
    this.isGreetingLoading = false,
    required this.location,
    required this.notificationCount,
    this.onAvatarTap,
    this.onLocationTap,
    required this.onNotificationTap,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        GestureDetector(
          onTap: onAvatarTap,
          child: Row(
            children: [
              // Avatar — 41×41 with 1px #DBC483 border
              Container(
                width: 41.w,
                height: 41.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFDBC483),
                    width: 1,
                  ),
                  color: Colors.grey.shade200,
                ),
                child: ClipOval(
                  child: isAvatarLoading
                      ? ShimmerCircle(radius: 19.w)
                      : avatarUrl.isNotEmpty
                          ? Image.network(
                              avatarUrl,
                              key: ValueKey(avatarUrl),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _avatarPlaceholder(),
                            )
                          : _avatarPlaceholder(),
                ),
              ),
              SizedBox(width: 12.w),
              // Greeting + location
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isGreetingLoading) ...[
                    ShimmerBox(
                        width: 120.w,
                        height: 18.h,
                        borderRadius: BorderRadius.circular(4.r)),
                    SizedBox(height: 4.h),
                    ShimmerBox(
                        width: 80.w,
                        height: 14.h,
                        borderRadius: BorderRadius.circular(4.r)),
                  ] else ...[
                    Text(
                      'Hi, $greetingName',
                      style: GoogleFonts.poppins(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: 14 * 0.075,
                        height: 1.0,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    GestureDetector(
                      onTap: onLocationTap,
                      child: Row(
                        children: [
                          Icon(Icons.location_on_rounded,
                              size: 15.sp, color: AppColors.primary),
                          SizedBox(width: 2.w),
                          Text(
                            location,
                            style: GoogleFonts.poppins(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w300,
                              color: theme.colorScheme.onSurface,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        // Notification + Search — single pill (#FAF7F1, 91×41, r:39)
        Container(
          width: 91.w,
          height: 42.h,
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF2A2A2A)
                : const Color(0xFFFAF7F1),
            borderRadius: BorderRadius.circular(39.r),
          ),
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Notification bell — outline, 1.5px stroke #343434
              GestureDetector(
                onTap: onNotificationTap,
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      size: 26.sp,
                      color: theme.colorScheme.onSurface,
                    ),
                    if (notificationCount > 0)
                      Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          width: 14.w,
                          height: 14.w,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: Colors.red),
                          child: Center(
                            child: Text(
                              notificationCount > 9
                                  ? '9+'
                                  : '$notificationCount',
                              style: GoogleFonts.inter(
                                  fontSize: 7.sp,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Search icon — asset, 20×20
              GestureDetector(
                onTap: onSearchTap,
                behavior: HitTestBehavior.opaque,
                child: Image.asset(
                  'assets/images/search_icon.png',
                  width: 24.w,
                  height: 24.w,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _avatarPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: Icon(Icons.person, size: 22.sp, color: Colors.grey),
    );
  }
}
