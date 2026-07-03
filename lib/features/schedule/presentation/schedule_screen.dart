import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../shared_widgets/empty_state.dart';
import '../../../shared_widgets/navy_hero_card.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthLabel = '${_month(now.month)} ${now.year}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
      children: [
        NavyHeroCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Jadwal Belajar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                monthLabel,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const EmptyState(
          icon: Icons.menu_book_outlined,
          title: 'Belum ada jadwal hari ini',
          subtitle: 'Mulai atur jadwal belajarmu agar lebih terorganisir.',
          action: null, // FAB on the shell handles "Tambah Jadwal" for now.
        ),
      ],
    );
  }

  static String _month(int i) => const [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli',
        'Agustus', 'September', 'Oktober', 'November', 'Desember',
      ][(i - 1) % 12];
}
