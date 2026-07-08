import 'package:brokkerspot/views/auth/controller/email_verification_controller.dart';
import 'package:brokkerspot/views/auth/controller/forget_password_controller.dart';
import 'package:brokkerspot/views/auth/view/email_verification_view.dart';
import 'package:brokkerspot/core/constants/flutter_toast.dart';
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
    controller = Get.put(ForgetPasswordController());
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        _topSection(context, isDark),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: _contentSection(isDark),
                        ),
                      ],
                    ),
                    _bottomCityImage(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Top section ───────────────────────────────────────────────────────────────

  Widget _topSection(BuildContext context, bool isDark) {
    final backBorderColor =
        isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE5E5E5);
    final backIconColor = isDark ? Colors.white : Colors.black87;

    return SizedBox(
      height: 220.h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -90.h,
            right: -20.w,
            child: Image.asset(
              'assets/images/top_curve.png',
              width: 300.w,
              height: 349.h,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: 10.h,
            left: 20.w,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: backBorderColor),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: backIconColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Content section ───────────────────────────────────────────────────────────

  Widget _contentSection(bool isDark) {
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.black54;

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
              color: subtitleColor,
              fontWeight: FontWeight.w400,
            ),
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
        _emailField(isDark),
        SizedBox(height: 30.h),
        _verifyButton(isDark),
      ],
    );
  }

  // ── Email field ───────────────────────────────────────────────────────────────

  Widget _emailField(bool isDark) {
    final inputTextColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.grey.shade500 : Colors.grey;
    final enabledBorderColor =
        isDark ? const Color(0xFF3A3A3A) : Colors.black26;
    final focusedBorderColor = isDark ? Colors.grey.shade400 : Colors.black;

    return TextField(
      controller: emailController,
      style: GoogleFonts.roboto(
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 2,
        color: inputTextColor,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: 'E-mail',
        hintStyle: GoogleFonts.roboto(
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
          color: hintColor,
        ),
        suffixIconConstraints: const BoxConstraints(minWidth: 0),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: enabledBorderColor),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: focusedBorderColor),
        ),
      ),
    );
  }

  // ── Verify button ─────────────────────────────────────────────────────────────

  Widget _verifyButton(bool isDark) {
    final disabledBg = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300;
    final disabledTextColor = isDark ? Colors.white38 : Colors.black54;

    return SizedBox(
      width: double.infinity,
      height: 46.h,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _isValidEmail ? const Color(0xFFD9C27C) : disabledBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        onPressed: _isValidEmail
            ? () async {
                bool success = await controller
                    .forgetPassword(emailController.text.trim());
                if (success && mounted) {
                  Get.to(() => EmailVerificationView(
                        password: true,
                        email: emailController.text.trim(),
                      ));
                } else if (!success) {
                  AppToast.error("Failed to send OTP. Please try again.");
                }
              }
            : null,
        child: Text(
          'Continue',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: _isValidEmail ? Colors.white : disabledTextColor,
          ),
        ),
      ),
    );
  }

  // ── Bottom image ──────────────────────────────────────────────────────────────

  Widget _bottomCityImage() {
    return Image.asset(
      'assets/images/city.png',
      width: double.infinity,
      fit: BoxFit.fitWidth,
    );
  }
}
