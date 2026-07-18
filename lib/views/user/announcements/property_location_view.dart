import 'dart:io';

import 'package:brokkerspot/core/common_widget/api_service.dart' as api;
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/controllers/common_data_controller.dart';
import 'package:brokkerspot/models/city_model.dart';
import 'package:brokkerspot/models/country_model.dart';
import 'package:brokkerspot/models/locality_model.dart';
import 'package:brokkerspot/views/user/announcements/controller/announcement_controller.dart';
import 'package:brokkerspot/views/user/announcements/map_picker_view.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

class PropertyLocationView extends StatefulWidget {
  const PropertyLocationView({super.key});

  @override
  State<PropertyLocationView> createState() => _PropertyLocationViewState();
}

class _PropertyLocationViewState extends State<PropertyLocationView> {
  late final CommonDataController _ctrl;
  final _addressCtrl = TextEditingController();

  // ── Location ──────────────────────────────────────────────────────────────
  CountryModel? _selectedCountry;
  CityModel? _selectedCity;
  LocalityModel? _selectedLocality;

  final _countryKey = GlobalKey<_FloatingDropdownState>();
  final _cityKey = GlobalKey<_FloatingDropdownState>();
  final _areaKey = GlobalKey<_FloatingDropdownState>();

  double? _latitude;
  double? _longitude;

  // ── Documents ─────────────────────────────────────────────────────────────
  String? _propertyFor;
  bool get _isSell => _propertyFor == 'Sell';

  String _selectedIdType = 'UAE ID';
  bool _idDropdownOpen = false;
  final _idTypes = ['UAE ID', 'Passport'];

  // Sell files
  XFile? _idFrontFile, _idBackFile, _deedFile, _nocFile;
  // Rent files
  XFile? _rentIdFrontFile, _rentIdBackFile, _rentDeedFile;
  // Existing URLs from edit mode
  String? _existingFrontUrl,
      _existingBackUrl,
      _existingDeedUrl,
      _existingNocUrl;

  // ── Upload state ──────────────────────────────────────────────────────────
  bool _isUploading = false;
  int _uploadedCount = 0;
  int _totalToUpload = 0;
  double get _uploadProgress =>
      _totalToUpload == 0 ? 0 : _uploadedCount / _totalToUpload;

  final _picker = ImagePicker();

  // ── Validation ────────────────────────────────────────────────────────────
  bool get _isLocationValid =>
      _selectedCountry != null &&
      _selectedCity != null &&
      _selectedLocality != null &&
      _addressCtrl.text.trim().isNotEmpty;

  bool get _isDocumentsValid {
    if (_isSell) {
      return (_idFrontFile != null || _existingFrontUrl != null) &&
          (_idBackFile != null || _existingBackUrl != null) &&
          (_deedFile != null || _existingDeedUrl != null);
    }
    return (_rentIdFrontFile != null || _existingFrontUrl != null) &&
        (_rentIdBackFile != null || _existingBackUrl != null) &&
        (_rentDeedFile != null || _existingDeedUrl != null);
  }

  bool get _isUAE {
    final name = (_selectedCountry?.name ?? '').toLowerCase();
    return name.contains('uae') ||
        name.contains('united arab emirates') ||
        name.contains('u.a.e');
  }

  bool get _isValid =>
      _isUAE ? _isLocationValid && _isDocumentsValid : _isLocationValid;

  @override
  void initState() {
    super.initState();
    _ctrl = CommonDataController.to;
    _addressCtrl.addListener(() => setState(() {}));

    final c = Get.find<AnnouncementController>();
    _latitude = c.latitude;
    _longitude = c.longitude;
    if (c.address != null) _addressCtrl.text = c.address!;

    _propertyFor = c.listingType == 1
        ? 'Sell'
        : c.listingType == 2
            ? 'Rent'
            : null;
    _existingFrontUrl = c.passportFrontUrl;
    _existingBackUrl = c.passportBackUrl;
    _existingDeedUrl = c.titleDeedUrl;
    _existingNocUrl = c.nocUrl;

    _ctrl.loadCountries().then((_) => _restoreSelections(c));
  }

