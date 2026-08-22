import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/core/services/session_cleanup.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:brokkerspot/views/brokker/brokker_account/broker_my_information_view.dart';
import 'package:brokkerspot/views/user/dashboard/dashboard_view.dart';
import 'package:brokkerspot/views/user/settings/settings_view.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

class AccountMenuView extends StatelessWidget {
  AccountMenuView({super.key});

  final ProfileController profileCtrl = Get.put(ProfileController());

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
                final bool isLoggedIn = profileCtrl.profileData.value != null;

                final vs = profileCtrl.profileData.value?['verificationStatus'];
                final isPending = isLoggedIn &&
                    profileCtrl.hasBrokerRole &&
                    (vs == 'inactive' || vs == 'pending' || vs == 'rejected');

                final bool canAccess = isLoggedIn && !isPending;
                final isDark =
                    Theme.of(context).brightness == Brightness.dark;
                return SingleChildScrollView(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                  child: Column(
                    children: [
                      // First card group
                      _buildCardGroup(isDark: isDark, [
                        _menuItem(
                            'assets/images/broker_my_profile_icon.png',
                            'My Information',
                            () => Get.to(() => const BrokerMyInformationView()),
                            enabled: canAccess, isDark: isDark),
                        _menuItem('assets/images/broker_mydeal_icon.png',
                            'My Deals', () {},
                            enabled: canAccess, isDark: isDark),
                        _menuItem('assets/images/broker_bank_icon.png',
                            'My Bank Account Details', () {},
                            enabled: canAccess, isDark: isDark),
                        _menuItem('assets/images/broker_announcement.png',
                            'Announcement', () {},
                            enabled: canAccess, isDark: isDark),
                        _menuItem('assets/images/broker_wishlist_icon.png',
                            'My Wishlist', () {},
                            enabled: canAccess, isDark: isDark),
                      ]),
                      SizedBox(height: 16.h),
                      // Second card group
                      _buildCardGroup(isDark: isDark, [
                        _menuItem('assets/images/switch_to_user_icon.png',
                            'Switch to User side', () async {
                          Get.dialog(
                            const Center(child: CircularProgressIndicator()),
                            barrierDismissible: false,
                          );
                          final ok = await profileCtrl.switchRole(1);
                          if (Get.isDialogOpen ?? false) Get.back();
                          if (ok) {
                            LocalStorageService.saveLastSide('user');
                            // Wipe broker-side cached data so the user side
                            // opens with fresh role-correct responses, not
                            // stale broker-side payloads.
                            await clearRoleScopedCache();
                            Get.offAll(() => const DashboardView());
                          }
                        }, isDark: isDark),
                        _menuItem('assets/images/subscription_icon.png',
                            'My Subscription', () {},
                            enabled: canAccess, isDark: isDark),
                        _menuItem(
                            'assets/images/broker_settings_icon.png',
                            'Setting',
                            () => Get.to(() => SettingsView(side: 'broker')),

                            enabled: isLoggedIn, isDark: isDark),
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

  /// Card shell, matching AccountMenuView's user-side counterpart
  /// (`_buildCard` in views/user/account/account_view.dart) exactly: a bordered
  /// surface rather than a shadowed one, so both profile screens read as the
  /// same component.
  Widget _buildCardGroup(List<Widget> children, {required bool isDark}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF090B11) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2D3C) : const Color(0xFFE8E8E8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  /// Row, matching the user-side `_tile`: title on the left, gold-tinted
  /// icon on the right at 26x26, no chevron and no divider. The icon
  /// assets were already shared between the two screens — only the way
  /// they were drawn differed (left, 20x20 and untinted here).
  Widget _menuItem(
    String assetPath,
    String title,
    VoidCallback onTap, {
    required bool isDark,
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 18.h),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: enabled
                      ? (isDark ? Colors.white : const Color(0xFF1A1A1A))
                      : Colors.grey.shade400,
                  height: 1.0,
                  letterSpacing: 0,
                ),
              ),
            ),
            Opacity(
              opacity: enabled ? 1.0 : 0.4,
              child: Image.asset(
                assetPath,
                width: 26.w,
                height: 26.w,
                // Image.asset defaults to BoxFit.scaleDown, which only ever
                // shrinks. Two of the broker-only assets are tiny at source
                // (broker_bank_icon 14x14, subscription_icon 19x12), so they
                // sat well under the 26 box while every other icon filled it —
                // which is what made this screen's icons look uneven against
                // the user side. contain scales them up to match.
                fit: BoxFit.contain,
                color: AppColors.primary,
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
