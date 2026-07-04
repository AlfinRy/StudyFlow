import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared_widgets/confirm_delete_dialog.dart';
import '../../../shared_widgets/empty_state.dart';
import '../../../shared_widgets/navy_hero_card.dart';
import '../domain/task.dart';
import '../task_providers.dart';
import 'task_form_screen.dart';
import 'widgets/task_card.dart';

/// Halaman To-Do List / Tugas (PRD §5.3, UI_DESIGN.md §6).
///
/// Filter: Semua / Berjalan / Selesai. Daftar sudah ter-sort by deadline
/// terdekat (lihat TaskRepository.getAll). Toggle selesai, edit, dan hapus
/// reaktif lewat [taskListProvider].
class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  int _filter = 0; // 0=Semua, 1=Berjalan, 2=Selesai
  static const _filters = ['Semua', 'Berjalan', 'Selesai'];

  void _openForm([Task? task]) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TaskFormScreen(task: task)),
    );
  }

  Future<void> _confirmDelete(Task task) async {
    final ok = await showConfirmDeleteDialog(
      context,
      title: 'Hapus tugas?',
      message: 'Tugas "${task.title}" akan dihapus permanen.',
    );
    if (ok) {
      await ref.read(taskListProvider.notifier).remove(task.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tugas dihapus.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  List<Task> _applyFilter(List<Task> all) {
    switch (_filter) {
      case 1:
        return all.where((t) => !t.isDone).toList();
      case 2:
        return all.where((t) => t.isDone).toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(taskListProvider);
    final visible = _applyFilter(all);

    final total = all.length;
    final done = all.where((t) => t.isDone).length;
    final active = total - done;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
      children: [
        NavyHeroCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tetap Fokus',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                active == 0
                    ? 'Mantap! Tidak ada tugas tertunda. 🎉'
                    : 'Kamu punya $active tugas yang perlu dikerjakan.',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        _FilterTabs(
          labels: _filters,
          selected: _filter,
          onSelect: (i) => setState(() => _filter = i),
        ),
        const SizedBox(height: AppSpacing.lg),

        if (visible.isEmpty)
          EmptyState(
            icon: Icons.task_outlined,
            title: _emptyTitle(),
            subtitle: 'Tambah tugas menggunakan tombol + di bawah.',
          )
        else
          Column(
            children: [
              for (final t in visible)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: TaskCard(
                    task: t,
                    onToggle: () =>
                        ref.read(taskListProvider.notifier).toggleDone(t),
                    onEdit: () => _openForm(t),
                    onDelete: () => _confirmDelete(t),
                  ),
                ),
            ],
          ),

        const SizedBox(height: AppSpacing.xl),
        _StatsRow(total: total, done: done, active: active),
      ],
    );
  }

  String _emptyTitle() {
    switch (_filter) {
      case 1:
        return 'Tidak ada tugas berjalan';
      case 2:
        return 'Belum ada tugas selesai';
      default:
        return 'Belum ada tugas';
    }
  }
}

/// Segmented filter tabs (UI_DESIGN.md §6). Stateless, state dipegang layar.
class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final active = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelect(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: active ? AppColors.accent : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.cardRadius - 4),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    color: active ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Dua kartu statistik bawah (UI_DESIGN.md §6). Streak/poin (gamifikasi)
/// sengaja tidak difabrikasi — menyusul Fase 8 (Progres) yang punya sumber
/// datanya. Di sini hanya metrik real dari data tugas.
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.total, required this.done, required this.active});
  final int total;
  final int done;
  final int active;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0.0 : done / total;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.checklist_rounded,
            iconColor: AppColors.accent,
            title: 'Statistik',
            value: '$done/$total Tugas selesai',
            progress: percent,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatCard(
            icon: Icons.flash_on_rounded,
            iconColor: AppColors.warning,
            title: 'Tugas Aktif',
            value: '$active tugas berjalan',
            progress: null,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.progress,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final double? progress; // null = no progress bar

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation<Color>(iconColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
