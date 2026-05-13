import 'dart:async';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class LocationPickerPopup extends StatefulWidget {
  const LocationPickerPopup({super.key});

  @override
  State<LocationPickerPopup> createState() => _LocationPickerPopupState();
}

class _LocationPickerPopupState extends State<LocationPickerPopup> {
  final _pageCtrl = PageController();
  int _page = 0;
  String? _selected;
  Timer? _timer;

  static const _images = [
    'assets/images/rent1.png',
    'assets/images/rent2.png',
    'assets/images/room.png',
  ];

  static const _locations = [
    {'flag': '🇮🇳', 'name': 'India'},
    {'flag': '🇦🇪', 'name': 'UAE'},
    {'flag': '🇫🇷', 'name': 'France'},
    {'flag': '🇲🇦', 'name': 'Morocco'},
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      final next = (_page + 1) % _images.length;
      _pageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    Navigator.pop(context);
    Get.snackbar(
      '',
      '',
      titleText: Text(
        'Location Set!',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontSize: 14.sp,
        ),
      ),
      messageText: Text(
        'Exploring properties in $_selected',
        style: GoogleFonts.inter(color: Colors.white70, fontSize: 13.sp),
      ),
      backgroundColor: AppColors.primaryDark,
      snackPosition: SnackPosition.BOTTOM,
      borderRadius: 14,
      margin: EdgeInsets.all(16.w),
      icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
      clipBehavior: Clip.antiAlias,
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildImageCarousel(),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildImageCarousel() {
    return SizedBox(
      height: 220.h,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageCtrl,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: _images.length,
            itemBuilder: (_, i) => Image.asset(
              _images[i],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          // bottom gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.72),
                  ],
                  stops: const [0.35, 1.0],
                ),
              ),
            ),
          ),
          // text overlay
          Positioned(
            bottom: 18.h,
            left: 20.w,
            right: 20.w,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Find Your\nDream Property',
                  style: GoogleFonts.inter(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Buy, sell or rent with ease',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // animated dots
          Positioned(
            top: 14.h,
            right: 14.w,
            child: Row(
              children: List.generate(_images.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: EdgeInsets.symmetric(horizontal: 3.w),
                  width: _page == i ? 18.w : 6.w,
                  height: 6.h,
                  decoration: BoxDecoration(
                    color: _page == i ? AppColors.primary : Colors.white54,
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                );
              }),
            ),
          ),
          // close button
          Positioned(
            top: 8.h,
            left: 8.w,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(6.r),
                decoration: const BoxDecoration(
                  color: Colors.black38,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close_rounded, color: Colors.white, size: 16.sp),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final active = _selected != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.location_on_rounded,
                    color: AppColors.primaryDark, size: 18.sp),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Your Location',
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    'Where would you like to explore?',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 18.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 2.h),
            decoration: BoxDecoration(
              border: Border.all(
                color: active
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : Colors.grey.shade200,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(12.r),
              color: Colors.grey.shade50,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selected,
                hint: Row(
                  children: [
                    Icon(Icons.public_rounded,
                        color: Colors.grey.shade400, size: 18.sp),
                    SizedBox(width: 10.w),
                    Text(
                      'Choose a country',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                isExpanded: true,
                icon: Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primaryDark, size: 22.sp),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                items: _locations.map((loc) {
                  return DropdownMenuItem<String>(
                    value: loc['name'],
                    child: Row(
                      children: [
                        Text(
                          loc['flag']!,
                          style: TextStyle(fontSize: 20.sp),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          loc['name']!,
                          style: GoogleFonts.inter(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selected = v),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
                gradient: active
                    ? const LinearGradient(
                        colors: [Color(0xFFDBC483), Color(0xFFB8923E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: active ? null : Colors.grey.shade200,
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        )
                      ]
                    : null,
              ),
              child: ElevatedButton(
                onPressed: active ? _confirm : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Let's Explore!",
                      style: GoogleFonts.inter(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: active ? Colors.white : Colors.black38,
                      ),
                    ),
                    if (active) ...[
                      SizedBox(width: 8.w),
                      Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 18.sp),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
