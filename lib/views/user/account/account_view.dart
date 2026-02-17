import 'package:brokkerspot/views/brokker/brokker_login/view/brokker_login_view.dart';
import 'package:brokkerspot/views/user/deals/my_project_deals_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountView extends StatelessWidget {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
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
            title: 'My Account',
            onTap: () {},
          ),
          _divider(),
          _accountTile(
            icon: Icons.handshake_outlined,
            title: 'My Project Deals',
            onTap: () {
              Get.to(() => const MyProjectDealsView());
            },
          ),
          _divider(),
          _accountTile(
            icon: Icons.campaign_outlined,
            title: 'My Announcements',
            onTap: () {},
          ),
          _divider(),
          _accountTile(
            icon: Icons.swap_horiz,
            title: 'Switch to Broker side',
            onTap: () {
              Get.to(() => BrokerOnboardingView());
              // Get.offAll(() => BrokerDashBoardView());
            },
          ),
          _divider(),
          _accountTile(
            icon: Icons.favorite_border,
            title: 'My Wishlist',
            onTap: () {},
          ),
          _divider(),
          _accountTile(
            icon: Icons.settings_outlined,
            title: 'Setting',
            onTap: () {},
          ),
          _divider(),
        ],
      ),
    );
  }

  // ---------------- TILE ----------------
  Widget _accountTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
        child: Row(
          children: [
            Icon(
              icon,
              size: 28,
              color: const Color(0xFFD9C27C), // gold
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.black45,
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
