import 'package:brokkerspot/views/auth/foreget_password_view.dart';
import 'package:brokkerspot/views/auth/signup_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../controllers/auth/login_controller.dart';
import '../../widgets/common/custom_text_field.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late LoginController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LoginController();
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            AppAssets.background,
            fit: BoxFit.cover,
          ),

          // Linear Gradient Overlay
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x30000000), // #00000033
                  Color(0xE4000000), // #000000E5
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 28.w),
              child: Column(
                children: [
                  SizedBox(height: 40.h),
                  // Logo
                  Image.asset(
                    AppAssets.appName,
                    width: 170.w,
                  ),
                  SizedBox(height: 160.h),
                  // Email Field
                  CustomTextField(
                    controller: _controller.emailController,
                    hintText: AppStrings.email,
                    suffixIcon: Icons.person_outline,
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => _controller.onFieldChanged(),
                  ),
                  SizedBox(height: 24.h),
                  // Password Field
                  CustomTextField(
                    controller: _controller.passwordController,
                    hintText: AppStrings.password,
                    suffixIcon: _controller.obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    obscureText: _controller.obscurePassword,
                    onSuffixTap: _controller.togglePasswordVisibility,
                    onChanged: (_) => _controller.onFieldChanged(),
                  ),
                  SizedBox(height: 16.h),
                  // Remember Me & Forgot Password
                  _buildRememberForgotRow(),
                  SizedBox(height: 28.h),
                  // Login Button
                  _buildLoginButton(),
                  SizedBox(height: 28.h),
                  // OR Divider
                  _buildOrDivider(),
                  SizedBox(height: 28.h),
                  // Create Account & Continue as Guest
                  _buildBottomLinks(),
                  const Spacer(),
                  // Need Help
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

  Widget _buildRememberForgotRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Remember Me
        Row(
          children: [
            SizedBox(
              width: 40.w,
              height: 22.h,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Switch(
                  value: _controller.rememberMe,
                  onChanged: _controller.toggleRememberMe,
                  activeColor: AppColors.textWhite,
                  activeTrackColor: AppColors.primary,
                  inactiveThumbColor: Colors.white70,
                  inactiveTrackColor: Colors.grey.shade600,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
        // Forgot Password
        GestureDetector(
          onTap: () {
            // Handle forgot password
            Get.to(() => const ForgetPasswordView());
          },
          child: Text(
            AppStrings.forgotPassword,
            style: GoogleFonts.roboto(
              color: AppColors.textWhite,
              fontSize: 13.sp,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton(
        onPressed:
            _controller.isLoading ? _controller.login : _controller.login,
        style: ElevatedButton.styleFrom(
          backgroundColor: _controller.hasInput
              ? AppColors.primary
              : Colors.white.withOpacity(0.6),
          foregroundColor: _controller.hasInput
              ? AppColors.backgroundDark
              : AppColors.textWhite,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.r),
            side: BorderSide(
              color: _controller.hasInput
                  ? AppColors.primary
                  : Colors.white.withValues(alpha: 0.5),
              width: 1.2,
            ),
          ),
        ),
        child: _controller.isLoading
            ? SizedBox(
                width: 22.w,
                height: 22.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2.w,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                ),
              )
            : Text(
                AppStrings.login,
                style: GoogleFonts.roboto(
                  fontSize: 15.sp,
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 0.5.h,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            AppStrings.or,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 13.sp,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 0.5.h,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            // Handle create account

            Navigator.push(
                context, MaterialPageRoute(builder: (context) => SignUpView()));
          },
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
          onTap: () {
            // Handle continue as guest
          },
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
      onTap: () {
        // Handle need help
      },
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
