import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_spacing.dart';
import 'app_logo.dart';

/// Dialog "Tentang Aplikasi" (versi mengikuti pubspec). Dipakai dari drawer &
/// halaman Profil.
void showStudyFlowAbout(BuildContext context) {
  showAboutDialog(
    context: context,
    applicationName: 'StudyFlow',
    applicationVersion: '1.0.0',
    applicationIcon: const AppLogo(size: 48),
    applicationLegalese: '© 2026 StudyFlow',
    children: const [
      SizedBox(height: AppSpacing.md),
      Text(
        'Aplikasi manajemen belajar: jadwal, tugas, materi, dan progres — '
        'offline-first.',
        style: TextStyle(
            color: AppColors.textSecondary, fontSize: 13, height: 1.4),
      ),
    ],
  );
}

/// Info jujur soal dukungan bahasa. Saat ini app hanya Bahasa Indonesia; bahasa
/// lain belum didukung karena seluruh string masih hard-coded (i18n menyusul).
void showLanguageInfo(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.language, color: AppColors.accent),
      title: const Text('Bahasa'),
      content: const Text(
        'Saat ini StudyFlow baru mendukung Bahasa Indonesia. '
        'Dukungan bahasa lain akan hadir di pembaruan mendatang.',
        style: TextStyle(
            color: AppColors.textSecondary, fontSize: 13, height: 1.5),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Mengerti'),
        ),
      ],
    ),
  );
}

/// Umpan balik konsisten untuk menu yang belum diimplementasi.
void showComingSoon(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('$feature akan segera hadir.'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}
