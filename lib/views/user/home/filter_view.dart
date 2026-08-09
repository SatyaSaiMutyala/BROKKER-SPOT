import 'dart:async';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/controllers/common_data_controller.dart';
import 'package:brokkerspot/models/property_filter_model.dart';
import 'package:brokkerspot/views/user/announcements/repo/announcement_repo.dart';
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

  // Price text-field controllers — nullable so _hydrateFromFilter is safe to
  // call before they're initialised (first call from initState).
  TextEditingController? _minPriceCtrl;
  TextEditingController? _maxPriceCtrl;

  // True when the user has typed a max price below the current min.
  bool _priceRangeError = false;

  // Live result count shown on the Apply button.
  int? _resultCount;
  bool _isCountLoading = false;
  Timer? _countDebounce;
  final _repo = AnnouncementRepository();

  @override
  void initState() {
    super.initState();
    _minPriceCtrl = TextEditingController();
    _maxPriceCtrl = TextEditingController();
    _hydrateFromFilter(widget.initial);

    // Warm the reference lists and fetch the initial result count.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _common.loadPropertyTypes();
      _fetchCount();
      // Country / City / Area loading — hidden for now (not needed).
      // _common.loadCountries();
      // if (_countryId != null) _common.loadCities(_countryId!);
      // if (_cityId != null && _countryId != null) {
      //   _common.loadLocalities(cityId: _cityId!, countryId: _countryId!);
      // }
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
    // Sync text fields (null-safe: controllers may not exist on the very first
    // call from initState, before they're assigned above).
    _minPriceCtrl?.text =
        _price.start > _priceFloor ? _price.start.round().toString() : '';
    _maxPriceCtrl?.text =
        _price.end < _priceCeil ? _price.end.round().toString() : '';
  }

  @override
  void dispose() {
    _minPriceCtrl?.dispose();
    _maxPriceCtrl?.dispose();
    _countDebounce?.cancel();
    super.dispose();
  }

  // ── Count helpers ──────────────────────────────────────────────────────────

  /// setState + schedule a debounced count refresh. Use instead of bare setState
  /// for every filter change so the Apply button stays in sync.
  void _updateAndCount(VoidCallback fn) {
    setState(fn);
    _scheduleCountFetch();
  }

  void _scheduleCountFetch() {
    _countDebounce?.cancel();
    _countDebounce = Timer(const Duration(milliseconds: 600), _fetchCount);
  }

  Future<void> _fetchCount() async {
    if (!mounted) return;
    setState(() => _isCountLoading = true);
    try {
      final count =
          await _repo.fetchAnnouncementCount(filter: _buildCurrentFilter());
      if (mounted) {
        setState(() {
          _resultCount = count;
          _isCountLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isCountLoading = false);
    }
  }

  /// Builds the [PropertyFilter] from current state — shared by [_apply] and
  /// [_fetchCount] so they always reflect the same selection.
  PropertyFilter _buildCurrentFilter() {
    return PropertyFilter(
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
      minPrice: _priceEngaged ? _price.start : null,
      maxPrice: _priceEngaged ? _price.end : null,
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  /// True once either price handle has moved off the full-range extremes.
  bool get _priceEngaged =>
      _price.start > _priceFloor || _price.end < _priceCeil;

  void _reset() {
    setState(() => _hydrateFromFilter(PropertyFilter.empty));
    _scheduleCountFetch();
  }

  void _apply() {
    Get.back(result: _buildCurrentFilter());
  }

  // ── Selection handlers ───────────────────────────────────────────────────────

  void _onPropertyForChanged(String value) {
    _updateAndCount(() {
      _propertyFor = value;
      _propertySub = null; // sub-toggle is contextual; reset on switch
    });
  }

  // Country / City / Area handlers — hidden for now (see commented UI above).
  /*
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
  */

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
                        onSelect: (v) =>
                            _updateAndCount(() => _propertySub = v),
                      ),
                    ],

                    _divider(isDark),
                    _section('Property Type'),
                    _propertyTypeChips(isDark),

                    // ── Country / City / Area — hidden for now (not needed) ──
                    /*
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
                    */

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
                                onSelect: (v) => _updateAndCount(
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
                                onSelect: (v) => _updateAndCount(
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
                    child: _isCountLoading
                        ? SizedBox(
                            width: 22.w,
                            height: 22.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _resultCount != null
                                ? 'Show ${_fmtCount(_resultCount!)} properties'
                                : 'Apply',
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
              onTap: () => _updateAndCount(() {
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
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final labelStyle = GoogleFonts.poppins(
      fontSize: 12.sp,
      color: Colors.grey.shade500,
    );
    final fieldStyle = GoogleFonts.poppins(
      fontSize: 14.sp,
      color: isDark ? Colors.white : Colors.black87,
    );

    // Snap to nearest AED 5,000 — keeps the slider smooth but lands on clean values.
    double snap(double v) => (v / 5000).round() * 5000;

    void syncFromSlider(RangeValues v) {
      final snapped = RangeValues(snap(v.start), snap(v.end));
      setState(() {
        _price = snapped;
        _priceRangeError = false;
      });
      _minPriceCtrl?.text =
          snapped.start > _priceFloor ? snapped.start.round().toString() : '';
      _maxPriceCtrl?.text =
          snapped.end < _priceCeil ? snapped.end.round().toString() : '';
      _scheduleCountFetch();
    }

    void syncFromMin(String val) {
      final trimmed = val.replaceAll(',', '').trim();
      final n = trimmed.isEmpty ? _priceFloor : double.tryParse(trimmed);
      if (n == null) return;
      final clamped = n.clamp(_priceFloor, _price.end);
      setState(() {
        _price = RangeValues(clamped, _price.end);
        _priceRangeError = false;
      });
      _scheduleCountFetch();
    }

    void syncFromMax(String val) {
      final trimmed = val.replaceAll(',', '').trim();
      final n = trimmed.isEmpty ? _priceCeil : double.tryParse(trimmed);
      if (n == null) return;
      final hasError = trimmed.isNotEmpty && n < _price.start;
      final clamped = n.clamp(_price.start, _priceCeil);
      setState(() {
        _price = RangeValues(_price.start, clamped);
        _priceRangeError = hasError;
      });
      _scheduleCountFetch();
    }

    InputDecoration fieldDec(String hint) => InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            fontSize: 14.sp,
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: true,
          fillColor: Colors.transparent,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        );

    return Column(
      children: [
        // ── Min / Max text fields ────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 52.h,
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    alignment: Alignment.centerLeft,
                    child: TextField(
                      controller: _minPriceCtrl,
                      keyboardType: TextInputType.number,
                      style: fieldStyle,
                      decoration: fieldDec('0'),
                      onChanged: syncFromMin,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text('Minimum', style: labelStyle),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 20.h, left: 10.w, right: 10.w),
              child: Text(
                'to',
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 52.h,
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    alignment: Alignment.centerLeft,
                    child: TextField(
                      controller: _maxPriceCtrl,
                      keyboardType: TextInputType.number,
                      style: fieldStyle,
                      decoration: fieldDec('Any'),
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
        SizedBox(height: 12.h),
        // ── Range slider ─────────────────────────────────────────────────────
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
            // Allow thumbs to overlap so the max can reach very low
            // values (e.g. 5,000) even when min is at 0.
            minThumbSeparation: 0,
          ),
          child: RangeSlider(
            values: _price,
            min: _priceFloor,
            max: _priceCeil,
            onChanged: syncFromSlider,
          ),
        ),
        if (_priceRangeError) ...[
          SizedBox(height: 4.h),
          Text(
            'Maximum price must be greater than minimum price',
            style: GoogleFonts.poppins(
              fontSize: 11.sp,
              color: Colors.red.shade400,
            ),
          ),
        ],
      ],
    );
  }

  /// Formats a count for the Apply button: 75346 → "75.3K", 1200000 → "1.2M".
  String _fmtCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}
