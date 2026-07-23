import 'dart:async';

import 'package:brokkerspot/views/auth/controller/email_verification_controller.dart';
import 'package:brokkerspot/views/auth/controller/forget_password_controller.dart';
import 'package:brokkerspot/views/auth/view/create_new_password.dart';
import 'package:brokkerspot/views/auth/view/login_view.dart';
import 'package:brokkerspot/widgets/common/custom_back_button.dart';
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
  bool _isOtpValid = false;

  /// Resend cooldown. The code is already sent on arrival, so the timer starts
  /// at 60 and "GET CODE" stays disabled until it reaches 0.
  static const int _resendCooldown = 60;
  Timer? _resendTimer;
  int _secondsLeft = _resendCooldown;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      EmailVerificationController(),
      tag: widget.email,
    );
    forgetPasswordController =
        Get.put(ForgetPasswordController(), tag: widget.email);

    final otpCtrl = widget.password == false
        ? controller.otpController
        : forgetPasswordController.otpController;
    otpCtrl.addListener(() {
      setState(() {
        _isOtpValid = otpCtrl.text.trim().length == 6;
      });
    });

    _startResendTimer();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _secondsLeft = _resendCooldown);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        if (mounted) setState(() => _secondsLeft = 0);
      } else {
        if (mounted) setState(() => _secondsLeft--);
      }
    });
  }

  /// mm:ss for the countdown label.
  String get _timerLabel {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _onGetCode() async {
    if (_secondsLeft > 0) return;
    final success = widget.password == false
        ? await controller.resendOtp(widget.email)
        : await forgetPasswordController.forgetPassword(widget.email);
    if (success) {
      controller.otpController.clear();
      _startResendTimer();
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    Get.delete<EmailVerificationController>(tag: widget.email);
    Get.delete<ForgetPasswordController>(tag: widget.email);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, __) {
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
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            _topSection(context, isDark),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                              child: _contentSection(context, isDark),
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
      },
    );
  }

  // ── Top section ───────────────────────────────────────────────────────────────

  Widget _topSection(BuildContext context, bool isDark) {
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
            child: CustomBackButton(
              isDark: isDark,
              iconColor: backIconColor,
              onTap: () => Get.back(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Content section ───────────────────────────────────────────────────────────

  Widget _contentSection(BuildContext context, bool isDark) {
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.black54;

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
            color: subtitleColor,
          ),
        ),
        SizedBox(height: 30.h),
        _otpField(isDark),
        SizedBox(height: 30.h),
        _verifyButton(isDark),
      ],
    );
  }

  // ── OTP field ─────────────────────────────────────────────────────────────────

  Widget _otpField(bool isDark) {
    final inputTextColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.grey.shade500 : Colors.grey;
    final underlineColor = isDark ? const Color(0xFF3A3A3A) : Colors.black26;

    return TextField(
      controller: widget.password == false
          ? controller.otpController
          : forgetPasswordController.otpController,
      keyboardType: TextInputType.number,
      maxLength: 6,
      cursorColor: AppColors.primary,
      style: GoogleFonts.inter(
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 2,
        color: inputTextColor,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: 'Code',
        hintStyle: GoogleFonts.inter(
          fontSize: 15.sp,
          color: hintColor,
        ),
        filled: true,
        fillColor: Colors.transparent,
        suffixIcon: InkWell(
          onTap: _secondsLeft > 0 ? null : _onGetCode,
          child: Padding(
            padding: EdgeInsets.only(top: 14.h),
            child: Text(
              _secondsLeft > 0 ? _timerLabel : 'GET CODE',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: _secondsLeft > 0
                    ? (isDark ? Colors.grey.shade500 : Colors.grey)
                    : const Color(0xFFD9C27C),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: underlineColor),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: underlineColor),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: underlineColor),
        ),
      ),
    );
  }

  // ── Verify button ─────────────────────────────────────────────────────────────

  Widget _verifyButton(bool isDark) {
    final disabledBg = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300;

    return Obx(() {
      final isDisabled = !_isOtpValid || controller.isLoading.value;
      return SizedBox(
        width: double.infinity,
        height: 48.h,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _isOtpValid ? AppColors.primary : disabledBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 0,
          ),
          onPressed: isDisabled
              ? null
              : () async {
                  if (widget.password == true) {
                    bool success = await forgetPasswordController
                        .forgotPasswordVerifyOtp(widget.email);
                    if (success && mounted) {
                      Get.to(() => CreateNewPasswordView(email: widget.email));
                    }
                  } else {
                    bool success = await controller.verifyOtp(widget.email);
                    if (success && mounted) {
                      _showSuccessBottomSheet(isDark);
                    }
                  }
                },
          child: controller.isLoading.value
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  'Verify Now',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
        ),
      );
    });
  }

  // ── Success bottom sheet ──────────────────────────────────────────────────────

  void _showSuccessBottomSheet(bool isDark) {
    final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.grey.shade400 : Colors.black54;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          height: 220.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(
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
                  color: textColor,
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

  // ── Bottom image ──────────────────────────────────────────────────────────────

  Widget _bottomCityImage() {
    return Image.asset(
      'assets/images/city.png',
      width: double.infinity,
      fit: BoxFit.fitWidth,
    );
  }
}
