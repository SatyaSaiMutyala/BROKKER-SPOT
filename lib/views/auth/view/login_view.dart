import 'package:brokkerspot/views/auth/view/foreget_password_view.dart';
import 'package:brokkerspot/views/auth/view/help/need_help_view.dart';
import 'package:brokkerspot/views/auth/view/signup_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../controller/login_controller.dart';
import '../../../widgets/common/custom_text_field.dart';

class LoginView extends StatelessWidget {
  LoginView({super.key});

  final LoginController controller = Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(AppAssets.background, fit: BoxFit.cover),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x30000000),
                  Color(0xE4000000),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 28.w),
              child: Column(
                children: [
                  SizedBox(height: 100.h),

                  Image.asset(AppAssets.appName, width: 170.w),

                  SizedBox(height: 140.h),

                  /// EMAIL
                  CustomTextField(
                    controller: controller.emailController,
                    hintText: AppStrings.email,
                    suffixIcon: Icons.person_outline,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => controller.validateForm(),
                  ),

                  SizedBox(height: 24.h),

                  /// PASSWORD
                  Obx(() => CustomTextField(
                        controller: controller.passwordController,
                        hintText: AppStrings.password,
                        suffixIcon: controller.obscurePassword.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        obscureText: controller.obscurePassword.value,
                        onSuffixTap: controller.togglePasswordVisibility,
                        onChanged: (_) => controller.validateForm(),
                      )),

                  SizedBox(height: 16.h),

                  _buildRememberForgotRow(),

                  SizedBox(height: 28.h),

                  _buildLoginButton(),

                  SizedBox(height: 28.h),

                  _buildOrDivider(),

                  SizedBox(height: 28.h),

                  _buildBottomLinks(),

                  const Spacer(),

                  Align(alignment: Alignment.topLeft, child: _buildNeedHelp()),

                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Remember + Forgot
  Widget _buildRememberForgotRow() {
    return Obx(() => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 40.w,
                  height: 22.h,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Switch(
                      value: controller.rememberMe.value,
                      onChanged: controller.toggleRememberMe,
                      activeColor: AppColors.textWhite,
                      activeTrackColor: AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  AppStrings.rememberMe,
                  style: GoogleFonts.roboto(
                    color: AppColors.textWhite,
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => Get.to(() => const ForgetPasswordView()),
              child: Text(
                AppStrings.forgotPassword,
                style: GoogleFonts.roboto(
                  color: AppColors.textWhite,
                  fontSize: 13.sp,
                ),
              ),
            ),
          ],
        ));
  }

  /// LOGIN BUTTON
  Widget _buildLoginButton() {
    return Obx(() {
      final valid = controller.isFormValid.value;
      return SizedBox(
        width: double.infinity,
        height: 52.h,
        child: ElevatedButton(
          onPressed: controller.isLoading.value
              ? null
              : valid
                  ? controller.login
                  : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: valid ? AppColors.primary : Colors.grey.shade400,
            disabledBackgroundColor: Colors.grey.shade400,
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
                  AppStrings.login,
                  style: GoogleFonts.roboto(
                    fontSize: 15.sp,
                    color: valid ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      );
    });
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(height: 0.5.h, color: Colors.white54),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            AppStrings.or,
            style: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 13.sp,
            ),
          ),
        ),
        Expanded(
          child: Container(height: 0.5.h, color: Colors.white54),
        ),
      ],
    );
  }

  Widget _buildBottomLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Get.to(() => SignUpView()),
          child: Text(
            AppStrings.createNewAccount,
            style: GoogleFonts.roboto(
              color: AppColors.textWhite,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: Text(
            AppStrings.continueAsGuest,
            style: GoogleFonts.roboto(
              color: AppColors.textWhite,
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNeedHelp() {
    return GestureDetector(
      onTap: () => Get.to(() => const NeedHelpView()),
      child: Text(
        AppStrings.needHelp,
        style: GoogleFonts.roboto(
          color: AppColors.textWhite,
          fontSize: 13.sp,
        ),
      ),
    );
  }
}
