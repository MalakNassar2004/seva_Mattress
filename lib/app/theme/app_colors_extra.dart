import 'package:flutter/material.dart';

/// Extra colors used by the Inventory and Customers screens.
/// Kept in a separate file so it never conflicts with app_colors.dart.
/// You can merge these into AppColors later.
class AppColorsExtra {
  AppColorsExtra._();

  static const Color amber = Color(0xFFB45309);
  static const Color amberBg = Color(0xFFFEF3C7);
  static const Color amberBorder = Color(0xFFFCD34D);

  static const Color warningBorder = Color(0xFFF6D28B);
  static const Color warningSoft = Color(0xFFFFF8EB);

  static const Color dangerBorder = Color(0xFFF3B4B4);
  static const Color dangerSoft = Color(0xFFFFF5F5);

  static const Color successBorder = Color(0xFFBFE5CD);

  static const Color infoBg = Color(0xFFE8F1FD);
  static const Color infoBorder = Color(0xFFC3D8F5);

  static const Color chipGrey = Color(0xFFE5E9F0);
  static const Color panelGrey = Color(0xFFF6F8FB);
  static const Color panelBorder = Color(0xFFE3E8F0);
  static const Color segmentBg = Color(0xFFEBEEF3);
}
