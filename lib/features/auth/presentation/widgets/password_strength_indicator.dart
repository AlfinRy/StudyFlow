import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/security/auth_validators.dart';

/// Indikator visual kekuatan kata sandi (4 segmen + label).
/// Hanya tampil saat user mulai mengetik (dikendalikan layar pemanggil).
class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({super.key, required this.strength});

  final PasswordStrength strength;

  static const _labels = ['Sangat lemah', 'Lemah', 'Cukup', 'Kuat', 'Sangat kuat'];
  static const _colors = [
    AppColors.danger,
    AppColors.danger,
    AppColors.warning,
    AppColors.info,
    AppColors.success,
  ];

  @override
  Widget build(BuildContext context) {
    final score = strength.score;
    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(4, (i) {
              final filled = i < score;
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i == 3 ? 0 : 4),
                  decoration: BoxDecoration(
                    color: filled
                        ? _colors[score]
                        : AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _labels[score],
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _colors[score],
          ),
        ),
      ],
    );
  }
}
