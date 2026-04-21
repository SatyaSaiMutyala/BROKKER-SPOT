import 'dart:io';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:brokkerspot/widgets/common/custom_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class PropertyVideoImagesView extends StatefulWidget {
  const PropertyVideoImagesView({super.key});

  @override
  State<PropertyVideoImagesView> createState() =>
      _PropertyVideoImagesViewState();
}

class _PropertyVideoImagesViewState extends State<PropertyVideoImagesView> {
  final ImagePicker _picker = ImagePicker();
  File? _videoFile;
  final List<File?> _imageFiles = List.filled(12, null);

  bool get _isValid => _imageFiles.whereType<File>().length >= 8;

  // ─── Video picker ───
  void _pickVideo(ImageSource source) async {
    try {
      final picked = await _picker.pickVideo(source: source);
      if (picked != null) setState(() => _videoFile = File(picked.path));
    } catch (_) {}
  }

  void _showVideoPicker() {
    _showSourceSheet(
      onCamera: () => _pickVideo(ImageSource.camera),
      onGallery: () => _pickVideo(ImageSource.gallery),
    );
  }

  // ─── Image picker (single box) ───
  void _pickImage(int index) {
    _showSourceSheet(
      onCamera: () async {
        try {
          final picked = await _picker.pickImage(
              source: ImageSource.camera, imageQuality: 80);
          if (picked != null) {
            setState(() => _imageFiles[index] = File(picked.path));
          }
        } catch (_) {}
      },
      onGallery: () async {
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
        } catch (_) {}
      },
    );
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
      body: SafeArea(
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
                    Text('Add Video Max Length 1min',
                        style: GoogleFonts.inter(fontSize: 13.sp, color: Colors.black87)),
                    SizedBox(height: 12.h),
                    GestureDetector(
                      onTap: _showVideoPicker,
                      child: _videoBox(),
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
                      '${_imageFiles.whereType<File>().length}/12 selected',
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
                onPressed: _isValid ? () => Navigator.pop(context, true) : () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _videoBox() {
    return Container(
      width: 100.w,
      height: 100.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.r),
        color: _videoFile != null ? Colors.black : Colors.white,
      ),
      child: CustomPaint(
        painter: _DashedBorderPainter(color: Colors.grey.shade300),
        child: _videoFile != null
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
                        _videoFile!.path.split('/').last,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(4.r),
      child: file != null
          ? Stack(
              fit: StackFit.expand,
              children: [
                Image.file(file, fit: BoxFit.cover),
                Positioned(
                  top: 4.h,
                  right: 4.w,
                  child: GestureDetector(
                    onTap: () => setState(() => _imageFiles[index] = null),
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
            )
          : CustomPaint(
              painter: _DashedBorderPainter(color: Colors.grey.shade300),
              child: Center(
                child: Icon(Icons.image_outlined,
                    size: 28.sp, color: Colors.grey.shade300),
              ),
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
