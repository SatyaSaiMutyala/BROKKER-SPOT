import 'package:brokkerspot/views/auth/email_verification_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';

class ForgetPasswordView extends StatelessWidget {
  const ForgetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
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
          'Password assistance',
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
                text: 'Enter the email address with brokkerspot.',
              ),
              TextSpan(
                text: '*',
                style: GoogleFonts.roboto(color: Colors.red),
              ),
            ],
          ),
        ),
        SizedBox(height: 30.h),
        _emailField(),
        SizedBox(height: 30.h),
        _verifyButton(context),
      ],
    );
  }

  // ---------------- OTP FIELD ----------------
  Widget _emailField() {
    return TextField(
      // keyboardType: TextInputType.number,

      style: GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 2,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: 'Email',
        hintStyle: GoogleFonts.inter(
          fontSize: 14.sp,
          color: Colors.grey,
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
          Get.to(() => const EmailVerificationView(
                password: true,
              ));
        },
        child: Text(
          'Continue',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
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
