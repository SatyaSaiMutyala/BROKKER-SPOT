import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// One row in the Create Announcement wizard.
///
/// Shows:  [gold icon]  [stepNumber. Title \n subtitle \n? warning]  [✓ | ⓘ] [›]
/// Active step gets a 2px #DBC483 gold border; warning steps get the same border
/// plus orange warning text below the subtitle.
class FormSectionTile extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isComplete;
  final bool isEnabled;
  final bool isCurrent;
  final bool hasWarning;
  final String? warningText;
  // Replaces the checkmark+chevron on the right (used for the toggle on step 7).
  final Widget? trailingOverride;
  final VoidCallback? onTap;

  const FormSectionTile({
    super.key,
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isComplete = false,
    this.isEnabled = true,
    this.isCurrent = false,
    this.hasWarning = false,
    this.warningText,
    this.trailingOverride,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = (isCurrent || hasWarning)
        ? AppColors.primary
        : isDark
            ? const Color(0xFF2E2E2E)
            : const Color(0xFFF2F2F2);
    final borderWidth = (isCurrent || hasWarning) ? 2.0 : 1.0;
    final tileColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final titleColor = isEnabled
        ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
        : Colors.grey.shade600;
    final subtitleColor = isEnabled
        ? (isDark ? Colors.grey.shade400 : Colors.grey.shade500)
        : Colors.grey.shade600;
    final iconColor = isEnabled
        ? AppColors.primary
        : (isDark ? Colors.grey.shade700 : Colors.grey.shade300);
    final chevronColor = isEnabled
        ? (isDark ? Colors.grey.shade500 : Colors.grey.shade400)
        : (isDark ? Colors.grey.shade700 : Colors.grey.shade300);

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 19.w, vertical: 4.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(5.r),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Row(
          children: [
            Icon(icon, size: 26.sp, color: iconColor),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$stepNumber.  $title',
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                      height: 1.2,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w400,
                        color: subtitleColor,
                        height: 1.2,
                      ),
                    ),
                  ],
                  if (hasWarning && warningText != null) ...[
                    SizedBox(height: 2.h),
                    Text(
                      warningText!,
                      style: GoogleFonts.poppins(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 6.w),
            if (trailingOverride != null)
              trailingOverride!
            else ...[
              if (isComplete)
                _GreenCheck()
              else if (hasWarning)
                Icon(Icons.info_outline_rounded,
                    size: 18.sp, color: AppColors.primary)
              else
                SizedBox(width: 18.w),
              SizedBox(width: 4.w),
              Icon(Icons.chevron_right, size: 20.sp, color: chevronColor),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Green filled circle checkmark — 16×16, #149A35 ───────────────────────────

class _GreenCheck extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18.w,
      height: 18.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF149A35),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Icon(Icons.check_rounded,
          size: 11.sp, color: Colors.white),
    );
  }
}
