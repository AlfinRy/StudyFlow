// Helper label tanggal/waktu dalam Bahasa Indonesia (pure, testable).
//
// `weekday` mengikuti `DateTime.weekday`: 1 = Senin ... 7 = Minggu.
// `month` mengikuti `DateTime.month`: 1 = Januari ... 12 = Desember.

import 'package:flutter/material.dart';

const List<String> idnWeekdays = [
  'Senin',
  'Selasa',
  'Rabu',
  'Kamis',
  'Jumat',
  'Sabtu',
  'Minggu',
];

const List<String> idnShortWeekdays = [
  'Sen',
  'Sel',
  'Rab',
  'Kam',
  'Jum',
  'Sab',
  'Min',
];

const List<String> idnMonths = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

const List<String> idnShortMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

String idnWeekday(int weekday) => idnWeekdays[(weekday - 1) % 7];

String idnShortWeekday(int weekday) => idnShortWeekdays[(weekday - 1) % 7];

String idnMonth(int month) => idnMonths[(month - 1) % 12];

String idnShortMonth(int month) => idnShortMonths[(month - 1) % 12];

/// Format tanggal compact, mis. "15 Okt 2026".
String idnFormatDateCompact(DateTime d) =>
    '${d.day} ${idnShortMonth(d.month)} ${d.year}';

/// Format "HH:mm" dari [TimeOfDay].
String formatTimeOfDay(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Parse "HH:mm" menjadi [TimeOfDay], atau null jika format tidak valid.
TimeOfDay? parseTimeOfDay(String value) {
  final minutes = scheduleTimeToMinutes(value);
  if (minutes == null) return null;
  return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
}

/// Konversi "HH:mm" → menit sejak tengah malam. Null jika format invalid.
/// Dipindahkan ke sini agar bisa dipakai bersama oleh form & test.
int? scheduleTimeToMinutes(String hhmm) {
  final parts = hhmm.split(':');
  if (parts.length != 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  if (h < 0 || h > 23 || m < 0 || m > 59) return null;
  return h * 60 + m;
}
