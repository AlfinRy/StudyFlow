import 'package:flutter_test/flutter_test.dart';

import 'package:study_flow/core/utils/date_labels.dart';
import 'package:study_flow/core/utils/deadline_format.dart';
import 'package:study_flow/features/tasks/domain/task_priority.dart';
import 'package:study_flow/features/tasks/presentation/task_form_validation.dart';
import 'package:study_flow/features/tasks/presentation/widgets/task_priority_style.dart';

/// Verifikasi logic tugas: validasi form, format deadline, dan mapping
/// prioritas (PRD §9: uji logic non-UI).
void main() {
  final now = DateTime(2026, 7, 4, 10, 0); // Sabtu

  group('validateTaskForm', () {
    test('judul kosong → error', () {
      expect(validateTaskForm('   '), isNotNull);
      expect(validateTaskForm(''), isNotNull);
    });

    test('judul terisi → valid', () {
      expect(validateTaskForm('Esai Bahasa Inggris'), isNull);
    });
  });

  group('formatTaskDeadline', () {
    test('tugas selesai → "Selesai"', () {
      final l = formatTaskDeadline(
          dueDate: now.subtract(const Duration(days: 1)), isDone: true, now: now);
      expect(l.text, 'Selesai');
      expect(l.isDone, isTrue);
    });

    test('jatuh tempo hari ini', () {
      final l = formatTaskDeadline(dueDate: now, isDone: false, now: now);
      expect(l.text, 'Jatuh tempo hari ini');
      expect(l.tone, DeadlineTone.soon);
    });

    test('besok', () {
      final l = formatTaskDeadline(
          dueDate: now.add(const Duration(days: 1)), isDone: false, now: now);
      expect(l.text, 'Besok');
    });

    test('N hari lagi (<= 7)', () {
      final l = formatTaskDeadline(
          dueDate: now.add(const Duration(days: 5)), isDone: false, now: now);
      expect(l.text, '5 hari lagi');
    });

    test('absolut (> 7 hari) memakai format "Deadline: D Bln"', () {
      final l = formatTaskDeadline(
          dueDate: now.add(const Duration(days: 20)), isDone: false, now: now);
      // 4 Jul + 20 hari = 24 Jul 2026
      expect(l.text, 'Deadline: 24 Jul');
      expect(l.tone, DeadlineTone.normal);
    });

    test('terlambat → overdue', () {
      final l = formatTaskDeadline(
          dueDate: now.subtract(const Duration(days: 3)), isDone: false, now: now);
      expect(l.text, 'Terlambat 3 hari');
      expect(l.isOverdue, isTrue);
    });

    test('tugas selesai tidak dianggap overdue walau lewat deadline', () {
      final l = formatTaskDeadline(
          dueDate: now.subtract(const Duration(days: 3)), isDone: true, now: now);
      expect(l.isOverdue, isFalse);
      expect(l.isDone, isTrue);
    });
  });

  group('TaskPriorityStyle', () {
    test('high → danger + URGENT', () {
      final s = TaskPriorityStyle.of(TaskPriority.high);
      expect(s.badge, 'URGENT');
    });

    test('medium → warning + NORMAL', () {
      final s = TaskPriorityStyle.of(TaskPriority.medium);
      expect(s.badge, 'NORMAL');
    });

    test('low → RENDAH', () {
      final s = TaskPriorityStyle.of(TaskPriority.low);
      expect(s.badge, 'RENDAH');
    });
  });

  group('idnFormatDateCompact', () {
    test('format "D Bln Tahun"', () {
      expect(idnFormatDateCompact(DateTime(2026, 7, 4)), '4 Jul 2026');
      expect(idnFormatDateCompact(DateTime(2026, 10, 15)), '15 Okt 2026');
    });
  });
}
