import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:study_flow/features/tasks/data/task_repository.dart';
import 'package:study_flow/features/tasks/domain/recurrence.dart';
import 'package:study_flow/features/tasks/domain/task.dart';
import 'package:study_flow/features/tasks/domain/task_priority.dart';

/// Harness Hive temp (meniru pola test/data_layer_test.dart). Box terpisah
/// per test agar tidak saling bocor.
Future<Box<dynamic>> _openBox(String name) async {
  final box = await Hive.openBox(name);
  await box.clear();
  return box;
}

void main() {
  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('studyflow_recur_test');
    Hive.init(dir.absolute.path);
  });
  group('Recurrence.nextDueDate', () {
    final base = DateTime(2026, 1, 15, 9, 30); // Jum 15 Jan 2026, 09:30

    test('none mengembalikan tanggal yang sama', () {
      expect(Recurrence.none.nextDueDate(base), base);
    });

    test('daily maju tepat 1 hari, jam dipertahankan', () {
      final next = Recurrence.daily.nextDueDate(base);
      expect(next, DateTime(2026, 1, 16, 9, 30));
    });

    test('weekly maju 7 hari', () {
      expect(Recurrence.weekly.nextDueDate(base), DateTime(2026, 1, 22, 9, 30));
    });

    test('biweekly maju 14 hari', () {
      expect(
          Recurrence.biweekly.nextDueDate(base), DateTime(2026, 1, 29, 9, 30));
    });

    test('monthly maju 1 bulan', () {
      expect(
          Recurrence.monthly.nextDueDate(base), DateTime(2026, 2, 15, 9, 30));
    });

    test('monthly menormalisasi overflow tanggal (31 Jan → akhir Feb)', () {
      final jan31 = DateTime(2026, 1, 31, 8);
      final next = Recurrence.monthly.nextDueDate(jan31);
      // 31 Feb 2026 tak ada → dinormalisasi ke 3 Mar 2026.
      expect(next, DateTime(2026, 3, 3, 8));
    });
  });

  group('Recurrence.isActive & fromName', () {
    test('isActive hanya true untuk pola bukan none', () {
      expect(Recurrence.none.isActive, isFalse);
      expect(Recurrence.daily.isActive, isTrue);
      expect(Recurrence.monthly.isActive, isTrue);
    });

    test('fromName parse nama valid', () {
      expect(Recurrence.fromName('weekly'), Recurrence.weekly);
      expect(Recurrence.fromName('biweekly'), Recurrence.biweekly);
    });

    test('fromName default none untuk null/nilai tak dikenal', () {
      expect(Recurrence.fromName(null), Recurrence.none);
      expect(Recurrence.fromName('bogus'), Recurrence.none);
    });
  });

  group('Task persistence (recurrence roundtrip)', () {
    late TaskRepository repo;

    setUp(() async {
      repo = TaskRepository(await _openBox('test_recurrence_tasks'));
    });

    test('recurrence tersimpan & terbaca kembali', () async {
      await repo.add(Task(
        id: '',
        title: 'Belajar harian',
        dueDate: DateTime(2026, 1, 15),
        recurrence: Recurrence.daily,
      ));
      final loaded = repo.getAll().first;
      expect(loaded.recurrence, Recurrence.daily);
    });

    test('task lama (tanpa field recurrence) default ke none', () async {
      // Simulasi data lama: map tanpa key 'recurrence'.
      final box = await _openBox('test_recurrence_legacy');
      await box.put('legacy', {
        'id': 'legacy',
        'title': 'Tugas lawas',
        'dueDate': DateTime(2026, 1, 1).toIso8601String(),
        'isDone': false,
      });
      final legacy = TaskRepository(box).getAll().first;
      expect(legacy.recurrence, Recurrence.none);
    });
  });

  group('TaskRepository.generateNextOccurrence', () {
    late TaskRepository repo;

    setUp(() async {
      repo = TaskRepository(await _openBox('test_next_occurrence'));
    });

    test('mengembalikan null bila recurrence none', () {
      final done = Task(
        id: 't1',
        title: 'Sekali',
        dueDate: DateTime(2026, 1, 15),
        isDone: true,
        recurrence: Recurrence.none,
      );
      expect(repo.generateNextOccurrence(done), isNull);
    });

    test('instance berikutnya: id baru, belum selesai, deadline maju', () {
      final done = Task(
        id: 't1',
        title: 'Belajar mingguan',
        dueDate: DateTime(2026, 1, 15, 9, 30),
        isDone: true,
        completedAt: DateTime(2026, 1, 15, 10),
        category: 'Matematika',
        priority: TaskPriority.high,
        recurrence: Recurrence.weekly,
      );
      final next = repo.generateNextOccurrence(done)!;

      expect(next.id, isNot(done.id)); // id baru
      expect(next.id, isNotEmpty);
      expect(next.isDone, isFalse);
      expect(next.completedAt, isNull);
      expect(next.dueDate, DateTime(2026, 1, 22, 9, 30)); // +7 hari
      // Properti lain dipertahankan.
      expect(next.title, done.title);
      expect(next.category, done.category);
      expect(next.priority, done.priority);
      expect(next.recurrence, Recurrence.weekly); // tetap berulang
    });

    test('instance berikutnya bisa dipersist via add', () async {
      final done = await repo.add(Task(
        id: '',
        title: 'Belajar harian',
        dueDate: DateTime(2026, 1, 15),
        recurrence: Recurrence.daily,
      ));
      await repo.toggleDone(done);
      final next = repo.generateNextOccurrence(repo.getAll().first)!;
      await repo.add(next);

      final all = repo.getAll();
      expect(all.length, 2);
      // Yang baru belum selesai + deadline besok.
      final fresh = all.firstWhere((t) => !t.isDone);
      expect(fresh.dueDate.day, 16);
    });
  });
}
