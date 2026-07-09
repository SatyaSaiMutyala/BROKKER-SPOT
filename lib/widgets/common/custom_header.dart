import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Single reusable app bar used across every screen.
///
/// Title is left-aligned (poppins 20sp w500), matching the announcement /
/// meeting / broker-project screens. When [showBackButton] is true a circular
/// back-button appears to the left of the title. An optional [trailing] widget
/// is placed at the far right. A theme-aware hairline divider separates the
/// header from the content below.
class CustomHeader extends StatelessWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBack;
  final Widget? leading;
  final Widget? trailing;

  const CustomHeader({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.onBack,
    this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final iconColor = isDark ? Colors.white : Colors.black87;
    final iconBg =
        isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100;
    final dividerColor =
        isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200;

    Widget? leftWidget;
    if (leading != null) {
      leftWidget = leading!;
    } else if (showBackButton) {
      leftWidget = GestureDetector(
        onTap: onBack ?? () => Navigator.pop(context),
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 38.w,
          height: 38.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: iconBg,
          ),
          child: Icon(Icons.arrow_back_ios_new,
              size: 14.sp, color: iconColor),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 12.h),
          child: Row(
            children: [
              if (leftWidget != null) ...[
                leftWidget,
                SizedBox(width: 14.w),
              ],
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                    height: 1.0,
                    letterSpacing: 0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) ...[
                SizedBox(width: 10.w),
                trailing!,
              ],
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: dividerColor),
      ],
    );
  }
}
