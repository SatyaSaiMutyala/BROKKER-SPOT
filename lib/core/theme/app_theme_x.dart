import 'package:flutter/material.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';

/// Semantic color tokens for the app.
///
/// Use [context.colors] in widgets instead of hardcoded [Colors.white] /
/// [Colors.black87] so screens automatically respond to theme changes.
///
/// Example:
///   Container(color: context.colors.bgPrimary)
///   Text('Hello', style: TextStyle(color: context.colors.textPrimary))
extension AppThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  AppColorTokens get colors =>
      isDark ? AppColorTokens.dark : AppColorTokens.light;
}

class AppColorTokens {
  const AppColorTokens({
    required this.bgPrimary,
    required this.bgCard,
    required this.bgSurface,
    required this.bgOverlay,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.border,
    required this.divider,
    required this.iconSecondary,
    required this.inputFill,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.statusBarIconBrightness,
  });

  // Backgrounds
  final Color bgPrimary;
  final Color bgCard;
  final Color bgSurface;
  final Color bgOverlay;

  // Text
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;

  // Borders & dividers
  final Color border;
  final Color divider;

  // Icons
  final Color iconSecondary;

  // Input
  final Color inputFill;

  // Shimmer
  final Color shimmerBase;
  final Color shimmerHighlight;

  // Status bar
  final Brightness statusBarIconBrightness;

  static const light = AppColorTokens(
    bgPrimary: Colors.white,
    bgCard: Colors.white,
    bgSurface: Color(0xFFF5F5F5),
    bgOverlay: Color(0xFFF0F0F0),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF666666),
    textHint: Color(0xFFAAAAAA),
    border: Color(0xFFE8E8E8),
    divider: Color(0xFFEEEEEE),
    iconSecondary: Color(0xFF888888),
    inputFill: Color(0xFFF8F8F8),
    shimmerBase: Color(0xFFE0E0E0),
    shimmerHighlight: Color(0xFFF5F5F5),
    statusBarIconBrightness: Brightness.dark,
  );

  static const dark = AppColorTokens(
    bgPrimary: AppColors.backgroundDark,
    bgCard: AppColors.backgroundOverlay,
    bgSurface: Color(0xFF1E3545),
    bgOverlay: Color(0xFF243E50),
    textPrimary: Colors.white,
    textSecondary: Color(0xFFB0BEC5),
    textHint: Color(0xFF6E8090),
    border: Color(0xFF2A4A5A),
    divider: Color(0xFF2A4A5A),
    iconSecondary: Color(0xFF8BAFC0),
    inputFill: AppColors.backgroundOverlay,
    shimmerBase: Color(0xFF1E3545),
    shimmerHighlight: Color(0xFF2A4A5A),
    statusBarIconBrightness: Brightness.light,
  );
}
