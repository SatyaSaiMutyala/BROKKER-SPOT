import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Saved announcements tab.
///
/// The backend has no wishlist endpoint yet, so this renders the empty state
/// only. When the API lands, drop a controller in and swap [_buildEmpty] for
/// the loaded list — the surrounding chrome already matches the other tabs.
class WishlistView extends StatelessWidget {
  const WishlistView({super.key});

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
            const CustomHeader(title: 'Wishlist', showBackButton: false),
            Expanded(child: _buildEmpty(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    final mutedText = isDark ? Colors.grey.shade500 : Colors.grey.shade400;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/broker_wishlist_icon.png',
              width: 56.w,
              height: 56.w,
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
              colorBlendMode: BlendMode.srcIn,
            ),
            SizedBox(height: 16.h),
            Text(
              'No saved properties yet',
              style: GoogleFonts.inter(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : const Color(0xFF1A1A1A),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Tap the heart on an announcement to keep it here for later.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                height: 1.5,
                color: mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
