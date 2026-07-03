import 'package:flutter/material.dart';

/// Design tokens for StudyFlow.
///
/// Source: documentation/UI_DESIGN.md section 1.
/// Values are visual estimates from the Figma mockups — refine with exact
/// Figma inspect values later (see UI_DESIGN.md section 10).
class AppColors {
  AppColors._();

  // Brand — navy gradient (hero cards, splash, dark top areas)
  static const Color navyDark = Color(0xFF0F2A47);
  static const Color navyLight = Color(0xFF16324F);
  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navyDark, navyLight],
  );

  // Accent — bright blue (primary buttons, active icons, progress)
  static const Color accent = Color(0xFF3B82F6);
  static const Color accentDark = Color(0xFF2E6FE0);

  // Surfaces
  static const Color background = Color(0xFFF7F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceBorder = Color(0xFFE2E8F0);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textOnNavy = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);
}
