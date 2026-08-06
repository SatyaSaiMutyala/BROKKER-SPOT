import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/controllers/common_data_controller.dart';
import 'package:brokkerspot/models/property_filter_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// Horizontal scrollable chip row. Each chip opens a themed bottom sheet.
/// Calls [onFilterChanged] with an updated [PropertyFilter] whenever the
/// user applies a selection. Callers forward this to PropertySearchController.
class HomeFilterBar extends StatelessWidget {
  final PropertyFilter filter;
  final ValueChanged<PropertyFilter> onFilterChanged;
  final double? horizontalPadding;

  const HomeFilterBar({
    super.key,
    required this.filter,
    required this.onFilterChanged,
    this.horizontalPadding,
  });

  static const double _priceFloor = 0;
  static const double _priceCeil = 10000000;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final chips = <Widget>[];

    // ── 1. Buy / Rent ──────────────────────────────────────────────────────
    final listingLabel = filter.listingType == 1
        ? 'Buy'
        : filter.listingType == 2
            ? 'Rent'
            : 'All';
    chips.add(_chip(
      context: context,
      label: listingLabel,
      isActive: filter.listingType != null,
      isDark: isDark,
      onTap: () => _showListingTypeSheet(context, isDark),
    ));

    // ── 2. Property status: grouped segmented pill (All | Ready | Off Plan) ──
    chips.add(SizedBox(width: 8.w));
    chips.add(_statusGroup(isDark));

    // ── 3. Property Type ───────────────────────────────────────────────────
    chips.add(SizedBox(width: 8.w));
    chips.add(_chip(
      context: context,
      label: filter.propertyTypeName ?? 'Type',
      isActive: filter.propertyTypeId != null,
      isDark: isDark,
      onTap: () => _showPropertyTypeSheet(context, isDark),
    ));

    // ── 4. Bedrooms ────────────────────────────────────────────────────────
    final bedsLabel = filter.bedrooms == null
        ? 'Beds'
        : '${filter.bedrooms} Bed${filter.bedrooms == 1 ? '' : 's'}';
    chips.add(SizedBox(width: 8.w));
    chips.add(_chip(
      context: context,
      label: bedsLabel,
      isActive: filter.bedrooms != null,
      isDark: isDark,
      onTap: () => _showBedsSheet(context, isDark),
    ));

    // ── 5. Price ───────────────────────────────────────────────────────────
    final priceLabel = (filter.minPrice != null || filter.maxPrice != null)
        ? '${_fmt(filter.minPrice ?? _priceFloor)}-${_fmt(filter.maxPrice ?? _priceCeil)}'
        : 'Price';
    chips.add(SizedBox(width: 8.w));
    chips.add(_chip(
      context: context,
      label: priceLabel,
      isActive: filter.minPrice != null || filter.maxPrice != null,
      isDark: isDark,
      onTap: () => _showPriceSheet(context, isDark),
    ));

    // ── 6. Bathrooms ───────────────────────────────────────────────────────
    final bathsLabel = filter.bathrooms == null
        ? 'Baths'
        : '${filter.bathrooms} Bath${filter.bathrooms == 1 ? '' : 's'}';
    chips.add(SizedBox(width: 8.w));
    chips.add(_chip(
      context: context,
      label: bathsLabel,
      isActive: filter.bathrooms != null,
      isDark: isDark,
      onTap: () => _showBathsSheet(context, isDark),
    ));

