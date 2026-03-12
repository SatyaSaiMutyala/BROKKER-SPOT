import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/views/auth/view/login_view.dart';
import 'package:brokkerspot/views/auth/view/signup_view.dart';
import 'package:brokkerspot/views/brokker/brokker_login/view/brokker_login_view.dart';
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
    final int accountType = user?.accountType ?? 0;

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
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                  child: Column(
                    children: [
                      // First card
                      _buildCard(
                        children: [
                          _accountTile(
                            icon: Icons.person_outline,
                            title: 'My Information',
                            enabled: !isGuest,
                            onTap: () {},
                          ),
                          // _tileDivider(),
                          _accountTile(
                            icon: Icons.handshake_outlined,
                            title: 'My Deals',
                            enabled: !isGuest,
                            onTap: () {
                              Get.to(() => const MyProjectDealsView());
                            },
                          ),
                          // _tileDivider(),
                          _accountTile(
                            icon: Icons.campaign_outlined,
                            title: 'Announcement',
                            enabled: !isGuest,
                            onTap: () {},
                          ),
                          // _tileDivider(),
                          _accountTile(
                            icon: Icons.favorite,
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
                            final isBroker = profileCtrl.accountType.value == 2;
                            return _accountTile(
                              icon: Icons.people_outline,
                              title: isBroker ? 'Switch to Broker Side' : accountType == 2 ? 'Switch to Broker' : 'Become Broker',
                              enabled: true,
                              onTap: () {
                                if (isBroker) {
                                  Get.offAll(() => BrokerDashBoardView());
                                } else {
                                  Get.to(() => BrokerOnboardingView());
                                }
                              },
                            );
                          }),
                          // _tileDivider(),
                          _accountTile(
                            icon: Icons.settings_outlined,
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
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: enabled
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.4),
            ),
            SizedBox(width: 16.w),
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
                fontSize: 12.sp,
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
