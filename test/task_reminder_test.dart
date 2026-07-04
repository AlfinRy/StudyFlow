import 'package:flutter_test/flutter_test.dart';

import 'package:study_flow/core/utils/task_reminder_schedule.dart';

/// Verifikasi perhitungan waktu reminder (PRD §5.4: H-1 & hari-H, default
/// pukul 08:00). Pure — tidak menyentuh plugin notifikasi.
void main() {
  // "Sekarang" untuk semua test: Senin 2026-07-06 10:00.
  final now = DateTime(2026, 7, 6, 10, 0);

  group('computeReminderTimes', () {
    test('deadline 3 hari ke depan → keduanya dijadwalkan', () {
      final due = DateTime(2026, 7, 9, 23, 59);
      final t = computeReminderTimes(dueDate: due, now: now);
      // H-1 = 8 Jul 08:00, hari-H = 9 Jul 08:00.
      expect(t.dayBefore, DateTime(2026, 7, 8, 8));
      expect(t.onDay, DateTime(2026, 7, 9, 8));
      expect(t.isEmpty, isFalse);
    });

    test('deadline besok → H-1 sudah lewat (hari ini), hanya hari-H', () {
      final due = DateTime(2026, 7, 7, 23, 59);
      final t = computeReminderTimes(dueDate: due, now: now);
      // H-1 = hari ini (6 Jul) 08:00 → sudah lewat.
      expect(t.dayBefore, isNull);
      expect(t.onDay, DateTime(2026, 7, 7, 8));
    });

    test('deadline hari ini → keduanya sudah lewat → kosong', () {
      final due = DateTime(2026, 7, 6, 23, 59);
      final t = computeReminderTimes(dueDate: due, now: now);
      expect(t.dayBefore, isNull);
      expect(t.onDay, isNull);
      expect(t.isEmpty, isTrue);
    });

    test('deadline di masa lalu → kosong', () {
      final due = DateTime(2026, 7, 1, 23, 59);
      final t = computeReminderTimes(dueDate: due, now: now);
      expect(t.isEmpty, isTrue);
    });

    test('reminderHour configurable', () {
      final due = DateTime(2026, 7, 9, 23, 59);
      final t = computeReminderTimes(dueDate: due, now: now, reminderHour: 18);
      expect(t.onDay, DateTime(2026, 7, 9, 18));
      expect(t.dayBefore, DateTime(2026, 7, 8, 18));
    });

    test('reminder persis di batas waktu tidak dijadwalkan (isAfter strict)', () {
      // now = 6 Jul 08:00 persis → onDay untuk 6 Jul 08:00 = now, bukan after.
      final nowAtEight = DateTime(2026, 7, 6, 8, 0);
      final due = DateTime(2026, 7, 6, 23, 59);
      final t = computeReminderTimes(dueDate: due, now: nowAtEight);
      expect(t.onDay, isNull); // == now, bukan isAfter
    });
  });
}
