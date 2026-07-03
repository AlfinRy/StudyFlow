import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared_widgets/empty_state.dart';
import '../../../shared_widgets/navy_hero_card.dart';
import '../../../shared_widgets/section_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateLabel =
        '${_weekday(now.weekday)}, ${now.day} ${_month(now.month)} ${now.year}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        96,
      ),
      children: [
        NavyHeroCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLabel,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Halo, Andi Pratama!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Kamu punya 3 jadwal dan 2 tugas hari ini. Semangat! 💪',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const Divider(height: AppSpacing.xl, color: Colors.white24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Target Mingguan',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '85%',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 56,
                    width: 56,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: 0.85,
                          strokeWidth: 6,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.accent),
                        ),
                        const Center(
                          child: Icon(Icons.check_circle,
                              color: Colors.white, size: 22),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Jadwal Hari Ini'),
        const SizedBox(height: AppSpacing.sm),
        const EmptyState(
          icon: Icons.event_available,
          title: 'Belum ada jadwal hari ini',
          subtitle: 'Tambah jadwal dari tab Jadwal untuk melihatnya di Beranda.',
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionHeader(title: 'Tugas Mendatang'),
        const SizedBox(height: AppSpacing.sm),
        const EmptyState(
          icon: Icons.task_outlined,
          title: 'Belum ada tugas mendatang',
          subtitle: 'Tambah tugas dari tab Tugas untuk melihatnya di sini.',
        ),
      ],
    );
  }

  static String _weekday(int i) => const [
        'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu',
      ][(i - 1) % 7];

  static String _month(int i) => const [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli',
        'Agustus', 'September', 'Oktober', 'November', 'Desember',
      ][(i - 1) % 12];
}
