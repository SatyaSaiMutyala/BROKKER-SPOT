import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:brokkerspot/core/common_widget/api_service.dart' as api;
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/user/announcements/controller/announcement_controller.dart';
import 'package:brokkerspot/views/user/announcements/controller/amenity_controller.dart';
import 'package:brokkerspot/views/user/announcements/controller/property_type_controller.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/widgets/common/overlay_dropdown_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class PropertyInformationView extends StatefulWidget {
  const PropertyInformationView({super.key});

  @override
  State<PropertyInformationView> createState() =>
      _PropertyInformationViewState();
}

class _PropertyInformationViewState extends State<PropertyInformationView> {
  // ── Form state ────────────────────────────────────────────────────────────
  bool _isCommercial = false;
  String? _propertyFor;
  String? _propertyType;
  String? _bedroom;
  String? _bathroom;
  String? _floor;
  String? _totalFloor;
  String? _isProperty;
  final _nameCtrl = TextEditingController();
  final _sqftCtrl = TextEditingController();
  final _spmCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final Set<String> _selectedAmenityIds = {};
  final _amenityCtrl = AmenityController.to;
  final _propertyTypeCtrl = PropertyTypeController.to;
  final _bedroomBathroomCounts = ['1', '2', '3', '4', '5+'];
  final _floorCounts = ['G', '1', '2', '3', '4', '5+'];
  final _isPropertyOptions = ['Ready', 'Off Plan'];
  DateTime? _completionDate;

  // ── Media state ───────────────────────────────────────────────────────────
  final ImagePicker _picker = ImagePicker();
  File? _videoFile;
  String? _existingVideoUrl;
  final List<File?> _imageFiles = List.filled(12, null);
  final List<String?> _existingImageUrls = List.filled(12, null);
  bool _isUploading = false;
  int _uploadedCount = 0;
  int _totalToUpload = 0;

  static const int _maxVideoBytes = 50 * 1024 * 1024;

  int get _filledSlotCount {
    int count = 0;
    for (int i = 0; i < 12; i++) {
      if (_imageFiles[i] != null || _existingImageUrls[i] != null) count++;
    }
    return count;
  }

  double get _uploadProgress =>
      _totalToUpload == 0 ? 0 : _uploadedCount / _totalToUpload;

  bool get _isValid =>
      _propertyFor != null &&
      _propertyType != null &&
      _sqftCtrl.text.trim().isNotEmpty &&
      _spmCtrl.text.trim().isNotEmpty &&
      _bedroom != null &&
      _bathroom != null &&
      _floor != null &&
      _totalFloor != null &&
      _descCtrl.text.trim().isNotEmpty &&
      (_propertyFor == 'Rent' || _isProperty != null) &&
      (_isProperty != 'Off Plan' || _completionDate != null) &&
      _filledSlotCount >= 8;

