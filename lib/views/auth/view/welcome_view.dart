import 'package:brokkerspot/views/auth/controller/welcome_view_controller.dart';
import 'package:brokkerspot/views/auth/view/help/need_help_view.dart';
import 'package:brokkerspot/views/auth/view/login_view.dart';
import 'package:brokkerspot/views/user/dashboard/dashboard_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';

class WelcomeView extends StatelessWidget {
  WelcomeView({super.key});

  final WelcomeViewController controller = Get.put(WelcomeViewController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            Image.asset(AppAssets.background, fit: BoxFit.cover),

            // Gradient Overlay - darker at bottom for contrast
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.3, 0.55, 0.75, 1.0],
                  colors: [
                    Color(0x10000000),
                    Color(0x40000000),
                    Color(0x90000000),
                    Color(0xCC000000),
                    Color(0xF0000000),
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
                    SizedBox(height: 100.h),

                    // App Logo
                    Image.asset(AppAssets.appName, width: 170.w),

                    const Spacer(flex: 3),

                    // Login or Create Account
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Login or Create Account',
                        style: TextStyle(
                          fontFamily: 'Lato',
                          fontSize: 16.sp,
                          color: AppColors.textWhite,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),

                    SizedBox(height: 18.h),

                    // Google Button
                    _buildSocialButton(
                      icon: 'assets/images/google_splash_icon.png',
                      label: 'Continue with Google',
                      onTap: controller.signInWithGoogle,
                    ),

                    SizedBox(height: 14.h),

                    // Apple Button
                    _buildSocialButton(
                      icon: 'assets/images/apple_splash_icon.png',
                      label: 'Continue with Apple',
                      onTap: controller.signInWithApple,
                    ),

                    SizedBox(height: 20.h),

                    // OR Divider
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 0.5,
                            color: Colors.white,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              fontFamily: 'Lato',
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 0.5,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 10.h),

                    // Continue with Email
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Get.to(() => LoginView()),
                        borderRadius: BorderRadius.circular(30.r),
                        splashColor: Colors.white24,
                        highlightColor: Colors.white12,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/email_icon.png',
                                width: 21.sp,
                                height: 21.sp,
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                'Continue with Email',
                                style: TextStyle(
                                  fontFamily: 'Lato',
                                  fontSize: 15.sp,
                                  color: AppColors.textWhite,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Need Help + Guest
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => Get.to(() => const NeedHelpView()),
                          child: Text(
                            'Need Help?',
                            style: TextStyle(
                              fontFamily: 'Lato',
                              fontSize: 15.sp,
                              color: AppColors.textWhite,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Get.offAll(() => DashboardView()),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 22.w, vertical: 9.h),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: AppColors.primary, width: 1.2),
                              borderRadius: BorderRadius.circular(28.r),
                            ),
                            child: Text(
                              'Continue As Guest',
                              style: TextStyle(
                                fontFamily: 'Lato',
                                fontSize: 15.sp,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),

            // Loading Overlay
            if (controller.isLoading.value)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
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
        height: 54.h,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(icon, width: 22.w, height: 26.h),
            SizedBox(width: 12.w),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Lato',
                fontSize: 16.sp,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
