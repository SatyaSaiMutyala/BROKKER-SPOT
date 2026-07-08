import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/theme/theme_controller.dart';
import 'package:brokkerspot/views/user/settings/change_password_view.dart';
import 'package:brokkerspot/views/user/account/controller/account_controller.dart';
import 'package:brokkerspot/widgets/common/location_picker_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsView extends StatelessWidget {
  final String side;
  SettingsView({super.key, this.side = 'user'});

  final AccountController _accountController = Get.put(AccountController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context, theme, isDark),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(27.w, 24.h, 27.w, 24.h),
                child: Column(
                  children: [
                    // ── Card 1: personalisation ─────────────────────────────
                    _buildCard(
                      isDark: isDark,
                      children: [
                        Obx(() {
                          final dark = ThemeController.to.isDark;
                          return _tile(
                            title: dark ? 'Dark mode' : 'Light mode',
                            isDark: isDark,
                            trailing: _buildThemeSwitch(),
                          );
                        }),
                        _tile(
                          title: 'Password & Security',
                          icon: Icons.password_outlined,
                          isDark: isDark,
                          onTap: () => Get.to(() => ChangePasswordView()),
                        ),
                        _tile(
                          title: 'Location',
                          icon: Icons.location_on_outlined,
                          isDark: isDark,
                          onTap: () => Get.dialog(
                            const LocationPickerPopup(),
                            barrierDismissible: false,
                          ),
                        ),
                        _tile(
                          title: 'Language',
                          icon: Icons.translate_outlined,
                          isDark: isDark,
                          onTap: () {},
                        ),
                        _tile(
                          title: 'Currency',
                          icon: Icons.currency_exchange_outlined,
                          isDark: isDark,
                          onTap: () {},
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),

                    // ── Card 2: legal / support ─────────────────────────────
                    _buildCard(
                      isDark: isDark,
                      children: [
                        _tile(
                          title: 'Terms & Conditions',
                          icon: Icons.description_outlined,
                          isDark: isDark,
                          onTap: () {},
                        ),
                        _tile(
                          title: 'Help & Support',
                          icon: Icons.headset_mic_outlined,
                          isDark: isDark,
                          onTap: () {},
                        ),
                        _tile(
                          title: 'About Us',
                          icon: Icons.info_outline_rounded,
                          isDark: isDark,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── App version ────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.only(bottom: 100.h),
              child: Text(
                'App Version: 1.0.0',
                style: GoogleFonts.poppins(
                  fontSize: 12.sp,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header: back circle + centered title + red logout circle ───────────────

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 0),
      child: Row(
        children: [
          // Back button — gray filled circle
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF2F2F2),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16.sp,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          // Title — centered
          Expanded(
            child: Center(
              child: Text(
                'Setting',
                style: GoogleFonts.poppins(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                  height: 1.0,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          // Logout — filled red circle
          GestureDetector(
            onTap: () => _showLogoutDialog(context),
            child: Container(
              width: 36.w,
              height: 36.w,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFF4B4B),
              ),
              child: Icon(
                Icons.power_settings_new_rounded,
                size: 18.sp,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Card wrapper ───────────────────────────────────────────────────────────

  Widget _buildCard({required bool isDark, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFFE8E8E8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  // ── Tile: title left, gold icon (or custom trailing) right ─────────────────

  Widget _tile({
    required String title,
    required bool isDark,
    IconData? icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 18.h),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  height: 1.0,
                  letterSpacing: 0,
                ),
              ),
            ),
            if (trailing != null)
              trailing
            else if (icon != null)
              Icon(icon, size: 21.sp, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  // ── Theme toggle switch ────────────────────────────────────────────────────

  Widget _buildThemeSwitch() {
    return Obx(() {
      final isDark = ThemeController.to.isDark;
      return SizedBox(
        width: 40.w,
        height: 24.h,
        child: FittedBox(
          fit: BoxFit.contain,
          child: Switch(
            value: !isDark,
            onChanged: (_) => ThemeController.to.toggleTheme(),
            thumbColor: WidgetStateProperty.all(Colors.white),
            trackColor: WidgetStateProperty.resolveWith((states) {
              return states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : Colors.grey.shade300;
            }),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ),
      );
    });
  }

  // ── Logout bottom sheet ────────────────────────────────────────────────────

  void _showLogoutDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 34.h),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Logout',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Are you sure you want to logout?',
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  _accountController.logout(side: side);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4B4B),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
                child: Text(
                  'Yes, Logout',
                  style: GoogleFonts.poppins(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade200,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
