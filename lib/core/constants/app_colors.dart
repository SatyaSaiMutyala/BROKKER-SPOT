import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFFDBC483);
  static const Color primaryLight = Color(0xFFE8C878);
  static const Color primaryDark = Color(0xFFB8923E);

  // Background Colors
  static const Color backgroundDark = Color(0xFF0D1F2D);
  static const Color backgroundOverlay = Color(0xFF1A3A4A);

  // Text Colors
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textBlack = Color(0xFF000000);
  static const Color textGrey = Color(0xFFB0B0B0);
  static const Color textHint = Color(0xFF8A8A8A);

  // Input Field Colors
  static const Color inputBackground = Colors.transparent;
  static const Color inputBorder = Color(0xFF4A4A4A);
  static const Color inputBorderFocused = Color(0xFFD4A84B);

  // Other Colors
  static const Color divider = Color(0xFF4A4A4A);
  static const Color switchActive = Color(0xFFD4A84B);
  static const Color switchInactive = Color(0xFF4A4A4A);

  // Payment Screen Colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color goldAccent = Color(0xFFD9C27C);

  // Announcement Screen Colors
  static const Color teal = Color(0xFF2B8B8B);
  static const Color tealLight = Color(0xFFE8F5F5);
  static const Color activeGreen = Color(0xFF4CAF50);

  // App Bar — dark theme
  static const Color appBarDarkBg = Color(0xFF090B11);
  static const Color appBarDarkBorder = Color(0xFF1B1D27);

  // App Bar — light theme
  static const Color appBarLightBg = Color(0xFFFFFFFF);
  static const Color appBarLightBorder = Color(0xFFE8E8E8);

  // Back button circle — dark theme gradient fill + icon
  static const Color backBtnDarkFillTop = Color(0xFF3A3A3C); // lighter (top-left)
  static const Color backBtnDarkFillBottom = Color(0xFF1C1C1E); // darker (bottom-right)
  static const Color backBtnDarkIcon = Color(0xD1FFFFFF);

  // Back button circle — light theme
  static const Color backBtnLightBg = Color(0xFFF2F2F2);
  static const Color backBtnLightIcon = Color(0xDD000000);

  // Bottom navigation bar
  static const Color navActive = Color(0xFFC8A961);
  static const Color navInactiveLight = Color(0xFF1C1C1E);
  static const Color navInactiveDark = Color(0xFFE4E4E7);
  static const Color navCenterButtonLight = Color(0xFFF7F2E9);
  static const Color navCenterButtonDark = Color(0xFF1E212A);
}
