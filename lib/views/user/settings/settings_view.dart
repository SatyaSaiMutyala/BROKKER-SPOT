import 'package:brokkerspot/core/constants/app_colors.dart';
import 'package:brokkerspot/core/theme/theme_controller.dart';
import 'package:brokkerspot/views/auth/controller/profile_controller.dart';
import 'package:brokkerspot/views/user/settings/change_password_view.dart';
import 'package:brokkerspot/views/user/account/controller/account_controller.dart';
import 'package:brokkerspot/widgets/common/custom_header.dart';
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
      backgroundColor:
          isDark ? const Color(0xFF090B11) : theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CustomHeader(
              title: 'Setting',
              showBackButton: true,
              trailing: GestureDetector(
                onTap: () => _showLogoutDialog(context),
                child: Container(
                  width: 36.w,
                  height: 36.w,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFFF4B4B),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(2.w),
                    child: Image.asset(
                      'assets/images/logout_icon.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(27.w, 40.h, 27.w, 24.h),
                child: Column(
                  children: [
                    // ── Card 1: personalisation ─────────────────────────────
                    _buildCard(
                      isDark: isDark,
                      children: [
                        _tile(
                          title: 'Theme',
                          iconAsset: 'assets/images/theme_icon.png',
                          isDark: isDark,
                          onTap: () => ThemeController.to.toggleTheme(),
                        ),
                        _tile(
                          title: 'Password & Security',
                          iconAsset: 'assets/images/password.png',
                          isDark: isDark,
                          onTap: () => Get.to(() => ChangePasswordView()),
                        ),
                        _tile(
                          title: 'Language',
                          iconAsset: 'assets/images/language.png',
                          isDark: isDark,
                          onTap: () {},
                        ),
                        Obx(() => _tile(
                              title: 'Currency',
                              iconAsset: 'assets/images/currency.png',
                              isDark: isDark,
                              trailing: Text(
                                ProfileController.to.currency,
                                style: GoogleFonts.poppins(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary,
                                ),
                              ),
                              onTap: () => _showCurrencyPicker(context, isDark),
                            )),
                      ],
                    ),

                    SizedBox(height: 16.h),

                    // ── Card 2: legal / support ─────────────────────────────
                    _buildCard(
                      isDark: isDark,
                      children: [
                        _tile(
                          title: 'Terms & Conditions',
                          iconAsset: 'assets/images/terms.png',
                          isDark: isDark,
                          onTap: () {},
                        ),
                        _tile(
                          title: 'Help & Support',
                          iconAsset: 'assets/images/help.png',
                          isDark: isDark,
                          onTap: () {},
                        ),
                        _tile(
                          title: 'About Us',
                          iconAsset: 'assets/images/about_icon.png',
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

  // ── Card wrapper ───────────────────────────────────────────────────────────

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

  // ── Tile: title left, gold icon (or custom trailing) right ─────────────────

  Widget _tile({
    required String title,
    required bool isDark,
    String? iconAsset,
    IconData? icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    Widget? iconWidget;
    if (trailing != null) {
      iconWidget = trailing;
    } else if (iconAsset != null) {
      iconWidget = Image.asset(
        iconAsset,
        width: 24.w,
        height: 24.w,
        color: AppColors.primary,
      );
    } else if (icon != null) {
      iconWidget = Icon(icon, size: 24.sp, color: AppColors.primary);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
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
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      height: 1.0,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                if (iconWidget != null) iconWidget,
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Logout bottom sheet ────────────────────────────────────────────────────

  /// Currencies offered in the picker.
  ///
  /// `edit-settings` accepts any code in its country→currency table (~143 of
  /// them), but the backend only computes exchange rates for these seven
  /// (see exchange-rates.cron.ts), so anything else would leave prices with no
  /// rate to convert against. Kept deliberately narrow for that reason.
  static const List<(String code, String label)> _currencies = [
    ('AED', 'UAE Dirham'),
    ('USD', 'US Dollar'),
    ('EUR', 'Euro'),
    ('INR', 'Indian Rupee'),
    ('MAD', 'Moroccan Dirham'),
    ('NPR', 'Nepalese Rupee'),
    ('CNY', 'Chinese Yuan'),
  ];

  void _showCurrencyPicker(BuildContext context, bool isDark) {
    final profile = ProfileController.to;
    final sheetBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final titleColor = Theme.of(context).colorScheme.onSurface;
    final subColor = isDark ? Colors.grey.shade500 : Colors.grey.shade600;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      // Closing mid-save would leave the spinner's result with nowhere to go
      // and the row still showing the old value.
      isDismissible: !profile.isSavingCurrency,
      enableDrag: !profile.isSavingCurrency,
      builder: (sheetCtx) => Container(
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 28.h),
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: subColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'Currency',
              style: GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Prices across the app are shown in this currency.',
              style: GoogleFonts.poppins(
                fontSize: 12.sp,
                fontWeight: FontWeight.w300,
                color: subColor,
              ),
            ),
            SizedBox(height: 12.h),
            Obx(() {
              final selected = profile.currency;
              final pending = profile.savingCurrencyCode.value;
              final saving = pending != null;

              return Column(
                children: _currencies.map((c) {
                  final isSelected = c.$1 == selected;
                  final isPending = c.$1 == pending;
                  // While a save runs, the row being saved keeps full contrast
                  // and shows a spinner; the rest fade so it is obvious which
                  // one is in flight and that the others are inert.
                  final dimmed = saving && !isPending;

                  return InkWell(
                    onTap: saving
                        ? null
                        : () async {
                            final ok = await profile.updateCurrency(c.$1);
                            if (ok && sheetCtx.mounted) {
                              Navigator.pop(sheetCtx);
                            }
                          },
                    borderRadius: BorderRadius.circular(12.r),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: dimmed ? 0.4 : 1,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 52.w,
                              child: Text(
                                c.$1,
                                style: GoogleFonts.poppins(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected || isPending
                                      ? AppColors.primary
                                      : titleColor,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                c.$2,
                                style: GoogleFonts.poppins(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w400,
                                  color: subColor,
                                ),
                              ),
                            ),
                            if (isPending)
                              SizedBox(
                                width: 20.sp,
                                height: 20.sp,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            else if (isSelected)
                              Icon(Icons.check_circle,
                                  size: 20.sp, color: AppColors.primary),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

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
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
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
