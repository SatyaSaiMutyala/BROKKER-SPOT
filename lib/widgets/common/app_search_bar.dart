import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Gold-bordered search field with the filter button beside it.
///
/// Used both as a live input (Search screen) and as a tap target that opens
/// the search screen (Home) — pass [readOnly] with [onTap] for the latter.
class AppSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// Tapping anywhere on the field. Combine with [readOnly] to hand off to a
  /// dedicated search screen instead of typing in place.
  final VoidCallback? onTap;
  final bool readOnly;

  final VoidCallback? onFilterTap;

  /// Hides the trailing filter button when a screen has no filters to open.
  final bool showFilterButton;

  /// Side inset, so a host screen can line the bar up with its own gutter.
  final double? horizontalPadding;

  const AppSearchBar({
    super.key,
    this.controller,
    this.hintText = 'City, Area or Building...',
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
    this.onFilterTap,
    this.showFilterButton = true,
    this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding ?? 12.w),
      child: Row(
        children: [
          Expanded(child: _buildField(theme, isDark)),
          if (showFilterButton) ...[
            SizedBox(width: 6.w),
            GestureDetector(
              onTap: onFilterTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 46.w,
                height: 45.h,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(39.r),
                  border: Border.all(color: AppColors.primary, width: 1),
                ),
                // The asset ships with square-ish corners, so clip it to the
                // pill shape rather than letting them poke out.
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/filter_icon.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildField(ThemeData theme, bool isDark) {
    return Container(
      height: 45.h,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(color: AppColors.primary, width: 1),
      ),
      child: Row(
        children: [
          SizedBox(width: 12.w),
          Image.asset(
            'assets/images/search_icon.png',
            width: 18.w,
            height: 18.w,
            color: AppColors.primary,
            colorBlendMode: BlendMode.srcIn,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              onTap: onTap,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                color: theme.colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: true,
                fillColor: Colors.transparent,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14.h),
              ),
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
    );
  }
}
