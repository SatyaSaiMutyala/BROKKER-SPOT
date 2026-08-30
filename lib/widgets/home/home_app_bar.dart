import 'package:brokkerspot/core/common_widget/shimmer_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Shared home-screen app bar: avatar + greeting on the left, a
/// notification+search pill on the right. Used by both the user and broker
/// home screens so they stay visually identical.
class HomeAppBar extends StatelessWidget {
  final String avatarUrl;
  final bool isAvatarLoading;
  final String greetingName;
  final bool isGreetingLoading;
  final int notificationCount;
  final VoidCallback? onAvatarTap;
  final VoidCallback onNotificationTap;
  final VoidCallback onSearchTap;

  const HomeAppBar({
    super.key,
    required this.avatarUrl,
    this.isAvatarLoading = false,
    required this.greetingName,
    this.isGreetingLoading = false,
    required this.notificationCount,
    this.onAvatarTap,
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
            // The greeting is a single line now that the country came out, so
            // it lines up on the avatar's middle instead of its top edge.
            crossAxisAlignment: CrossAxisAlignment.center,
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
              if (isGreetingLoading)
                // Tracks the text's own box: 18sp on a 1.35 line.
                ShimmerBox(
                  width: 140.w,
                  height: 24.h,
                  borderRadius: BorderRadius.circular(4.r),
                )
              else
                Text(
                  'Hi, $greetingName',
                  style: GoogleFonts.poppins(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 18 * 0.05,
                    // Poppins needs 1.4em for its glyphs; a tight box shears
                    // the tops off once a long name ellipsises.
                    height: 1.35,
                  ),
                ),
            ],
          ),
        ),
        const Spacer(),
        // Notification pill (#FAF7F1, r:39). Was 91.w when it also held the
        // search icon — restore that width if search comes back.
        Container(
          width: 48.w,
          height: 42.h,
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF2A2A2A)
                : const Color(0xFFFAF7F1),
            borderRadius: BorderRadius.circular(39.r),
          ),
          // No side padding — the single icon is centred, and 12.w each side
          // left less room than the 26.sp bell needs.
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
              // Search icon — parked; the home screen has its own search bar.
              // GestureDetector(
              //   onTap: onSearchTap,
              //   behavior: HitTestBehavior.opaque,
              //   child: Image.asset(
              //     'assets/images/search_icon.png',
              //     width: 24.w,
              //     height: 24.w,
              //     color: theme.colorScheme.onSurface,
              //   ),
              // ),
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