    // ── 7. Reset All Filters ───────────────────────────────────────────────
    if (!filter.hasNoFacets) {
      chips.add(SizedBox(width: 12.w));
      chips.add(GestureDetector(
        onTap: () => onFilterChanged(PropertyFilter.empty),
        child: Center(
          child: Text(
            'Reset All Filters',
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ),
      ));
    }

    return SizedBox(
      height: 39.h,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding ?? 16.w),
        children: chips,
      ),
    );
  }

  // ── Chip widget ────────────────────────────────────────────────────────────

  Widget _chip({
    required BuildContext context,
    required String label,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38.h,
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary
              : isDark
                  ? const Color(0xFF2A2A2A)
                  : Colors.white,
          borderRadius: BorderRadius.circular(25.r),
          border: isActive
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
                color: isActive
                    ? Colors.white
                    : isDark
                        ? Colors.white70
                        : Colors.black87,
                height: 1.0,
                letterSpacing: 0,
              ),
            ),
            if (showArrow) ...[
              SizedBox(width: 4.w),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 14.sp,
                color: isActive
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

  /// Contextual segmented pill:
  ///  • Buy / All → Ready | Off Plan   (drives `propertyStatus`: 1 / 2)
  ///  • Rent       → Yearly | Monthly  (drives `rentPeriod`)
  Widget _statusGroup(bool isDark) {
    final status = filter.propertyStatus; // null=All, 1=Ready, 2=Off Plan
    final isRent = filter.listingType == 2;
    final rentPeriod = filter.rentPeriod; // 'Yearly' | 'Monthly' | null

    Widget seg(String label, bool isActive, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 38.h,
          padding: EdgeInsets.symmetric(horizontal: 14.w),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(25.r),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: isActive
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

    return Container(
      height: 38.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: isRent
            ? [
                // Rent → Yearly | Monthly (drives rentPeriod).
                seg(
                  'Yearly',
                  rentPeriod == 'Yearly',
                  () => onFilterChanged(
                    rentPeriod == 'Yearly'
                        ? filter.cleared(rentPeriod: true)
                        : filter.copyWith(rentPeriod: 'Yearly'),
                  ),
                ),
                seg(
                  'Monthly',
                  rentPeriod == 'Monthly',
                  () => onFilterChanged(
                    rentPeriod == 'Monthly'
                        ? filter.cleared(rentPeriod: true)
                        : filter.copyWith(rentPeriod: 'Monthly'),
                  ),
                ),
              ]
            : [
                // Buy / All → Ready | Off Plan (drives propertyStatus).
                seg(
                  'Ready',
                  status == 1,
                  () => onFilterChanged(
                    status == 1
                        ? filter.cleared(propertyStatus: true)
                        : filter.copyWith(propertyStatus: 1),
                  ),
                ),
                seg(
                  'Off Plan',
                  status == 2,
                  () => onFilterChanged(
                    status == 2
                        ? filter.cleared(propertyStatus: true)
                        : filter.copyWith(propertyStatus: 2),
                  ),
                ),
              ],
      ),
    );
  }

  // ── Bottom sheets ──────────────────────────────────────────────────────────

  void _showListingTypeSheet(BuildContext context, bool isDark) {
    FocusScope.of(context).unfocus(); // no filter needs the keyboard
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 32.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _handle(isDark),
            SizedBox(height: 20.h),
            _title('Property For', isDark),
            SizedBox(height: 20.h),
            Row(
              children: [
                _optionTile(
                  'All',
                  filter.listingType == null,
                  isDark,
                  () {
                    onFilterChanged(filter.cleared(
                      listingType: true,
                      propertyStatus: true,
                      rentPeriod: true,
                    ));
                    Navigator.of(ctx).pop();
                  },
                ),
                SizedBox(width: 12.w),
                _optionTile(
                  'Buy',
                  filter.listingType == 1,
                  isDark,
                  () {
                    onFilterChanged(
                      filter.copyWith(listingType: 1).cleared(rentPeriod: true),
                    );
                    Navigator.of(ctx).pop();
                  },
                ),
                SizedBox(width: 12.w),
                _optionTile(
                  'Rent',
                  filter.listingType == 2,
                  isDark,
                  () {
                    onFilterChanged(
                      filter
                          .copyWith(listingType: 2)
                          .cleared(propertyStatus: true),
                    );
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPropertyTypeSheet(BuildContext context, bool isDark) {
    FocusScope.of(context).unfocus(); // no filter needs the keyboard
    final common = CommonDataController.to;
    common.loadPropertyTypes();

    String? selId = filter.propertyTypeId;
    String? selName = filter.propertyTypeName;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _handle(isDark)),
              SizedBox(height: 20.h),
              _title('Property Type', isDark),
              SizedBox(height: 16.h),
              Obx(() {
                final types = common.propertyTypes;
                if (common.isLoadingPropertyTypes.value && types.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.h),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary),
                    ),
                  );
                }
                return Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: types.map((t) {
                    final isSel = selId == t.id;
                    return GestureDetector(
                      onTap: () => setSheet(() {
                        if (isSel) {
                          selId = null;
                          selName = null;
                        } else {
                          selId = t.id;
                          selName = t.name;
                        }
                      }),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 9.h),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: isSel
                                ? AppColors.primary
                                : isDark
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          t.name,
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w400,
                            color: isSel
                                ? Colors.white
                                : isDark
                                    ? Colors.white70
                                    : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }),
              SizedBox(height: 20.h),
              _applyBtn(() {
                onFilterChanged(
                  selId == null
                      ? filter.cleared(propertyType: true)
                      : filter.copyWith(
                          propertyTypeId: selId,
                          propertyTypeName: selName,
                        ),
                );
                Navigator.of(ctx).pop();
              }, isDark),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  void _showBedsSheet(BuildContext context, bool isDark) {
    FocusScope.of(context).unfocus(); // no filter needs the keyboard
    const opts = ['1', '2', '3', '4', '5+'];
    int? sel = filter.bedrooms;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _handle(isDark)),
              SizedBox(height: 20.h),
              _title('Bedrooms', isDark),
              SizedBox(height: 16.h),
              Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: opts.map((opt) {
                  final val = opt == '5+' ? 5 : int.parse(opt);
                  final isSel = sel == val;
                  return _countChip(
                    opt,
                    isSel,
                    isDark,
                    () => setSheet(() => sel = isSel ? null : val),
                  );
                }).toList(),
              ),
              SizedBox(height: 20.h),
              _applyBtn(() {
                onFilterChanged(
                  sel == null
                      ? filter.cleared(bedrooms: true)
                      : filter.copyWith(bedrooms: sel),
                );
                Navigator.of(ctx).pop();
              }, isDark),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  void _showPriceSheet(BuildContext context, bool isDark) {
    // Dismiss any lingering keyboard; the min/max fields only focus on tap.
    FocusScope.of(context).unfocus();
    var price = RangeValues(
      (filter.minPrice ?? _priceFloor).clamp(_priceFloor, _priceCeil),
      (filter.maxPrice ?? _priceCeil).clamp(_priceFloor, _priceCeil),
    );

    final minCtrl = TextEditingController(
      text: price.start > _priceFloor ? price.start.round().toString() : '',
    );
    final maxCtrl = TextEditingController(
      text: price.end < _priceCeil ? price.end.round().toString() : '',
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      // The min/max fields summon the keyboard, and this is the only filter
      // sheet that has one. viewInsets.bottom lifts the sheet clear of the
      // keyboard; the scroll view keeps the content reachable on short screens
      // where the keyboard leaves too little room for the whole sheet.
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (ctx, setSheet) {
              void syncFromSlider(RangeValues v) {
                setSheet(() => price = v);
                minCtrl.text =
                    v.start > _priceFloor ? v.start.round().toString() : '';
                maxCtrl.text =
                    v.end < _priceCeil ? v.end.round().toString() : '';
              }

              void syncFromMin(String val) {
                final n = double.tryParse(val.replaceAll(',', ''));
                if (n == null) return;
                final clamped = n.clamp(_priceFloor, price.end);
                setSheet(() => price = RangeValues(clamped, price.end));
              }

              void syncFromMax(String val) {
                final n = double.tryParse(val.replaceAll(',', ''));
                if (n == null) return;
                final clamped = n.clamp(price.start, _priceCeil);
                setSheet(() => price = RangeValues(price.start, clamped));
              }

              final borderColor =
                  isDark ? Colors.grey.shade700 : Colors.grey.shade300;
              final labelStyle = GoogleFonts.poppins(
                fontSize: 12.sp,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
              );
              final fieldStyle = GoogleFonts.poppins(
                fontSize: 14.sp,
                color: isDark ? Colors.white : Colors.black87,
              );

              return Padding(
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _handle(isDark),
                    SizedBox(height: 20.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _title('Price Range (AED)', isDark),
                        GestureDetector(
                          onTap: () => setSheet(() {
                            price = RangeValues(_priceFloor, _priceCeil);
                            minCtrl.clear();
                            maxCtrl.clear();
                          }),
                          child: Text(
                            'Reset',
                            style: GoogleFonts.poppins(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    // ── Min / Max text fields ──────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 52.h,
                                decoration: BoxDecoration(
                                  border: Border.all(color: borderColor),
                                  borderRadius: BorderRadius.circular(10.r),
                                  color: Colors.transparent,
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 14.w),
                                alignment: Alignment.centerLeft,
                                child: TextField(
                                  controller: minCtrl,
                                  keyboardType: TextInputType.number,
                                  style: fieldStyle,
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    hintStyle: GoogleFonts.poppins(
                                      fontSize: 14.sp,
                                      color: isDark
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade400,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: syncFromMin,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text('Minimum', style: labelStyle),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: 20.h),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.w),
                            child: Text('to',
                                style: GoogleFonts.poppins(
                                  fontSize: 14.sp,
                                  color:
                                      isDark ? Colors.white70 : Colors.black54,
                                )),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 52.h,
                                decoration: BoxDecoration(
                                  border: Border.all(color: borderColor),
                                  borderRadius: BorderRadius.circular(10.r),
                                  color: Colors.transparent,
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 14.w),
                                alignment: Alignment.centerLeft,
                                child: TextField(
                                  controller: maxCtrl,
                                  keyboardType: TextInputType.number,
                                  style: fieldStyle,
                                  decoration: InputDecoration(
                                    hintText: 'Any',
                                    hintStyle: GoogleFonts.poppins(
                                      fontSize: 14.sp,
                                      color: isDark
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade400,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    filled: true,
                                    fillColor: Colors.transparent,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: syncFromMax,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text('Maximum', style: labelStyle),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16.h),
                    // ── Range slider ───────────────────────────────────────
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3.h,
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: isDark
                            ? const Color(0xFF3A3A3A)
                            : const Color(0xFFDDDDDD),
                        thumbColor: AppColors.primary,
                        overlayColor: AppColors.primary.withValues(alpha: 0.15),
                        rangeThumbShape:
                            RoundRangeSliderThumbShape(enabledThumbRadius: 9.r),
                      ),
                      child: RangeSlider(
                        values: price,
                        min: _priceFloor,
                        max: _priceCeil,
                        divisions: 100,
                        onChanged: syncFromSlider,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _applyBtn(() {
                      var f = filter.cleared(price: true);
                      // The price filter is "engaged" once either handle moves off
                      // the full-range extremes. When it is, send BOTH bounds
                      // explicitly — including min_price=0 (a real lower bound the
                      // user picked, not the same as "no minimum").
                      final priceEngaged =
                          price.start > _priceFloor || price.end < _priceCeil;
                      if (priceEngaged) {
                        f = f.copyWith(
                          minPrice: price.start,
                          maxPrice: price.end,
                        );
                      }
                      onFilterChanged(f);
                      Navigator.of(ctx).pop();
                    }, isDark),
                    SizedBox(height: 20.h),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showBathsSheet(BuildContext context, bool isDark) {
    FocusScope.of(context).unfocus(); // no filter needs the keyboard
    const opts = ['1', '2', '3', '4', '5+'];
    int? sel = filter.bathrooms;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: _handle(isDark)),
              SizedBox(height: 20.h),
              _title('Bathrooms', isDark),
              SizedBox(height: 16.h),
              Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                children: opts.map((opt) {
                  final val = opt == '5+' ? 5 : int.parse(opt);
                  final isSel = sel == val;
                  return _countChip(
                    opt,
                    isSel,
                    isDark,
                    () => setSheet(() => sel = isSel ? null : val),
                  );
                }).toList(),
              ),
              SizedBox(height: 20.h),
              _applyBtn(() {
                onFilterChanged(
                  sel == null
                      ? filter.cleared(bathrooms: true)
                      : filter.copyWith(bathrooms: sel),
                );
                Navigator.of(ctx).pop();
              }, isDark),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────

  Widget _handle(bool isDark) => Container(
        width: 40.w,
        height: 4.h,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(2.r),
        ),
      );

  Widget _title(String text, bool isDark) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      );

  Widget _optionTile(
    String label,
    bool isActive,
    bool isDark,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 13.h),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: isActive
                  ? AppColors.primary
                  : isDark
                      ? Colors.grey.shade600
                      : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: isActive
                  ? Colors.white
                  : isDark
                      ? Colors.white70
                      : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Widget _countChip(
    String label,
    bool isActive,
    bool isDark,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60.w,
        padding: EdgeInsets.symmetric(vertical: 10.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isActive
                ? AppColors.primary
                : isDark
                    ? Colors.grey.shade600
                    : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13.sp,
            fontWeight: FontWeight.w400,
            color: isActive
                ? Colors.white
                : isDark
                    ? Colors.white70
                    : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _applyBtn(VoidCallback onTap, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 50.h,
      child: ElevatedButton(
        onPressed: onTap,
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
    );
  }

  static String _fmt(double v) {
    if (v >= 1000000) {
      final m = v / 1000000;
      return '${m == m.roundToDouble() ? m.toStringAsFixed(0) : m.toStringAsFixed(1)}M';
    }
    if (v >= 1000) return '${(v / 1000).round()}K';
    return v.round().toString();
  }
}
