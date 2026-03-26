import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:brokkerspot/views/user/dashboard/dashboard_view.dart';
import 'package:brokkerspot/views/user/settings/settings_view.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

class AccountMenuView extends StatelessWidget {
  const AccountMenuView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: SafeArea(
        child: Column(
          children: [
            CustomHeader(
              title: 'My Account',
              showBackButton: LocalStorageService.isLoggedIn(),
              onBack: () => Get.back(),
            ),
            Expanded(
              child: Obx(() {
        final bool isLoggedIn = LocalStorageService.isLoggedIn();
        final profileCtrl = Get.put(ProfileController());
        final isPending = isLoggedIn &&
            profileCtrl.role.value == 2 &&
            profileCtrl.profileData.value?['verificationStatus'] == 'pending';
        final bool canAccess = isLoggedIn && !isPending;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
          child: Column(
            children: [
              // First card group
              _buildCardGroup([
                _menuItem('assets/images/broker_my_profile_icon.png', 'My Information', () {}, enabled: canAccess),
                _menuItem('assets/images/broker_mydeal_icon.png', 'My Deals', () {}, enabled: canAccess),
                _menuItem('assets/images/broker_bank_icon.png', 'My Bank Account Details', () {}, enabled: canAccess),
                _menuItem('assets/images/broker_announcement.png', 'Announcement', () {}, enabled: canAccess),
                _menuItem('assets/images/broker_wishlist_icon.png', 'My Wishlist', () {}, showDivider: false, enabled: canAccess),
              ]),
              SizedBox(height: 16.h),
              // Second card group
              _buildCardGroup([
                _menuItem('assets/images/switch_to_user_icon.png', 'Switch to User side', () {
                  LocalStorageService.saveLastSide('user');
                  Get.offAll(() => const DashboardView());
                }),
                _menuItem('assets/images/subscription_icon.png', 'My Subscription', () {}, enabled: canAccess),
                _menuItem('assets/images/broker_settings_icon.png', 'Setting', () => Get.to(() => SettingsView(side: 'broker')), showDivider: false, enabled: isLoggedIn),
              ]),
            ],
          ),
        );
      }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _menuItem(
    String assetPath,
    String title,
    VoidCallback onTap, {
    bool showDivider = true,
    bool enabled = true,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16.r),
          child: Opacity(
            opacity: enabled ? 1.0 : 0.4,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              child: Row(
                children: [
                  Image.asset(assetPath, width: 20.w, height: 20.w),
                  SizedBox(width: 20.w),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 22.sp, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200),
          ),
      ],
    );
  }
}
