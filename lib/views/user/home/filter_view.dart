import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/controllers/common_data_controller.dart';
import 'package:brokkerspot/models/property_filter_model.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/widgets/common/overlay_dropdown_field.dart';
import 'package:brokkerspot/widgets/search/filter_pill_group.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full-screen property filter (see Figma). Edits a working copy of the
/// incoming [initial] filter and returns a new [PropertyFilter] via
/// `Get.back(result: ...)` when the user taps **Apply**. Returns nothing if
/// the user backs out, leaving the caller's filter untouched.
///
/// Location and property-type are selected from [CommonDataController]'s cached
/// reference lists and submitted as IDs; the human-readable names ride along so
/// re-opening the screen shows the current selection.
class FilterView extends StatefulWidget {
  final PropertyFilter initial;

  const FilterView({super.key, this.initial = PropertyFilter.empty});

  @override
  State<FilterView> createState() => _FilterViewState();
}

class _FilterViewState extends State<FilterView> {
  final _common = CommonDataController.to;

  // Price slider bounds (AED). min/max only submitted when moved off a bound.
  static const double _priceFloor = 0;
  static const double _priceCeil = 10000000; // 10M

  static const _propertyForOptions = ['All', 'Buy', 'Rent'];
  static const _buyStatusOptions = ['Ready', 'Off Plan'];
  static const _rentPeriodOptions = ['Yearly', 'Monthly'];
  static const _countOptions = ['1', '2', '3', '4', '5+'];

  late String _propertyFor; // 'All' | 'Buy' | 'Rent'
  String? _propertySub; // Ready/Off Plan (Buy) or Yearly/Monthly (Rent)

  String? _propertyTypeId, _propertyTypeName;
  String? _countryId, _countryName;
  String? _cityId, _cityName;
  String? _areaId, _areaName;
  int? _bedrooms, _bathrooms;
  late RangeValues _price;

