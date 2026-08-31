import 'dart:math' as math;

import 'package:brokkerspot/core/common_widget/full_screen_image_view.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/core/services/session_cleanup.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:brokkerspot/views/brokker/brokker_account/broker_my_information_view.dart';
import 'package:brokkerspot/views/brokker/project/broker_projects_view.dart';
import 'package:brokkerspot/views/user/dashboard/dashboard_view.dart';
import 'package:brokkerspot/views/user/settings/settings_view.dart';
import 'package:brokkerspot/views/user/wishlist/wishlist_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// Broker "Account" tab — profile header (avatar + verified ribbon, name,
/// email) followed by a menu list. Every action from the old stats screen
/// and the settings sub-menu lives here now, just restyled into one dark
/// card list instead of two separate screens.
class BrokerProfileView extends StatelessWidget {
  BrokerProfileView({super.key});

  final ProfileController controller = Get.put(ProfileController());

  static const _avatarSize = 100.0;
  // ── Verified badge (assets/images/v-icon.png) ─────────────────────────────
  // A standalone seal, so it just gets pinned to the avatar's rim — the
  // previous artwork was a curved ribbon and needed its arc measured off the
  // image to sit flush.
  static const _badgeSize = 30.0;

  /// Distance from the avatar's centre to the badge's, and the bearing it sits
  /// at. Positive angles are above the horizontal, so this one puts it down and
  /// to the right — just past the rim, overlapping the photo rather than
  /// floating clear of it.
  static const _badgeDistance = 52.0;
  static const _badgeAngle = -0.73; // ~42° below the horizontal

  /// Square and centred on the avatar, wide enough for the badge's far edge —
  /// that way the avatar itself stays put on screen.
  static const _badgeBox = 2 * (_badgeDistance + _badgeSize / 2);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 0),
              child: Text(
                'Account',
                style: GoogleFonts.poppins(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    children: [
                      SizedBox(height: 24.h),
                      _buildProfileHeader(theme),
                      SizedBox(height: 28.h),
                      _buildCardGroup(theme, [
                        _menuItem(
                          theme,
                          'assets/images/broker_my_profile_icon.png',
                          'Manage Profile',
                          () => Get.to(() => const BrokerMyInformationView()),
                        ),
                        _menuItem(
                          theme,
                          'assets/images/broker_announcement.png',
                          'My Announcements',
                          () => Get.to(() =>
                              const BrokerProjectsView(showMineOnly: true)),
                        ),
                        // _menuItem(
                        //   theme,
                        //   'assets/images/broker_mydeal_icon.png',
                        //   'My Deals',
                        //   () {},
                        // ),
                        // _menuItem(
                        //   theme,
                        //   'assets/images/broker_bank_icon.png',
                        //   'My Bank Account Details',
                        //   () {},
                        // ),
                        _menuItem(
                          theme,
                          'assets/images/broker_wishlist_icon.png',
                          'Wishlist',
                          // Same screen the user side uses. The wishlist
                          // endpoint scopes entries by the active role
                          // (user_role in its $match), so opening it here
                          // returns the broker-side saves.
                          () => Get.to(
                              () => const WishlistView(showBackButton: true)),
                        ),
                        // _menuItem(
                        //   theme,
                        //   'assets/images/subscription_icon.png',
                        //   'My Subscription',
                        //   () {},
                        // ),
                        _menuItem(
                          theme,
                          'assets/images/broker_settings_icon.png',
                          'Setting',
                          () => Get.to(() => SettingsView(side: 'broker')),
                        ),
                      ]),
                      SizedBox(height: 16.h),
                      _buildCardGroup(theme, [
                        _menuItem(
                          theme,
                          'assets/images/switch_to_user_icon.png',
                          'Switch to User side',
                          () => _switchToUser(),
                        ),
                      ]),
                      SizedBox(height: 30.h),
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

  Future<void> _switchToUser() async {
    Get.dialog(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
    final ok = await controller.switchRole(1);
    if (Get.isDialogOpen ?? false) Get.back();
    if (ok) {
      LocalStorageService.saveLastSide('user');
      // Wipe broker-side cached data so the user side opens with fresh
      // role-correct responses, not stale broker-side payloads.
      await clearRoleScopedCache();
      Get.offAll(() => const DashboardView());
    }
  }

  Widget _buildProfileHeader(ThemeData theme) {
    final data = controller.profileData.value;
    final bool isVerified = data?['verificationStatus'] == 'approved';

    return Column(
      children: [
        GestureDetector(
          onTap: () => FullScreenImageView.show(
            imageUrl: controller.brokerProfileImage.value.isNotEmpty
                ? controller.brokerProfileImage.value
                : null,
            assetPath: controller.brokerProfileImage.value.isEmpty
                ? 'assets/images/profile.jpg'
                : null,
          ),
          child: SizedBox(
            width: _badgeBox.w,
            height: _badgeBox.w,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: _avatarSize.w,
                  height: _avatarSize.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey,
                  ),
                  child: ClipOval(
                    child: controller.brokerProfileImage.value.isNotEmpty
                        ? Image.network(
                            controller.brokerProfileImage.value,
                            fit: BoxFit.cover,
                            width: _avatarSize.w,
                            height: _avatarSize.w,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/images/profile.jpg',
                              fit: BoxFit.cover,
                              width: _avatarSize.w,
                              height: _avatarSize.w,
                            ),
                          )
                        : Image.asset(
                            'assets/images/profile.jpg',
                            fit: BoxFit.cover,
                            width: _avatarSize.w,
                            height: _avatarSize.w,
                          ),
                  ),
                ),
                // Last in the stack so the badge sits over the photo rather
                // than the photo's circle cropping it.
                if (isVerified)
                  Positioned(
                    left: (_badgeBox / 2 +
                            _badgeDistance * math.cos(_badgeAngle) -
                            _badgeSize / 2)
                        .w,
                    top: (_badgeBox / 2 -
                            _badgeDistance * math.sin(_badgeAngle) -
                            _badgeSize / 2)
                        .w,
                    width: _badgeSize.w,
                    height: _badgeSize.w,
                    child: Image.asset(
                      'assets/images/v-icon.png',
                      fit: BoxFit.contain,
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          controller.userName.value.isNotEmpty
              ? controller.userName.value
              : '-',
          style: GoogleFonts.poppins(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          controller.userEmail.value.isNotEmpty
              ? controller.userEmail.value
              : '-',
          style: GoogleFonts.poppins(
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildCardGroup(ThemeData theme, List<Widget> children) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161616) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: Column(children: children),
    );
  }

  /// Row, matching the user-side `_tile` exactly — same padding, weight and
  /// bare gold icon, and no separator, so both profile screens render the
  /// same component at the same height.
  Widget _menuItem(
    ThemeData theme,
    String assetPath,
    String title,
    VoidCallback onTap,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            // Same insets as the user-side tile so both cards stand the same
            // height.
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 18.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      height: 1.0,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                // Matches the user-side tile exactly (`_tile` in
                // views/user/account/account_view.dart): the icon sits bare and
                // gold-tinted at 26x26. It used to be an 18x18 untinted image
                // inside a gold-bordered box, which is what made the same
                // assets read as different icons across the two screens.
                Image.asset(
                  assetPath,
                  width: 26.w,
                  height: 26.w,
                  color: AppColors.primary,
                  colorBlendMode: BlendMode.srcIn,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
