import 'package:flutter_test/flutter_test.dart';

import 'package:study_flow/features/progress/domain/progress_stats.dart';
import 'package:study_flow/features/schedule/domain/schedule.dart';
import 'package:study_flow/features/tasks/domain/task.dart';

/// Verifikasi perhitungan progres belajar (Fase 8) — semua pure function.
void main() {
  // Wednesday 8 July 2026 → minggu berjalan: Mon 6 .. Sun 12 Jul 2026.
  final now = DateTime(2026, 7, 8, 10, 0);

  group('window waktu', () {
    test('weekStart jatuh di Senin', () {
      expect(weekStart(now).weekday, DateTime.monday);
      expect(weekStart(now), DateTime(2026, 7, 6));
    });

    test('weekEnd jatuh di Minggu 23:59', () {
      expect(weekEnd(now).weekday, DateTime.sunday);
      expect(weekEnd(now), DateTime(2026, 7, 12, 23, 59, 59, 999));
    });

    test('monthStart & monthEnd', () {
      expect(monthStart(now), DateTime(2026, 7, 1));
      expect(monthEnd(now).day, 31);
      expect(monthEnd(now).month, 7);
    });
  });

  group('summaryAll', () {
    test('persentase akurat', () {
      final tasks = [
        Task(id: '1', title: 'A', dueDate: DateTime(2026, 7, 5)),
        Task(id: '2', title: 'B', dueDate: DateTime(2026, 7, 5), isDone: true),
        Task(id: '3', title: 'C', dueDate: DateTime(2026, 7, 5), isDone: true),
        Task(id: '4', title: 'D', dueDate: DateTime(2026, 7, 5)),
      ];
      final s = summaryAll(tasks);
      expect(s.total, 4);
      expect(s.done, 2);
      expect(s.incomplete, 2);
      expect(s.percent, 0.5);
    });

    test('kosong → percent 0 (bukan NaN)', () {
      final s = summaryAll(const []);
      expect(s.percent, 0);
    });
  });

  group('summaryInWindow', () {
    final inWeek = Task(id: 'a', title: 'in', dueDate: DateTime(2026, 7, 7));
    final inWeekDone =
        Task(id: 'b', title: 'done', dueDate: DateTime(2026, 7, 10), isDone: true);
    final outOfWeek = Task(id: 'c', title: 'out', dueDate: DateTime(2026, 8, 1));

    test('hanya tugas berdeadline di dalam minggu ini', () {
      final s = summaryInWindow([inWeek, inWeekDone, outOfWeek],
          weekStart(now), weekEnd(now));
      expect(s.total, 2);
      expect(s.done, 1);
    });

    test('hanya tugas berdeadline di dalam bulan ini', () {
      final s = summaryInWindow([inWeek, inWeekDone, outOfWeek],
          monthStart(now), monthEnd(now));
      expect(s.total, 2);
      expect(s.done, 1);
    });

    test('boundary: deadline tepat di awal/akhir window termasuk', () {
      final atStart = Task(id: 'x', title: 'start', dueDate: weekStart(now));
      final atEnd = Task(id: 'y', title: 'end', dueDate: weekEnd(now));
      final s = summaryInWindow(
          [atStart, atEnd], weekStart(now), weekEnd(now));
      expect(s.total, 2);
    });
  });

  group('weeklyCompletions', () {
    test('menghitung completedAt per hari untuk minggu ini', () {
      final tasks = [
        Task(
          id: '1',
          title: 'A',
          dueDate: DateTime(2026, 7, 1),
          isDone: true,
          completedAt: DateTime(2026, 7, 6, 9), // Senin
        ),
        Task(
          id: '2',
          title: 'B',
          dueDate: DateTime(2026, 7, 1),
          isDone: true,
          completedAt: DateTime(2026, 7, 6, 20), // Senin juga
        ),
        Task(
          id: '3',
          title: 'C',
          dueDate: DateTime(2026, 7, 1),
          isDone: true,
          completedAt: DateTime(2026, 7, 8, 12), // Rabu (hari ini)
        ),
        Task(
          id: '4',
          title: 'D',
          dueDate: DateTime(2026, 7, 1),
          isDone: true,
          completedAt: DateTime(2026, 6, 30), // minggu lalu, diabaikan
        ),
      ];
      final days = weeklyCompletions(tasks, now);
      expect(days.length, 7);
      expect(days.first.label, 'Sen');
      expect(days.first.count, 2);
      expect(days[2].label, 'Rab');
      expect(days[2].count, 1);
      expect(days[2].isToday, isTrue);
      // Total minggu ini = 3 (4 minus 1 di minggu lalu).
      expect(days.fold<int>(0, (a, d) => a + d.count), 3);
    });

    test('tanpa completion → semua 0', () {
      final days = weeklyCompletions(const [], now);
      expect(days.every((d) => d.count == 0), isTrue);
    });
  });

  group('completionStreak', () {
    test('streak putus bila hari ini & kemarin kosong', () {
      final tasks = [
        Task(
          id: '1',
          title: 'A',
          dueDate: DateTime(2026, 7, 1),
          isDone: true,
          completedAt: DateTime(2026, 7, 4), // Sabtu, hari ini Rabu
        ),
      ];
      expect(completionStreak(tasks, now), 0);
    });

    test('streak aktif dari kemarin ke belakang', () {
      // hari ini = 8 Jul (Rabu), kemarin 7, lusa-1 = 6
      final tasks = [
        Task(id: '1', title: 'A', dueDate: DateTime(2026, 1, 1), isDone: true,
            completedAt: DateTime(2026, 7, 7)),
        Task(id: '2', title: 'B', dueDate: DateTime(2026, 1, 1), isDone: true,
            completedAt: DateTime(2026, 7, 6)),
        Task(id: '3', title: 'C', dueDate: DateTime(2026, 1, 1), isDone: true,
            completedAt: DateTime(2026, 7, 5)),
      ];
      expect(completionStreak(tasks, now), 3);
    });

    test('streak termasuk hari ini', () {
      final tasks = [
        Task(id: '1', title: 'A', dueDate: DateTime(2026, 1, 1), isDone: true,
            completedAt: DateTime(2026, 7, 8)),
        Task(id: '2', title: 'B', dueDate: DateTime(2026, 1, 1), isDone: true,
            completedAt: DateTime(2026, 7, 7)),
      ];
      expect(completionStreak(tasks, now), 2);
    });

    test('kosong → 0', () {
      expect(completionStreak(const [], now), 0);
    });
  });

  group('scheduledMinutesPerWeek', () {
    test('menjumlahkan durasi tiap jadwal sekali', () {
      final schedules = [
        Schedule(
          id: '1',
          title: 'A',
          dayOfWeek: 1,
          startTime: '08:00',
          endTime: '09:30', // 90 menit
        ),
        Schedule(
          id: '2',
          title: 'B',
          dayOfWeek: 3,
          startTime: '10:00',
          endTime: '12:00', // 120 menit
        ),
      ];
      expect(scheduledMinutesPerWeek(schedules), 210);
    });

    test('end <= start diabaikan', () {
      final schedules = [
        Schedule(
          id: '1',
          title: 'bad',
          dayOfWeek: 1,
          startTime: '12:00',
          endTime: '12:00',
        ),
      ];
      expect(scheduledMinutesPerWeek(schedules), 0);
    });
  });
}