  @override
  void initState() {
    super.initState();
    _hydrateFromFilter(widget.initial);

    // Warm the reference lists (each is a no-op if already cached this session).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _common.loadCountries();
      _common.loadPropertyTypes();
      if (_countryId != null) _common.loadCities(_countryId!);
      if (_cityId != null && _countryId != null) {
        _common.loadLocalities(cityId: _cityId!, countryId: _countryId!);
      }
    });
  }

  void _hydrateFromFilter(PropertyFilter f) {
    _propertyFor = f.listingType == 1
        ? 'Buy'
        : f.listingType == 2
            ? 'Rent'
            : 'All';
    if (f.listingType == 1) {
      _propertySub = f.propertyStatus == 1
          ? 'Ready'
          : f.propertyStatus == 2
              ? 'Off Plan'
              : null;
    } else if (f.listingType == 2) {
      _propertySub = f.rentPeriod;
    }
    _propertyTypeId = f.propertyTypeId;
    _propertyTypeName = f.propertyTypeName;
    _countryId = f.countryId;
    _countryName = f.countryName;
    _cityId = f.cityId;
    _cityName = f.cityName;
    _areaId = f.areaId;
    _areaName = f.areaName;
    _bedrooms = f.bedrooms;
    _bathrooms = f.bathrooms;
    _price = RangeValues(
      (f.minPrice ?? _priceFloor).clamp(_priceFloor, _priceCeil).toDouble(),
      (f.maxPrice ?? _priceCeil).clamp(_priceFloor, _priceCeil).toDouble(),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _reset() {
    setState(() => _hydrateFromFilter(PropertyFilter.empty));
  }

  void _apply() {
    final result = PropertyFilter(
      listingType: _propertyFor == 'Buy'
          ? 1
          : _propertyFor == 'Rent'
              ? 2
              : null,
      propertyStatus: _propertyFor == 'Buy'
          ? (_propertySub == 'Ready'
              ? 1
              : _propertySub == 'Off Plan'
                  ? 2
                  : null)
          : null,
      rentPeriod: _propertyFor == 'Rent' ? _propertySub : null,
      propertyTypeId: _propertyTypeId,
      propertyTypeName: _propertyTypeName,
      countryId: _countryId,
      countryName: _countryName,
      cityId: _cityId,
      cityName: _cityName,
      areaId: _areaId,
      areaName: _areaName,
      bedrooms: _bedrooms,
      bathrooms: _bathrooms,
      minPrice: _price.start > _priceFloor ? _price.start : null,
      maxPrice: _price.end < _priceCeil ? _price.end : null,
    );
    Get.back(result: result);
  }

  // ── Selection handlers ───────────────────────────────────────────────────────

  void _onPropertyForChanged(String value) {
    setState(() {
      _propertyFor = value;
      _propertySub = null; // sub-toggle is contextual; reset on switch
    });
  }

  void _onCountryChanged(String name) {
    final country = _common.countries.firstWhereOrNull((c) => c.name == name);
    if (country == null) return;
    setState(() {
      _countryId = country.id;
      _countryName = country.name;
      _cityId = null;
      _cityName = null;
      _areaId = null;
      _areaName = null;
    });
    _common.loadCities(country.id);
  }

  void _onCityChanged(String name) {
    final city = _common.cities.firstWhereOrNull((c) => c.name == name);
    if (city == null || _countryId == null) return;
    setState(() {
      _cityId = city.id;
      _cityName = city.name;
      _areaId = null;
      _areaName = null;
    });
    _common.loadLocalities(cityId: city.id, countryId: _countryId!);
  }

  void _onAreaChanged(String name) {
    final area = _common.localities.firstWhereOrNull((a) => a.name == name);
    if (area == null) return;
    setState(() {
      _areaId = area.id;
      _areaName = area.name;
    });
  }

  int? _parseCount(String v) => v == '5+' ? 5 : int.tryParse(v);
  String? _countLabel(int? v) =>
      v == null ? null : (v >= 5 ? '5+' : v.toString());

  // ── UI ───────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CustomHeader(
              title: 'Filter',
              showBackButton: true,
              trailing: GestureDetector(
                onTap: _reset,
                behavior: HitTestBehavior.opaque,
                child: Text(
                  'Reset',
                  style: GoogleFonts.poppins(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section('Property For'),
                    FilterPillGroup(
                      options: _propertyForOptions,
                      selected: _propertyFor,
                      onSelect: _onPropertyForChanged,
                    ),

                    // Contextual sub-toggle: Buy → Ready/Off Plan, Rent → Yearly/Monthly.
                    if (_propertyFor != 'All') ...[
                      _divider(isDark),
                      _section('Property'),
                      FilterPillGroup(
                        expand: false,
                        options: _propertyFor == 'Buy'
                            ? _buyStatusOptions
                            : _rentPeriodOptions,
                        selected: _propertySub,
                        onSelect: (v) => setState(() => _propertySub = v),
                      ),
                    ],

                    _divider(isDark),
                    _section('Property Type'),
                    _propertyTypeChips(isDark),

                    _divider(isDark),
                    _section('Country'),
                    Obx(() => OverlayDropdownField(
                          hint: _common.isLoadingCountries.value
                              ? 'Loading...'
                              : 'Select Country',
                          value: _countryName,
                          items:
                              _common.countries.map((c) => c.name).toList(),
                          onSelect: _onCountryChanged,
                          prefixIcon: Icons.public,
                        )),

                    _divider(isDark),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _section('City'),
                              Obx(() => OverlayDropdownField(
                                    hint: _common.isLoadingCities.value
                                        ? 'Loading...'
                                        : 'Select City',
                                    value: _cityName,
                                    items: _common.cities
                                        .map((c) => c.name)
                                        .toList(),
                                    onSelect: _onCityChanged,
                                  )),
                            ],
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _section('Area'),
                              Obx(() => OverlayDropdownField(
                                    hint: _common.isLoadingLocalities.value
                                        ? 'Loading...'
                                        : 'Select Area',
                                    value: _areaName,
                                    items: _common.localities
                                        .map((a) => a.name)
                                        .toList(),
                                    onSelect: _onAreaChanged,
                                  )),
                            ],
                          ),
                        ),
                      ],
                    ),

                    _divider(isDark),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _section('Bedroom'),
                              OverlayDropdownField(
                                hint: '0',
                                value: _countLabel(_bedrooms),
                                items: _countOptions,
                                onSelect: (v) => setState(
                                    () => _bedrooms = _parseCount(v)),
                                prefixIcon: Icons.bed_outlined,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _section('Bathroom'),
                              OverlayDropdownField(
                                hint: '0',
                                value: _countLabel(_bathrooms),
                                items: _countOptions,
                                onSelect: (v) => setState(
                                    () => _bathrooms = _parseCount(v)),
                                prefixIcon: Icons.bathtub_outlined,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    _divider(isDark),
                    _section('Price Range'),
                    _priceRange(isDark),
                  ],
                ),
              ),
            ),

            // ── Apply ────────────────────────────────────────────────────────────
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 12.h),
                child: SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: _apply,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _divider(bool isDark) => Padding(
        padding: EdgeInsets.symmetric(vertical: 18.h),
        child: Divider(
          height: 1,
          thickness: 1,
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEDEDED),
        ),
      );

  Widget _propertyTypeChips(bool isDark) {
    return Obx(() {
      final types = _common.propertyTypes;
      if (_common.isLoadingPropertyTypes.value && types.isEmpty) {
        return SizedBox(
          height: 40.h,
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 20.w,
              height: 20.w,
              child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary),
            ),
          ),
        );
      }
      return SizedBox(
        height: 40.h,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.zero,
          itemCount: types.length,
          separatorBuilder: (_, __) => SizedBox(width: 10.w),
          itemBuilder: (_, i) {
            final t = types[i];
            final isSelected = _propertyTypeId == t.id;
            return GestureDetector(
              onTap: () => setState(() {
                if (isSelected) {
                  _propertyTypeId = null;
                  _propertyTypeName = null;
                } else {
                  _propertyTypeId = t.id;
                  _propertyTypeName = t.name;
                }
              }),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFF0EEE9),
                  borderRadius: BorderRadius.circular(22.r),
                ),
                child: Text(
                  t.name,
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : isDark
                            ? Colors.white70
                            : Colors.black87,
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _priceRange(bool isDark) {
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 3.h,
            activeTrackColor: AppColors.primary,
            inactiveTrackColor:
                isDark ? const Color(0xFF3A3A3A) : const Color(0xFFDDDDDD),
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: 0.15),
            rangeThumbShape:
                RoundRangeSliderThumbShape(enabledThumbRadius: 9.r),
          ),
          child: RangeSlider(
            values: _price,
            min: _priceFloor,
            max: _priceCeil,
            divisions: 100,
            onChanged: (v) => setState(() => _price = v),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Min ${_fmtPrice(_price.start)}',
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Text(
                'Max ${_fmtPrice(_price.end)}',
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _fmtPrice(double v) {
    if (v >= 1000000) {
      final m = v / 1000000;
      return '${m == m.roundToDouble() ? m.toStringAsFixed(0) : m.toStringAsFixed(1)}M';
    }
    if (v >= 1000) return '${(v / 1000).round()}K';
    return v.round().toString();
  }
}
