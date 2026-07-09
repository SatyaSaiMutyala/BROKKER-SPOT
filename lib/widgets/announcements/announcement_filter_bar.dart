import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

/// Listing-type dropdown chip ("All"/"Buy"/"Rent") + property-type chip row,
/// shared by the user and broker Announcements screens so both filter the
/// same way and look identical.
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
  final VoidCallback onListingTap;
  final ValueChanged<String?> onPropertyTypeChanged;

  const AnnouncementFilterBar({
    super.key,
    required this.selectedListingType,
    required this.selectedPropertyType,
    required this.onListingTap,
    required this.onPropertyTypeChanged,
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
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        children: [
          _chip(
            label: listingLabel,
            isSelected: selectedListingType != null,
            hasDropdown: true,
            isDark: isDark,
            onTap: onListingTap,
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

  Widget _chip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    bool hasDropdown = false,
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
            if (hasDropdown) ...[
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
          ],
        ),
      ),
    );
  }
}
