import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared_widgets/app_logo.dart';

/// Layar splash singkat (UI_DESIGN.md §2) — ditampilkan saat state auth masih
/// dimuat untuk menghindari kedipan halaman login.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.navyGradient),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          AppLogo(size: 140),
          SizedBox(height: AppSpacing.md),
          Text(
            'StudyFlow',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Belajar lebih efektif, terorganisir, dan menyenangkan',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: 24,
            height: 24,
            child:
                CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
