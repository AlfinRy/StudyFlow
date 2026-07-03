import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../auth/auth_providers.dart';
import '../../../shared_widgets/empty_state.dart';
import '../../../shared_widgets/navy_hero_card.dart';
import '../../../shared_widgets/section_header.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final name =
        (user?.name.isNotEmpty ?? false) ? user!.name : 'Pengguna';

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
              Text(
                'Halo, $name!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              const Text(
                'Kelola jadwal dan tugasmu agar tetap produktif hari ini. 💪',
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
                          '0%',
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
                      children: const [
                        CircularProgressIndicator(
                          value: 0,
                          strokeWidth: 6,
                          backgroundColor: Colors.white24,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.accent),
                        ),
                        Center(
                          child: Icon(Icons.school_outlined,
                              color: Colors.white70, size: 22),
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
