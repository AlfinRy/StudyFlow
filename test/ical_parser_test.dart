import 'package:flutter_test/flutter_test.dart';
import 'package:study_flow/features/schedule/data/ical_parser.dart';

/// Uji parser .ics → Schedule mingguan (FEATURE_ROADMAP #5). Murni logic.
void main() {
  const sample = '''
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Test//EN
BEGIN:VEVENT
UID:1
SUMMARY:Matematika
LOCATION:Ruang 101
DTSTART;TZID=Asia/Jakarta:20260105T080000
DTEND;TZID=Asia/Jakarta:20260105T093000
RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR
END:VEVENT
BEGIN:VEVENT
UID:2
SUMMARY:UTBK Tryout
DTSTART:20260110T140000Z
DTEND:20260110T160000Z
END:VEVENT
BEGIN:VEVENT
UID:3
SUMMARY:Libur Nasional
DTSTART;VALUE=DATE:20260117
DTEND;VALUE=DATE:20260118
END:VEVENT
END:VCALENDAR
''';

  group('parseIcsToSchedules', () {
    test('konten kosong / tanpa VEVENT → list kosong', () {
      expect(parseIcsToSchedules(''), isEmpty);
      expect(parseIcsToSchedules('BEGIN:VCALENDAR\nEND:VCALENDAR'), isEmpty);
    });

    test('sample: 4 slot (3 dari RRULE + 1 event tunggal, all-day dilewati)',
        () {
      final out = parseIcsToSchedules(sample);
      expect(out.length, 4);

      final mat = out.where((s) => s.title == 'Matematika').toList();
      expect(mat.length, 3);
      // BYDAY MO,WE,FR → weekday 1,3,5.
      expect(mat.map((s) => s.dayOfWeek).toList()..sort(), [1, 3, 5]);
      for (final s in mat) {
        expect(s.startTime, '08:00');
        expect(s.endTime, '09:30');
        expect(s.location, 'Ruang 101');
      }

      final utbk = out.firstWhere((s) => s.title == 'UTBK Tryout');
      // 2026-01-10 adalah Sabtu → weekday 6.
      expect(utbk.dayOfWeek, 6);
      expect(utbk.startTime, '14:00');
      expect(utbk.endTime, '16:00');

      // All-day "Libur Nasional" dilewati.
      expect(out.any((s) => s.title.contains('Libur')), isFalse);
    });

    test('RRULE WEEKLY diekspansi; FREQ lain mundur ke weekday DTSTART', () {
      final out = parseIcsToSchedules('''
BEGIN:VCALENDAR
BEGIN:VEVENT
SUMMARY:Olahraga
DTSTART:20260106T070000
DTEND:20260106T080000
RRULE:FREQ=DAILY
END:VEVENT
END:VCALENDAR
''');
      // FREQ=DAILY (bukan WEEKLY) → tidak ekspansi, pakai weekday DTSTART.
      // 2026-01-06 = Selasa → 2.
      expect(out.length, 1);
      expect(out.first.dayOfWeek, 2);
    });

    test('DTEND hilang → endTime = start + 1 jam', () {
      final out = parseIcsToSchedules('''
BEGIN:VCALENDAR
BEGIN:VEVENT
SUMMARY:Tanpa End
DTSTART:20260107T130000
END:VEVENT
END:VCALENDAR
''');
      expect(out.length, 1);
      expect(out.first.startTime, '13:00');
      expect(out.first.endTime, '14:00');
    });

    test('dedup internal: judul+hari+jam sama hanya sekali', () {
      final out = parseIcsToSchedules('''
BEGIN:VCALENDAR
BEGIN:VEVENT
SUMMARY:Dup
DTSTART:20260105T090000
DTEND:20260105T100000
RRULE:FREQ=WEEKLY;BYDAY=MO
END:VEVENT
BEGIN:VEVENT
SUMMARY:Dup
DTSTART:20260112T090000
DTEND:20260112T100000
RRULE:FREQ=WEEKLY;BYDAY=MO
END:VEVENT
END:VCALENDAR
''');
      // Dua VEVENT identik (Senin 09:00 "Dup") → 1 slot.
      expect(out.length, 1);
    });

    test('escape teks iCalendar dilepas', () {
      final out = parseIcsToSchedules(r'''
BEGIN:VCALENDAR
BEGIN:VEVENT
SUMMARY:Mat\, Sains\; & Komputer
DTSTART:20260105T080000
DTEND:20260105T090000
END:VEVENT
END:VCALENDAR
''');
      expect(out.first.title, 'Mat, Sains; & Komputer');
    });

    test('id dikosongkan (diisi repository saat disimpan)', () {
      final out = parseIcsToSchedules(sample);
      for (final s in out) {
        expect(s.id, '');
      }
    });

    test('line unfolding (RFC 5545)', () {
      // SUMMARY terlipat di tengah kata "Kompu|ter".
      final out = parseIcsToSchedules('''
BEGIN:VCALENDAR
BEGIN:VEVENT
SUMMARY:Pengantar Ilmu Kompu
 ter
DTSTART:20260105T080000
DTEND:20260105T090000
END:VEVENT
END:VCALENDAR
''');
      expect(out.first.title, 'Pengantar Ilmu Komputer');
    });
  });
}
