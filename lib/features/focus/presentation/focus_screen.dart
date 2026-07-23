import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/celebration_service.dart';
import '../../../shared_widgets/confetti_celebration.dart';
import '../../progress/presentation/widgets/progress_donut.dart';
import '../../tasks/domain/task.dart';
import '../domain/focus_stats.dart';
import '../domain/pomodoro_config.dart';
import '../focus_providers.dart';
import 'focus_settings_sheet.dart';
import 'focus_timer_controller.dart';

/// Layar Pomodoro / Focus Timer. Warna fase semantik (fokus=biru, jeda
/// pendek=hijau, jeda panjang=biru-info), indikator siklus, opsional kaitkan
/// dengan tugas, dan statistik hari ini.
class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen>
    with WidgetsBindingObserver {
  FocusPhase? _lastSeenPhase;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Sinkronisasi timer setelah kembali dari background (akurat wall-clock).
    if (state == AppLifecycleState.resumed) {
      ref.read(pomodoroTimerProvider.notifier).onAppResumed();
    }
  }

  void _maybeCelebrate(PomodoroTimerState s) {
    // Deteksi transisi fase fokus → jeda = satu pomodoro selesai (XP masuk).
    if (_lastSeenPhase == FocusPhase.focus &&
        (s.phase == FocusPhase.shortBreak ||
            s.phase == FocusPhase.longBreak)) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.phase == FocusPhase.longBreak
              ? '🎯 Sesi fokus selesai! Nikmati jeda panjangmu.'
              : '🎯 Sesi fokus selesai! Waktu istirahat sebentar.'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    }
    _lastSeenPhase = s.phase;
  }

  Color _phaseColor(FocusPhase p) => switch (p) {
        FocusPhase.focus => AppColors.accent,
        FocusPhase.shortBreak => AppColors.success,
        FocusPhase.longBreak => AppColors.info,
      };

  String _formatClock(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final timer = ref.watch(pomodoroTimerProvider);
    final config = ref.watch(pomodoroConfigProvider);

    // Sinkronisasi bila config berubah saat idle (agar tampilan durasi tepat).
    ref.listen<PomodoroConfig>(pomodoroConfigProvider, (prev, next) {
      if (timer.status == TimerStatus.idle && prev != next) {
        ref.read(pomodoroTimerProvider.notifier).reset();
      }
    });
    _maybeCelebrate(timer);

    final sessions = ref.watch(focusSessionListProvider);
    final now = DateTime.now();
    final countToday = focusCountToday(sessions, now);
    final minutesToday = focusMinutesToday(sessions, now);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fokus (Pomodoro)'),
        actions: [
          IconButton(
            tooltip: 'Pengaturan',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _openSettings(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Hero(phase: timer.phase, completedFocusCount:
                      timer.completedFocusCount, config: config),
                  const SizedBox(height: AppSpacing.xl),
                  _TimerRing(
                    timer: timer,
                    config: config,
                    phaseColor: _phaseColor(timer.phase),
                    formatClock: _formatClock,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _Controls(
                    timer: timer,
                    onStart: () => ref
                        .read(pomodoroTimerProvider.notifier)
                        .start(),
                    onPause: () => ref
                        .read(pomodoroTimerProvider.notifier)
                        .pause(),
                    onReset: () => ref
                        .read(pomodoroTimerProvider.notifier)
                        .reset(),
                    onSkip: () => ref
                        .read(pomodoroTimerProvider.notifier)
                        .skip(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _TaskPicker(timer: timer),
                  const SizedBox(height: AppSpacing.xl),
                  _TodayStats(countToday: countToday, minutesToday: minutesToday),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
            // Confetti saat sesi fokus selesai.
            const IgnorePointer(
              child: ConfettiCelebration(
                kinds: [CelebrationKind.focusComplete],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const FocusSettingsSheet(),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.phase,
    required this.completedFocusCount,
    required this.config,
  });

  final FocusPhase phase;
  final int completedFocusCount;
  final PomodoroConfig config;

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
              Icon(Icons.timer_outlined, color: Colors.white.withValues(alpha: 0.9)),
              const SizedBox(width: AppSpacing.sm),
              Text(
                phase == FocusPhase.focus ? 'Waktu Fokus' : 'Waktu Istirahat',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Konsentrasi penuh, tanpa gangguan. Selesaikan satu siklus '
            'untuk mendapat XP.',
            style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.md),
          _CycleDots(
            completed: completedFocusCount % config.cyclesBeforeLongBreak,
            total: config.cyclesBeforeLongBreak,
          ),
        ],
      ),
    );
  }
}

class _CycleDots extends StatelessWidget {
  const _CycleDots({required this.completed, required this.total});
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final filled = i < completed;
        return Container(
          width: 10,
          height: 10,
          margin: EdgeInsets.only(right: i == total - 1 ? 0 : 6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? Colors.white : Colors.white.withValues(alpha: 0.25),
          ),
        );
      }),
    );
  }
}

