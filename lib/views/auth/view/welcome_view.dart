import 'package:brokkerspot/views/auth/view/help/need_help_view.dart';
import 'package:brokkerspot/views/auth/view/login_view.dart';
import 'package:brokkerspot/views/user/dashboard/dashboard_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';

class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(AppAssets.background, fit: BoxFit.cover),

          // Gradient Overlay
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

          // Content
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 28.w),
              child: Column(
                children: [
                  SizedBox(height: 120.h),

                  // App Logo
                  Image.asset(AppAssets.appName, width: 170.w),

                  const Spacer(),

                  // Login or Create Account text
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Login or Create Account',
                      style: GoogleFonts.roboto(
                        fontSize: 14.sp,
                        color: AppColors.textWhite,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Continue with Google
                  _buildSocialButton(
                    icon: 'assets/images/google_icon.png',
                    label: 'Continue with Google',
                    onTap: () {},
                  ),

                  SizedBox(height: 12.h),

                  // Continue with Apple
                  _buildSocialButton(
                    icon: 'assets/images/apple_icon.png',
                    label: 'Continue with Apple',
                    onTap: () {},
                  ),

                  SizedBox(height: 16.h),

                  // OR divider
                  Row(
                    children: [
                      Expanded(
                        child: Container(height: 0.5.h, color: Colors.white54),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          'OR',
                          style: GoogleFonts.roboto(
                            color: Colors.white38,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(height: 0.5.h, color: Colors.white54),
                      ),
                    ],
                  ),

                  SizedBox(height: 16.h),

                  // Continue with Email
                  GestureDetector(
                    onTap: () => Get.to(() => LoginView()),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.mail_outline,
                          color: AppColors.textWhite,
                          size: 20.sp,
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          'Continue with Email',
                          style: GoogleFonts.roboto(
                            fontSize: 14.sp,
                            color: AppColors.textWhite,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Spacer(),

                  // Need Help? + Continue As Guest
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Get.to(() => const NeedHelpView()),
                        child: Text(
                          'Need Help?',
                          style: GoogleFonts.roboto(
                            fontSize: 13.sp,
                            color: AppColors.textWhite,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.offAll(() => DashboardView()),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primary),
                            borderRadius: BorderRadius.circular(24.r),
                          ),
                          child: Text(
                            'Continue As Guest',
                            style: GoogleFonts.roboto(
                              fontSize: 13.sp,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 50.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(icon, width: 22.w, height: 22.h),
            SizedBox(width: 12.w),
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 14.sp,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
