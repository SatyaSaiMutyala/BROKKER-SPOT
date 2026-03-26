import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/views/user/settings/change_password_view.dart';
import 'package:brokkerspot/views/user/account/controller/account_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsView extends StatelessWidget {
  final String side;
  SettingsView({super.key, this.side = 'user'});

  final AccountController _accountController = Get.put(AccountController());

  @override
  Widget build(BuildContext context) {
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
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                  child: _buildSettingsCard(),
                ),
              ),
              // App Version at bottom
              Padding(
                padding: EdgeInsets.only(bottom: 24.h),
                child: Text(
                  'App Version: 1.0.0',
                  style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Get.back(),
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E5E5)),
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 16.sp,
                color: Colors.black,
              ),
            ),
          ),
          // Title
          Expanded(
            child: Center(
              child: Text(
                'Setting',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          // Logout button (power icon)
          GestureDetector(
            onTap: () => _showLogoutDialog(context),
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFF6B6B), width: 2),
              ),
              child: Icon(
                Icons.power_settings_new,
                size: 20.sp,
                color: const Color(0xFFFF6B6B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- SETTINGS CARD ----------------
  Widget _buildSettingsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        children: [
          _settingsTile(
            icon: Icons.light_mode_outlined,
            iconColor: AppColors.goldAccent,
            title: 'Light mode',
            trailing: _buildSwitch(),
          ),
          _tileDivider(),
          _settingsTile(
            icon: Icons.lock_outline,
            iconColor: AppColors.goldAccent,
            title: 'Change Password',
            onTap: () => Get.to(() => ChangePasswordView()),
          ),
          _tileDivider(),
          _settingsTile(
            icon: Icons.translate,
            iconColor: AppColors.goldAccent,
            title: 'Language',
            trailingText: 'English',
            onTap: () {},
          ),
          _tileDivider(),
          _settingsTile(
            icon: Icons.currency_exchange,
            iconColor: AppColors.goldAccent,
            title: 'Currency',
            trailingText: 'Euro',
            onTap: () {},
          ),
          _tileDivider(),
          _settingsTile(
            icon: Icons.description_outlined,
            iconColor: AppColors.goldAccent,
            title: 'Terms & Conditions',
            onTap: () {},
          ),
          _tileDivider(),
          _settingsTile(
            icon: Icons.headset_mic_outlined,
            iconColor: AppColors.goldAccent,
            title: 'Help & Support',
            onTap: () {},
          ),
          _tileDivider(),
          _settingsTile(
            icon: Icons.help_outline,
            iconColor: AppColors.goldAccent,
            title: 'About Us',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  // ---------------- SETTINGS TILE ----------------
  Widget _settingsTile({
    required IconData icon,
    required String title,
    Color? iconColor,
    Widget? trailing,
    String? trailingText,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
        child: Row(
          children: [
            Icon(icon, size: 24.sp, color: iconColor ?? AppColors.goldAccent),
            SizedBox(width: 16.w),
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
            if (trailingText != null)
              Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: Text(
                  trailingText,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
            if (trailing != null)
              trailing
            else
              Icon(
                Icons.chevron_right,
                size: 22.sp,
                color: Colors.grey.shade500,
              ),
          ],
        ),
      ),
    );
  }

  // ---------------- SWITCH ----------------
  Widget _buildSwitch() {
    return SizedBox(
      width: 40.w,
      height: 24.h,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Switch(
          value: false,
          onChanged: (val) {},
          thumbColor: WidgetStateProperty.all(Colors.white),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return Colors.grey.shade300;
          }),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
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

  // ---------------- LOGOUT DIALOG ----------------
  void _showLogoutDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 34.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Logout',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Are you sure you want to logout?',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 24.h),
            // Yes, Logout button
            SizedBox(
              width: double.infinity,
              height: 50.h,
              child: ElevatedButton(
                onPressed: () {
                  Get.back();
                  _accountController.logout(side: side);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.r),
                  ),
                ),
                child: Text(
                  'Yes, Logout',
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            // Cancel button
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
                  style: GoogleFonts.inter(
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
