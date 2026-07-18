import 'package:brokkerspot/views/auth/view/foreget_password_view.dart';
import 'package:brokkerspot/views/auth/view/signup_view.dart';
import 'package:brokkerspot/views/auth/controller/welcome_view_controller.dart';
import 'package:brokkerspot/widgets/common/custom_text_field.dart';
import 'package:brokkerspot/widgets/common/top_curve_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../controller/login_controller.dart';

class LoginView extends StatelessWidget {
  LoginView({super.key});

  final LoginController controller =
      Get.put(LoginController(), permanent: true);
  final WelcomeViewController socialController =
      Get.put(WelcomeViewController());

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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
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
                                  text: "Let's ",
                                  style: GoogleFonts.roboto(
                                    fontSize: 26.sp,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.primary,
                                  ),
                                ),
                                TextSpan(
                                  text: "Sign In",
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

                          // Subtitle
                          Text(
                            'quis nostrud exercitation ullamco laboris nisi ut',
                            style: GoogleFonts.roboto(
                              fontSize: 13.sp,
                              color:
                                  isDark ? Colors.grey.shade400 : Colors.grey,
                              fontWeight: FontWeight.w400,
                            ),
                          ),

                          SizedBox(height: 40.h),

                          // Email field
                          CustomTextField(
                            controller: controller.emailController,
                            hintText: 'Email',
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (_) => controller.validateForm(),
                            isDark: isDark,
                            suffixWidget: Image.asset(
                              'assets/images/email_profile_icon.png',
                              color: AppColors.primary,
                              width: 22.sp,
                              height: 22.sp,
                            ),
                          ),

                          SizedBox(height: 20.h),

                          // Password field
                          Obx(() => CustomTextField(
                                controller: controller.passwordController,
                                hintText: 'Password',
                                obscureText: controller.obscurePassword.value,
                                onChanged: (_) => controller.validateForm(),
                                isDark: isDark,
                                suffixIcon: controller.obscurePassword.value
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                onSuffixTap:
                                    controller.togglePasswordVisibility,
                              )),

                          SizedBox(height: 14.h),

                          _buildRememberForgotRow(isDark),

                          SizedBox(height: 28.h),

                          _buildLoginButton(isDark),

                          SizedBox(height: 28.h),

                          _buildOrDivider(isDark),

                          SizedBox(height: 28.h),

                          _buildSocialButtons(isDark),

                          SizedBox(height: 30.h),

                          _buildSignUpLink(),

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

  Widget _topSection(BuildContext context) {
    return TopCurveSection(
        onBack: () => Navigator.pop(context), curveTop: -110);
  }

  // ── Remember me + Forgot password ────────────────────────────────────────────

  Widget _buildRememberForgotRow(bool isDark) {
    final labelColor = isDark ? Colors.grey.shade400 : Colors.black54;

    return Obx(() => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 40.w,
                  height: 28.h,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Switch(
                      value: controller.rememberMe.value,
                      onChanged: controller.toggleRememberMe,
                      activeThumbColor: Colors.white,
                      activeTrackColor: AppColors.primary,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey.shade300,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Remember me',
                  style: GoogleFonts.roboto(
                    color: labelColor,
                    fontSize: 15.sp,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => Get.to(() => const ForgetPasswordView()),
              child: Text(
                'Forgot password?',
                style: GoogleFonts.roboto(
                  color: labelColor,
                  fontSize: 15.sp,
                ),
              ),
            ),
          ],
        ));
  }

  // ── Login button ──────────────────────────────────────────────────────────────

  Widget _buildLoginButton(bool isDark) {
    return Obx(() {
      final valid = controller.isFormValid.value;
      final disabledBg =
          isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade300;
      final disabledText = isDark ? Colors.white38 : Colors.black45;

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
                  ? controller.login
                  : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: valid ? AppColors.primary : disabledBg,
            disabledBackgroundColor: disabledBg,
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
                  'Login',
                  style: GoogleFonts.roboto(
                    fontSize: 15.sp,
                    color: valid ? Colors.white : disabledText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      );
    });
  }

  // ── Or divider ────────────────────────────────────────────────────────────────

  Widget _buildOrDivider(bool isDark) {
    final lineColor =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFB5B5B5);
    final textColor = isDark ? Colors.grey.shade400 : Colors.grey;

    return Row(
      children: [
        Expanded(child: Container(height: 0.5, color: lineColor)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'Or Sign With',
            style: GoogleFonts.roboto(color: textColor, fontSize: 13.sp),
          ),
        ),
        Expanded(child: Container(height: 0.5, color: lineColor)),
      ],
    );
  }

  // ── Social buttons ────────────────────────────────────────────────────────────

  Widget _buildSocialButtons(bool isDark) {
    final circleBg = isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: socialController.signInWithGoogle,
          child: Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(shape: BoxShape.circle, color: circleBg),
            child: Center(
              child: Image.asset(
                'assets/images/google_icon.png',
                width: 56.w,
                height: 56.w,
              ),
            ),
          ),
        ),
        SizedBox(width: 20.w),
        GestureDetector(
          onTap: socialController.signInWithApple,
          child: Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(shape: BoxShape.circle, color: circleBg),
            child: Center(
              child: Image.asset(
                'assets/images/apple_icon.png',
                width: 56.w,
                height: 56.w,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Sign up link ──────────────────────────────────────────────────────────────

  Widget _buildSignUpLink() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Don't have an account?  ",
            style: GoogleFonts.roboto(color: Colors.grey, fontSize: 15.sp),
          ),
          GestureDetector(
            onTap: () => Get.to(() => SignUpView()),
            child: Text(
              'Sign Up',
              style: GoogleFonts.roboto(
                color: AppColors.primary,
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
