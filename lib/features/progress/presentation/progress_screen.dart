import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/date_labels.dart';
import '../../../shared_widgets/navy_hero_card.dart';
import '../../../shared_widgets/section_header.dart';
import '../../schedule/schedule_providers.dart';
import '../../tasks/task_providers.dart';
import '../domain/gamification.dart';
import '../domain/progress_stats.dart';
import 'widgets/progress_donut.dart';

/// Halaman Progres Belajar (PRD §5.5, UI_DESIGN.md §7). Semua angka diturunkan
/// dari data nyata (tugas & jadwal lokal) — tidak ada nilai difabrikasi.
///
/// Catatan: sinkronisasi ringkasan ke Firestore (`progress/{uid}`, PRD §5.5)
/// belum aktif karena Firebase belum dikonfigurasi (menyusul Fase 9). Seluruh
/// perhitungan di bawah sudah akurat dari sumber lokal dan reaktif.
class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  /// 0 = Mingguan, 1 = Bulanan. Mengontrol window donut + 2 kartu statistik.
  int _window = 0;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final tasks = ref.watch(taskListProvider);
    final schedules = ref.watch(scheduleListProvider);

    final start = _window == 0 ? weekStart(now) : monthStart(now);
    final end = _window == 0 ? weekEnd(now) : monthEnd(now);
    final windowed = summaryInWindow(tasks, start, end);
    final overall = summaryAll(tasks);
    final weekly = weeklyCompletions(tasks, now);
    final streak = completionStreak(tasks, now);
    final scheduledMin = scheduledMinutesPerWeek(schedules);

    final doneCount = overall.done;
    final xp = doneCount * xpPerTask;
    final level = levelForXp(xp);
    final next = nextLevel(level);
    final levelProg = levelProgress(xp);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
      children: [
        _Hero(windowLabel: _window == 0 ? 'Mingguan' : 'Bulanan'),
        const SizedBox(height: AppSpacing.lg),

        _WindowTabs(
          selected: _window,
          onSelect: (i) => setState(() => _window = i),
        ),
        const SizedBox(height: AppSpacing.xl),

        // Donut + 2 kartu statistik (windowed)
        _DonutRow(summary: windowed, scheduledMinutes: scheduledMin),
        const SizedBox(height: AppSpacing.xl),

        _CapaianCard(
          overall: overall,
          streak: streak,
        ),
        const SizedBox(height: AppSpacing.xl),

        // Aktivitas mingguan (heatmap)
        const SectionHeader(title: 'Aktivitas Mingguan'),
        const SizedBox(height: AppSpacing.sm),
        _WeeklyHeatmap(days: weekly),
        const SizedBox(height: AppSpacing.xl),

        // Streak
        _StreakCard(streak: streak),
        const SizedBox(height: AppSpacing.xl),

        // Pencapaian (milestone)
        SectionHeader(
          title: 'Pencapaian',
          onSeeAll: () => _toast('Pencapaian lengkap menyusul.'),
        ),
        const SizedBox(height: AppSpacing.sm),
        _MilestoneList(doneCount: doneCount, streak: streak, tasks: tasks, now: now),
        const SizedBox(height: AppSpacing.xl),

        // Level / XP
        _LevelCard(
          level: level,
          next: next,
          xp: xp,
          progress: levelProg,
        ),
      ],
    );
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header & tabs
// ---------------------------------------------------------------------------

class _Hero extends StatelessWidget {
  const _Hero({required this.windowLabel});
  final String windowLabel;

