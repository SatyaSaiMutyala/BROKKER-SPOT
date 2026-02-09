import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';

class DealVerificationWaitView extends StatelessWidget {
  const DealVerificationWaitView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Illustration placeholder
            _buildIllustration(),
            SizedBox(height: 32.h),
            // Message
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Text(
                'Please wait while we verify\nBooking Payment Proof',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  height: 1.4,
                ),
              ),
            ),
            const Spacer(flex: 2),
            // Back to Home button
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
              child: SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: () {
                    // Go back to home / pop until deals
                    Get.until((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldAccent,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                  ),
                  child: Text(
                    'Back To Home',
                    style: GoogleFonts.inter(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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

  Widget _buildIllustration() {
    // Placeholder illustration matching the design
    // (hourglass + person at desk)
    return SizedBox(
      width: 220.w,
      height: 180.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Hourglass
          Positioned(
            left: 20.w,
            child: Icon(
              Icons.hourglass_bottom_rounded,
              size: 100.sp,
              color: Colors.grey.shade400,
            ),
          ),
          // Clipboard/checklist
          Positioned(
            top: 0,
            right: 40.w,
            child: Container(
              width: 60.w,
              height: 80.h,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.grey.shade300),
              ),
              padding: EdgeInsets.all(8.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => Padding(
                    padding: EdgeInsets.only(bottom: 6.h),
                    child: Row(
                      children: [
                        Icon(Icons.check_box,
                            size: 12.sp, color: AppColors.goldAccent),
                        SizedBox(width: 4.w),
                        Expanded(
                          child: Container(
                            height: 4.h,
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Person at desk
          Positioned(
            bottom: 0,
            right: 10.w,
            child: Column(
              children: [
                // Head
                CircleAvatar(
                  radius: 16.r,
                  backgroundColor: AppColors.goldAccent.withValues(alpha: 0.3),
                  child: Icon(Icons.person, size: 20.sp, color: AppColors.goldAccent),
                ),
                // Body/desk
                Container(
                  width: 50.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Icon(Icons.laptop_mac,
                      size: 24.sp, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
