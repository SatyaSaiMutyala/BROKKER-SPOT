import 'package:brokkerspot/views/auth/controller/email_verification_controller.dart';
import 'package:brokkerspot/views/auth/controller/forget_password_controller.dart';
import 'package:brokkerspot/views/auth/view/create_new_password.dart';
import 'package:brokkerspot/views/auth/view/login_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';

class EmailVerificationView extends StatefulWidget {
  final bool password;
  final String email;

  const EmailVerificationView({
    super.key,
    this.password = false,
    required this.email,
  });

  @override
  State<EmailVerificationView> createState() => _EmailVerificationViewState();
}

class _EmailVerificationViewState extends State<EmailVerificationView> {
  late final EmailVerificationController controller;
  late final ForgetPasswordController forgetPasswordController;

  @override
  void initState() {
    super.initState();

    // Initialize controller safely
    controller = Get.put(
      EmailVerificationController(),
      tag: widget.email,
    );
    forgetPasswordController =
        Get.put(ForgetPasswordController(), tag: widget.email);
  }

  @override
  void dispose() {
    Get.delete<EmailVerificationController>(tag: widget.email);
    Get.delete<ForgetPasswordController>(tag: widget.email);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) {
        return Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: true,
          body: SafeArea(
            child: Column(
              children: [
                _topSection(context),
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: _contentSection(context),
                        ),
                        SizedBox(height: 20.h),
                        _bottomCityImage(context),
                      ],
                    ),
                  ),
                ),
              ],
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
              onTap: () => Get.back(),
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
        Text(
          'Please Enter The 6-Digit Code We Sent To Your E-Mail',
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            color: Colors.black54,
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
      controller: widget.password == false
          ? controller.otpController
          : forgetPasswordController.otpController,
      keyboardType: TextInputType.number,
      maxLength: 6,
      style: GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 2,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: 'Enter OTP',
        hintStyle: GoogleFonts.inter(
          fontSize: 14.sp,
          color: Colors.grey,
        ),
        suffixIcon: InkWell(
          onTap: () async {
            if (widget.password == false) {
              bool success = await controller.resendOtp(widget.email);
              if (success) {
                controller.otpController.clear();
              }
            } else {
              bool success =
                  await forgetPasswordController.forgetPassword(widget.email);
              if (success) {
                controller.otpController.clear();
              }
            }
          },
          child: Padding(
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
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black26),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black),
        ),
      ),
    );
  }

  // ---------------- VERIFY BUTTON ----------------
  Widget _verifyButton(BuildContext context) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 46.h,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD9C27C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          onPressed: controller.isLoading.value
              ? null
              : () async {
                  if (widget.password == true) {
                    bool success = await forgetPasswordController
                        .forgotPasswordVerifyOtp(widget.email);
                    if (success) {
                      Get.to(() => CreateNewPasswordView(email: widget.email));
                    }
                  } else {
                    bool success = await controller.verifyOtp(widget.email);
                    if (success) {
                      _showSuccessBottomSheet(context);
                    }
                  }
                },
          child: controller.isLoading.value
              ? const CircularProgressIndicator(
                  color: Colors.white,
                )
              : Text(
                  'Verify Now',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  // ---------------- SUCCESS BOTTOM SHEET ----------------
  void _showSuccessBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
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
              Container(
                height: 56.h,
                width: 56.h,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFD9C27C),
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'You have successfully created an account.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 3), () {
      Get.offAll(() => LoginView());
    });
  }

  // ---------------- BOTTOM IMAGE ----------------
  Widget _bottomCityImage(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: keyboardOpen ? 60.h : 120.h,
      width: double.infinity,
      child: Image.asset(
        'assets/images/city.png',
        fit: BoxFit.cover,
      ),
    );
  }
}
