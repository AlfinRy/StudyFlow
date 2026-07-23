import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/celebration_service.dart';
import '../domain/focus_session.dart';
import '../domain/pomodoro_config.dart';
import '../focus_providers.dart';

/// Status mesin timer.
enum TimerStatus { idle, running, paused }

/// Snapshot reaktif dari timer.
class PomodoroTimerState {
  const PomodoroTimerState({
    required this.phase,
    required this.status,
    required this.remainingSeconds,
    required this.completedFocusCount,
    this.sessionTaskId,
    this.sessionTaskTitle,
  });

  final FocusPhase phase;
  final TimerStatus status;
  final int remainingSeconds;
  final int completedFocusCount;

  /// Tugas yang dikaitkan dengan sesi fokus berjalan (boleh null).
  final String? sessionTaskId;
  final String? sessionTaskTitle;

  bool get isRunning => status == TimerStatus.running;

  /// Persentase progres fase (0.0–1.0) untuk indikator lingkaran.
  double progressFor(FocusPhase phase, PomodoroConfig config) {
    final total = config.durationSeconds(phase);
    if (total <= 0) return 0;
    return 1 - (remainingSeconds / total).clamp(0.0, 1.0);
  }

  PomodoroTimerState copyWith({
    FocusPhase? phase,
    TimerStatus? status,
    int? remainingSeconds,
    int? completedFocusCount,
    String? sessionTaskId,
    String? sessionTaskTitle,
  }) {
    return PomodoroTimerState(
      phase: phase ?? this.phase,
      status: status ?? this.status,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      completedFocusCount:
          completedFocusCount ?? this.completedFocusCount,
      sessionTaskId: sessionTaskId ?? this.sessionTaskId,
      sessionTaskTitle: sessionTaskTitle ?? this.sessionTaskTitle,
    );
  }
}

/// Controller Pomodoro: mesin status fase dengan timer yang **tahan suspend
/// background** — sisa waktu dihitung dari wall-clock target (`_phaseEndAt`),
/// bukan sekadar decrement, sehingga akurat walau app di-background.
class PomodoroTimerController extends StateNotifier<PomodoroTimerState> {
  PomodoroTimerController(this._ref, PomodoroConfig initialConfig)
      : super(PomodoroTimerState(
          phase: FocusPhase.focus,
          status: TimerStatus.idle,
          remainingSeconds:
              initialConfig.durationSeconds(FocusPhase.focus),
          completedFocusCount: 0,
        ));

  final Ref _ref;

  Timer? _timer;
  DateTime? _phaseEndAt; // target wall-clock akhir fase (absolut)

  PomodoroConfig get _config => _ref.read(pomodoroConfigProvider);

  void setTask(String? id, String? title) {
    state = state.copyWith(sessionTaskId: id, sessionTaskTitle: title);
  }

  /// Mulai / lanjutkan. Dari idle → fase fokus baru; dari paused → lanjut sisa.
  void start() {
    if (state.isRunning) return;
    final now = DateTime.now();
    if (state.status == TimerStatus.idle) {
      // Sesi baru: reset ke fase fokus.
      _beginPhase(FocusPhase.focus, completedFocusCount: 0, startAt: now);
    } else {
      // Lanjut fase yang dijeda: hitung ulang target dari sisa detik.
      _phaseEndAt = now.add(Duration(seconds: state.remainingSeconds));
      state = state.copyWith(status: TimerStatus.running);
      _startTicking();
    }
  }

  void pause() {
    if (!state.isRunning) return;
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(status: TimerStatus.paused);
  }

  /// Berhenti total & kembali ke idle (fase fokus penuh, hitungan siklus 0).
  void reset() {
    _timer?.cancel();
    _timer = null;
    _phaseEndAt = null;
    state = PomodoroTimerState(
      phase: FocusPhase.focus,
      status: TimerStatus.idle,
      remainingSeconds: _config.durationSeconds(FocusPhase.focus),
      completedFocusCount: 0,
      sessionTaskId: state.sessionTaskId,
      sessionTaskTitle: state.sessionTaskTitle,
    );
  }

  /// Lewati fase saat ini tanpa memberi hadiah (focus tidak dapat XP).
  void skip() {
    _timer?.cancel();
    _timer = null;
    _transitionFromCompletion(awarded: false);
  }

  /// Dipanggil UI saat app kembali ke foreground: sinkronisasi ulang agar
  /// timer tetap akurat setelah di-suspend OS di background.
  void onAppResumed() {
    if (!state.isRunning) return;
    final end = _phaseEndAt;
    if (end == null) return;
    final now = DateTime.now();
    final remaining = end.difference(now).inSeconds;
    if (remaining <= 0) {
      _transitionFromCompletion(awarded: state.phase.isFocus);
    } else {
      state = state.copyWith(remainingSeconds: remaining);
      _startTicking();
    }
  }

  void _beginPhase(FocusPhase phase,
      {required int completedFocusCount, required DateTime startAt}) {
    final duration = Duration(seconds: _config.durationSeconds(phase));
    _phaseEndAt = startAt.add(duration);
    state = state.copyWith(
      phase: phase,
      status: TimerStatus.running,
      completedFocusCount: completedFocusCount,
      remainingSeconds: duration.inSeconds,
    );
    _startTicking();
  }

  void _startTicking() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    _tick();
  }

  void _tick() {
    final end = _phaseEndAt;
    if (end == null) return;
    final now = DateTime.now();
    final remaining = end.difference(now).inSeconds;
    if (remaining <= 0) {
      _transitionFromCompletion(awarded: state.phase.isFocus);
      return;
    }
    state = state.copyWith(remainingSeconds: remaining);
  }

  /// Disebut saat fase saat ini selesai (alami atau skip). [awarded] = apakah
  /// fase fokus diselesaikan utuh (berhak XP & menit belajar).
  void _transitionFromCompletion({required bool awarded}) {
    _timer?.cancel();
    _timer = null;
    final justFinished = state.phase;
    var focusCount = state.completedFocusCount;
    if (awarded && justFinished.isFocus) {
      focusCount++;
      _awardFocusSession();
    }
    final next = nextPhaseAfter(
      justFinished: justFinished,
      completedFocusCount: focusCount,
      config: _config,
    );

    final shouldAutoStart = justFinished.isFocus
        ? _config.autoStartBreaks
        : _config.autoStartFocus;
    final now = DateTime.now();
    if (shouldAutoStart) {
      _beginPhase(next.phase, completedFocusCount: next.completedFocusCount,
          startAt: now);
    } else {
      _phaseEndAt = null;
      state = state.copyWith(
        phase: next.phase,
        status: TimerStatus.paused,
        completedFocusCount: next.completedFocusCount,
        remainingSeconds: _config.durationSeconds(next.phase),
      );
    }
  }

  /// Catat sesi fokus selesai → memberi XP & menit belajar (lihat focus_stats).
  void _awardFocusSession() {
    final now = DateTime.now();
    final minutes = _config.focusMinutes;
    _ref.read(focusSessionListProvider.notifier).add(
          FocusSession(
            id: '',
            startedAt: now.subtract(Duration(minutes: minutes)),
            endedAt: now,
            durationMinutes: minutes,
            taskId: state.sessionTaskId,
            taskTitle: state.sessionTaskTitle,
          ),
        );
    // Rayakan sesi fokus selesai (confetti).
    celebrate(_ref, CelebrationKind.focusComplete);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
