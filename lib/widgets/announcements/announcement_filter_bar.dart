import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/controllers/common_data_controller.dart';
import 'package:brokkerspot/widgets/common/property_type_picker.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AnnouncementFilterBar extends StatelessWidget {
  final String? selectedListingType; // null | 'Sell' | 'Rent'
  final String? selectedPropertyType;
  final ValueChanged<String?> onListingTypeChanged;
  final ValueChanged<String?> onPropertyTypeChanged;

  /// Residential vs Commercial — the split every listing carries from the
  /// create form. `null` shows both.
  ///
  /// Optional: the chip only appears for hosts that pass
  /// [onIsCommercialChanged], so a screen with nothing to do with it is not
  /// forced to grow a filter it cannot honour.
  final bool? selectedIsCommercial;
  final ValueChanged<bool?>? onIsCommercialChanged;

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
    this.selectedIsCommercial,
    this.onIsCommercialChanged,
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
          // Category and type in one chip, one sheet — see
          // showPropertyTypeSheet. Replaces a fixed row of six type chips
          // that knew nothing of the admin-managed list or its categories.
          Padding(
            padding: EdgeInsets.only(left: 8.w),
            child: _propertyTypeChip(context, isDark),
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
        ],
      ),
    );
  }

  Widget _propertyTypeChip(BuildContext context, bool isDark) {
    final active = selectedIsCommercial != null || selectedPropertyType != null;
    return GestureDetector(
      onTap: () => _openPropertyTypeSheet(context),
      child: _chipShell(
        label: propertyTypeChipLabel(
          isCommercial: selectedIsCommercial,
          typeName: selectedPropertyType,
        ),
        isSelected: active,
        isDark: isDark,
        showChevron: true,
      ),
    );
  }

  /// The host screens filter by type *name*, so the sheet's pre-selection is
  /// looked up by name — within the chosen category, since a name can exist
  /// in both.
  Future<void> _openPropertyTypeSheet(BuildContext context) async {
    final category = selectedIsCommercial == null
        ? null
        : (selectedIsCommercial! ? 'commercial' : 'residential');
    final current = CommonDataController.to.propertyTypes.firstWhereOrNull(
        (t) =>
            t.name == selectedPropertyType &&
            (category == null || t.category == category));

    final picked = await showPropertyTypeSheet(
      context,
      isCommercial: selectedIsCommercial,
      typeId: current?.id,
    );
    if (picked == null) return; // dismissed
    onIsCommercialChanged?.call(picked.isCommercial);
    onPropertyTypeChanged(picked.typeName);
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
        _menuItem('', 'All', isDark, isActive: selectedListingType == null),
        _menuItem('Sell', 'Buy', isDark,
            isActive: selectedListingType == 'Sell'),
        _menuItem('Rent', 'Rent', isDark,
            isActive: selectedListingType == 'Rent'),
      ],
      child: _chipShell(
        label: label,
        isSelected: isSelected,
        isDark: isDark,
        showChevron: true,
      ),
    );
  }

  /// The pill every menu-backed chip in this bar wears, so the category chip
  /// and the listing chip can't drift apart.
  Widget _chipShell({
    required String label,
    required bool isSelected,
    required bool isDark,
    bool showChevron = false,
  }) {
    final foreground = isSelected
        ? Colors.white
        : isDark
            ? Colors.white70
            : Colors.black87;

    return Container(
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
              color: foreground,
              height: 1.0,
              letterSpacing: 0,
            ),
          ),
          if (showChevron) ...[
            SizedBox(width: 4.w),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14.sp,
              color: foreground,
            ),
          ],
        ],
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, String label, bool isDark,
      {required bool isActive}) {
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
