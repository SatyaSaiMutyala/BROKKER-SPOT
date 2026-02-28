import 'package:brokkerspot/views/auth/controller/email_verification_controller.dart';
import 'package:brokkerspot/views/auth/controller/forget_password_controller.dart';
import 'package:brokkerspot/views/auth/view/email_verification_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';

class ForgetPasswordView extends StatefulWidget {
  const ForgetPasswordView({super.key});

  @override
  State<ForgetPasswordView> createState() => _ForgetPasswordViewState();
}

class _ForgetPasswordViewState extends State<ForgetPasswordView> {
  late final ForgetPasswordController controller;

  TextEditingController emailController = TextEditingController();
  bool _isValidEmail = false;

  bool _checkEmail(String email) {
    return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(email.trim());
  }

  @override
  void initState() {
    super.initState();

    controller = Get.put(
      ForgetPasswordController(),
    );

    emailController.addListener(() {
      final valid = _checkEmail(emailController.text);
      if (valid != _isValidEmail) {
        setState(() => _isValidEmail = valid);
      }
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    Get.delete<EmailVerificationController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
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
          'PASSWORD ASSISTANCE',
          style: GoogleFonts.carlito(
            fontSize: 24.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 10.h),
        RichText(
          text: TextSpan(
            style: GoogleFonts.carlito(
                fontSize: 14.sp,
                color: Colors.black54,
                fontWeight: FontWeight.w400),
            children: [
              const TextSpan(
                text: 'Enter the Email Address with Brokkerspot.',
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
      controller: emailController,

      style: GoogleFonts.roboto(
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 2,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: 'E-mail',
        hintStyle: GoogleFonts.roboto(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
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
          backgroundColor:
              _isValidEmail ? const Color(0xFFD9C27C) : Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        onPressed: _isValidEmail
            ? () async {
                bool success = await controller
                    .forgetPassword(emailController.text.trim());
                if (success) {
                  Get.to(() => EmailVerificationView(
                        password: true,
                        email: emailController.text.trim(),
                      ));
                } else {
                  Get.snackbar(
                    "Error",
                    "Failed to send OTP. Please try again.",
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              }
            : null,
        child: Text(
          'Continue',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: _isValidEmail ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  // ---------------- BOTTOM IMAGE ----------------
  Widget _bottomCityImage(BuildContext context) {
    return Image.asset(
      'assets/images/city.png',
      height: 120.h,
      width: double.infinity,
      fit: BoxFit.cover,
    );
  }
}
