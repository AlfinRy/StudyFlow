import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:study_flow/features/materials/data/material_repository.dart';
import 'package:study_flow/features/materials/domain/material_file_type.dart';
import 'package:study_flow/features/materials/domain/study_material.dart';
import 'package:study_flow/features/schedule/data/schedule_repository.dart';
import 'package:study_flow/features/schedule/domain/schedule.dart';
import 'package:study_flow/features/schedule/domain/schedule_category.dart';
import 'package:study_flow/features/tasks/data/task_repository.dart';
import 'package:study_flow/features/tasks/domain/task.dart';
import 'package:study_flow/features/tasks/domain/task_priority.dart';

/// Verifikasi repository + persistensi Hive (offline-first) tanpa Flutter
/// binding. Setiap repository memakai box sendiri yang di-clear per test.
void main() {
  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('studyflow_hive_test');
    Hive.init(dir.absolute.path);
  });

  group('ScheduleRepository', () {
    late Box<dynamic> box;
    late ScheduleRepository repo;

    setUp(() async {
      box = await Hive.openBox('test_schedules');
      await box.clear();
      repo = ScheduleRepository(box);
    });

    test('add, getAll (sorted by start), forDay', () async {
      expect(repo.getAll(), isEmpty);
      await repo.add(const Schedule(
        id: '',
        title: 'Matematika',
        dayOfWeek: 1,
        startTime: '08:00',
        endTime: '09:30',
        category: ScheduleCategory.kuliah,
      ));
      await repo.add(const Schedule(
        id: '',
        title: 'Fisika',
        dayOfWeek: 1,
        startTime: '07:00',
        endTime: '08:00',
      ));
      final all = repo.getAll();
      expect(all.length, 2);
      expect(all.first.title, 'Fisika'); // sorted by startTime
      expect(repo.forDay(1).length, 2);
      expect(repo.forDay(2), isEmpty);
    });

    test('update & remove', () async {
      final s = await repo.add(const Schedule(
        id: '',
        title: 'B. Inggris',
        dayOfWeek: 2,
        startTime: '10:00',
        endTime: '11:00',
      ));
      await repo.update(s.copyWith(location: 'Lab A'));
      expect(repo.getAll().first.location, 'Lab A');
      await repo.remove(s.id);
      expect(repo.getAll(), isEmpty);
    });

    test('persists across box close/re-open', () async {
      await repo.add(const Schedule(
        id: '',
        title: 'Kimia',
        dayOfWeek: 3,
        startTime: '09:00',
        endTime: '10:00',
      ));
      await box.close();
      box = await Hive.openBox('test_schedules');
      repo = ScheduleRepository(box);
      expect(repo.getAll().length, 1);
    });
  });

  group('TaskRepository', () {
    late Box<dynamic> box;
    late TaskRepository repo;

    setUp(() async {
      box = await Hive.openBox('test_tasks');
      await box.clear();
      repo = TaskRepository(box);
    });

    test('sort by dueDate + toggleDone + filters', () async {
      await repo.add(Task(
        id: '',
        title: 'Late',
        dueDate: DateTime(2026, 1, 10),
      ));
      await repo.add(Task(
        id: '',
        title: 'Early',
        dueDate: DateTime(2026, 1, 1),
      ));
      expect(repo.getAll().first.title, 'Early');

      final early = repo.getAll().first;
      expect(early.isDone, isFalse);
      await repo.toggleDone(early);
      expect(repo.getAll().first.isDone, isTrue);
      // 'Late' is still incomplete, 'Early' is now completed.
      expect(repo.incomplete.length, 1);
      expect(repo.completed.length, 1);
    });

    test('priority, category & description roundtrip', () async {
      await repo.add(Task(
        id: '',
        title: 'Proyek',
        dueDate: DateTime(2026, 2, 2),
        priority: TaskPriority.high,
        category: 'Sains',
        description: 'detail',
      ));
      final t = repo.getAll().first;
      expect(t.priority, TaskPriority.high);
      expect(t.category, 'Sains');
      expect(t.description, 'detail');
    });

    test('remove', () async {
      final t = await repo.add(Task(
        id: '',
        title: 'X',
        dueDate: DateTime(2026, 3, 3),
      ));
      await repo.remove(t.id);
      expect(repo.getAll(), isEmpty);
    });
  });

  group('MaterialRepository', () {
    late Box<dynamic> box;
    late MaterialRepository repo;

    setUp(() async {
      box = await Hive.openBox('test_materials');
      await box.clear();
      repo = MaterialRepository(box);
    });

    test('add, sorted newest first, fileType roundtrip', () async {
      await repo.add(StudyMaterial(
        id: '',
        title: 'Old',
        category: 'Sains',
        filePathOrUrl: '/a.pdf',
        fileType: MaterialFileType.pdf,
        createdAt: DateTime(2026, 1, 1),
      ));
      await repo.add(StudyMaterial(
        id: '',
        title: 'New',
        category: 'Bahasa',
        filePathOrUrl: 'https://x',
        fileType: MaterialFileType.link,
        createdAt: DateTime(2026, 1, 5),
      ));
      final all = repo.getAll();
      expect(all.first.title, 'New');
      expect(all.first.fileType, MaterialFileType.link);
      expect(all.last.fileType, MaterialFileType.pdf);
    });

    test('update & remove', () async {
      final m = await repo.add(StudyMaterial(
        id: '',
        title: 'Note',
        category: 'Umum',
        filePathOrUrl: 'x',
        fileType: MaterialFileType.note,
        createdAt: DateTime(2026, 1, 1),
      ));
      await repo.update(m.copyWith(title: 'Note 2'));
      expect(repo.getAll().first.title, 'Note 2');
      await repo.remove(m.id);
      expect(repo.getAll(), isEmpty);
    });
  });
}
