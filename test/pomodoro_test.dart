import 'package:flutter_test/flutter_test.dart';
import 'package:study_flow/features/focus/domain/focus_session.dart';
import 'package:study_flow/features/focus/domain/focus_stats.dart';
import 'package:study_flow/features/focus/domain/pomodoro_config.dart';

/// Uji pure logic Pomodoro: konfigurasi, transisi fase, & statistik sesi.
void main() {
  final now = DateTime(2026, 7, 10, 10, 0); // Jumat 10:00
  final monday = DateTime(2026, 7, 6); // Senin pekan itu

  group('PomodoroConfig', () {
    test('default = 25/5/15, 4 siklus', () {
      const c = PomodoroConfig();
      expect(c.focusMinutes, 25);
      expect(c.shortBreakMinutes, 5);
      expect(c.longBreakMinutes, 15);
      expect(c.cyclesBeforeLongBreak, 4);
      expect(c.durationSeconds(FocusPhase.focus), 25 * 60);
    });

    test('fromMap clamp nilai di luar rentang → default', () {
      final c = PomodoroConfig.fromMap({
        'focusMinutes': 999,
        'shortBreakMinutes': 0,
        'longBreakMinutes': 'abc',
      });
      expect(c.focusMinutes, 25); // clamp → default
      expect(c.shortBreakMinutes, 5);
      expect(c.longBreakMinutes, 15);
    });

    test('fromMap nilai valid dipakai', () {
      final c = PomodoroConfig.fromMap({
        'focusMinutes': 50,
        'cyclesBeforeLongBreak': 6,
        'autoStartBreaks': true,
      });
      expect(c.focusMinutes, 50);
      expect(c.cyclesBeforeLongBreak, 6);
      expect(c.autoStartBreaks, isTrue);
    });
  });

  group('nextPhaseAfter', () {
    const config = PomodoroConfig(cyclesBeforeLongBreak: 4);

    test('fokus ke-1,2,3 → jeda pendek', () {
      for (final done in [1, 2, 3]) {
        final t = nextPhaseAfter(
            justFinished: FocusPhase.focus,
            completedFocusCount: done,
            config: config);
        expect(t.phase, FocusPhase.shortBreak, reason: 'done=$done');
        expect(t.completedFocusCount, done);
      }
    });

    test('fokus ke-4 (kelipatan) → jeda panjang', () {
      final t = nextPhaseAfter(
          justFinished: FocusPhase.focus,
          completedFocusCount: 4,
          config: config);
      expect(t.phase, FocusPhase.longBreak);
    });

    test('fokus ke-8 → jeda panjang', () {
      final t = nextPhaseAfter(
          justFinished: FocusPhase.focus,
          completedFocusCount: 8,
          config: config);
      expect(t.phase, FocusPhase.longBreak);
    });

    test('setelah jeda (pendek/panjang) → fokus, hitungan tak berubah', () {
      for (final break_ in [FocusPhase.shortBreak, FocusPhase.longBreak]) {
        final t = nextPhaseAfter(
            justFinished: break_,
            completedFocusCount: 4,
            config: config);
        expect(t.phase, FocusPhase.focus);
        expect(t.completedFocusCount, 4);
      }
    });
  });

  group('focus_stats', () {
    FocusSession s(DateTime ended, {int minutes = 25}) => FocusSession(
          id: '${ended.millisecondsSinceEpoch}',
          startedAt: ended.subtract(Duration(minutes: minutes)),
          endedAt: ended,
          durationMinutes: minutes,
        );

    test('focusXp = sesi valid × 30', () {
      final list = [s(now), s(now.subtract(const Duration(days: 1)))];
      expect(focusXp(list), 60);
    });

    test('sesi <1 menit tidak dihitung (anti abuse)', () {
      final tiny = FocusSession(
        id: 'x',
        startedAt: now,
        endedAt: now,
        durationMinutes: 0,
      );
      expect(focusXp([tiny]), 0);
      expect(focusMinutesTotal([tiny]), 0);
    });

    test('focusMinutesToday hanya hitung hari ini', () {
      final list = [
        s(now), // hari ini
        s(now.subtract(const Duration(days: 1))), // kemarin
      ];
      expect(focusMinutesToday(list, now), 25);
      expect(focusCountToday(list, now), 1);
    });

    test('focusMinutesThisWeek hanya hitung pekan ini', () {
      // Senin pekan ini + hari ini → dalam pekan; pekan lalu → luar.
      final lastWeek = monday.subtract(const Duration(days: 1));
      final list = [
        s(monday.add(const Duration(hours: 2))),
        s(now),
        s(lastWeek),
      ];
      expect(focusMinutesThisWeek(list, now), 50); // 2 sesi dalam pekan
    });
  });

  group('FocusPhase', () {
    test('isFocus hanya true untuk focus', () {
      expect(FocusPhase.focus.isFocus, isTrue);
      expect(FocusPhase.shortBreak.isFocus, isFalse);
      expect(FocusPhase.longBreak.isFocus, isFalse);
    });

    test('label tidak kosong', () {
      for (final p in FocusPhase.values) {
        expect(p.label.isNotEmpty, isTrue);
      }
    });
  });
}
