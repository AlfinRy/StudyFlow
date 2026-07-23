// Konfigurasi & mesin status fase Pomodoro (Fase Focus Timer).
// PURE — tanpa Flutter / Hive, agar mudah di-unit-test.
// Lihat test/pomodoro_test.dart.

/// Fase dalam satu siklus Pomodoro.
enum FocusPhase { focus, shortBreak, longBreak }

extension FocusPhaseLabel on FocusPhase {
  String get label => switch (this) {
        FocusPhase.focus => 'Fokus',
        FocusPhase.shortBreak => 'Jeda Pendek',
        FocusPhase.longBreak => 'Jeda Panjang',
      };

  /// Apakah fase ini adalah sesi belajar (memberi XP & menit belajar).
  bool get isFocus => this == FocusPhase.focus;
}

/// Pengaturan durasi Pomodoro. Persisten di Hive (settings box).
class PomodoroConfig {
  const PomodoroConfig({
    this.focusMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.cyclesBeforeLongBreak = 4,
    this.autoStartBreaks = false,
    this.autoStartFocus = false,
  });

  /// Durasi fokus (menit). Min 1, mak. 120.
  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;

  /// Berapa siklus fokus sebelum jeda panjang (umumnya 4).
  final int cyclesBeforeLongBreak;

  /// Mulai jeda otomatis setelah fokus selesai.
  final bool autoStartBreaks;
  /// Mulai fokus otomatis setelah jeda selesai.
  final bool autoStartFocus;

  int durationMinutes(FocusPhase phase) => switch (phase) {
        FocusPhase.focus => focusMinutes,
        FocusPhase.shortBreak => shortBreakMinutes,
        FocusPhase.longBreak => longBreakMinutes,
      };

  int durationSeconds(FocusPhase phase) => durationMinutes(phase) * 60;

  PomodoroConfig copyWith({
    int? focusMinutes,
    int? shortBreakMinutes,
    int? longBreakMinutes,
    int? cyclesBeforeLongBreak,
    bool? autoStartBreaks,
    bool? autoStartFocus,
  }) {
    return PomodoroConfig(
      focusMinutes: focusMinutes ?? this.focusMinutes,
      shortBreakMinutes: shortBreakMinutes ?? this.shortBreakMinutes,
      longBreakMinutes: longBreakMinutes ?? this.longBreakMinutes,
      cyclesBeforeLongBreak:
          cyclesBeforeLongBreak ?? this.cyclesBeforeLongBreak,
      autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
      autoStartFocus: autoStartFocus ?? this.autoStartFocus,
    );
  }

  Map<String, dynamic> toMap() => {
        'focusMinutes': focusMinutes,
        'shortBreakMinutes': shortBreakMinutes,
        'longBreakMinutes': longBreakMinutes,
        'cyclesBeforeLongBreak': cyclesBeforeLongBreak,
        'autoStartBreaks': autoStartBreaks,
        'autoStartFocus': autoStartFocus,
      };

  factory PomodoroConfig.fromMap(Map<String, dynamic> map) => PomodoroConfig(
        focusMinutes: _clampInt(map['focusMinutes'], 1, 120, 25),
        shortBreakMinutes: _clampInt(map['shortBreakMinutes'], 1, 60, 5),
        longBreakMinutes: _clampInt(map['longBreakMinutes'], 1, 60, 15),
        cyclesBeforeLongBreak: _clampInt(map['cyclesBeforeLongBreak'], 1, 12, 4),
        autoStartBreaks: (map['autoStartBreaks'] as bool?) ?? false,
        autoStartFocus: (map['autoStartFocus'] as bool?) ?? false,
      );

  static int _clampInt(dynamic v, int min, int max, int fallback) {
    final n = v is int ? v : int.tryParse('$v');
    if (n == null || n < min || n > max) return fallback;
    return n;
  }
}

/// Hasil transisi fase. [completedFocusCount] termasuk fase fokus yang baru
/// saja selesai (jika [justFinished] adalah focus).
class PhaseTransition {
  const PhaseTransition(this.phase, this.completedFocusCount);
  final FocusPhase phase;
  final int completedFocusCount;
}

/// Menentukan fase berikutnya setelah [justFinished] selesai.
///
/// Aturan: setelah fokus → jeda panjang bila [completedFocusCount] kelipatan
/// [config.cyclesBeforeLongBreak], jika tidak jeda pendek. Setelah jeda → fokus.
PhaseTransition nextPhaseAfter({
  required FocusPhase justFinished,
  required int completedFocusCount,
  required PomodoroConfig config,
}) {
  if (justFinished == FocusPhase.focus) {
    final isLong = config.cyclesBeforeLongBreak > 0 &&
        completedFocusCount % config.cyclesBeforeLongBreak == 0;
    return PhaseTransition(
      isLong ? FocusPhase.longBreak : FocusPhase.shortBreak,
      completedFocusCount,
    );
  }
  return PhaseTransition(FocusPhase.focus, completedFocusCount);
}
