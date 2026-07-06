import 'package:flutter/material.dart';
import 'package:brokkerspot/core/constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.primaryDark,
          surface: Colors.white,
          onPrimary: Colors.white,
          onSurface: const Color(0xFF1A1A1A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF1A1A1A),
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: const Color(0xFFE8E8E8)),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFEEEEEE),
          thickness: 0.5,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(Colors.white),
          trackColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? AppColors.primary
                : Colors.grey.shade300;
          }),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF1A1A1A)),
          bodyMedium: TextStyle(color: Color(0xFF1A1A1A)),
          bodySmall: TextStyle(color: Color(0xFF666666)),
        ),
      );

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: AppColors.backgroundDark,
        colorScheme: ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.primaryLight,
          surface: AppColors.backgroundDark,
          onPrimary: Colors.white,
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.backgroundDark,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          color: AppColors.backgroundOverlay,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF2A4A5A)),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF2A4A5A),
          thickness: 0.5,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.backgroundOverlay,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2A4A5A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2A4A5A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          hintStyle: const TextStyle(color: Color(0xFF666E7A)),
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(Colors.white),
          trackColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? AppColors.primary
                : const Color(0xFF2A4A5A);
          }),
          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Color(0xFFB0BEC5)),
        ),
      );
}
