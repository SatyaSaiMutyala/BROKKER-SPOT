import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/controllers/common_data_controller.dart';
import 'package:brokkerspot/models/property_type_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// A category and a kind of property, picked together.
///
/// [isCommercial] null means either category; [typeId] null means any type
/// within it. A type always belongs to the category it was picked under.
class PropertyTypeSelection {
  final bool? isCommercial;
  final String? typeId;
  final String? typeName;

  const PropertyTypeSelection({this.isCommercial, this.typeId, this.typeName});

  static const none = PropertyTypeSelection();

  bool get isEmpty => isCommercial == null && typeId == null;
}

/// Residential / Commercial on top, that category's types as icon tiles below.
///
/// One control for both, because they are one decision: a type lives in
/// exactly one category — the reference list carries a Villa, a Building, a
/// Floor and a Land on each side as separate records — so picking them apart
/// let the two disagree and the filter match nothing.
///
/// Controlled: it shows [isCommercial] / [selectedTypeId] and reports every
/// change through [onChanged]. Used inside [showPropertyTypeSheet] and
/// directly on the full filter screen.
class PropertyTypePicker extends StatelessWidget {
  final bool? isCommercial;
  final String? selectedTypeId;
  final ValueChanged<PropertyTypeSelection> onChanged;

  const PropertyTypePicker({
    super.key,
    required this.isCommercial,
    required this.selectedTypeId,
    required this.onChanged,
  });

  /// The category whose tiles are on show. Residential until one is picked —
  /// where most listings are — without counting as picked.
  bool get _showingCommercial => isCommercial ?? false;

  PropertyTypeSelection get _current =>
      PropertyTypeSelection(isCommercial: isCommercial, typeId: selectedTypeId);

  void _onCategoryTap(bool commercial) =>
      onChanged(selectCategory(_current, commercial));

  void _onTypeTap(PropertyTypeModel type) =>
      onChanged(selectType(_current, type));

  /// The selection after tapping a category tab.
  ///
  /// Tapping the active one again lets go of it and of its type. Switching
  /// drops the type, which belongs to the category being left.
  static PropertyTypeSelection selectCategory(
      PropertyTypeSelection current, bool commercial) {
    if (current.isCommercial == commercial) return PropertyTypeSelection.none;
    return PropertyTypeSelection(isCommercial: commercial);
  }

