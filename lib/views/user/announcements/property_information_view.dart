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

  /// One size input; [_sizeUnit] decides which unit it means.
  final _sizeCtrl = TextEditingController();
  String _sizeUnit = _unitSqft;

  static const _unitSqft = 'Sqft';
  static const _unitSqm = 'Sqm';
  static const _sizeUnits = [_unitSqft, _unitSqm];
  static const double _sqftPerSqm = 10.7639104;

  double get _sizeValue => double.tryParse(_sizeCtrl.text.trim()) ?? 0;
  bool get _isSqft => _sizeUnit == _unitSqft;

  // The payload carries both units and the detail screens render each one, so
  // the unit the user didn't pick is derived rather than left at 0.
  double get _sqftValue => _isSqft ? _sizeValue : _sizeValue * _sqftPerSqm;
  double get _sqmValue => _isSqft ? _sizeValue / _sqftPerSqm : _sizeValue;
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
  final List<File?> _imageFiles = List.filled(_maxImages, null);
  final List<String?> _existingImageUrls = List.filled(_maxImages, null);
  bool _isUploading = false;
  int _uploadedCount = 0;
  int _totalToUpload = 0;

  static const int _maxVideoBytes = 50 * 1024 * 1024;

  /// Photo slots a listing gets. The grid, the upload loop and the gallery
  /// picker all read this, so the cap can't drift apart between them.
  static const int _maxImages = 12;

  int get _filledSlotCount {
    int count = 0;
    for (int i = 0; i < _maxImages; i++) {
      if (_imageFiles[i] != null || _existingImageUrls[i] != null) count++;
    }
    return count;
  }

  double get _uploadProgress =>
      _totalToUpload == 0 ? 0 : _uploadedCount / _totalToUpload;

  // ── Required-field reporting ──────────────────────────────────────────────
  // The Save button stays visually disabled while the form is incomplete, but
  // remains tappable so a tap can point at what's missing instead of doing
  // nothing. Set once the user has tried to submit — errors aren't shown before
  // that, so a fresh form isn't covered in red.
  bool _showErrors = false;

  final _propertyForKey = GlobalKey();
  final _propertyTypeKey = GlobalKey();
  final _sizeKey = GlobalKey();
  final _bedroomKey = GlobalKey();
  final _bathroomKey = GlobalKey();
  final _floorKey = GlobalKey();
  final _totalFloorKey = GlobalKey();
  final _isPropertyKey = GlobalKey();
  final _completionDateKey = GlobalKey();
  final _descriptionKey = GlobalKey();

  /// Required fields in the order they appear on screen, so the first entry
  /// still missing is also the one nearest the top of the form.
  ///
  /// The conditional entries mirror the same rules as [_isValid] — "Is Property"
  /// is hidden for Rent, and the completion date only exists for Off Plan — so
  /// the two can't disagree about what counts as complete.
  List<({GlobalKey key, String label, bool missing})> get _requiredFields => [
        (
          key: _propertyForKey,
          label: 'Property For',
          missing: _propertyFor == null
        ),
        (
          key: _propertyTypeKey,
          label: 'Property Type',
          missing: _propertyType == null
        ),
        (
          key: _sizeKey,
          label: 'Property Size',
          missing: _sizeCtrl.text.trim().isEmpty
        ),
        (key: _bedroomKey, label: 'Bedroom', missing: _bedroom == null),
        (key: _bathroomKey, label: 'Bathroom', missing: _bathroom == null),
        (key: _floorKey, label: 'Floor', missing: _floor == null),
        (
          key: _totalFloorKey,
          label: 'Total Floor',
          missing: _totalFloor == null
        ),
        if (_propertyFor != 'Rent')
          (
            key: _isPropertyKey,
            label: 'Is Property',
            missing: _isProperty == null
          ),
        if (_propertyFor != 'Rent' && _isProperty == 'Off Plan')
          (
            key: _completionDateKey,
            label: 'Completion Date',
            missing: _completionDate == null
          ),
        (
          key: _imageSectionKey,
          label: 'at least 8 property images',
          missing: _filledSlotCount < 8
        ),
        (
          key: _descriptionKey,
          label: 'Property Description',
          missing: _descCtrl.text.trim().isEmpty
        ),
      ];

  /// Save tap. Valid → proceed; invalid → turn on error borders and bring the
  /// first missing field into view rather than leaving a dead button.
  void _onSaveTap() {
    if (_isUploading) return;
    // Dismiss the keyboard immediately so it doesn't stay open during the
    // save progress or on the way back to the previous screen.
    FocusScope.of(context).unfocus();
    if (_isValid) {
      _saveAndNext();
      return;
    }
    setState(() => _showErrors = true);
    final first = _requiredFields.where((f) => f.missing).firstOrNull;
    if (first == null) return;
    // Next frame: the red borders we just triggered change some heights, so
    // measure after that layout has landed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = first.key.currentContext;
      if (!mounted || ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        alignment: 0.2,
      );
    });
    EasyLoading.showToast(
      'Please add ${first.label}',
      duration: const Duration(seconds: 2),
      toastPosition: EasyLoadingToastPosition.bottom,
    );
  }

  bool get _isValid =>
      _propertyFor != null &&
      _propertyType != null &&
      _sizeCtrl.text.trim().isNotEmpty &&
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
    // Restore into whichever unit actually has a value, preferring sqft since
    // that's the default. Both are stored, so an existing announcement will
    // normally have both and shows as sqft.
    if ((c.sqft ?? 0) > 0) {
      _sizeUnit = _unitSqft;
      _sizeCtrl.text = c.sqft!.toStringAsFixed(0);
    } else if ((c.sqm ?? 0) > 0) {
      _sizeUnit = _unitSqm;
      _sizeCtrl.text = c.sqm!.toStringAsFixed(0);
    }
    _bedroom = _intToCountStr(c.bedrooms);
    _bathroom = _intToCountStr(c.bathrooms);
    _floor = _intToFloorStr(c.floor);
    _totalFloor = _intToFloorStr(c.totalFloors);
    if (c.description != null) _descCtrl.text = c.description!;
    if (c.amenities.isNotEmpty) _selectedAmenityIds.addAll(c.amenities);
    // Refresh rather than trust the session cache: both lists are edited in
    // the admin panel, so an amenity or property type added there has to show
    // up the next time this screen is opened, not after an app restart. With
    // a cached list present this is silent — the current options stay on
    // screen and are swapped for the fresh ones when the response lands.
    _amenityCtrl.loadAmenities(force: true);
    _propertyTypeCtrl.load(force: true);
    if (c.propertyStatus == 1) _isProperty = 'Ready';
    if (c.propertyStatus == 2) _isProperty = 'Off Plan';
    _completionDate = c.completionDate;
    _isCommercial = c.isCommercialProperty == 1;
    _existingVideoUrl = c.videoUrl;
    for (int i = 0; i < c.imageUrls.length && i < _maxImages; i++) {
      _existingImageUrls[i] = c.imageUrls[i];
    }
    _descCtrl.addListener(() => setState(() {}));
    _sizeCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _sizeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  int _parseCount(String? val) {
    if (val == null) return 0;
    if (val == '5+') return 5;
    return int.tryParse(val) ?? 0;
  }

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

  // Anchors for scrolling a fresh selection back into view once a picker
  // returns — see [_revealSection].
  final _videoSectionKey = GlobalKey();
  final _imageSectionKey = GlobalKey();

  /// Scrolls the section behind [key] back into view after a pick.
  ///
  /// Picking pushes the app to the background and back; on return the form can
  /// sit at a different offset, leaving the thumbnail the user just chose below
  /// the fold. Deferred to the next frame so the rebuilt (and now taller)
  /// section has been laid out before we measure it.
  void _revealSection(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (!mounted || ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        // Park it near the top — the image grid is far too tall to fit whole.
        alignment: 0.1,
      );
    });
  }

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
      _revealSection(_videoSectionKey);
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

  /// One-line notice about the photo cap.
  void _warn(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

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
            _revealSection(_imageSectionKey);
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
          final free = _maxImages - _filledSlotCount;
          if (free <= 0) {
            _warn('You can add up to $_maxImages photos.');
            return;
          }
          // Cap the picker itself rather than quietly dropping the overflow
          // afterwards. The platform picker stops accepting taps at the limit,
          // so the count on screen is the count that lands.
          final List<XFile> picked;
          if (free == 1) {
            // The plugin only accepts a limit of 2 or more, so a single free
            // slot goes through the single-image picker instead.
            final one = await _picker.pickImage(
                source: ImageSource.gallery, imageQuality: 80);
            picked = one == null ? <XFile>[] : <XFile>[one];
          } else {
            picked = await _picker.pickMultiImage(imageQuality: 80, limit: free);
          }

          if (picked.isNotEmpty) {
            int added = 0;
            setState(() {
              int slot = index;
              for (final f in picked) {
                while (slot < _maxImages && _imageFiles[slot] != null) {
                  slot++;
                }
                if (slot >= _maxImages) break;
                _imageFiles[slot] = File(f.path);
                slot++;
                added++;
              }
            });
            _revealSection(_imageSectionKey);
            // Older platforms ignore the picker limit, so anything that still
            // didn't fit is called out rather than vanishing.
            if (added < picked.length) {
              _warn('Only $added of ${picked.length} photos were added — '
                  'the limit is $_maxImages.');
            }
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
    // Drop focus before the sheet opens. The tap that got us here was consumed
    // by the placeholder's own GestureDetector, so it never reached the unfocus
    // handler wrapping the body — and a still-focused field makes the keyboard
    // flash back when the picker hands the activity over, which shifts the
    // scroll position out from under the user.
    FocusScope.of(context).unfocus();
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
      for (int i = 0; i < _maxImages; i++) {
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
        propertyTypeId: _propertyTypeCtrl.idForName(_propertyType!),
        propertyName:
            _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
        sqft: _sqftValue,
        sqm: _sqmValue,
        bedrooms: _parseCount(_bedroom),
        bathrooms: _parseCount(_bathroom),
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
                      // Dragging the form closes the keyboard, so the user isn't
                      // scrolling a half-height viewport with the keypad in the way.
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
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
                            key: _propertyForKey,
                            hasError: _showErrors && _propertyFor == null,
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
                                key: _propertyTypeKey,
                                hasError: _showErrors && _propertyType == null,
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
                            key: _sizeKey,
                            children: [
                              Expanded(
                                child: _textField(
                                  controller: _sizeCtrl,
                                  hint: '0',
                                  isDark: isDark,
                                  prefixIcon: Icons.square_foot,
                                  keyboardType: TextInputType.number,
                                  hasError: _showErrors &&
                                      _sizeCtrl.text.trim().isEmpty,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              // Fixed width: the unit label is short and never
                              // needs half the row.
                              SizedBox(
                                width: 108.w,
                                child: OverlayDropdownField(
                                  hint: _unitSqft,
                                  value: _sizeUnit,
                                  items: _sizeUnits,
                                  onSelect: (v) =>
                                      setState(() => _sizeUnit = v),
                                ),
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
                                      key: _bedroomKey,
                                      hasError: _showErrors && _bedroom == null,
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
                                      key: _bathroomKey,
                                      hasError:
                                          _showErrors && _bathroom == null,
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
                                      key: _floorKey,
                                      hasError: _showErrors && _floor == null,
                                      hint: 'Select Floor',
                                      value: _floor,
                                      items: _floorCounts,
                                      onSelect: (v) =>
                                          setState(() => _floor = v),
                                      prefixIcon: Icons.layers_outlined,
                                      maxPanelHeight: 264,
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
                                      key: _totalFloorKey,
                                      hasError:
                                          _showErrors && _totalFloor == null,
                                      hint: 'Select Floor',
                                      value: _totalFloor,
                                      items: _floorCounts,
                                      onSelect: (v) =>
                                          setState(() => _totalFloor = v),
                                      prefixIcon: Icons.layers_outlined,
                                      maxPanelHeight: 264,
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
                              key: _isPropertyKey,
                              hasError: _showErrors && _isProperty == null,
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
                              KeyedSubtree(
                                key: _completionDateKey,
                                child: _datePicker(
                                  isDark: isDark,
                                  hasError:
                                      _showErrors && _completionDate == null,
                                ),
                              ),
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
                            key: _videoSectionKey,
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
                            // No border to redden here — the grid is 12 separate
                            // tiles — so the count carries the error instead.
                            _showErrors && _filledSlotCount < 8
                                ? '$_filledSlotCount/$_maxImages selected — add at least 8'
                                : '$_filledSlotCount/$_maxImages selected',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              color: _showErrors && _filledSlotCount < 8
                                  ? Colors.red.shade400
                                  : Colors.grey.shade500,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          KeyedSubtree(
                            key: _imageSectionKey,
                            child: _imageGrid(isDark),
                          ),
                          SizedBox(height: 24.h),

                          // ── Property Description ───────────────────────────────
                          _label('Property Description',
                              required: true, isDark: isDark),
                          SizedBox(height: 8.h),
                          KeyedSubtree(
                            key: _descriptionKey,
                            child: _descriptionField(
                              isDark: isDark,
                              hasError:
                                  _showErrors && _descCtrl.text.trim().isEmpty,
                            ),
                          ),
                          SizedBox(height: 32.h),
                        ],
                      ),
                    ),
                  ),

                  // ── Save button ────────────────────────────────────────────────
                  Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                    child: GestureDetector(
                      // Always tappable (unless mid-upload): an invalid tap
                      // reports what's missing instead of doing nothing. The
                      // colours below still key off _isValid, so it looks
                      // disabled exactly as before.
                      onTap: _isUploading ? null : _onSaveTap,
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
            if (_isUploading) _buildUploadOverlay(isDark),
          ],
        ),
      ),
    );
  }

  // ── Upload overlay ────────────────────────────────────────────────────────

  Widget _buildUploadOverlay(bool isDark) {
    final percent = (_uploadProgress * 100).toInt();
    final isDone = _uploadedCount >= _totalToUpload && _totalToUpload > 0;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white70 : Colors.black54;
    final trackColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);
    return Positioned.fill(
      child: AbsorbPointer(
        child: Container(
          color: Colors.black.withValues(alpha: 0.6),
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
                            value: _uploadProgress,
                            strokeWidth: 7,
                            strokeCap: StrokeCap.round,
                            backgroundColor: trackColor,
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
                      color: textColor,
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
      itemCount: _maxImages,
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
    TextInputType? keyboardType,
    bool hasError = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border.all(
          color: hasError
              ? Colors.red.shade400
              : (isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300),
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
              keyboardType: keyboardType,
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

  Widget _descriptionField({required bool isDark, bool hasError = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        border: Border.all(
          color: hasError
              ? Colors.red.shade400
              : (isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300),
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

  Widget _datePicker({required bool isDark, bool hasError = false}) {
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
            color: hasError
                ? Colors.red.shade400
                : (isDark ? const Color(0xFF3A3A3A) : Colors.grey.shade300),
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
