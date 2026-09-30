import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Coral
  static const Color primaryCoral = Color(0xFFE86F4D);
  static const Color secondaryCoral = Color(0xFFF47B57);
  static const Color lightCoral = Color(0xFFFCE0D7);

  // Backgrounds
  static const Color creamBackground = Color(0xFFFFF9EF);
  static const Color cardSurface = Color(0xFFFFFDF8);

  // Text
  static const Color primaryNavy = Color(0xFF10243E);
  static const Color secondaryText = Color(0xFF5F6470);

  // Borders
  static const Color border = Color(0xFFE7D8C9);
  static const Color lightBorder = Color(0xFFF0E7DB);

  // Accents
  static const Color blue = Color(0xFF244F8F);
  static const Color purple = Color(0xFF5B5BB6);

  // Status
  static const Color success = Color(0xFF5FA77B);
  static const Color warning = Color(0xFFE7B84A);
  static const Color error = Color(0xFFD9534F);

  // Basic
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Gradient
  static const List<Color> brandGradient = [
    Color(0xFF244F8F),
    Color(0xFF5B5BB6),
    Color(0xFFE86F4D),
  ];

  // Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: AppColors.primaryNavy.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: AppColors.primaryCoral.withValues(alpha: 0.3),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