class _TimerRing extends StatelessWidget {
  const _TimerRing({
    required this.timer,
    required this.config,
    required this.phaseColor,
    required this.formatClock,
  });

  final PomodoroTimerState timer;
  final PomodoroConfig config;
  final Color phaseColor;
  final String Function(int) formatClock;

  @override
  Widget build(BuildContext context) {
    final progress = timer.progressFor(timer.phase, config);
    return Center(
      child: ProgressDonut(
        progress: progress,
        size: 260,
        strokeWidth: 18,
        progressColor: phaseColor,
        trackColor: AppColors.surfaceBorder,
        center: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              timer.phase.label,
              style: TextStyle(
                color: phaseColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              formatClock(timer.remainingSeconds),
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              timer.status == TimerStatus.idle
                  ? 'Tekan mulai untuk fokus'
                  : timer.status == TimerStatus.paused
                      ? 'Dijeda'
                      : 'Sedang berjalan…',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.timer,
    required this.onStart,
    required this.onPause,
    required this.onReset,
    required this.onSkip,
  });

  final PomodoroTimerState timer;
  final VoidCallback onStart, onPause, onReset, onSkip;

  @override
  Widget build(BuildContext context) {
    final isRunning = timer.isRunning;
    final isIdle = timer.status == TimerStatus.idle;
    return Row(
      children: [
        if (!isIdle)
          _CircleIcon(
            icon: Icons.restart_alt_rounded,
            tooltip: 'Reset',
            onTap: onReset,
          ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: FilledButton(
            onPressed: isRunning ? onPause : onStart,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 26),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  isRunning
                      ? 'Jeda'
                      : (isIdle ? 'Mulai Fokus' : 'Lanjutkan'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        if (!isIdle)
          _CircleIcon(
            icon: Icons.skip_next_rounded,
            tooltip: 'Lewati',
            onTap: onSkip,
          ),
      ],
    );
  }
}

class _CircleIcon extends StatelessWidget {
  const _CircleIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        shape: CircleBorder(
          side: BorderSide(color: AppColors.surfaceBorder),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(icon, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _TaskPicker extends ConsumerWidget {
  const _TaskPicker({required this.timer});
  final PomodoroTimerState timer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(focusableTasksProvider);
    final selectedId = timer.sessionTaskId;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.flag_outlined, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                value: selectedId,
                isExpanded: true,
                hint: const Text('Fokus pada tugas (opsional)',
                    style: TextStyle(fontSize: 14)),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Tanpa tugas tertentu',
                        style: TextStyle(fontSize: 14)),
                  ),
                  ...tasks.map((t) => DropdownMenuItem<String?>(
                        value: t.id,
                        child: Text(t.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14)),
                      )),
                ],
                onChanged: (id) {
                  final Task? task =
                      tasks.where((t) => t.id == id).cast<Task?>().firstOrNull;
                  ref
                      .read(pomodoroTimerProvider.notifier)
                      .setTask(id, task?.title);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayStats extends StatelessWidget {
  const _TodayStats({required this.countToday, required this.minutesToday});
  final int countToday;
  final int minutesToday;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.check_circle_outline,
            value: '$countToday',
            label: 'Sesi hari ini',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            icon: Icons.access_time_rounded,
            value: '${minutesToday}m',
            label: 'Menit fokus',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            icon: Icons.bolt_rounded,
            value: '${countToday * xpPerFocusSession}',
            label: 'XP hari ini',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final String value;
  final String label;

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
        children: [
          Icon(icon, color: AppColors.accent, size: 20),
          const SizedBox(height: AppSpacing.xs),
          Text(value,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11, color: AppColors.textSecondary, height: 1.2)),
        ],
      ),
    );
  }
}