  /// The selection after tapping a type tile.
  ///
  /// Tapping the selected tile lets go of the type but keeps the category.
  /// Picking one settles the category it was shown under — Residential when
  /// none was picked, since that is the list on show.
  static PropertyTypeSelection selectType(
      PropertyTypeSelection current, PropertyTypeModel type) {
    if (current.typeId == type.id) {
      return PropertyTypeSelection(isCommercial: current.isCommercial);
    }
    return PropertyTypeSelection(
      isCommercial: current.isCommercial ?? false,
      typeId: type.id,
      typeName: type.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _categoryTab('Residential', false, isDark),
            SizedBox(width: 12.w),
            _categoryTab('Commercial', true, isDark),
          ],
        ),
        SizedBox(height: 16.h),
        _typeTiles(isDark),
      ],
    );
  }

  Widget _categoryTab(String label, bool commercial, bool isDark) {
    final selected = isCommercial == commercial;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onCategoryTap(commercial),
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 46.h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.14)
                : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected
                  ? AppColors.primary
                  : (isDark ? Colors.white70 : Colors.black54),
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeTiles(bool isDark) {
    final common = CommonDataController.to;
    return Obx(() {
      final wanted = _showingCommercial ? 'commercial' : 'residential';
      final types =
          common.propertyTypes.where((t) => t.category == wanted).toList();

      if (types.isEmpty) {
        return SizedBox(
          height: 100.h,
          child: Center(
            child: common.isLoadingPropertyTypes.value
                ? SizedBox(
                    width: 22.w,
                    height: 22.w,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  )
                : Text(
                    'No property types',
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
          ),
        );
      }

      return SizedBox(
        height: 100.h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          itemCount: types.length,
          separatorBuilder: (_, __) => SizedBox(width: 10.w),
          itemBuilder: (_, i) => _typeTile(types[i], isDark),
        ),
      );
    });
  }

  Widget _typeTile(PropertyTypeModel type, bool isDark) {
    final selected = selectedTypeId == type.id;
    final accent = selected
        ? AppColors.primary
        : (isDark ? Colors.white60 : Colors.black45);
    return GestureDetector(
      onTap: () => _onTypeTap(type),
      child: Container(
        width: 96.w,
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.10)
              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconForPropertyType(type.name), size: 28.sp, color: accent),
            SizedBox(height: 8.h),
            Text(
              type.name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 11.sp,
                height: 1.2,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? AppColors.primary
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An icon for a property type, by name — the reference list carries no
/// icon of its own, and types are added from the admin panel.
///
/// Longer names are checked before the shorter ones they contain ("Villa
/// Compound" before "Villa", "Industrial Land" before "Land"); anything
/// unrecognised gets the generic building.
IconData iconForPropertyType(String name) {
  final n = name.toLowerCase();
  if (n.contains('penthouse')) return Icons.roofing;
  if (n.contains('hotel')) return Icons.hotel_outlined;
  if (n.contains('villa compound')) return Icons.holiday_village_outlined;
  if (n.contains('townhouse')) return Icons.holiday_village_outlined;
  if (n.contains('villa')) return Icons.villa_outlined;
  if (n.contains('apartment')) return Icons.apartment;
  if (n.contains('studio')) return Icons.bed_outlined;
  if (n.contains('building')) return Icons.location_city;
  if (n.contains('floor')) return Icons.layers_outlined;
  if (n.contains('industrial') || n.contains('factory')) {
    return Icons.factory_outlined;
  }
  if (n.contains('mixed')) return Icons.maps_home_work_outlined;
  if (n.contains('land') || n.contains('plot')) {
    return Icons.landscape_outlined;
  }
  if (n.contains('labour') || n.contains('labor')) return Icons.groups_outlined;
  if (n.contains('bulk')) return Icons.inventory_2_outlined;
  if (n.contains('office')) return Icons.business_center_outlined;
  if (n.contains('showroom')) return Icons.storefront_outlined;
  if (n.contains('shop')) return Icons.store_outlined;
  if (n.contains('warehouse')) return Icons.warehouse_outlined;
  return Icons.home_work_outlined;
}

/// The Property Types sheet: header, [PropertyTypePicker], Apply.
///
/// Resolves to the picked selection on Apply — [PropertyTypeSelection.none]
/// after Clear — or null when dismissed without applying.
Future<PropertyTypeSelection?> showPropertyTypeSheet(
  BuildContext context, {
  bool? isCommercial,
  String? typeId,
}) {
  FocusScope.of(context).unfocus(); // no filter needs the keyboard
  CommonDataController.to.loadPropertyTypes();
  final isDark = Theme.of(context).brightness == Brightness.dark;

  var current = PropertyTypeSelection(
    isCommercial: isCommercial,
    typeId: typeId,
  );

  return showModalBottomSheet<PropertyTypeSelection>(
    context: context,
    backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    isScrollControlled: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheet) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Icon(Icons.home_rounded,
                      size: 24.sp, color: AppColors.primary),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Property Types',
                      style: GoogleFonts.poppins(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  if (!current.isEmpty)
                    GestureDetector(
                      onTap: () => Navigator.of(ctx)
                          .pop(PropertyTypeSelection.none),
                      child: Text(
                        'Clear',
                        style: GoogleFonts.poppins(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 20.h),
              PropertyTypePicker(
                isCommercial: current.isCommercial,
                selectedTypeId: current.typeId,
                onChanged: (next) => setSheet(() => current = next),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(current),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                  ),
                  child: Text(
                    'Apply',
                    style: GoogleFonts.poppins(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The filter chip's label for a selection: the type when one is picked,
/// else the category, else [placeholder].
String propertyTypeChipLabel({
  bool? isCommercial,
  String? typeName,
  String placeholder = 'Property Type',
}) {
  if (typeName != null && typeName.isNotEmpty) return typeName;
  if (isCommercial == null) return placeholder;
  return isCommercial ? 'Commercial' : 'Residential';
}
