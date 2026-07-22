import 'package:flutter/material.dart';

import 'package:brokkerspot/core/constants/app_colors.dart';

/// Colour + metric tokens for [AppBottomNavBar], resolved per brightness so
/// the user and broker dashboards stay visually identical.
@immutable
class AppBottomNavBarTheme {
  final Color background;
  final Color border;
  final Color shadow;
  final Color activeIcon;
  final Color inactiveIcon;
  final Color centerButtonBackground;
  final Color centerButtonIcon;

  const AppBottomNavBarTheme({
    required this.background,
    required this.border,
    required this.shadow,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.centerButtonBackground,
    required this.centerButtonIcon,
  });

  factory AppBottomNavBarTheme.of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }

  static const AppBottomNavBarTheme light = AppBottomNavBarTheme(
    background: Colors.white,
    border: Color(0xFFEDEDED),
    shadow: Color(0x14000000),
    activeIcon: AppColors.navActive,
    inactiveIcon: AppColors.navInactiveLight,
    centerButtonBackground: AppColors.navCenterButtonLight,
    centerButtonIcon: AppColors.navInactiveLight,
  );

  static const AppBottomNavBarTheme dark = AppBottomNavBarTheme(
    background: AppColors.appBarDarkBg,
    border: AppColors.appBarDarkBorder,
    shadow: Color(0x40000000),
    activeIcon: AppColors.navActive,
    inactiveIcon: AppColors.navInactiveDark,
    centerButtonBackground: AppColors.navCenterButtonDark,
    centerButtonIcon: AppColors.navInactiveDark,
  );
}
