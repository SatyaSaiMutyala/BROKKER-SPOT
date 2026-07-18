import 'package:brokkerspot/views/auth/controller/create_new_password_controller.dart';
import 'package:brokkerspot/widgets/common/custom_back_button.dart';
import 'package:brokkerspot/widgets/common/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';

class CreateNewPasswordView extends StatelessWidget {
  final String email;

  const CreateNewPasswordView({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CreateNewPasswordController(email));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final FocusNode passwordFocus = FocusNode();
    final FocusNode confirmFocus = FocusNode();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom + 24.h,
                ),
                child: Column(
                  children: [
                    _topSection(
                        context, isDark, MediaQuery.paddingOf(context).top),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Obx(() => _contentSection(
                            context,
                            isDark,
                            controller,
                            passwordFocus,
                            confirmFocus,
                          )),
                    ),
                  ],
                ),
              ),
            ),
            _bottomCityImage(),
          ],
        ),
      ),
    );
  }

  Widget _topSection(BuildContext context, bool isDark, double topPadding) {
    final backIconColor = isDark ? Colors.white : Colors.black87;

    return SizedBox(
      height: 220.h,
      child: Stack(
        children: [
          Positioned(
            top: -30.h,
            right: -20.w,
            child: Image.asset(
              'assets/images/top_curve.png',
              width: 300.w,
              height: 349.h,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: topPadding + 10.h,
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

  Widget _contentSection(
    BuildContext context,
    bool isDark,
    CreateNewPasswordController controller,
    FocusNode passwordFocus,
    FocusNode confirmFocus,
  ) {
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.black54;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create New Password',
          style: GoogleFonts.inter(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 10.h),
        Text(
          'We\'ll ask for this password whenever you sign in.',
          style: GoogleFonts.inter(fontSize: 12.sp, color: subtitleColor),
        ),
        SizedBox(height: 30.h),
        CustomTextField(
          controller: controller.passwordController,
          hintText: 'Enter New Password',
          obscureText: true,
          isDark: isDark,
          suffixIcon: Icons.visibility_off_outlined,
        ),
        SizedBox(height: 16.h),
        CustomTextField(
          controller: controller.confirmPasswordController,
          hintText: 'Re-Enter New Password',
          obscureText: true,
          isDark: isDark,
          suffixIcon: Icons.visibility_off_outlined,
        ),
        SizedBox(height: 20.h),
        Wrap(
          spacing: 12.w,
          runSpacing: 8.h,
          children: [
            _Rule('1 Uppercase', controller.hasUppercase.value, isDark),
            _Rule('1 Lowercase', controller.hasLowercase.value, isDark),
            _Rule('1 Number', controller.hasNumber.value, isDark),
            _Rule('8 characters', controller.hasMinLength.value, isDark),
            _Rule(
                '1 special character', controller.hasSpecialChar.value, isDark),
            _Rule('Passwords match', controller.passwordsMatch.value, isDark),
          ],
        ),
        SizedBox(height: 30.h),
        SizedBox(
          width: double.infinity,
          height: 46.h,
          child: ElevatedButton(
            onPressed:
                (!controller.isPasswordValid || controller.isLoading.value)
                    ? null
                    : controller.resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: controller.isPasswordValid
                  ? const Color(0xFFD9C27C)
                  : (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: controller.isLoading.value
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    'Verify Now',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: controller.isPasswordValid
                          ? Colors.white
                          : (isDark ? Colors.white38 : Colors.black54),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _bottomCityImage() {
    return Image.asset(
      'assets/images/city.png',
      width: double.infinity,
      fit: BoxFit.fitWidth,
    );
  }
}

class _Rule extends StatelessWidget {
  final String text;
  final bool valid;
  final bool isDark;

  const _Rule(this.text, this.valid, this.isDark);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          valid ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 14,
          color: valid ? AppColors.primary : Colors.grey,
        ),
        SizedBox(width: 6.w),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: valid
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? Colors.white54 : Colors.black54),
          ),
        ),
      ],
    );
  }
}
