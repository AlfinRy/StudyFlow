import 'package:flutter/material.dart';

/// Design tokens for StudyFlow.
///
/// Source: documentation/UI_DESIGN.md section 1.
/// Values are visual estimates from the Figma mockups — refine with exact
/// Figma inspect values later (see UI_DESIGN.md section 10).
///
/// **Dark mode:** token permukaan (background, surface, surfaceBorder,
/// textPrimary, textSecondary) bersifat theme-aware lewat [brightness] zone
/// yang diperbarui di root app (MaterialApp.builder). Widget membaca getter
/// ini saat build → otomatis ikut mode gelap/terang. Token brand (navy,
/// accent) & semantik tetap konstan (cocok di kedua mode).
class AppColors {
  AppColors._();

  /// Zone kecerahan aktif (di-update di MaterialApp.builder). Default terang.
  static Brightness brightness = Brightness.light;

  // Brand — navy gradient (hero cards, splash, dark top areas) — tetap konstan.
  static const Color navyDark = Color(0xFF0F2A47);
  static const Color navyLight = Color(0xFF16324F);
  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navyDark, navyLight],
  );

  // Accent — bright blue (primary buttons, active icons, progress) — konstan.
  static const Color accent = Color(0xFF3B82F6);
  static const Color accentDark = Color(0xFF2E6FE0);

  // --- Palet eksplisit per mode (dipakai ThemeData & getter) ---
  // Terang (UI_DESIGN.md §1.1)
  static const Color lightBackground = Color(0xFFF7F9FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // Gelap (cool navy-gray, mengurangi silau saat belajar malam)
  static const Color darkBackground = Color(0xFF0F141C);
  static const Color darkSurface = Color(0xFF1A2230);
  static const Color darkSurfaceBorder = Color(0xFF2A3548);
  static const Color darkTextPrimary = Color(0xFFE8EDF5);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // --- Getter theme-aware (dibaca widget saat build) ---
  static Color get background =>
      brightness == Brightness.dark ? darkBackground : lightBackground;
  static Color get surface =>
      brightness == Brightness.dark ? darkSurface : lightSurface;
  static Color get surfaceBorder =>
      brightness == Brightness.dark ? darkSurfaceBorder : lightSurfaceBorder;
  static Color get textPrimary =>
      brightness == Brightness.dark ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary =>
      brightness == Brightness.dark ? darkTextSecondary : lightTextSecondary;

  // Text on navy — putih (selalu pada hero gelap).
  static const Color textOnNavy = Color(0xFFFFFFFF);

  // Semantic — konstan di kedua mode.
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);
}
