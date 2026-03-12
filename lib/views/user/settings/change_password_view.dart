import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/user/settings/change_password_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ChangePasswordView extends StatelessWidget {
  ChangePasswordView({super.key});

  final ChangePasswordController controller =
      Get.put(ChangePasswordController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _topSection(context),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 28.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "Change ",
                                  style: GoogleFonts.roboto(
                                    fontSize: 26.sp,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.primary,
                                  ),
                                ),
                                TextSpan(
                                  text: "Password",
                                  style: GoogleFonts.roboto(
                                    fontSize: 26.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            'Enter your current password and set a new one',
                            style: GoogleFonts.roboto(
                              fontSize: 13.sp,
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: 40.h),

                          // Old Password field
                          Obx(() => TextField(
                                controller: controller.oldPasswordController,
                                obscureText:
                                    controller.obscureOldPassword.value,
                                onChanged: (_) => controller.validateForm(),
                                style: GoogleFonts.roboto(
                                  fontSize: 15.sp,
                                  color: Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Current Password',
                                  hintStyle: GoogleFonts.roboto(
                                    fontSize: 15.sp,
                                    color: Colors.grey,
                                  ),
                                  suffixIcon: GestureDetector(
                                    onTap: controller.toggleOldPassword,
                                    child: Icon(
                                      controller.obscureOldPassword.value
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.primary,
                                      size: 22.sp,
                                    ),
                                  ),
                                  enabledBorder: const UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Color(0xFFB5B5B5)),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Color(0xFFB5B5B5)),
                                  ),
                                ),
                              )),
                          SizedBox(height: 20.h),

                          // New Password field
                          Obx(() => TextField(
                                controller: controller.newPasswordController,
                                obscureText:
                                    controller.obscureNewPassword.value,
                                onChanged: (val) =>
                                    controller.validatePassword(val),
                                style: GoogleFonts.roboto(
                                  fontSize: 15.sp,
                                  color: Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'New Password',
                                  hintStyle: GoogleFonts.roboto(
                                    fontSize: 15.sp,
                                    color: Colors.grey,
                                  ),
                                  suffixIcon: GestureDetector(
                                    onTap: controller.toggleNewPassword,
                                    child: Icon(
                                      controller.obscureNewPassword.value
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.primary,
                                      size: 22.sp,
                                    ),
                                  ),
                                  enabledBorder: const UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Color(0xFFB5B5B5)),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Color(0xFFB5B5B5)),
                                  ),
                                ),
                              )),
                          SizedBox(height: 12.h),

                          // Password requirements
                          Obx(() => Wrap(
                                spacing: 12.w,
                                runSpacing: 6.h,
                                children: [
                                  _passwordRule('1 Uppercase',
                                      controller.hasUppercase.value),
                                  _passwordRule('1 Lowercase',
                                      controller.hasLowercase.value),
                                  _passwordRule(
                                      '1 Number', controller.hasNumber.value),
                                  _passwordRule('8 characters',
                                      controller.hasMinLength.value),
                                  _passwordRule('1 special character',
                                      controller.hasSpecialChar.value),
                                ],
                              )),
                          SizedBox(height: 20.h),

                          // Confirm Password field
                          Obx(() => TextField(
                                controller:
                                    controller.confirmPasswordController,
                                obscureText:
                                    controller.obscureConfirmPassword.value,
                                onChanged: (_) => controller.validateForm(),
                                style: GoogleFonts.roboto(
                                  fontSize: 15.sp,
                                  color: Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Confirm New Password',
                                  hintStyle: GoogleFonts.roboto(
                                    fontSize: 15.sp,
                                    color: Colors.grey,
                                  ),
                                  suffixIcon: GestureDetector(
                                    onTap: controller.toggleConfirmPassword,
                                    child: Icon(
                                      controller.obscureConfirmPassword.value
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.primary,
                                      size: 22.sp,
                                    ),
                                  ),
                                  enabledBorder: const UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Color(0xFFB5B5B5)),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Color(0xFFB5B5B5)),
                                  ),
                                ),
                              )),
                          SizedBox(height: 40.h),

                          // Change Password button
                          _buildChangeButton(),
                          SizedBox(height: 40.h),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
            top: -100.h,
            right: -10.w,
            child: Image.asset(
              'assets/images/top_curve.png',
              width: 300.w,
              height: 349.h,
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: 5.h,
            left: 20.w,
            child: InkWell(
              onTap: () => Get.back(),
              child: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                ),
                child: const Icon(Icons.arrow_back_ios_new, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- CHANGE PASSWORD BUTTON ----------------
  Widget _buildChangeButton() {
    return Obx(() {
      final valid = controller.isFormValid.value;
      return Container(
        width: double.infinity,
        height: 52.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.r),
          boxShadow: [
            BoxShadow(
              color: (valid ? AppColors.primary : Colors.grey.shade300)
                  .withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: controller.isLoading.value
              ? null
              : valid
                  ? controller.changePassword
                  : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: valid ? AppColors.primary : Colors.grey.shade300,
            disabledBackgroundColor: Colors.grey.shade300,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.r),
            ),
          ),
          child: controller.isLoading.value
              ? SizedBox(
                  width: 22.w,
                  height: 22.h,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Change Password',
                  style: GoogleFonts.roboto(
                    fontSize: 15.sp,
                    color: valid ? Colors.white : Colors.black45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      );
    });
  }

  Widget _passwordRule(String text, bool active) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle,
          size: 14.sp,
          color: active ? Colors.green : Colors.grey.shade400,
        ),
        SizedBox(width: 4.w),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 10.sp,
            color: active ? Colors.black87 : Colors.grey.shade500,
            fontWeight: active ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
