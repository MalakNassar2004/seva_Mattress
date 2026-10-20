import 'package:flutter/material.dart';

/// Single source of truth for every color in the app.
/// Change a value here and it updates everywhere.
class AppColors {
  AppColors._();

  // Brand
  static const Color primaryBlue = Color(0xFF0A5FC4); // buttons, links
  static const Color deepBlue = Color(0xFF0B4F9E); // headings, PIN title
  static const Color lightBlue = Color(0xFFDCE8FA); // chips, icon boxes
  static const Color glowBlue = Color(0xFFDCE6FB); // soft background glow

  // Surfaces
  static const Color background = Color(0xFFF8FAFC);
  static const Color white = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFDDE3EC);

  // Text
  static const Color textDark = Color(0xFF111827);
  static const Color grey = Color(0xFF6B7280);
  static const Color greyLight = Color(0xFF9CA3AF);

  // Status
  static const Color danger = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);

  // Shadows
  static const Color shadow = Color(0x14101828);

  // Splash gradient (sampled from the reference mesh background)
  static const Color splashTop = Color(0xFFEDF8FE);
  static const Color splashMid = Color(0xFFBFE5FA);
  static const Color splashCyan = Color(0xFF8FD3F4);
  static const Color splashDeep = Color(0xFF4574BA);
  static const Color splashLightCyan = Color(0xFFA9DDF5);
}