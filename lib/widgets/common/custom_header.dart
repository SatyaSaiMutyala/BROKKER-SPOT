import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/widgets/common/custom_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Single reusable app bar used across every screen.
///
/// Dark theme: [AppColors.appBarDarkBg] background, 0.5 px divider.
/// Back button is handled by [CustomBackButton].
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
    final iconColor =
        isDark ? AppColors.backBtnDarkIcon : AppColors.backBtnLightIcon;
    final bg = isDark ? AppColors.appBarDarkBg : AppColors.appBarLightBg;
    final borderColor =
        isDark ? AppColors.appBarDarkBorder : AppColors.appBarLightBorder;

    Widget? leftWidget;
    if (leading != null) {
      leftWidget = leading!;
    } else if (showBackButton) {
      leftWidget = CustomBackButton(
        isDark: isDark,
        iconColor: iconColor,
        onTap: onBack ?? () => Navigator.pop(context),
      );
    }

    return Container(
      color: bg,
      child: Column(
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
          Divider(height: 0.5, thickness: 0.5, color: borderColor),
        ],
      ),
    );
  }
}
