import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/date_labels.dart';
import '../../../shared_widgets/navy_hero_card.dart';
import '../../../shared_widgets/section_header.dart';
import '../../auth/auth_providers.dart';
import '../../schedule/presentation/widgets/schedule_card.dart';
import '../../schedule/schedule_providers.dart';
import '../../materials/material_providers.dart';
import '../../materials/presentation/materials_screen.dart';
import '../../materials/presentation/widgets/material_card.dart';
import '../../tasks/presentation/widgets/task_card.dart';
import '../../tasks/task_providers.dart';
import '../../shell/shell_providers.dart';

/// Beranda / Dashboard (PRD §5.5 dashboard, UI_DESIGN.md §4). Mengagregasi:
/// sapaan + progres tugas, jadwal hari ini, dan tugas mendatang — semua dari
/// data lokal (Hive) yang reaktif.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Maks item yang ditampilkan per section di dashboard.
  static const _previewCount = 3;

  void _goToTab(WidgetRef ref, int tab) =>
      ref.read(activeTabProvider.notifier).state = tab;

  void _openMaterials(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MaterialsScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final name = (user?.name.isNotEmpty ?? false) ? user!.name : 'Pengguna';

    final now = DateTime.now();
    final dateLabel =
        '${idnWeekday(now.weekday)}, ${now.day} ${idnMonth(now.month)} ${now.year}';

    final todaySchedules = ref.watch(schedulesForTodayProvider);
    final incomplete = ref.watch(incompleteTasksProvider);
    final allTasks = ref.watch(taskListProvider);

    final total = allTasks.length;
    final done = total - incomplete.length;
    final percent = total == 0 ? 0.0 : done / total;

    final upcoming = incomplete.take(_previewCount).toList();

    final materials = ref.watch(materialListProvider);
    final recentMaterials = materials.take(_previewCount).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
      children: [
        _HeroCard(
          dateLabel: dateLabel,
          name: name,
          scheduleCount: todaySchedules.length,
          taskCount: incomplete.length,
          percent: percent,
          done: done,
          total: total,
        ),
        const SizedBox(height: AppSpacing.xl),

        // Jadwal hari ini
        SectionHeader(
          title: 'Jadwal Hari Ini',
          onSeeAll: todaySchedules.isNotEmpty
              ? () => _goToTab(ref, 1)
              : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (todaySchedules.isEmpty)
          const _SectionHint(
              icon: Icons.event_available,
              text: 'Belum ada jadwal hari ini.')
        else
          Column(
            children: [
              for (final s in todaySchedules.take(_previewCount))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: ScheduleCard(
                    schedule: s,
                    onTap: () => _goToTab(ref, 1),
                  ),
                ),
            ],
          ),
        const SizedBox(height: AppSpacing.xl),

        // Tugas mendatang
        SectionHeader(
          title: 'Tugas Mendatang',
          onSeeAll: incomplete.isNotEmpty ? () => _goToTab(ref, 2) : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (upcoming.isEmpty)
          const _SectionHint(
              icon: Icons.task_outlined, text: 'Tidak ada tugas tertunda. 🎉')
        else
          Column(
            children: [
              for (final t in upcoming)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: TaskCard(
                    task: t,
                    onToggle: () =>
                        ref.read(taskListProvider.notifier).toggleDone(t),
                    onEdit: () => _goToTab(ref, 2),
                  ),
                ),
            ],
          ),
        const SizedBox(height: AppSpacing.xl),

        // Materi pembelajaran (akses via shortcut — UI_DESIGN.md §9.1)
        SectionHeader(
          title: 'Materi Pembelajaran',
          onSeeAll:
              materials.isNotEmpty ? () => _openMaterials(context) : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (recentMaterials.isEmpty)
          const _SectionHint(
              icon: Icons.folder_open_rounded,
              text: 'Belum ada materi tersimpan.')
        else
          Column(
            children: [
              for (final m in recentMaterials)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: GestureDetector(
                    onTap: () => _openMaterials(context),
                    child: MaterialCard(material: m),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// Hero card navy: tanggal, sapaan, motivasi dinamis, ringkasan progres tugas
/// dengan mini donut (UI_DESIGN.md §4).
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.dateLabel,
    required this.name,
    required this.scheduleCount,
    required this.taskCount,
    required this.percent,
    required this.done,
    required this.total,
  });

  final String dateLabel;
  final String name;
  final int scheduleCount;
  final int taskCount;
  final double percent;
  final int done;
  final int total;

  String get _motivasi {
    if (scheduleCount == 0 && taskCount == 0) {
      return 'Tidak ada jadwal maupun tugas mendesak. Manfaatkan waktumu! ✨';
    }
    if (scheduleCount > 0) {
      return 'Kamu punya $scheduleCount jadwal'
          '${taskCount > 0 ? ' dan $taskCount tugas' : ''} hari ini.';
    }
    return 'Kamu punya $taskCount tugas yang perlu dikerjakan.';
  }

  @override
  Widget build(BuildContext context) {
    return NavyHeroCard(
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
          Text(
            _motivasi,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const Divider(height: AppSpacing.xl, color: Colors.white24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Progres Tugas',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(percent * 100).round()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$done dari $total tugas selesai',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 64,
                width: 64,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: total == 0 ? 0 : percent,
                      strokeWidth: 6,
                      backgroundColor: Colors.white24,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.accent),
                    ),
                    Center(
                      child: total == 0
                          ? const Icon(Icons.event_note_rounded,
                              color: Colors.white70, size: 22)
                          : Text(
                              '${(percent * 100).round()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Petunjuk kosong ringkas untuk section dashboard (lebih kompak dari
/// EmptyState agar dua section tidak terlalu berat).
class _SectionHint extends StatelessWidget {
  const _SectionHint({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