  @override
  Widget build(BuildContext context) {
    return NavyHeroCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progres Belajar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pantau capaian belajarmu periode $windowLabel.',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _WindowTabs extends StatelessWidget {
  const _WindowTabs({required this.selected, required this.onSelect});
  final int selected;
  final ValueChanged<int> onSelect;

  static const _labels = ['Mingguan', 'Bulanan'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        children: List.generate(_labels.length, (i) {
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
                  _labels[i],
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

// ---------------------------------------------------------------------------
// Donut + statistik
// ---------------------------------------------------------------------------

class _DonutRow extends StatelessWidget {
  const _DonutRow({required this.summary, required this.scheduledMinutes});
  final ProgressSummary summary;
  final int scheduledMinutes;

  String get _hoursLabel {
    final h = scheduledMinutes ~/ 60;
    final m = scheduledMinutes % 60;
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}j';
    return '${h}j ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final percent = (summary.percent * 100).round();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ProgressDonut(
          progress: summary.percent,
          center: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                summary.total == 0 ? '—' : '$percent%',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const Text(
                'SELESAI',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            children: [
              _StatCard(
                icon: Icons.checklist_rounded,
                iconColor: AppColors.accent,
                label: 'Tugas Selesai',
                value: '${summary.done} dari ${summary.total}',
              ),
              const SizedBox(height: AppSpacing.sm),
              _StatCard(
                icon: Icons.schedule_rounded,
                iconColor: AppColors.warning,
                label: 'Waktu Belajar',
                value: summary.total == 0
                    ? '—'
                    : '$_hoursLabel/mgg',
                hint: 'Terjadwal',
              ),
            ],
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
    required this.label,
    required this.value,
    this.hint,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hint == null ? label : '$label · $hint',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Capaian minggu ini
// ---------------------------------------------------------------------------

class _CapaianCard extends StatelessWidget {
  const _CapaianCard({
    required this.overall,
    required this.streak,
  });

  final ProgressSummary overall;
  final int streak;

  String get _insight {
    if (overall.total == 0) {
      return 'Belum ada tugas. Tambahkan tugas untuk mulai melacak progres belajarmu.';
    }
    if (overall.done == 0) {
      return 'Kamu punya ${overall.total} tugas. Ayo selesaikan tugas pertamamu hari ini! 🚀';
    }
    final pct = (overall.percent * 100).round();
    final streakText = streak >= 2 ? ' Streak $streak hari beruntun, pertahankan!' : '';
    return 'Kamu telah menyelesaikan ${overall.done} dari ${overall.total} tugas '
        '($pct%).$streakText';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FF),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.insights_rounded, color: AppColors.accentDark, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Capaian',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _insight,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Heatmap mingguan
// ---------------------------------------------------------------------------

class _WeeklyHeatmap extends StatelessWidget {
  const _WeeklyHeatmap({required this.days});
  final List<DailyCompletion> days;

  @override
  Widget build(BuildContext context) {
    final maxCount = days.fold<int>(0, (a, d) => a > d.count ? a : d.count);
    return Row(
      children: [
        for (final d in days) ...[
          Expanded(child: _DayChip(day: d, intensity: maxCount == 0 ? 0 : d.count / maxCount)),
          if (d != days.last) const SizedBox(width: AppSpacing.xs),
        ],
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({required this.day, required this.intensity});
  final DailyCompletion day;
  final double intensity; // 0..1 relatif terhadap hari tersibuk minggu ini

  @override
  Widget build(BuildContext context) {
    final hasActivity = day.count > 0;
    final bg = hasActivity
        ? AppColors.accent.withValues(alpha: 0.18 + 0.55 * intensity)
        : AppColors.background;
    final fg = hasActivity ? AppColors.accentDark : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(
          color: day.isToday
              ? AppColors.accent
              : (hasActivity ? AppColors.accent.withValues(alpha: 0.3) : AppColors.surfaceBorder),
          width: day.isToday ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            day.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${day.date.day}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${day.count}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: hasActivity ? AppColors.accentDark : AppColors.surfaceBorder,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Streak
// ---------------------------------------------------------------------------

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak});
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFFB923C)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department_rounded,
              color: Colors.white, size: 30),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak hari',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'Streak belajar beruntun',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            streak >= 7 ? '🔥' : '⚡',
            style: const TextStyle(fontSize: 22),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Milestone
// ---------------------------------------------------------------------------

class _MilestoneDef {
  const _MilestoneDef({
    required this.icon,
    required this.title,
    required this.description,
    required this.kind,
    required this.threshold,
  });
  final IconData icon;
  final String title;
  final String description;
  final MilestoneKind kind;
  final int threshold;
}

const _milestones = <_MilestoneDef>[
  _MilestoneDef(
    icon: Icons.flag_rounded,
    title: 'Langkah Pertama',
    description: 'Selesaikan 1 tugas',
    kind: MilestoneKind.taskCount,
    threshold: 1,
  ),
  _MilestoneDef(
    icon: Icons.looks_5_rounded,
    title: 'Lima Sehati',
    description: 'Selesaikan 5 tugas',
    kind: MilestoneKind.taskCount,
    threshold: 5,
  ),
  _MilestoneDef(
    icon: Icons.event_repeat_rounded,
    title: 'Konsisten',
    description: 'Streak 3 hari berturut',
    kind: MilestoneKind.streak,
    threshold: 3,
  ),
  _MilestoneDef(
    icon: Icons.workspace_premium_rounded,
    title: 'Sepuluh Tuntas',
    description: 'Selesaikan 10 tugas',
    kind: MilestoneKind.taskCount,
    threshold: 10,
  ),
  _MilestoneDef(
    icon: Icons.emoji_events_rounded,
    title: 'Tak Terhentikan',
    description: 'Streak 7 hari berturut',
    kind: MilestoneKind.streak,
    threshold: 7,
  ),
];

class _MilestoneList extends StatelessWidget {
  const _MilestoneList({
    required this.doneCount,
    required this.streak,
    required this.tasks,
    required this.now,
  });

  final int doneCount;
  final int streak;
  final List tasks; // List<Task> (dynamic untuk hindari import ulang)
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    // Tanggal completion terurut naik, untuk label relatif milestone tugas.
    final completionDates = tasks
        .where((t) => t.completedAt != null)
        .map<DateTime>((t) => t.completedAt as DateTime)
        .toList()
      ..sort();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < _milestones.length; i++) ...[
            _MilestoneTile(
              def: _milestones[i],
              unlocked: milestoneUnlocked(
                _milestones[i].kind,
                _milestones[i].threshold,
                doneCount: doneCount,
                streak: streak,
              ),
              reachedAt: _milestones[i].kind == MilestoneKind.taskCount
                  ? taskMilestoneReachedAt(
                      _milestones[i].threshold, completionDates)
                  : null,
              now: now,
            ),
            if (i < _milestones.length - 1)
              const Divider(height: 1, color: AppColors.surfaceBorder, indent: 12),
          ],
        ],
      ),
    );
  }
}

class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({
    required this.def,
    required this.unlocked,
    required this.reachedAt,
    required this.now,
  });

  final _MilestoneDef def;
  final bool unlocked;
  final DateTime? reachedAt;
  final DateTime now;

  String _relativeLabel() {
    final d = reachedAt;
    if (d == null) return 'Tercapai';
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(d.year, d.month, d.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    if (diff < 7) return '$diff hari lalu';
    return '${d.day} ${idnShortMonth(d.month)}';
  }

  @override
  Widget build(BuildContext context) {
    final color = unlocked ? AppColors.warning : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: unlocked
                  ? AppColors.warning.withValues(alpha: 0.15)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(AppSpacing.md),
            ),
            child: Icon(
              unlocked ? def.icon : Icons.lock_outline_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  def.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: unlocked
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  def.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            unlocked ? _relativeLabel() : def.description.contains('Streak')
                ? 'Streak ${def.threshold}'
                : '${def.threshold} tugas',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: unlocked ? AppColors.success : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Level / XP
// ---------------------------------------------------------------------------

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.next,
    required this.xp,
    required this.progress,
  });

  final StudyLevel level;
  final StudyLevel? next;
  final int xp;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.navyGradient,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${level.index}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level ${level.index} · ${level.title}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      next == null
                          ? 'Kamu sudah di level tertinggi! 🎉'
                          : 'Menuju level berikutnya: ${next!.title}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            next == null ? '$xp XP' : '$xp / ${next!.minXp} XP',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
