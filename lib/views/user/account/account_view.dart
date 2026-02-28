import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/views/auth/view/login_view.dart';
import 'package:brokkerspot/views/auth/view/signup_view.dart';
import 'package:brokkerspot/views/brokker/brokker_login/view/brokker_login_view.dart';
import 'package:brokkerspot/views/brokker/brokker_login/view/create_brokker_account_view.dart';
import 'package:brokkerspot/views/user/account/controller/account_controller.dart';
import 'package:brokkerspot/views/user/deals/my_project_deals_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';

class AccountView extends StatelessWidget {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    AccountController controller = Get.put(AccountController());
    final bool isGuest = !LocalStorageService.isLoggedIn();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'Account',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          _accountTile(
            icon: Icons.person_outline,
            title: 'MyAccount',
            enabled: !isGuest,
            onTap: () {},
          ),
          _divider(),
          _accountTile(
            icon: Icons.handshake_outlined,
            title: 'My Project Deals',
            enabled: !isGuest,
            onTap: () {
              Get.to(() => const MyProjectDealsView());
            },
          ),
          _divider(),
          _accountTile(
            icon: Icons.campaign_outlined,
            title: isGuest ? 'MY ANNOUNCEMENTS' : 'My Announcements',
            enabled: !isGuest,
            onTap: () {},
          ),
          _divider(),
          _accountTile(
            icon: isGuest ? Icons.business_center_outlined : Icons.swap_horiz,
            title: isGuest ? 'Become Broker' : 'Switch to Broker side',
            enabled: true,
            onTap: () {
                Get.to(() => BrokerOnboardingView());
            },
          ),
          _divider(),
          _accountTile(
            icon: Icons.favorite_border,
            title: 'My Wishlist',
            enabled: !isGuest,
            onTap: () {},
          ),
          _divider(),
          _accountTile(
            icon: Icons.settings_outlined,
            title: 'Setting',
            enabled: !isGuest,
            onTap: () {},
          ),
          _divider(),
          if (!isGuest) ...[
            _accountTile(
              icon: Icons.logout_outlined,
              title: 'Logout',
              enabled: true,
              onTap: () {
                controller.logout();
              },
            ),
            _divider(),
          ],
        ],
      ),
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
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
        child: Row(
          children: [
            Icon(
              icon,
              size: 28,
              color: enabled
                  ? const Color(0xFFD9C27C)
                  : const Color(0xFFD9C27C).withValues(alpha: 0.4),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: enabled ? FontWeight.w500 : FontWeight.w400,
                  color: enabled ? Colors.black : Colors.grey.shade400,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: enabled ? Colors.black45 : Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- DIVIDER ----------------
  Widget _divider() {
    return Divider(
      height: 1,
      thickness: 0.6,
      color: Colors.grey.shade300,
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
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Without login you cannot use all features in this app.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 24.h),
            // Login button
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
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            // Signup button
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
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
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
