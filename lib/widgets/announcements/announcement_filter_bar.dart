import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AnnouncementFilterBar extends StatelessWidget {
  static const propertyTypes = [
    'Apartment',
    'Villa',
    'Studio',
    'Penthouse',
    'Townhouse',
    'Office',
  ];

  final String? selectedListingType; // null | 'Sell' | 'Rent'
  final String? selectedPropertyType;
  final ValueChanged<String?> onListingTypeChanged;
  final ValueChanged<String?> onPropertyTypeChanged;

  /// Side inset, so a host screen can line the chips up with its own gutter.
  final double? horizontalPadding;

  /// Whether the Draft chip rides in this bar. Only "My Announcements" has
  /// drafts to filter — the public feeds never see them.
  ///
  /// Unlike the two above, which sieve the page already fetched, this one is a
  /// server-side `?status=0`: a draft that hasn't been paged in yet would be
  /// missed otherwise. [onDraftChanged] fires with the new state.
  final bool showDraftChip;
  final bool draftSelected;
  final ValueChanged<bool>? onDraftChanged;

  const AnnouncementFilterBar({
    super.key,
    required this.selectedListingType,
    required this.selectedPropertyType,
    required this.onListingTypeChanged,
    required this.onPropertyTypeChanged,
    this.horizontalPadding,
    this.showDraftChip = false,
    this.draftSelected = false,
    this.onDraftChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final listingLabel = selectedListingType == null
        ? 'All'
        : selectedListingType == 'Sell'
            ? 'Buy'
            : 'Rent';

    return SizedBox(
      height: 39.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding ?? 16.w),
        children: [
          _listingChip(
            context: context,
            label: listingLabel,
            isSelected: selectedListingType != null,
            isDark: isDark,
          ),
          // Sits right after the listing chip, ahead of the property types —
          // it narrows the whole list rather than picking a kind of property.
          if (showDraftChip)
            Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: _chip(
                label: 'Draft',
                isSelected: draftSelected,
                isDark: isDark,
                onTap: () => onDraftChanged?.call(!draftSelected),
              ),
            ),
          ...propertyTypes.map((type) {
            final isSelected = selectedPropertyType == type;
            return Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: _chip(
                label: type,
                isSelected: isSelected,
                isDark: isDark,
                onTap: () => onPropertyTypeChanged(isSelected ? null : type),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _listingChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required bool isDark,
  }) {
    return PopupMenuButton<String>(
      onSelected: (val) => onListingTypeChanged(val.isEmpty ? null : val),
      offset: const Offset(0, 42),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      itemBuilder: (_) => [
        _menuItem('', 'All', isDark),
        _menuItem('Sell', 'Buy', isDark),
        _menuItem('Rent', 'Rent', isDark),
      ],
      child: Container(
        height: 38.h,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : isDark
                  ? const Color(0xFF2A2A2A)
                  : Colors.white,
          borderRadius: BorderRadius.circular(25.r),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? Colors.white70
                        : Colors.black87,
                height: 1.0,
                letterSpacing: 0,
              ),
            ),
            SizedBox(width: 4.w),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14.sp,
              color: isSelected
                  ? Colors.white
                  : isDark
                      ? Colors.white70
                      : Colors.black87,
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, String label, bool isDark) {
    final isActive = value.isEmpty
        ? selectedListingType == null
        : selectedListingType == value;
    return PopupMenuItem<String>(
      value: value,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive
                    ? AppColors.primary
                    : isDark
                        ? Colors.white
                        : Colors.black87,
              ),
            ),
          ),
          if (isActive)
            Icon(Icons.check, size: 14.sp, color: AppColors.primary),
        ],
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38.h,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : isDark
                  ? const Color(0xFF2A2A2A)
                  : Colors.white,
          borderRadius: BorderRadius.circular(25.r),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
            color: isSelected
                ? Colors.white
                : isDark
                    ? Colors.white70
                    : Colors.black87,
            height: 1.0,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