  @override
  void initState() {
    super.initState();
    final c = Get.find<AnnouncementController>();
    _propertyFor = c.listingType == 1
        ? 'Sell'
        : c.listingType == 2
            ? 'Rent'
            : null;
    _propertyType = c.propertyType;
    if (c.propertyName != null) _nameCtrl.text = c.propertyName!;
    if (c.sqft != null) _sqftCtrl.text = c.sqft!.toStringAsFixed(0);
    if (c.sqm != null) _spmCtrl.text = c.sqm!.toStringAsFixed(0);
    _bedroom = _intToCountStr(c.bedrooms);
    _bathroom = _intToCountStr(c.bathrooms);
    _floor = _intToFloorStr(c.floor);
    _totalFloor = _intToFloorStr(c.totalFloors);
    if (c.description != null) _descCtrl.text = c.description!;
    if (c.amenities.isNotEmpty) _selectedAmenityIds.addAll(c.amenities);
    _amenityCtrl.loadAmenities();
    _propertyTypeCtrl.load();
    if (c.propertyStatus == 1) _isProperty = 'Ready';
    if (c.propertyStatus == 2) _isProperty = 'Off Plan';
    _completionDate = c.completionDate;
    _isCommercial = c.isCommercialProperty == 1;
    _existingVideoUrl = c.videoUrl;
    for (int i = 0; i < c.imageUrls.length && i < 12; i++) {
      _existingImageUrls[i] = c.imageUrls[i];
    }
    _descCtrl.addListener(() => setState(() {}));
    _sqftCtrl.addListener(() => setState(() {}));
    _spmCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sqftCtrl.dispose();
    _spmCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  int _parseFloor(String? val) {
    if (val == null) return 0;
    if (val == 'G') return 0;
    if (val == '5+') return 5;
    return int.tryParse(val) ?? 0;
  }

  String? _intToFloorStr(int? val) {
    if (val == null) return null;
    if (val == 0) return 'G';
    if (val >= 5) return '5+';
    return val.toString();
  }

  String? _intToCountStr(int? val) {
    if (val == null || val == 0) return null;
    if (val >= 5) return '5+';
    return val.toString();
  }

  // ── Permissions ───────────────────────────────────────────────────────────

  Future<bool> _ensurePermissions({
    required ImageSource source,
    required bool needsMicrophone,
  }) async {
    final permissions = <Permission>[];
    if (source == ImageSource.camera) {
      permissions.add(Permission.camera);
      if (needsMicrophone) permissions.add(Permission.microphone);
    } else {
      if (!Platform.isIOS) {
        permissions
            .add(needsMicrophone ? Permission.videos : Permission.photos);
      }
    }
    for (final p in permissions) {
      var status = await p.status;
      if (status.isGranted || status.isLimited) continue;
      if (status.isRestricted) return false;
      status = await p.request();
      if (status.isGranted || status.isLimited) continue;
      if (!mounted) return false;
      final opened = await _showSettingsDialog(p);
      if (!opened) return false;
      status = await p.status;
      if (!status.isGranted && !status.isLimited) return false;
    }
    return true;
  }

  Future<bool> _showSettingsDialog(Permission permission) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final label = permission == Permission.camera
        ? 'Camera'
        : permission == Permission.microphone
            ? 'Microphone'
            : permission == Permission.videos
                ? 'Videos'
                : 'Photos';
    final granted = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r)),
            title: Text(
              '$label permission required',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            content: Text(
              'Please enable $label access in Settings to continue.',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel',
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.grey.shade400 : Colors.black54,
                    )),
              ),
              TextButton(
                onPressed: () async {
                  await openAppSettings();
                  if (ctx.mounted) Navigator.pop(ctx, true);
                },
                child: Text('Open Settings',
                    style: GoogleFonts.inter(
                        color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ) ??
        false;
    return granted;
  }

  // ── Media pickers ─────────────────────────────────────────────────────────

  void _pickVideo(ImageSource source) async {
    final ok = await _ensurePermissions(source: source, needsMicrophone: true);
    if (!ok) return;
    try {
      final picked = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 1),
      );
      if (picked == null) return;
      final file = File(picked.path);
      final size = await file.length();
      if (size > _maxVideoBytes) {
        EasyLoading.showError(
            'Video must be under 50 MB. Please choose a smaller file.');
        return;
      }
      setState(() => _videoFile = file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open video picker: $e')),
        );
      }
    }
  }

  void _showVideoPicker() {
    _showSourceSheet(
      onCamera: () => _pickVideo(ImageSource.camera),
      onGallery: () => _pickVideo(ImageSource.gallery),
    );
  }

  void _removeVideo() => setState(() {
        _videoFile = null;
        _existingVideoUrl = null;
      });

  void _pickImage(int index) {
    _showSourceSheet(
      onCamera: () async {
        final ok = await _ensurePermissions(
            source: ImageSource.camera, needsMicrophone: false);
        if (!ok) return;
        try {
          final picked = await _picker.pickImage(
              source: ImageSource.camera, imageQuality: 80);
          if (picked != null) {
            setState(() => _imageFiles[index] = File(picked.path));
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open camera: $e')),
            );
          }
        }
      },
      onGallery: () async {
        final ok = await _ensurePermissions(
            source: ImageSource.gallery, needsMicrophone: false);
        if (!ok) return;
        try {
          final picked = await _picker.pickMultiImage(imageQuality: 80);
          if (picked.isNotEmpty) {
            setState(() {
              int slot = index;
              for (final f in picked) {
                while (slot < 12 && _imageFiles[slot] != null) {
                  slot++;
                }
                if (slot >= 12) break;
                _imageFiles[slot] = File(f.path);
                slot++;
              }
            });
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not open gallery: $e')),
            );
          }
        }
      },
    );
  }

  void _showSourceSheet({
    required VoidCallback onCamera,
    required VoidCallback onGallery,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              title: Text('Camera',
                  style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: isDark ? Colors.white : Colors.black87)),
              onTap: () {
                Navigator.pop(context);
                onCamera();
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: Text('Gallery',
                  style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: isDark ? Colors.white : Colors.black87)),
              onTap: () {
                Navigator.pop(context);
                onGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _saveAndNext() async {
    final newImageCount = _imageFiles.where((f) => f != null).length;
    final hasNewVideo = _videoFile != null;
    setState(() {
      _isUploading = true;
      _uploadedCount = 0;
      _totalToUpload = newImageCount + (hasNewVideo ? 1 : 0);
    });
    try {
      final imageUrls = <String>[];
      for (int i = 0; i < 12; i++) {
        if (_imageFiles[i] != null) {
          final url = await api.uploadImage(
              file: _imageFiles[i]!, fileType: 'announcements');
          if (url != null) imageUrls.add(url);
          setState(() => _uploadedCount++);
        } else if (_existingImageUrls[i] != null) {
          imageUrls.add(_existingImageUrls[i]!);
        }
      }
      String? videoUrl;
      if (_videoFile != null) {
        videoUrl =
            await api.uploadImage(file: _videoFile!, fileType: 'announcements');
        setState(() => _uploadedCount++);
      } else {
        videoUrl = _existingVideoUrl;
      }
      final c = Get.find<AnnouncementController>();
      c.setListingType(_propertyFor == 'Sell' ? 1 : 2);
      c.setInformation(
        propertyType: _propertyType!,
        propertyName:
            _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        sqft: double.tryParse(_sqftCtrl.text.trim()) ?? 0,
        sqm: double.tryParse(_spmCtrl.text.trim()) ?? 0,
        bedrooms: int.tryParse(_bedroom!) ?? 0,
        bathrooms: int.tryParse(_bathroom!) ?? 0,
        floor: _parseFloor(_floor),
        totalFloors: _parseFloor(_totalFloor),
        description: _descCtrl.text.trim(),
        amenities: _selectedAmenityIds.toList(),
        propertyStatus: _isProperty == 'Off Plan' ? 2 : 1,
        isCommercialProperty: _isCommercial ? 1 : 0,
        completionDate: _completionDate,
      );
      c.setMedia(
        imageUrls: imageUrls,
        videoUrl: videoUrl,
        thumbnailUrl: imageUrls.isNotEmpty ? imageUrls.first : null,
      );
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() => _isUploading = false);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isUploading = false);
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  const CustomHeader(
                    title: 'Property Information',
                    showBackButton: true,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Commercial toggle ──────────────────────────────────
                          Row(
                            children: [
                              Icon(Icons.apartment_outlined,
                                  size: 20.sp, color: AppColors.primary),
                              SizedBox(width: 8.w),
                              Text(
                                'Commercial Property',
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  color:
                                      isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              const Spacer(),
                              Transform.scale(
                                scale: 0.6,
                                child: Switch(
                                  value: _isCommercial,
                                  onChanged: (v) =>
                                      setState(() => _isCommercial = v),
                                  activeTrackColor: AppColors.primary,
                                  thumbColor: const WidgetStatePropertyAll(
                                      Colors.white),
                                  inactiveTrackColor: Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),

                          // ── Property For ───────────────────────────────────────
                          _label('Property For',
                              required: true, isDark: isDark),
                          SizedBox(height: 8.h),
                          OverlayDropdownField(
                            hint: 'Rent or Sell',
                            value: _propertyFor,
                            items: const ['Rent', 'Sell'],
                            onSelect: (v) => setState(() {
                              _propertyFor = v;
                              if (v == 'Rent') {
                                _isProperty = 'Ready';
                                _completionDate = null;
                              }
                            }),
                            prefixIcon: Icons.home_outlined,
                          ),
                          SizedBox(height: 16.h),

                          // ── Property Type ──────────────────────────────────────
                          _label('Property Type',
                              required: true, isDark: isDark),
                          SizedBox(height: 8.h),
                          Obx(() => OverlayDropdownField(
                                hint: _propertyTypeCtrl.isLoading.value
                                    ? 'Loading...'
                                    : 'Select Now',
                                value: _propertyType,
                                items: _propertyTypeCtrl.names,
                                onSelect: (v) =>
                                    setState(() => _propertyType = v),
                                prefixIcon: Icons.domain_outlined,
                              )),
                          SizedBox(height: 16.h),

                          // ── Property Name ──────────────────────────────────────
                          _label('Property Name', isDark: isDark),
                          SizedBox(height: 8.h),
                          _textField(
                              controller: _nameCtrl,
                              hint: 'Write Here...',
                              isDark: isDark,
                              prefixIcon: Icons.shield_outlined),
                          SizedBox(height: 16.h),

                          // ── Property Size ──────────────────────────────────────
                          _label('Property Size',
                              required: true, isDark: isDark),
                          SizedBox(height: 8.h),
                          Row(
                            children: [
                              Expanded(
                                child: _textFieldSuffix(
                                    controller: _sqftCtrl,
                                    hint: '0',
                                    suffix: 'Sqft',
                                    isDark: isDark,
                                    prefixIcon: Icons.square_foot),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: _textFieldSuffix(
                                    controller: _spmCtrl,
                                    hint: '0',
                                    suffix: 'Sqm',
                                    isDark: isDark,
                                    prefixIcon: Icons.square_foot),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),

                          // ── Bedroom + Bathroom ─────────────────────────────────
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label('Bedroom',
                                        required: true, isDark: isDark),
                                    SizedBox(height: 8.h),
                                    OverlayDropdownField(
                                      hint: '0',
                                      value: _bedroom,
                                      items: _bedroomBathroomCounts,
                                      onSelect: (v) =>
                                          setState(() => _bedroom = v),
                                      prefixIcon: Icons.bed_outlined,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label('Bathroom',
                                        required: true, isDark: isDark),
                                    SizedBox(height: 8.h),
                                    OverlayDropdownField(
                                      hint: '0',
                                      value: _bathroom,
                                      items: _bedroomBathroomCounts,
                                      onSelect: (v) =>
                                          setState(() => _bathroom = v),
                                      prefixIcon: Icons.bathtub_outlined,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),

                          // ── Floor + Total Floor ────────────────────────────────
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label('Floor',
                                        required: true, isDark: isDark),
                                    SizedBox(height: 8.h),
                                    OverlayDropdownField(
                                      hint: 'Select Floor',
                                      value: _floor,
                                      items: _floorCounts,
                                      onSelect: (v) =>
                                          setState(() => _floor = v),
                                      prefixIcon: Icons.layers_outlined,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _label('Total Floor',
                                        required: true, isDark: isDark),
                                    SizedBox(height: 8.h),
                                    OverlayDropdownField(
                                      hint: 'Select Floor',
                                      value: _totalFloor,
                                      items: _floorCounts,
                                      onSelect: (v) =>
                                          setState(() => _totalFloor = v),
                                      prefixIcon: Icons.layers_outlined,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),

                          // ── Is Property (hidden for Rent) ──────────────────────
                          if (_propertyFor != 'Rent') ...[
                            _label('Is Property',
                                required: true, isDark: isDark),
                            SizedBox(height: 8.h),
                            OverlayDropdownField(
                              hint: 'Select Now',
                              value: _isProperty,
                              items: _isPropertyOptions,
                              onSelect: (v) => setState(() {
                                _isProperty = v;
                                if (v != 'Off Plan') _completionDate = null;
                              }),
                              prefixIcon: Icons.home_outlined,
                            ),
                            if (_isProperty == 'Off Plan') ...[
                              SizedBox(height: 16.h),
                              _label('Completion Date of Property',
                                  required: true, isDark: isDark),
                              SizedBox(height: 8.h),
                              _datePicker(isDark: isDark),
                            ],
                            SizedBox(height: 20.h),
                          ],

                          // ── Amenities ──────────────────────────────────────────
                          Text(
                            'Amenities',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          _buildAmenities(isDark: isDark),
                          SizedBox(height: 24.h),

                          // ── Video ──────────────────────────────────────────────
                          Text(
                            'Add Property Video Max Length 1min',
                            style: GoogleFonts.inter(
                              fontSize: 13.sp,
                              color: isDark
                                  ? Colors.grey.shade300
                                  : Colors.black87,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Stack(
                            children: [
                              GestureDetector(
                                onTap: _showVideoPicker,
                                child: _videoBox(isDark),
                              ),
                              if (_videoFile != null ||
                                  _existingVideoUrl != null)
                                Positioned(
                                  top: 4.h,
                                  right: 4.w,
                                  child: GestureDetector(
                                    onTap: _removeVideo,
                                    child: Container(
                                      width: 20.w,
                                      height: 20.w,
                                      decoration: const BoxDecoration(
                                          color: Colors.black54,
                                          shape: BoxShape.circle),
                                      child: Icon(Icons.close,
                                          size: 13.sp, color: Colors.white),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 24.h),

                          // ── Images ─────────────────────────────────────────────
                          RichText(
                            text: TextSpan(
                              text: 'Add Property Images Minimum 8',
                              style: GoogleFonts.inter(
                                fontSize: 13.sp,
                                color: isDark
                                    ? Colors.grey.shade300
                                    : Colors.black87,
                              ),
                              children: [
                                TextSpan(
                                    text: ' *',
                                    style:
                                        GoogleFonts.inter(color: Colors.red)),
                              ],
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            '$_filledSlotCount/12 selected',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          _imageGrid(isDark),
                          SizedBox(height: 24.h),

                          // ── Property Description ───────────────────────────────
                          _label('Property Description',
                              required: true, isDark: isDark),
                          SizedBox(height: 8.h),
                          _descriptionField(isDark: isDark),
                          SizedBox(height: 32.h),
                        ],
                      ),
                    ),
                  ),

                  // ── Save button ────────────────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                    child: GestureDetector(
                      onTap: _isValid && !_isUploading ? _saveAndNext : null,
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
                          'Save',
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
                ],
              ),
            ),
            if (_isUploading) _buildUploadOverlay(),
          ],
        ),
      ),
    );
  }

  // ── Upload overlay ────────────────────────────────────────────────────────

  Widget _buildUploadOverlay() {
    final percent = (_uploadProgress * 100).toInt();
    final isDone = _uploadedCount >= _totalToUpload && _totalToUpload > 0;
    return Positioned.fill(
      child: AbsorbPointer(
        child: Container(
          color: Colors.black.withValues(alpha: 0.6),
          child: Center(
            child: Container(
              width: 200.w,
              padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 24.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
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
                            value: _uploadProgress,
                            strokeWidth: 7,
                            strokeCap: StrokeCap.round,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                          ),
                        ),
                        Text(
                          '$percent%',
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
                    isDone
                        ? 'Upload complete!'
                        : 'Uploading ${_uploadedCount + 1} of $_totalToUpload...',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
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

  // ── Video box ─────────────────────────────────────────────────────────────

  Widget _videoBox(bool isDark) {
    final hasVideo = _videoFile != null || _existingVideoUrl != null;
    final emptyBorderColor =
        isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final emptyIconColor = isDark ? Colors.grey.shade600 : Colors.grey.shade300;

    return Container(
      width: 100.w,
      height: 100.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.r),
        color: hasVideo
            ? Colors.black
            : (isDark ? const Color(0xFF1A1A1A) : Colors.white),
      ),
      child: CustomPaint(
        painter: _DashedBorderPainter(
            color: hasVideo ? Colors.transparent : emptyBorderColor),
        child: hasVideo
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6.r),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(color: Colors.grey.shade800),
                    Icon(Icons.videocam, color: Colors.white, size: 32.sp),
                    Positioned(
                      bottom: 4.h,
                      left: 4.w,
                      right: 4.w,
                      child: Text(
                        _videoFile != null
                            ? _videoFile!.path.split('/').last
                            : 'Video uploaded',
                        style: GoogleFonts.inter(
                            fontSize: 9.sp, color: Colors.white70),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
            : Center(
                child: Icon(Icons.videocam_outlined,
                    size: 32.sp, color: emptyIconColor),
              ),
      ),
    );
  }

  // ── Image grid ────────────────────────────────────────────────────────────

  Widget _imageGrid(bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 8.h,
      ),
      itemCount: 12,
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => _pickImage(i),
        child: _imageBox(i, isDark),
      ),
    );
  }

  Widget _imageBox(int index, bool isDark) {
    final file = _imageFiles[index];
    final existingUrl = _existingImageUrls[index];

    if (file != null || existingUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4.r),
        child: Stack(
          fit: StackFit.expand,
          children: [
            file != null
                ? Image.file(file, fit: BoxFit.cover)
                : CachedNetworkImage(
                    imageUrl: existingUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      color:
                          isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      child: Icon(Icons.broken_image_outlined,
                          color: Colors.grey.shade500, size: 28.sp),
                    ),
                  ),
            Positioned(
              top: 4.h,
              right: 4.w,
              child: GestureDetector(
                onTap: () => setState(() {
                  _imageFiles[index] = null;
                  _existingImageUrls[index] = null;
                }),
                child: Container(
                  width: 18.w,
                  height: 18.w,
                  decoration: const BoxDecoration(
                      color: Colors.black54, shape: BoxShape.circle),
                  child: Icon(Icons.close, size: 12.sp, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final iconColor = isDark ? Colors.grey.shade600 : Colors.grey.shade300;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: CustomPaint(
        painter: _DashedBorderPainter(color: borderColor),
        child: Center(
          child: Icon(Icons.image_outlined, size: 28.sp, color: iconColor),
        ),
      ),
    );
  }

  // ── Form sub-widgets ──────────────────────────────────────────────────────

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

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    IconData? prefixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        children: [
          if (prefixIcon != null) ...[
            SizedBox(width: 12.w),
            Icon(prefixIcon, size: 20.sp, color: AppColors.primary),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: true,
                fillColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textFieldSuffix({
    required TextEditingController controller,
    required String hint,
    required String suffix,
    required bool isDark,
    IconData? prefixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        children: [
          if (prefixIcon != null) ...[
            SizedBox(width: 10.w),
            Icon(prefixIcon, size: 20.sp, color: AppColors.primary),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: true,
                fillColor: Colors.transparent,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 10.w),
            child: Text(
              suffix,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _descriptionField({required bool isDark}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(12.w, 13.h, 0, 0),
                child: Icon(Icons.description_outlined,
                    size: 20.sp, color: AppColors.primary),
              ),
              Expanded(
                child: TextField(
                  controller: _descCtrl,
                  maxLines: 4,
                  maxLength: 300,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Write Here...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color:
                          isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                    ),
                    contentPadding: EdgeInsets.all(12.w),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: true,
                    fillColor: Colors.transparent,
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(right: 10.w, bottom: 6.h),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_descCtrl.text.length}/300',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _datePicker({required bool isDark}) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme(
                brightness: isDark ? Brightness.dark : Brightness.light,
                primary: AppColors.primary,
                onPrimary: Colors.white,
                secondary: AppColors.primary,
                onSecondary: Colors.white,
                error: Colors.red,
                onError: Colors.white,
                surface: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                onSurface: isDark ? Colors.white : Colors.black87,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) setState(() => _completionDate = picked);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 13.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          border: Border.all(
            color: isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 20.sp, color: AppColors.primary),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                _completionDate != null
                    ? '${_completionDate!.month.toString().padLeft(2, '0')}/${_completionDate!.day.toString().padLeft(2, '0')}/${_completionDate!.year}'
                    : 'mm/dd/yyyy',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: _completionDate != null
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey.shade400, size: 18.sp),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenities({required bool isDark}) {
    return Obx(() {
      if (_amenityCtrl.isLoading.value && _amenityCtrl.amenities.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        );
      }
      if (_amenityCtrl.error.value != null && _amenityCtrl.amenities.isEmpty) {
        return Row(
          children: [
            Expanded(
              child: Text(
                "Couldn't load amenities.",
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                ),
              ),
            ),
            TextButton(
              onPressed: () => _amenityCtrl.loadAmenities(force: true),
              child: Text('Retry',
                  style: GoogleFonts.inter(
                      fontSize: 12.sp, color: AppColors.primary)),
            ),
          ],
        );
      }
      if (_amenityCtrl.amenities.isEmpty) {
        return Text(
          'No amenities available',
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
          ),
        );
      }
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 4,
        mainAxisSpacing: 8.h,
        crossAxisSpacing: 8.w,
        children: _amenityCtrl.amenities.map((item) {
          final selected = _selectedAmenityIds.contains(item.id);
          return GestureDetector(
            onTap: () => setState(() {
              selected
                  ? _selectedAmenityIds.remove(item.id)
                  : _selectedAmenityIds.add(item.id);
            }),
            child: Row(
              children: [
                Container(
                  width: 18.w,
                  height: 18.w,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selected
                          ? AppColors.primary
                          : (isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade400),
                    ),
                    borderRadius: BorderRadius.circular(3.r),
                    color: selected
                        ? AppColors.primary
                        : (isDark ? const Color(0xFF1A1A1A) : Colors.white),
                  ),
                  child: selected
                      ? Icon(Icons.check, size: 12.sp, color: Colors.white)
                      : null,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    item.name,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    });
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  const _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (color == Colors.transparent) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    const radius = Radius.circular(4);
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, radius);
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        canvas.drawPath(metric.extractPath(dist, dist + dashWidth), paint);
        dist += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}
