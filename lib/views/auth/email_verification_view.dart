import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';

class EmailVerificationView extends StatelessWidget {
  const EmailVerificationView({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) {
        return Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: false, // ✅ IMPORTANT
          body: SafeArea(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  _topSection(context),
                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: _contentSection(context),
                        ),
                        const Spacer(),
                        _bottomCityImage(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------- TOP SECTION ----------------
  Widget _topSection(BuildContext context) {
    return SizedBox(
      height: 220.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -60.h,
            right: -20.w,
            child: Image.asset(
              'assets/images/top_curve.png',
              width: 300.w,
              height: 349.h,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: 20.h,
            left: 20.w,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: const Icon(Icons.arrow_back_ios, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- CONTENT ----------------
  Widget _contentSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20.h),
        Text(
          'EMAIL VERIFICATION',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 10.h),
        RichText(
          text: TextSpan(
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: Colors.black54,
            ),
            children: [
              const TextSpan(
                text: 'Please Enter The 6-Digit Code We Sent To Your E-Mail',
              ),
              TextSpan(
                text: '*',
                style: GoogleFonts.roboto(color: Colors.red),
              ),
            ],
          ),
        ),
        SizedBox(height: 30.h),
        _otpField(),
        SizedBox(height: 30.h),
        _verifyButton(context),
      ],
    );
  }

  // ---------------- OTP FIELD ----------------
  Widget _otpField() {
    return TextField(
      keyboardType: TextInputType.number,
      maxLength: 6,
      style: GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 2,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: 'Code',
        hintStyle: GoogleFonts.inter(
          fontSize: 14.sp,
          color: Colors.grey,
        ),
        suffixIcon: Padding(
          padding: EdgeInsets.only(top: 14.h),
          child: Text(
            'GET CODE',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: const Color(0xFFD9C27C),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        suffixIconConstraints: const BoxConstraints(minWidth: 0),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black26),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black),
        ),
      ),
    );
  }

  // ---------------- BUTTON ----------------
  Widget _verifyButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 46.h,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD9C27C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: () {
          _showSuccessBottomSheet(context);
        },
        child: Text(
          'Verify Now',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showSuccessBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          height: 220.h,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // CHECK ICON
              Container(
                height: 56.h,
                width: 56.h,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFD9C27C), // gold
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 28,
                ),
              ),

              SizedBox(height: 20.h),

              // TEXT
              Text(
                'You have successfully create an account.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: Colors.black54,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------- BOTTOM IMAGE ----------------
  Widget _bottomCityImage(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: keyboardOpen ? 60.h : 120.h, // 👈 shrink on keyboard
      width: double.infinity,
      child: Image.asset(
        'assets/images/city.png',
        fit: BoxFit.cover,
      ),
    );
  }
}
