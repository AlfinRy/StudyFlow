import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Kartu pencapaian yang dapat di-render menjadi gambar & dibagikan (Tier 4
/// roadmap). **Selalu memakai palet navy brand** (bukan theme-aware) agar tampil
/// konsisten di mana pun kartu dibagikan (IG/WA). Tangkap via `RepaintBoundary`.
class AchievementShareCard extends StatelessWidget {
  const AchievementShareCard({
    super.key,
    required this.levelIndex,
    required this.levelTitle,
    required this.xp,
    required this.streak,
    required this.tasksDone,
    this.userName,
  });

  final int levelIndex;
  final String levelTitle;
  final int xp;
  final int streak;
  final int tasksDone;
  final String? userName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
      decoration: const BoxDecoration(
        gradient: AppColors.navyGradient,
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Wordmark
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.auto_stories_rounded,
                  color: AppColors.accent, size: 18),
              SizedBox(width: 6),
              Text(
                'STUDYFLOW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Level badge (lingkaran)
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.45),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lv $levelIndex',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const Text(
                  'LEVEL',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Text(
            levelTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          if ((userName ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              userName!,
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ],
          const SizedBox(height: 22),

          // Statistik
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                _Stat(value: '$xp', label: 'XP'),
                _divider(),
                _Stat(value: '$streak', label: 'Streak'),
                _divider(),
                _Stat(value: '$tasksDone', label: 'Tugas'),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Belajar lebih teratur,\nrajin, & menyenangkan ✨',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        height: 26,
        width: 1,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: Colors.white.withValues(alpha: 0.15),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
