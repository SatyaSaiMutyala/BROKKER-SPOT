import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/views/auth/view/login_view.dart';
import 'package:brokkerspot/views/auth/view/signup_view.dart';
import 'package:brokkerspot/views/brokker/brokker_login/view/brokker_login_view.dart';
import 'package:brokkerspot/views/brokker/brokker_login/view/complete_profile_screen.dart';
import 'package:brokkerspot/views/brokker/brokker_login/view/create_brokker_account_view.dart';
import 'package:brokkerspot/views/user/account/controller/account_controller.dart';
import 'package:brokkerspot/views/user/deals/my_project_deals_view.dart';
import 'package:brokkerspot/views/user/settings/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:brokkerspot/views/brokker/dashboard/brokker_dashboard.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';

class AccountView extends StatelessWidget {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(AccountController());
    final bool isGuest = !LocalStorageService.isLoggedIn();
    final user = LocalStorageService.getUser()?.data;
    final int role = user?.role ?? 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              const CustomHeader(title: 'My Account'),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                  child: Column(
                    children: [
                      // First card
                      _buildCard(
                        children: [
                          _accountTile(
                            iconAsset: 'broker_my_profile_icon.png',
                            title: 'My Information',
                            enabled: !isGuest,
                            onTap: () {},
                          ),
                          _accountTile(
                            iconAsset: 'broker_mydeal_icon.png',
                            title: 'My Deals',
                            enabled: !isGuest,
                            onTap: () {
                              Get.to(() => const MyProjectDealsView());
                            },
                          ),
                          _accountTile(
                            iconAsset: 'broker_announcement.png',
                            title: 'Announcement',
                            enabled: !isGuest,
                            onTap: () {},
                          ),
                          _accountTile(
                            iconAsset: 'broker_wishlist_icon.png',
                            title: 'My Wishlist',
                            enabled: !isGuest,
                            onTap: () {},
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      // Second card
                      _buildCard(
                        children: [
                          Obx(() {
                            final profileCtrl = Get.find<ProfileController>();
                            final isBroker = profileCtrl.role.value == 2;
                            return _accountTile(
                              iconAsset: 'switch_to_user_icon.png',
                              title: isBroker
                                  ? 'Switch to Broker Side'
                                  : role == 2
                                      ? 'Switch to Broker'
                                      : 'Become Broker',
                              enabled: true,
                              onTap: () {
                                if (isBroker) {
                                  LocalStorageService.saveLastSide('broker');
                                  Get.offAll(() => BrokerDashBoardView());
                                } else {
                                  Get.to(() => BrokerOnboardingView());
                                }
                              },
                            );
                          }),
                          _accountTile(
                            iconAsset: 'broker_settings_icon.png',
                            title: 'Setting',
                            enabled: !isGuest,
                            onTap: () => Get.to(() => SettingsView()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- CARD ----------------
  Widget _buildCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(children: children),
    );
  }

  // ---------------- TILE ----------------
  Widget _accountTile({
    required String iconAsset,
    required String title,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
        child: Row(
          children: [
            Opacity(
              opacity: enabled ? 1.0 : 0.4,
              child: Image.asset(
                'assets/images/$iconAsset',
                width: 20.w,
                height: 20.w,
              ),
            ),
            SizedBox(width: 20.w),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: enabled ? Colors.black87 : Colors.grey.shade400,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 22,
              color: enabled ? Colors.grey.shade500 : Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- DIVIDER ----------------
  Widget _tileDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: Colors.grey.shade200,
      ),
    );
  }
}

// ---------------- LOGIN REQUIRED DIALOG ----------------
void showLoginRequiredDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please Login.',
              style: GoogleFonts.poppins(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Without login you cannot use all features in this app.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 46.h,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
                onPressed: () {
                  Get.back();
                  Get.to(() => LoginView());
                },
                child: Text(
                  'Login',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              height: 46.h,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
                onPressed: () {
                  Get.back();
                  Get.to(() => const SignUpView(isBrokerSignup: true));
                },
                child: Text(
                  'Signup',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void showAccountRejectedDialog(BuildContext context, String reason) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel_rounded, size: 48.sp, color: Colors.red),
            SizedBox(height: 16.h),
            Text(
              'Account Rejected',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              reason,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 46.h,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
                onPressed: () {
                  Get.back();
                  Get.to(() => CompleteProfileScreen());
                },
                child: Text(
                  'Complete Profile',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              height: 46.h,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
                onPressed: () => Get.back(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void showPendingVerificationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_top_rounded, size: 48.sp, color: Colors.amber),
            SizedBox(height: 16.h),
            Text(
              'Please wait for activate and verify',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 46.h,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
                onPressed: () => Get.back(),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void showCompleteProfileDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Complete Profile',
              style: GoogleFonts.poppins(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Please complete your profile to continue.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 46.h,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
                onPressed: () {
                  Get.back();
                  Get.to(() => CompleteProfileScreen());
                },
                child: Text(
                  'Continue',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              height: 46.h,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
                onPressed: () {
                  Get.back();
                },
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
