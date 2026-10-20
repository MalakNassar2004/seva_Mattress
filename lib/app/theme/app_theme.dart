import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Global theme. Use it in GetMaterialApp: theme: AppTheme.light
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    // The design uses Inter. Add the font to pubspec (or google_fonts);
    // if it is missing Flutter silently falls back to the default font.
    fontFamily: 'Inter',
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryBlue,
      primary: AppColors.primaryBlue,
      surface: AppColors.white,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.primaryBlue,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.primaryBlue),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
  );
}

/// Shared shadows so every card looks the same.
class AppShadows {
  AppShadows._();

  static const List<BoxShadow> soft = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> small = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 8,
      offset: Offset(0, 3),
    ),
  ];
}