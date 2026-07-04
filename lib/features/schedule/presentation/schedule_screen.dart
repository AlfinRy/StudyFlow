import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/date_labels.dart';
import '../../../shared_widgets/confirm_delete_dialog.dart';
import '../../../shared_widgets/empty_state.dart';
import '../../../shared_widgets/navy_hero_card.dart';
import '../../tasks/task_providers.dart';
import '../domain/schedule.dart';
import '../schedule_providers.dart';
import 'schedule_form_screen.dart';
import 'widgets/schedule_card.dart';
import 'widgets/schedule_date_selector.dart';

/// Halaman Jadwal Belajar (PRD §5.2, UI_DESIGN.md §5).
///
/// Jadwal bersifat mingguan (berulang per `dayOfWeek`). Date selector menentukan
/// weekday mana yang ditampilkan; data diambil dari Hive secara reaktif lewat
/// [scheduleListProvider].
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  late DateTime _selected;

  @override
  void initState() {
    super.initState();
    _selected = DateTime.now();
  }

  void _openForm([Schedule? schedule]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ScheduleFormScreen(schedule: schedule),
        fullscreenDialog: false,
      ),
    );
  }

  Future<bool> _confirmDelete(Schedule schedule) async {
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Hapus jadwal?',
      message: 'Jadwal "${schedule.title}" akan dihapus permanen.',
    );
    if (confirmed) {
      await ref.read(scheduleListProvider.notifier).remove(schedule.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Jadwal dihapus.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthLabel = '${idnMonth(now.month)} ${now.year}';

    final allSchedules = ref.watch(scheduleListProvider);
    final forSelectedDay = allSchedules
        .where((s) => s.dayOfWeek == _selected.weekday)
        .toList();

    final isToday = _selected.year == now.year &&
        _selected.month == now.month &&
        _selected.day == now.day;
    final sectionTitle = isToday
        ? 'Jadwal Hari Ini'
        : 'Jadwal ${idnWeekday(_selected.weekday)}';

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
        const SizedBox(height: AppSpacing.lg),

        ScheduleDateSelector(
          selected: _selected,
          onSelect: (d) => setState(() => _selected = d),
        ),
        const SizedBox(height: AppSpacing.xl),

        Text(
          sectionTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        if (forSelectedDay.isEmpty)
          EmptyState(
            icon: Icons.event_available,
            title: isToday
                ? 'Belum ada jadwal hari ini'
                : 'Belum ada jadwal ${idnWeekday(_selected.weekday)}',
            subtitle: 'Mulai atur jadwal belajarmu agar lebih terorganisir.',
            action: FilledButton.icon(
              onPressed: () => _openForm(),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Jadwal'),
            ),
          )
        else
          Column(
            children: forSelectedDay.map((s) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Dismissible(
                  key: ValueKey(s.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.danger),
                  ),
                  confirmDismiss: (_) => _confirmDelete(s),
                  child: ScheduleCard(
                    schedule: s,
                    onTap: () => _openForm(s),
                  ),
                ),
              );
            }).toList(),
          ),

        const SizedBox(height: AppSpacing.xl),
        const _WeeklyProgressCard(),
      ],
    );
  }
}

/// Kartu ringkasan progres (UI_DESIGN.md §5). Membaca data tugas lewat provider
/// yang sudah ada — forward-compatible dengan Fase 8 (Progres).
class _WeeklyProgressCard extends ConsumerWidget {
  const _WeeklyProgressCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskListProvider);
    final total = tasks.length;
    final done = tasks.where((t) => t.isDone).length;
    final percent = total == 0 ? 0.0 : done / total;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Progres Belajar',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(percent * 100).round()}% Selesai',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 8,
                    backgroundColor: AppColors.background,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.accent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.trending_up_rounded,
                color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}
