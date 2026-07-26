import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/constants/local_storage.dart';
import 'package:brokkerspot/core/services/session_cleanup.dart';
import 'package:brokkerspot/views/user/wishlist/wishlist_view.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:brokkerspot/views/auth/view/login_view.dart';
import 'package:brokkerspot/views/auth/view/signup_view.dart';
import 'package:brokkerspot/views/brokker/brokker_login/view/brokker_login_view.dart';
import 'package:brokkerspot/views/brokker/brokker_login/view/complete_profile_screen.dart';
import 'package:brokkerspot/views/brokker/dashboard/brokker_dashboard.dart';
import 'package:brokkerspot/views/user/account/controller/account_controller.dart';
import 'package:brokkerspot/views/user/announcements/my_announcements_tab_view.dart';
import 'package:brokkerspot/views/user/deals/my_project_deals_view.dart';
import 'package:brokkerspot/views/user/my_information/my_information_view.dart';
import 'package:brokkerspot/views/user/settings/settings_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountView extends StatelessWidget {
  const AccountView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(AccountController());
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isGuest = !LocalStorageService.isLoggedIn();
    final profileCtrl = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF090B11) : theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(27.w, 0, 27.w, 100.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16.h),

              // ── Header ───────────────────────────────────────────────────
              Text(
                'Account',
                style: GoogleFonts.poppins(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                  height: 1.0,
                  letterSpacing: 0,
                ),
              ),

              SizedBox(height: 48.h),

              // ── Profile avatar + name + email ────────────────────────────
              Center(child: _buildProfile(profileCtrl, isGuest, theme, isDark)),

              SizedBox(height: 28.h),

              // ── Card 1: main menu items ──────────────────────────────────
              _buildCard(
                isDark: isDark,
                children: [
                  _tile(
                    title: 'Manage Profile',
                    iconAsset: 'broker_my_profile_icon.png',
                    enabled: !isGuest,
                    isDark: isDark,
                    onTap: () => Get.to(() => const MyInformationView()),
                  ),
                  // _tile(
                  //   title: 'My Deals',
                  //   iconAsset: 'broker_mydeal_icon.png',
                  //   enabled: !isGuest,
                  //   isDark: isDark,
                  //   onTap: () => Get.to(() => const MyProjectDealsView()),
                  // ),
                  _tile(
                    title: 'My Announcements',
                    iconAsset: 'broker_announcement.png',
                    enabled: !isGuest,
                    isDark: isDark,
                    onTap: () => Get.to(() => const MyAnnouncementsTabView()),
                  ),
                  _tile(
                    title: 'Wishlist',
                    iconAsset: 'broker_wishlist_icon.png',
                    enabled: !isGuest,
                    isDark: isDark,
                    onTap: () =>
                        Get.to(() => const WishlistView(showBackButton: true)),
                  ),
                  _tile(
                    title: 'Setting',
                    iconAsset: 'broker_settings_icon.png',
                    enabled: !isGuest,
                    isDark: isDark,
                    onTap: () => Get.to(() => SettingsView()),
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // ── Card 2: Become a Broker ──────────────────────────────────
              Obx(() {
                final hasBrokerRole = profileCtrl.hasBrokerRole;
                return _buildCard(
                  isDark: isDark,
                  children: [
                    _tile(
                      title: hasBrokerRole
                          ? 'Switch to Broker'
                          : 'Become a Broker',
                      iconAsset: 'switch_to_user_icon.png',
                      enabled: true,
                      isDark: isDark,
                      onTap: () async {
                        if (hasBrokerRole) {
                          Get.dialog(
                            const Center(child: CircularProgressIndicator()),
                            barrierDismissible: false,
                          );
                          final ok = await profileCtrl.switchRole(2);
                          if (Get.isDialogOpen ?? false) Get.back();
                          if (ok) {
                            LocalStorageService.saveLastSide('broker');
                            await clearRoleScopedCache();
                            Get.offAll(() => BrokerDashBoardView());
                          }
                        } else {
                          Get.to(() => BrokerOnboardingView());
                        }
                      },
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  // ── Profile section: 95×95 rounded-square avatar, name, email ─────────────

  Widget _buildProfile(
      ProfileController ctrl, bool isGuest, ThemeData theme, bool isDark) {
    return Obx(() {
      final imgUrl = ctrl.profileImage.value.trim();
      final name = isGuest
          ? 'Guest'
          : ctrl.userName.value.isNotEmpty
              ? ctrl.userName.value
              : 'User';
      final email = isGuest ? '' : ctrl.userEmail.value;

      return Column(
        children: [
          // Avatar: 95×95 rounded-square (r20)
          ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: SizedBox(
              width: 95.w,
              height: 95.w,
              child: imgUrl.isNotEmpty
                  ? Image.network(
                      imgUrl,
                      key: ValueKey(imgUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _avatarPlaceholder(isDark),
                    )
                  : _avatarPlaceholder(isDark),
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
              height: 1.0,
            ),
          ),
          if (email.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              email,
              style: GoogleFonts.poppins(
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                height: 1.0,
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _avatarPlaceholder(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
      child: Icon(Icons.person,
          size: 40.sp,
          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
    );
  }

  // ── Card wrapper: border, radius, white/dark bg ────────────────────────────

  Widget _buildCard({required bool isDark, required List<Widget> children}) {
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

  // ── Tile: title left, gold icon right ─────────────────────────────────────

  Widget _tile({
    required String title,
    required String iconAsset,
    required VoidCallback onTap,
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
                'assets/images/$iconAsset',
                width: 26.w,
                height: 26.w,
                color: AppColors.primary,
                colorBlendMode: BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Separator inside card ──────────────────────────────────────────────────
}

// ── Dialogs (unchanged) ───────────────────────────────────────────────────────

/// Prompts a guest to log in or sign up.
///
/// [title] and [message] override the default copy so a caller can say what
/// specifically needs an account — e.g. the guest announcement feed explaining
/// that more listings sit behind login.
void showLoginRequiredDialog(
  BuildContext context, {
  String title = 'Please Login.',
  String message = 'Without login you cannot use all features in this app.',
}) {
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
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              message,
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
