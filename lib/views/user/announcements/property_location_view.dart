import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/controllers/common_data_controller.dart';
import 'package:brokkerspot/models/city_model.dart';
import 'package:brokkerspot/models/country_model.dart';
import 'package:brokkerspot/models/locality_model.dart';
import 'package:brokkerspot/views/user/announcements/controller/announcement_controller.dart';
import 'package:brokkerspot/views/user/announcements/map_picker_view.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/widgets/common/custom_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PropertyLocationView extends StatefulWidget {
  const PropertyLocationView({super.key});

  @override
  State<PropertyLocationView> createState() => _PropertyLocationViewState();
}

class _PropertyLocationViewState extends State<PropertyLocationView> {
  late final CommonDataController _ctrl;
  final _addressCtrl = TextEditingController();

  CountryModel? _selectedCountry;
  CityModel? _selectedCity;
  LocalityModel? _selectedLocality;

  bool _countryOpen = false;
  bool _cityOpen = false;
  bool _areaOpen = false;

  double? _latitude;
  double? _longitude;

  bool get _isValid =>
      _selectedCountry != null &&
      _selectedCity != null &&
      _selectedLocality != null &&
      _addressCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _ctrl = CommonDataController.to;
    _addressCtrl.addListener(() => setState(() {}));

    final c = Get.find<AnnouncementController>();
    _latitude = c.latitude;
    _longitude = c.longitude;
    if (c.address != null) _addressCtrl.text = c.address!;

