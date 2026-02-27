import 'package:brokkerspot/views/auth/controller/create_new_password_controller.dart';
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

    final FocusNode passwordFocus = FocusNode();
    final FocusNode confirmFocus = FocusNode();

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Stack(
          children: [
            /// MAIN CONTENT
            SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 160.h),
              child: Column(
                children: [
                  _topSection(context),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Obx(() => _contentSection(
                          context,
                          controller,
                          passwordFocus,
                          confirmFocus,
                        )),
                  ),
                ],
              ),
            ),

            /// BOTTOM IMAGE
            Positioned(
              bottom: -10,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/images/city.png',
                height: 120.h,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topSection(BuildContext context) {
    return SizedBox(
      height: 220.h,
      child: Stack(
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

  Widget _contentSection(
    BuildContext context,
    CreateNewPasswordController controller,
    FocusNode passwordFocus,
    FocusNode confirmFocus,
  ) {
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
          style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.black54),
        ),
        SizedBox(height: 30.h),

        /// PASSWORD FIELD
        TextField(
          controller: controller.passwordController,
          focusNode: passwordFocus,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Enter New Password',
          ),
        ),

        SizedBox(height: 16.h),

        /// CONFIRM PASSWORD FIELD
        TextField(
          controller: controller.confirmPasswordController,
          focusNode: confirmFocus,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: 'Re-Enter New Password',
          ),
        ),

        SizedBox(height: 20.h),

        /// PASSWORD RULES
        Wrap(
          spacing: 12.w,
          runSpacing: 8.h,
          children: [
            _Rule('1 Uppercase', controller.hasUppercase.value),
            _Rule('1 Lowercase', controller.hasLowercase.value),
            _Rule('1 Number', controller.hasNumber.value),
            _Rule('8 characters', controller.hasMinLength.value),
            _Rule('1 special character', controller.hasSpecialChar.value),
            _Rule('Passwords match', controller.passwordsMatch.value),
          ],
        ),

        SizedBox(height: 30.h),

        /// VERIFY BUTTON
        SizedBox(
          width: double.infinity,
          height: 46.h,
          child: ElevatedButton(
            onPressed:
                controller.isLoading.value ? null : controller.resetPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: controller.isPasswordValid
                  ? const Color(0xFFD9C27C)
                  : Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: controller.isLoading.value
                ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                : const Text('Verify Now'),
          ),
        ),
      ],
    );
  }
}

/// PASSWORD RULE WIDGET
class _Rule extends StatelessWidget {
  final String text;
  final bool valid;

  const _Rule(this.text, this.valid);

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
            color: valid ? Colors.black : Colors.black54,
          ),
        ),
      ],
    );
  }
}