  Future<void> _restoreSelections(AnnouncementController c) async {
    if (c.country == null) return;
    final country =
        _ctrl.countries.where((x) => x.name == c.country).firstOrNull;
    if (country == null) return;
    setState(() => _selectedCountry = country);

    await _ctrl.loadCities(country.id);
    if (c.city == null) return;
    final city = _ctrl.cities.where((x) => x.name == c.city).firstOrNull;
    if (city == null) return;
    setState(() => _selectedCity = city);

    await _ctrl.loadLocalities(cityId: city.id, countryId: country.id);
    if (c.area == null) return;
    final locality =
        _ctrl.localities.where((x) => x.name == c.area).firstOrNull;
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
      MaterialPageRoute(
          builder: (_) => MapPickerView(initialPosition: initial)),
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
    _countryKey.currentState?.close();
    _cityKey.currentState?.close();
    _areaKey.currentState?.close();
  }

  // ── Documents ─────────────────────────────────────────────────────────────

  Future<XFile?> _pickFile() async {
    try {
      return await _picker.pickImage(source: ImageSource.gallery);
    } catch (_) {
      return null;
    }
  }

  Future<void> _uploadAndSave() async {
    final c = Get.find<AnnouncementController>();
    c.setLocation(
      country: _selectedCountry!.name,
      city: _selectedCity!.name,
      area: _selectedLocality!.name,
      address: _addressCtrl.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
    );

    int total = 0;
    if (_isSell) {
      if (_idFrontFile != null) total++;
      if (_idBackFile != null) total++;
      if (_deedFile != null) total++;
      if (_nocFile != null) total++;
    } else {
      if (_rentIdFrontFile != null) total++;
      if (_rentIdBackFile != null) total++;
      if (_rentDeedFile != null) total++;
    }
    setState(() {
      _isUploading = true;
      _uploadedCount = 0;
      _totalToUpload = total;
    });

    try {
      Future<String?> uploadIfNew(XFile? file, String? existingUrl) async {
        if (file == null) return existingUrl;
        final url = await api.uploadImage(
            file: File(file.path), fileType: 'announcements');
        if (mounted) setState(() => _uploadedCount++);
        return url;
      }

      String? titleDeedUrl, passportFrontUrl, passportBackUrl, nocUrl;
      if (_isSell) {
        passportFrontUrl = await uploadIfNew(_idFrontFile, _existingFrontUrl);
        passportBackUrl = await uploadIfNew(_idBackFile, _existingBackUrl);
        titleDeedUrl = await uploadIfNew(_deedFile, _existingDeedUrl);
        nocUrl = await uploadIfNew(_nocFile, _existingNocUrl);
      } else {
        passportFrontUrl =
            await uploadIfNew(_rentIdFrontFile, _existingFrontUrl);
        passportBackUrl = await uploadIfNew(_rentIdBackFile, _existingBackUrl);
        titleDeedUrl = await uploadIfNew(_rentDeedFile, _existingDeedUrl);
      }

      Get.find<AnnouncementController>().setDocuments(
        titleDeedUrl: titleDeedUrl,
        passportFrontUrl: passportFrontUrl,
        passportBackUrl: passportBackUrl,
        nocUrl: nocUrl,
      );

      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Upload failed. Please try again.'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dividerColor =
        isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const CustomHeader(
                  title: 'Property Location & Documents',
                  showBackButton: true,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Geo buttons ──────────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: _geoButton(
                                icon: Icons.my_location_rounded,
                                label: 'Use Current Location',
                                isDark: isDark,
                                onTap: _useCurrentLocation,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _geoButton(
                                icon: Icons.map_outlined,
                                label: 'Choose From Map',
                                isDark: isDark,
                                onTap: _chooseFromMap,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),

                        // ── Country ──────────────────────────────────────────
                        _label('Country Where Property Exist',
                            required: true, isDark: isDark),
                        SizedBox(height: 8.h),
                        Obx(() => _FloatingDropdown(
                              key: _countryKey,
                              hint: 'Select Now',
                              value: _selectedCountry?.name,
                              prefixIcon: Icons.apartment_outlined,
                              items:
                                  _ctrl.countries.map((c) => c.name).toList(),
                              isLoading: _ctrl.isLoadingCountries.value,
                              isDark: isDark,
                              onBeforeOpen: _closeAll,
                              onSelect: (name) {
                                final country = _ctrl.countries
                                    .where((c) => c.name == name)
                                    .firstOrNull;
                                if (country == null) return;
                                setState(() {
                                  _selectedCountry = country;
                                  _selectedCity = null;
                                  _selectedLocality = null;
                                });
                                _ctrl.loadCities(country.id);
                              },
                            )),
                        SizedBox(height: 20.h),

                        // ── City + Area side by side ──────────────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('City Where Property Exist',
                                      required: true, isDark: isDark),
                                  SizedBox(height: 8.h),
                                  Obx(() => _FloatingDropdown(
                                        key: _cityKey,
                                        hint: 'Select Now',
                                        value: _selectedCity?.name,
                                        prefixIcon: Icons.home_outlined,
                                        items: _ctrl.cities
                                            .map((c) => c.name)
                                            .toList(),
                                        isLoading: _ctrl.isLoadingCities.value,
                                        enabled: _selectedCountry != null,
                                        isDark: isDark,
                                        onBeforeOpen: _closeAll,
                                        onSelect: (name) {
                                          final city = _ctrl.cities
                                              .where((c) => c.name == name)
                                              .firstOrNull;
                                          if (city == null ||
                                              _selectedCountry == null) {
                                            return;
                                          }
                                          setState(() {
                                            _selectedCity = city;
                                            _selectedLocality = null;
                                          });
                                          _ctrl.loadLocalities(
                                            cityId: city.id,
                                            countryId: _selectedCountry!.id,
                                          );
                                        },
                                      )),
                                ],
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Area Where Property Exist',
                                      required: true, isDark: isDark),
                                  SizedBox(height: 8.h),
                                  Obx(() => _FloatingDropdown(
                                        key: _areaKey,
                                        hint: 'Select Now',
                                        value: _selectedLocality?.name,
                                        prefixIcon: Icons.home_outlined,
                                        items: _ctrl.localities
                                            .map((l) => l.name)
                                            .toList(),
                                        isLoading:
                                            _ctrl.isLoadingLocalities.value,
                                        enabled: _selectedCity != null,
                                        isDark: isDark,
                                        onBeforeOpen: _closeAll,
                                        onSelect: (name) {
                                          final locality = _ctrl.localities
                                              .where((l) => l.name == name)
                                              .firstOrNull;
                                          if (locality == null) return;
                                          setState(() {
                                            _selectedLocality = locality;
                                          });
                                        },
                                      )),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),

