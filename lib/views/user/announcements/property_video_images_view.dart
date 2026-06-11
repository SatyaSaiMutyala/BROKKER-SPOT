import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:brokkerspot/core/common_widget/api_service.dart' as api;
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/user/announcements/controller/announcement_controller.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/widgets/common/custom_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class PropertyVideoImagesView extends StatefulWidget {
  const PropertyVideoImagesView({super.key});

  @override
  State<PropertyVideoImagesView> createState() =>
      _PropertyVideoImagesViewState();
}

class _PropertyVideoImagesViewState extends State<PropertyVideoImagesView> {
  final ImagePicker _picker = ImagePicker();
  File? _videoFile;
  String? _existingVideoUrl;
  final List<File?> _imageFiles = List.filled(12, null);
  final List<String?> _existingImageUrls = List.filled(12, null);

  bool get _isValid => _filledSlotCount >= 8;
  bool _isUploading = false;
  int _uploadedCount = 0;
  int _totalToUpload = 0;
  double get _uploadProgress =>
      _totalToUpload == 0 ? 0 : _uploadedCount / _totalToUpload;

  int get _filledSlotCount {
    int count = 0;
    for (int i = 0; i < 12; i++) {
      if (_imageFiles[i] != null || _existingImageUrls[i] != null) count++;
    }
    return count;
  }

  @override
  void initState() {
    super.initState();
    final c = Get.find<AnnouncementController>();
    _existingVideoUrl = c.videoUrl;
    for (int i = 0; i < c.imageUrls.length && i < 12; i++) {
      _existingImageUrls[i] = c.imageUrls[i];
    }
  }

  static const int _maxVideoBytes = 50 * 1024 * 1024; // 50 MB

  // ─── Permission gate ───
  /// Requests the permissions needed for the given source/media. Returns true
  /// only after the user grants them. If the user previously selected "Don't
  /// ask again" on Android, shows an in-app dialog routing them to Settings.
  Future<bool> _ensurePermissions({
    required ImageSource source,
    required bool needsMicrophone,
  }) async {
    final permissions = <Permission>[];

    if (source == ImageSource.camera) {
      permissions.add(Permission.camera);
      if (needsMicrophone) permissions.add(Permission.microphone);
    } else {
      // Gallery — on iOS 14+, image_picker uses PHPickerViewController which
      // grants scoped access without requiring explicit Photos permission.
      // Checking Permission.photos on iOS causes false "permanently denied"
      // popups because the OS manages access internally. Skip it on iOS.
      if (!Platform.isIOS) {
        permissions.add(
            needsMicrophone ? Permission.videos : Permission.photos);
      }
    }

    for (final p in permissions) {
      var status = await p.status;

      if (status.isGranted || status.isLimited) continue;

      // Restricted (parental/MDM controls) — can't request or change in settings.
      if (status.isRestricted) return false;

      // Always attempt the system request first.
      // On iOS, permission_handler can wrongly report notDetermined as
      // permanentlyDenied before a request is ever made, which suppresses the
      // OS dialog. Calling p.request() on a notDetermined permission shows the
      // system prompt; on a truly denied permission it returns immediately.
      status = await p.request();

      if (status.isGranted || status.isLimited) continue;

      // Truly denied — route user to Settings.
      if (!mounted) return false;
      final opened = await _showSettingsDialog(p);
      if (!opened) return false;
      status = await p.status;
      if (!status.isGranted && !status.isLimited) return false;
    }
    return true;
  }

