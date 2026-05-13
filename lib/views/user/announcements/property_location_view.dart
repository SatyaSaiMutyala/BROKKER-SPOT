import 'package:brokkerspot/core/constants/app_colors.dart';
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
  String? _country;
  String? _city;
  String? _area;
  final _addressCtrl = TextEditingController();

  bool _countryOpen = false;
  bool _cityOpen = false;
  bool _areaOpen = false;

  double? _latitude;
  double? _longitude;

  bool get _isValid =>
      _country != null &&
      _city != null &&
      _area != null &&
      _addressCtrl.text.trim().isNotEmpty;

  final _countries = ['India', 'UAE', 'France'];
  final _cities = [
    'Dubai',
    'Abu Dhabi',
    'Hyderabad',
    'London',
    'New York',
    'Toronto'
  ];
  final _areas = ['Downtown', 'Business Bay', 'Marina', 'Jumeirah', 'Deira'];

  void _closeAll() {
    _countryOpen = false;
    _cityOpen = false;
    _areaOpen = false;
  }

  @override
  void initState() {
    super.initState();
    final c = Get.find<AnnouncementController>();
    _country = c.country;
    _city = c.city;
    _area = c.area;
    _latitude = c.latitude;
    _longitude = c.longitude;
    if (c.address != null) _addressCtrl.text = c.address!;
    _addressCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  // ── Geo ──────────────────────────────────────────────────────────────────────

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
      if (result != null) _applyResult(result);
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
      MaterialPageRoute(
          builder: (_) => MapPickerView(initialPosition: initial)),
    );
    if (result != null) _applyResult(result);
  }

  void _applyResult(LocationPickerResult r) {
    setState(() {
      _country = r.country.isNotEmpty ? r.country : _country;
      _city = r.city.isNotEmpty ? r.city : _city;
      _area = r.area.isNotEmpty ? r.area : _area;
      _addressCtrl.text = r.address;
      _latitude = r.latitude;
      _longitude = r.longitude;
      _closeAll();
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const CustomHeader(
                title: 'PROPERTY LOCATION', showBackButton: true),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Country dropdown ──────────────────────────────────
                    _label('Select the country where property exist',
                        required: true),
                    SizedBox(height: 8.h),
                    _inlineDropdown(
                      hint: 'Select Country',
                      value: _country,
                      items: _countries,
                      isOpen: _countryOpen,
                      onToggle: () => setState(() {
                        final wasOpen = _countryOpen;
                        _closeAll();
                        _countryOpen = !wasOpen;
                      }),
                      onSelect: (v) => setState(() {
                        _country = v;
                        _countryOpen = false;
                      }),
                    ),
                    SizedBox(height: 20.h),

                    // ── City dropdown ─────────────────────────────────────
                    _label('Select the City where property exist',
                        required: true),
                    SizedBox(height: 8.h),
                    _inlineDropdown(
                      hint: 'Select city',
                      value: _city,
                      items: _cities,
                      isOpen: _cityOpen,
                      onToggle: () => setState(() {
                        final wasOpen = _cityOpen;
                        _closeAll();
                        _cityOpen = !wasOpen;
                      }),
                      onSelect: (v) => setState(() {
                        _city = v;
                        _cityOpen = false;
                      }),
                    ),
                    SizedBox(height: 20.h),

                    // ── Area dropdown ─────────────────────────────────────
                    _label('Select Area where property exist', required: true),
                    SizedBox(height: 8.h),
                    _inlineDropdown(
                      hint: 'Enter Areas',
                      value: _area,
                      items: _areas,
                      isOpen: _areaOpen,
                      onToggle: () => setState(() {
                        final wasOpen = _areaOpen;
                        _closeAll();
                        _areaOpen = !wasOpen;
                      }),
                      onSelect: (v) => setState(() {
                        _area = v;
                        _areaOpen = false;
                      }),
                    ),
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

                    // ── Address text area (auto-filled by geo) ────────────
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
                          country: _country!,
                          city: _city!,
                          area: _area!,
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

  // ── Widgets ───────────────────────────────────────────────────────────────────

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
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: isOpen
                  ? BorderRadius.vertical(top: Radius.circular(6.r))
                  : BorderRadius.circular(6.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color:
                          value != null ? Colors.black87 : Colors.grey.shade400,
                    ),
                  ),
                ),
                Icon(
                  isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey.shade500,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
        if (isOpen)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                left: BorderSide(color: Colors.grey.shade300),
                right: BorderSide(color: Colors.grey.shade300),
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(6.r)),
            ),
            child: Column(
              children: items.map((item) {
                final isSelected = value == item;
                return InkWell(
                  onTap: () => onSelect(item),
                  child: Container(
                    width: double.infinity,
                    padding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : null,
                    child: Text(
                      item,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? AppColors.primary : Colors.black87,
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
            ? [
                TextSpan(
                    text: ' *', style: GoogleFonts.inter(color: Colors.red))
              ]
            : null,
      ),
    );
  }

  Widget _textArea(
      {required TextEditingController controller, required String hint}) {
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
