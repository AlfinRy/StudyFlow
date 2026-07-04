import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:study_flow/core/utils/date_labels.dart';
import 'package:study_flow/features/schedule/presentation/schedule_form_validation.dart';

/// Verifikasi logic murni form jadwal + helper label tanggal (PRD §9: uji
/// logic non-UI). Tidak menyentuh Hive / widget binding.
void main() {
  group('validateScheduleForm', () {
    test('judul kosong → error', () {
      expect(
        validateScheduleForm(title: '   ', startTime: '08:00', endTime: '09:00'),
        isNotNull,
      );
    });

    test('format jam invalid → error', () {
      expect(
        validateScheduleForm(
            title: 'Matematika', startTime: '8', endTime: '09:00'),
        isNotNull,
      );
      expect(
        validateScheduleForm(
            title: 'Matematika', startTime: '08:00', endTime: '25:00'),
        isNotNull,
      );
    });

    test('jam selesai <= mulai → error', () {
      expect(
        validateScheduleForm(
            title: 'Fisika', startTime: '09:00', endTime: '09:00'),
        isNotNull,
      );
      expect(
        validateScheduleForm(
            title: 'Fisika', startTime: '10:00', endTime: '09:00'),
        isNotNull,
      );
    });

    test('input valid → null', () {
      expect(
        validateScheduleForm(
            title: 'B. Inggris', startTime: '08:00', endTime: '09:30'),
        isNull,
      );
    });
  });

  group('scheduleTimeToMinutes', () {
    test('parsing HH:mm', () {
      expect(scheduleTimeToMinutes('00:00'), 0);
      expect(scheduleTimeToMinutes('08:30'), 8 * 60 + 30);
      expect(scheduleTimeToMinutes('23:59'), 23 * 60 + 59);
    });

    test('reject invalid', () {
      expect(scheduleTimeToMinutes('24:00'), isNull);
      expect(scheduleTimeToMinutes('08:60'), isNull);
      expect(scheduleTimeToMinutes('abc'), isNull);
      expect(scheduleTimeToMinutes('8:30:00'), isNull);
    });
  });

  group('date labels', () {
    test('idnWeekday: 1=Senin, 7=Minggu', () {
      expect(idnWeekday(1), 'Senin');
      expect(idnWeekday(7), 'Minggu');
    });

    test('idnShortWeekday: 1=Sen, 5=Jum', () {
      expect(idnShortWeekday(1), 'Sen');
      expect(idnShortWeekday(5), 'Jum');
    });

    test('idnMonth: 1=Januari, 10=Oktober', () {
      expect(idnMonth(1), 'Januari');
      expect(idnMonth(10), 'Oktober');
    });

    test('wrap-around aman untuk input di luar rentang', () {
      expect(idnWeekday(8), 'Senin'); // (8-1)%7 = 0
      expect(idnMonth(13), 'Januari');
    });
  });

  group('TimeOfDay helpers', () {
    test('formatTimeOfDay', () {
      expect(formatTimeOfDay(const TimeOfDay(hour: 8, minute: 5)), '08:05');
      expect(formatTimeOfDay(const TimeOfDay(hour: 0, minute: 0)), '00:00');
      expect(formatTimeOfDay(const TimeOfDay(hour: 17, minute: 30)), '17:30');
    });

    test('parseTimeOfDay roundtrip', () {
      const t = TimeOfDay(hour: 9, minute: 45);
      expect(parseTimeOfDay(formatTimeOfDay(t)), t);
      expect(parseTimeOfDay('invalid'), isNull);
    });
  });
}
