// Smoke test halaman Progres (Fase 8). Menggunakan provider override dengan
// data in-memory (tanpa menulis ke Hive) untuk menghindari interaksi
// Hive + flutter_test FakeAsync. Logika perhitungan sendiri diuji terpisah di
// progress_stats_test.dart & gamification_test.dart.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:study_flow/features/focus/domain/focus_session.dart';
import 'package:study_flow/features/focus/focus_providers.dart';
import 'package:study_flow/features/progress/presentation/progress_screen.dart';
import 'package:study_flow/features/schedule/domain/schedule.dart';
import 'package:study_flow/features/schedule/schedule_providers.dart';
import 'package:study_flow/features/streak/domain/streak_profile.dart';
import 'package:study_flow/features/streak/streak_providers.dart';
import 'package:study_flow/features/tasks/domain/task.dart';
import 'package:study_flow/features/tasks/task_providers.dart';

/// Notifier tugas yang selalu mengembalikan daftar tetap (tanpa Hive).
class _FixedTaskList extends TaskListNotifier {
  _FixedTaskList(this.tasks);
  final List<Task> tasks;
  @override
  List<Task> build() => tasks;
}

/// Notifier jadwal yang selalu mengembalikan daftar tetap (tanpa Hive).
class _FixedScheduleList extends ScheduleListNotifier {
  _FixedScheduleList(this.schedules);
  final List<Schedule> schedules;
  @override
  List<Schedule> build() => schedules;
}

/// Notifier sesi fokus yang selalu mengembalikan daftar tetap (tanpa Hive).
class _FixedFocusList extends FocusSessionListNotifier {
  _FixedFocusList(this.sessions);
  final List<FocusSession> sessions;
  @override
  List<FocusSession> build() => sessions;
}

/// Notifier profil streak tanpa Hive (profil kosong, aksi no-op). Mencegah
/// totalXpProvider menyentuh box `settings` yang tak terinisialisasi di test.
class _FixedStreakProfile extends StreakProfileNotifier {
  @override
  StreakProfile build() => const StreakProfile();
  @override
  Future<void> reconcile(DateTime now) async {}
  @override
  Future<int> claimDaily(DateTime now) async => 0;
}

Future<void> _pump(
  WidgetTester tester,
  List<Task> tasks, {
  List<Schedule> schedules = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        taskListProvider.overrideWith(() => _FixedTaskList(tasks)),
        scheduleListProvider.overrideWith(() => _FixedScheduleList(schedules)),
        focusSessionListProvider.overrideWith(() => _FixedFocusList(const [])),
        streakProfileProvider.overrideWith(() => _FixedStreakProfile()),
      ],
      child: const MaterialApp(
        home: Scaffold(body: ProgressScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('state kosong: hero & elemen inti tampil', (tester) async {
    await _pump(tester, const []);
    expect(find.text('Progres Belajar'), findsOneWidget);
    expect(find.text('SELESAI'), findsOneWidget);
    expect(find.text('0 dari 0'), findsOneWidget); // donut row tugas selesai
    // Tab window tampil (on-screen).
    expect(find.text('Mingguan'), findsOneWidget);
    expect(find.text('Bulanan'), findsOneWidget);
  });

  testWidgets('dengan tugas: persen terhitung akurat (on-screen)', (tester) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final midWeek = startOfWeek.add(const Duration(days: 2));
    await _pump(tester, [
      Task(
        id: '1',
        title: 'A',
        dueDate: midWeek,
        isDone: true,
        completedAt: now,
      ),
      Task(id: '2', title: 'B', dueDate: midWeek, isDone: false),
      // Tugas berdeadline bulan depan → di luar window mingguan ini.
      Task(
        id: '3',
        title: 'C',
        dueDate: DateTime(now.year, now.month + 1, 15),
        isDone: true,
        completedAt: now,
      ),
    ]);

    // Window mingguan (default): 1 dari 2 selesai → 50%.
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('1 dari 2'), findsOneWidget);
  });
}