    // Load countries then attempt to restore any previously saved selections.
    _ctrl.loadCountries().then((_) => _restoreSelections(c));
  }

  /// Restores the country/city/area selections from the announcement controller
  /// (used when re-entering the screen after a partial save or on edit).
  Future<void> _restoreSelections(AnnouncementController c) async {
    if (c.country == null) return;

    final country = _ctrl.countries
        .where((x) => x.name == c.country)
        .firstOrNull;
    if (country == null) return;
    setState(() => _selectedCountry = country);

    await _ctrl.loadCities(country.id);
    if (c.city == null) return;

    final city = _ctrl.cities
        .where((x) => x.name == c.city)
        .firstOrNull;
    if (city == null) return;
    setState(() => _selectedCity = city);

    await _ctrl.loadLocalities(cityId: city.id, countryId: country.id);
    if (c.area == null) return;

    final locality = _ctrl.localities
        .where((x) => x.name == c.area)
        .firstOrNull;
    if (locality != null) setState(() => _selectedLocality = locality);
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  // ── Geo ───────────────────────────────────────────────────────────────────

  Future<void> _useCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      EasyLoading.showError('Location services are disabled');
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        EasyLoading.showError('Location permission denied');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      EasyLoading.showError('Location permission permanently denied');
      return;
    }
    EasyLoading.show(status: 'Getting location...');
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      EasyLoading.dismiss();
      if (!mounted) return;
      final result = await Navigator.push<LocationPickerResult>(
        context,
        MaterialPageRoute(
          builder: (_) => MapPickerView(
              initialPosition: LatLng(pos.latitude, pos.longitude)),
        ),
      );
      if (result != null) _applyMapResult(result);
    } catch (_) {
      EasyLoading.dismiss();
      EasyLoading.showError('Failed to get location');
    }
  }

  Future<void> _chooseFromMap() async {
    LatLng? initial;
    if (_latitude != null && _longitude != null) {
      initial = LatLng(_latitude!, _longitude!);
    }
    final result = await Navigator.push<LocationPickerResult>(
      context,
      MaterialPageRoute(builder: (_) => MapPickerView(initialPosition: initial)),
    );
    if (result != null) _applyMapResult(result);
  }

  void _applyMapResult(LocationPickerResult r) {
    setState(() {
      _addressCtrl.text = r.address;
      _latitude = r.latitude;
      _longitude = r.longitude;
      _closeAll();
    });
  }

  void _closeAll() {
    _countryOpen = false;
    _cityOpen = false;
    _areaOpen = false;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const CustomHeader(title: 'PROPERTY LOCATION', showBackButton: true),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Country ───────────────────────────────────────────
                    _label('Select the country where property exist',
                        required: true),
                    SizedBox(height: 8.h),
                    Obx(() => _inlineDropdown(
                          hint: 'Select Country',
                          value: _selectedCountry?.name,
                          items: _ctrl.countries.map((c) => c.name).toList(),
                          isOpen: _countryOpen,
                          isLoading: _ctrl.isLoadingCountries.value,
                          onToggle: () => setState(() {
                            final was = _countryOpen;
                            _closeAll();
                            _countryOpen = !was;
                          }),
                          onSelect: (name) {
                            final country = _ctrl.countries
                                .where((c) => c.name == name)
                                .firstOrNull;
                            if (country == null) return;
                            setState(() {
                              _selectedCountry = country;
                              _selectedCity = null;
                              _selectedLocality = null;
                              _countryOpen = false;
                            });
                            _ctrl.loadCities(country.id);
                          },
                        )),
                    SizedBox(height: 20.h),

                    // ── City ──────────────────────────────────────────────
                    _label('Select the City where property exist',
                        required: true),
                    SizedBox(height: 8.h),
                    Obx(() => _inlineDropdown(
                          hint: 'Select City',
                          value: _selectedCity?.name,
                          items: _ctrl.cities.map((c) => c.name).toList(),
                          isOpen: _cityOpen,
                          isLoading: _ctrl.isLoadingCities.value,
                          enabled: _selectedCountry != null,
                          onToggle: () => setState(() {
                            final was = _cityOpen;
                            _closeAll();
                            _cityOpen = !was;
                          }),
                          onSelect: (name) {
                            final city = _ctrl.cities
                                .where((c) => c.name == name)
                                .firstOrNull;
                            if (city == null || _selectedCountry == null) return;
                            setState(() {
                              _selectedCity = city;
                              _selectedLocality = null;
                              _cityOpen = false;
                            });
                            _ctrl.loadLocalities(
                              cityId: city.id,
                              countryId: _selectedCountry!.id,
                            );
                          },
                        )),
                    SizedBox(height: 20.h),

                    // ── Area / Locality ───────────────────────────────────
                    _label('Select Area where property exist', required: true),
                    SizedBox(height: 8.h),
                    Obx(() => _inlineDropdown(
                          hint: 'Select Area',
                          value: _selectedLocality?.name,
                          items:
                              _ctrl.localities.map((l) => l.name).toList(),
                          isOpen: _areaOpen,
                          isLoading: _ctrl.isLoadingLocalities.value,
                          enabled: _selectedCity != null,
                          onToggle: () => setState(() {
                            final was = _areaOpen;
                            _closeAll();
                            _areaOpen = !was;
                          }),
                          onSelect: (name) {
                            final locality = _ctrl.localities
                                .where((l) => l.name == name)
                                .firstOrNull;
                            if (locality == null) return;
                            setState(() {
                              _selectedLocality = locality;
                              _areaOpen = false;
                            });
                          },
                        )),
                    SizedBox(height: 20.h),

                    // ── Geo buttons ───────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _geoButton(
                            icon: Icons.my_location_rounded,
                            label: 'Use Current\nLocation',
                            onTap: _useCurrentLocation,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _geoButton(
                            icon: Icons.map_outlined,
                            label: 'Choose\nfrom Map',
                            onTap: _chooseFromMap,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),

                    // ── Address ───────────────────────────────────────────
                    _label('Enter Your Address', required: true),
                    SizedBox(height: 8.h),
                    _textArea(controller: _addressCtrl, hint: 'Write here...'),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
              child: CustomPrimaryButton(
                title: 'Save',
                backgroundColor:
                    _isValid ? AppColors.primary : Colors.grey.shade300,
                defaultColor: _isValid ? Colors.white : Colors.black45,
                onPressed: _isValid
                    ? () {
                        Get.find<AnnouncementController>().setLocation(
                          country: _selectedCountry!.name,
                          city: _selectedCity!.name,
                          area: _selectedLocality!.name,
                          address: _addressCtrl.text.trim(),
                          latitude: _latitude,
                          longitude: _longitude,
                        );
                        Navigator.pop(context, true);
                      }
                    : () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _geoButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 26.sp),
            SizedBox(height: 6.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inlineDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required bool isOpen,
    required VoidCallback onToggle,
    required ValueChanged<String> onSelect,
    bool isLoading = false,
    bool enabled = true,
  }) {
    final effectiveColor =
        enabled ? Colors.grey.shade300 : Colors.grey.shade200;
    final textColor = enabled ? Colors.black87 : Colors.grey.shade400;

    return Column(
      children: [
        GestureDetector(
          onTap: enabled ? onToggle : null,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: effectiveColor),
              borderRadius: isOpen
                  ? BorderRadius.vertical(top: Radius.circular(6.r))
                  : BorderRadius.circular(6.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: isLoading
                      ? SizedBox(
                          height: 16.h,
                          width: 16.h,
                          child: const CircularProgressIndicator(
                              strokeWidth: 2),
                        )
                      : Text(
                          value ?? hint,
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            color: value != null
                                ? textColor
                                : Colors.grey.shade400,
                          ),
                        ),
                ),
                Icon(
                  isOpen
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey.shade500,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
        if (isOpen && items.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                left: BorderSide(color: Colors.grey.shade300),
                right: BorderSide(color: Colors.grey.shade300),
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(6.r)),
            ),
            child: Column(
              children: items.map((item) {
                final isSelected = value == item;
                return InkWell(
                  onTap: () => onSelect(item),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                        horizontal: 14.w, vertical: 13.h),
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : null,
                    child: Text(
                      item,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? AppColors.primary
                            : Colors.black87,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _label(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.black87),
        children: required
            ? [TextSpan(text: ' *', style: GoogleFonts.inter(color: Colors.red))]
            : null,
      ),
    );
  }

  Widget _textArea({
    required TextEditingController controller,
    required String hint,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: TextField(
        controller: controller,
        maxLines: 5,
        style: GoogleFonts.inter(fontSize: 14.sp),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              GoogleFonts.inter(fontSize: 14.sp, color: Colors.grey.shade400),
          contentPadding: EdgeInsets.all(14.w),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