  Future<bool> _showSettingsDialog(Permission permission) async {
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
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r)),
            title: Text('$label permission required',
                style: GoogleFonts.poppins(
                    fontSize: 16.sp, fontWeight: FontWeight.w600)),
            content: Text(
              'Please enable $label access in Settings to continue.',
              style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.black87),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel',
                    style: GoogleFonts.inter(color: Colors.black54)),
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

  // ─── Video picker ───
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
        EasyLoading.showError('Video must be under 50 MB. Please choose a smaller file.');
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

  void _removeVideo() {
    setState(() {
      _videoFile = null;
      _existingVideoUrl = null;
    });
  }

  // ─── Image picker (single box) ───
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
                while (slot < 12 && _imageFiles[slot] != null) { slot++; }
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

  Future<void> _uploadAndSave() async {
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
        videoUrl = await api.uploadImage(
            file: _videoFile!, fileType: 'announcements');
        setState(() => _uploadedCount++);
      } else {
        videoUrl = _existingVideoUrl;
      }
      Get.find<AnnouncementController>().setMedia(
        imageUrls: imageUrls,
        videoUrl: videoUrl,
        thumbnailUrl: imageUrls.isNotEmpty ? imageUrls.first : null,
      );
      // Hold at 100% briefly so user sees completion before navigating back
      await Future.delayed(const Duration(milliseconds: 600));
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

  void _showSourceSheet({
    required VoidCallback onCamera,
    required VoidCallback onGallery,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              title: Text('Camera', style: GoogleFonts.inter(fontSize: 14.sp)),
              onTap: () {
                Navigator.pop(context);
                onCamera();
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: Text('Gallery', style: GoogleFonts.inter(fontSize: 14.sp)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
        child: Column(
          children: [
            const CustomHeader(title: 'VIDEO & IMAGES', showBackButton: true),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video
                    Text('Add Video (Max 1 min, 50 MB)',
                        style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.black87)),
                    SizedBox(height: 12.h),
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: _showVideoPicker,
                          child: _videoBox(),
                        ),
                        if (_videoFile != null || _existingVideoUrl != null)
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

                    // Images
                    RichText(
                      text: TextSpan(
                        text: 'Add Images minimum 8',
                        style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.black87),
                        children: [
                          TextSpan(
                              text: ' *',
                              style: GoogleFonts.inter(color: Colors.red)),
                        ],
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      '$_filledSlotCount/12 selected',
                      style: GoogleFonts.inter(
                          fontSize: 11.sp, color: Colors.grey.shade500),
                    ),
                    SizedBox(height: 12.h),
                    _imageGrid(),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
            Padding(
                padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 20.h),
                child: CustomPrimaryButton(
                  title: 'Save',
                  backgroundColor: _isValid ? AppColors.primary : Colors.grey.shade300,
                  defaultColor: _isValid ? Colors.white : Colors.black45,
                  onPressed: _isValid && !_isUploading ? _uploadAndSave : () {},
                ),
              ),
          ],
        ),
          ),  // SafeArea
          if (_isUploading) _buildUploadOverlay(),
        ],
      ),
    );
  }

  Widget _buildUploadOverlay() {
    final percent = (_uploadProgress * 100).toInt();
    final isDone = _uploadedCount >= _totalToUpload && _totalToUpload > 0;
    return Positioned.fill(
      child: AbsorbPointer(
        child: Container(
          color: Colors.black.withValues(alpha: 0.5),
          child: Center(
            child: Container(
              width: 200.w,
              padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 24.w),
              decoration: BoxDecoration(
                color: Colors.white,
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
                            backgroundColor: Colors.grey.shade200,
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
                      color: Colors.black87,
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


  Widget _videoBox() {
    final hasVideo = _videoFile != null || _existingVideoUrl != null;
    return Container(
      width: 100.w,
      height: 100.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.r),
        color: hasVideo ? Colors.black : Colors.white,
      ),
      child: CustomPaint(
        painter: _DashedBorderPainter(color: Colors.grey.shade300),
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
                    size: 32.sp, color: Colors.grey.shade300),
              ),
      ),
    );
  }

  Widget _imageGrid() {
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
        child: _imageBox(i),
      ),
    );
  }

  Widget _imageBox(int index) {
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
                      color: Colors.grey.shade200,
                      child: Icon(Icons.broken_image_outlined,
                          color: Colors.grey.shade400, size: 28.sp),
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

    return CustomPaint(
      painter: _DashedBorderPainter(color: Colors.grey.shade300),
      child: Center(
        child: Icon(Icons.image_outlined,
            size: 28.sp, color: Colors.grey.shade300),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  const _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
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