                        // ── Address ──────────────────────────────────────────
                        _label('Your Property Full Address',
                            required: true, isDark: isDark),
                        SizedBox(height: 8.h),
                        _addressArea(isDark: isDark),
                        SizedBox(height: 24.h),

                        if (_isUAE) ...[
                          // ── Document section ─────────────────────────────
                          Divider(height: 1, color: dividerColor),
                          SizedBox(height: 24.h),
                          if (_isSell)
                            ..._sellLayout(isDark, dividerColor)
                          else
                            ..._rentLayout(isDark, dividerColor),
                        ],
                        SizedBox(height: 32.h),
                      ],
                    ),
                  ),
                ),

                // ── Save button ──────────────────────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                  child: GestureDetector(
                    onTap: _isValid && !_isUploading ? _uploadAndSave : null,
                    child: Container(
                      width: double.infinity,
                      height: 52.h,
                      decoration: BoxDecoration(
                        color: _isValid
                            ? AppColors.primary
                            : (isDark
                                ? const Color(0xFF2A2A2A)
                                : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(38.r),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _isUploading ? 'Uploading...' : 'Save',
                        style: GoogleFonts.poppins(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: _isValid
                              ? Colors.white
                              : (isDark
                                  ? Colors.grey.shade600
                                  : Colors.black45),
                        ),
                      ),
                    ),
                  ),
                ),
                // ── RGPD note (UAE only) ─────────────────────────────────────
                if (_isUAE)
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'RGPD: ',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade600,
                            ),
                          ),
                          TextSpan(
                            text:
                                'We will only share your documents with brokers you choose and Allow (Authorize) through our application. If you want to delete your personal data, you can send us a request, and we will start the deletion process.',
                            style: GoogleFonts.inter(
                              fontSize: 12.sp,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.black54,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_isUploading) _buildUploadOverlay(isDark),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  // ── Upload overlay ─────────────────────────────────────────────────────────

  Widget _buildUploadOverlay(bool isDark) {
    final percent = (_uploadProgress * 100).toInt();
    final isDone = _totalToUpload == 0 || _uploadedCount >= _totalToUpload;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final trackColor =
        isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200;
    final statusColor = isDark ? Colors.white70 : Colors.black87;

    return Positioned.fill(
      child: AbsorbPointer(
        child: Container(
          color: Colors.black.withValues(alpha: 0.5),
          child: Center(
            child: Container(
              width: 200.w,
              padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 24.w),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 72.w,
                    height: 72.w,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 72.w,
                          height: 72.w,
                          child: CircularProgressIndicator(
                            value: _totalToUpload == 0 ? null : _uploadProgress,
                            strokeWidth: 7,
                            strokeCap: StrokeCap.round,
                            backgroundColor: trackColor,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                          ),
                        ),
                        Text(
                          _totalToUpload == 0 ? '...' : '$percent%',
                          style: GoogleFonts.poppins(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    _totalToUpload == 0
                        ? 'Saving...'
                        : isDone
                            ? 'Upload complete!'
                            : 'Uploading ${_uploadedCount + 1} of $_totalToUpload...',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Document layouts ───────────────────────────────────────────────────────

  List<Widget> _sellLayout(bool isDark, Color dividerColor) {
    final labelColor = isDark ? Colors.white : Colors.black87;
    final idLabel =
        _selectedIdType == 'UAE ID' ? 'Upload UAE ID Card' : 'Upload Passport';

    return [
      _docSectionLabel(idLabel, required: true, color: labelColor),
      SizedBox(height: 8.h),
      _docDropdown(
        isDark: isDark,
        selected: _selectedIdType,
        isOpen: _idDropdownOpen,
        options: _idTypes,
        onToggle: () => setState(() => _idDropdownOpen = !_idDropdownOpen),
        onSelect: (v) => setState(() {
          _selectedIdType = v;
          _idDropdownOpen = false;
        }),
      ),
      SizedBox(height: 12.h),
      Row(
        children: [
          Expanded(
            child: _uploadBox(
              isDark: isDark,
              label: 'Front Side',
              isUploaded: _idFrontFile != null || _existingFrontUrl != null,
              onTap: () async {
                final f = await _pickFile();
                if (f != null) setState(() => _idFrontFile = f);
              },
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _uploadBox(
              isDark: isDark,
              label: 'Back Side',
              isUploaded: _idBackFile != null || _existingBackUrl != null,
              onTap: () async {
                final f = await _pickFile();
                if (f != null) setState(() => _idBackFile = f);
              },
            ),
          ),
        ],
      ),
      SizedBox(height: 24.h),
      Divider(height: 1, color: dividerColor),
      SizedBox(height: 24.h),
      _docSectionLabel('Upload Title Deed Doc',
          required: true, color: labelColor),
      SizedBox(height: 12.h),
      _uploadBox(
        isDark: isDark,
        label: 'Upload',
        isUploaded: _deedFile != null || _existingDeedUrl != null,
        onTap: () async {
          final f = await _pickFile();
          if (f != null) setState(() => _deedFile = f);
        },
      ),
      if (_selectedIdType == 'UAE ID') ...[
        SizedBox(height: 24.h),
        Divider(height: 1, color: dividerColor),
        SizedBox(height: 24.h),
        _docSectionLabel('NOC Doc', color: labelColor),
        SizedBox(height: 12.h),
        _uploadBox(
          isDark: isDark,
          label: 'Upload',
          isUploaded: _nocFile != null || _existingNocUrl != null,
          onTap: () async {
            final f = await _pickFile();
            if (f != null) setState(() => _nocFile = f);
          },
        ),
      ],
    ];
  }

  List<Widget> _rentLayout(bool isDark, Color dividerColor) {
    final labelColor = isDark ? Colors.white : Colors.black87;
    final idLabel =
        _selectedIdType == 'UAE ID' ? 'Upload UAE ID Card' : 'Upload Passport';

    return [
      _docSectionLabel(idLabel, required: true, color: labelColor),
      SizedBox(height: 8.h),
      _docDropdown(
        isDark: isDark,
        selected: _selectedIdType,
        isOpen: _idDropdownOpen,
        options: _idTypes,
        onToggle: () => setState(() => _idDropdownOpen = !_idDropdownOpen),
        onSelect: (v) => setState(() {
          _selectedIdType = v;
          _idDropdownOpen = false;
        }),
      ),
      SizedBox(height: 12.h),
      Row(
        children: [
          Expanded(
            child: _uploadBox(
              isDark: isDark,
              label: 'Front Side',
              isUploaded: _rentIdFrontFile != null || _existingFrontUrl != null,
              onTap: () async {
                final f = await _pickFile();
                if (f != null) setState(() => _rentIdFrontFile = f);
              },
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _uploadBox(
              isDark: isDark,
              label: 'Back Side',
              isUploaded: _rentIdBackFile != null || _existingBackUrl != null,
              onTap: () async {
                final f = await _pickFile();
                if (f != null) setState(() => _rentIdBackFile = f);
              },
            ),
          ),
        ],
      ),
      SizedBox(height: 24.h),
      Divider(height: 1, color: dividerColor),
      SizedBox(height: 24.h),
      _docSectionLabel('Upload Title Deed Doc',
          required: true, color: labelColor),
      SizedBox(height: 12.h),
      _uploadBox(
        isDark: isDark,
        label: 'Upload',
        isUploaded: _rentDeedFile != null || _existingDeedUrl != null,
        onTap: () async {
          final f = await _pickFile();
          if (f != null) setState(() => _rentDeedFile = f);
        },
      ),
    ];
  }

  Widget _docSectionLabel(String text,
      {bool required = false, required Color color}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: GoogleFonts.inter(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        children: required
            ? [
                TextSpan(
                  text: ' *',
                  style: GoogleFonts.inter(
                      color: Colors.red, fontWeight: FontWeight.w600),
                ),
              ]
            : null,
      ),
    );
  }

  // ── Document type dropdown (grey border + description icon) ───────────────

  Widget _docDropdown({
    required bool isDark,
    required String selected,
    required bool isOpen,
    required List<String> options,
    required VoidCallback onToggle,
    required ValueChanged<String> onSelect,
  }) {
    final bg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300;
    final textColor = isDark ? Colors.white : Colors.black87;
    final chevronColor = isDark ? Colors.grey.shade500 : Colors.grey.shade500;
    final dividerColor =
        isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200;

    return Column(
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: borderColor),
              borderRadius: isOpen
                  ? BorderRadius.vertical(top: Radius.circular(8.r))
                  : BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(Icons.description_outlined,
                    size: 18.sp, color: AppColors.primary),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    selected,
                    style: GoogleFonts.inter(fontSize: 14.sp, color: textColor),
                  ),
                ),
                Icon(
                  isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: chevronColor,
                  size: 20.sp,
                ),
              ],
            ),
          ),
        ),
        if (isOpen)
          Container(
            decoration: BoxDecoration(
              color: bg,
              border: Border(
                left: BorderSide(color: borderColor),
                right: BorderSide(color: borderColor),
                bottom: BorderSide(color: borderColor),
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(8.r)),
            ),
            child: Column(
              children: options.map((item) {
                final isSelected = selected == item;
                final isLast = options.last == item;
                return InkWell(
                  onTap: () => onSelect(item),
                  child: Column(
                    children: [
                      Container(
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
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? AppColors.primary : textColor,
                          ),
                        ),
                      ),
                      if (!isLast)
                        Divider(
                            height: 1,
                            color: dividerColor,
                            indent: 14.w,
                            endIndent: 14.w),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // ── Location widgets ───────────────────────────────────────────────────────

  Widget _geoButton({
    required IconData icon,
    required String label,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 10.w),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: AppColors.primary),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 20.sp),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, {bool required = false, required bool isDark}) {
    return RichText(
      text: TextSpan(
        text: text,
        style: GoogleFonts.inter(
          fontSize: 13.sp,
          color: isDark ? Colors.grey.shade300 : Colors.black87,
        ),
        children: required
            ? [
                TextSpan(
                    text: ' *', style: GoogleFonts.inter(color: Colors.red))
              ]
            : null,
      ),
    );
  }

  Widget _addressArea({required bool isDark}) {
    final borderColor = isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300;
    final charCount = _addressCtrl.text.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(left: 12.w, top: 14.h),
                child: Icon(
                  Icons.description_outlined,
                  size: 18.sp,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: TextField(
                  controller: _addressCtrl,
                  maxLines: 5,
                  maxLength: 300,
                  buildCounter: (_,
                          {required currentLength,
                          required isFocused,
                          maxLength}) =>
                      null,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Write Here...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color:
                          isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 14.h, horizontal: 0),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
            ],
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          '$charCount/300',
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _uploadBox({
    required bool isDark,
    required String label,
    bool isUploaded = false,
    VoidCallback? onTap,
  }) {
    if (isUploaded) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36.h,
          decoration: BoxDecoration(
            color: const Color.fromARGB(87, 80, 239, 85),
            borderRadius: BorderRadius.circular(41.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline,
                  color: Colors.white, size: 18.sp),
              SizedBox(width: 6.w),
              Text(
                'Uploaded',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: const Color(0xFFD9D9D9),
          borderRadius: 41.r,
        ),
        child: SizedBox(
          height: 36.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_upload_outlined,
                  color: AppColors.primary, size: 18.sp),
              SizedBox(width: 6.w),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingDropdown extends StatefulWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final bool isDark;
  final ValueChanged<String> onSelect;
  final bool isLoading;
  final bool enabled;
  final IconData? prefixIcon;
  final VoidCallback? onBeforeOpen;

  const _FloatingDropdown({
    super.key,
    required this.hint,
    required this.value,
    required this.items,
    required this.isDark,
    required this.onSelect,
    this.isLoading = false,
    this.enabled = true,
    this.prefixIcon,
    this.onBeforeOpen,
  });

  @override
  State<_FloatingDropdown> createState() => _FloatingDropdownState();
}

class _FloatingDropdownState extends State<_FloatingDropdown> {
  bool _isOpen = false;
  OverlayEntry? _overlay;
  Offset _triggerOffset = Offset.zero;
  Size _triggerSize = Size.zero;

  @override
  void didUpdateWidget(_FloatingDropdown old) {
    super.didUpdateWidget(old);
    if (_isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isOpen) _overlay?.markNeedsBuild();
      });
    }
  }

  @override
  void dispose() {
    _overlay?.remove();
    _overlay = null;
    super.dispose();
  }

  void close() {
    if (!_isOpen) return;
    _overlay?.remove();
    _overlay = null;
    if (mounted) setState(() => _isOpen = false);
  }

  void _open() {
    widget.onBeforeOpen?.call();

    // Capture exact screen-space bounds of the trigger at the moment of tap.
    final box = context.findRenderObject() as RenderBox;
    _triggerOffset = box.localToGlobal(Offset.zero);
    _triggerSize = box.size;

    final isDark = widget.isDark;
    final borderColor = isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    _overlay = OverlayEntry(
      builder: (ctx) => Positioned(
        left: _triggerOffset.dx,
        top: _triggerOffset.dy + _triggerSize.height,
        width: _triggerSize.width,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxHeight: 200.h),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                left: BorderSide(color: borderColor),
                right: BorderSide(color: borderColor),
                bottom: BorderSide(color: borderColor),
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(6.r)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: widget.items.map((item) {
                  final sel = widget.value == item;
                  return InkWell(
                    onTap: () {
                      close();
                      widget.onSelect(item);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 13.h),
                      color: sel
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : null,
                      child: Text(
                        item,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                          color: sel
                              ? AppColors.primary
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlay!);
    setState(() => _isOpen = true);
  }

  void _toggle() {
    if (!widget.enabled) return;
    if (_isOpen) {
      close();
    } else {
      _open();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final borderColor = widget.enabled
        ? (isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300)
        : (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200);
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = widget.enabled
        ? (isDark ? Colors.white : Colors.black87)
        : (isDark ? Colors.grey.shade600 : Colors.grey.shade400);
    final hintColor = isDark ? Colors.grey.shade600 : Colors.grey.shade400;
    final chevronColor = Colors.grey.shade500;

    return GestureDetector(
      onTap: _toggle,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor),
          borderRadius: _isOpen
              ? BorderRadius.vertical(top: Radius.circular(6.r))
              : BorderRadius.circular(6.r),
        ),
        child: Row(
          children: [
            if (widget.prefixIcon != null) ...[
              Icon(widget.prefixIcon, size: 18.sp, color: AppColors.primary),
              SizedBox(width: 8.w),
            ],
            Expanded(
              child: Text(
                widget.value ?? widget.hint,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: widget.value != null ? textColor : hintColor,
                ),
              ),
            ),
            if (widget.isLoading)
              SizedBox(
                width: 16.sp,
                height: 16.sp,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            else
              Icon(
                _isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: chevronColor,
                size: 20.sp,
              ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;

  _DashedBorderPainter({required this.color, this.borderRadius = 8});

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 6.0;
    const dashSpace = 6.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );
    final path = Path()..addRRect(rrect);
    final dest = Path();
    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final end = (dist + dashWidth).clamp(0.0, metric.length);
        dest.addPath(metric.extractPath(dist, end), Offset.zero);
        dist += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dest, paint);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.borderRadius != borderRadius;
}
