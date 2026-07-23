// Statistik dari riwayat sesi fokus (PURE, tanpa Flutter). Dipakai layar
// Progres untuk XP & menit belajar aktual (bukan hanya terjadwal).

import 'focus_session.dart';

/// XP yang diberikan per sesi fokus yang diselesaikan (penuh).
const int xpPerFocusSession = 30;

/// Hanya sesi yang minimal 1 menit yang dihitung (anti abuse skip cepat).
bool _counts(FocusSession s) => s.durationMinutes >= 1;

/// Daftar sesi yang sah (memberi XP/menit).
List<FocusSession> validSessions(List<FocusSession> all) =>
    all.where(_counts).toList();

/// Total XP dari sesi fokus.
int focusXp(List<FocusSession> all) =>
    validSessions(all).length * xpPerFocusSession;

/// Total menit belajar dari sesi fokus (semua waktu).
int focusMinutesTotal(List<FocusSession> all) =>
    validSessions(all).fold<int>(0, (sum, s) => sum + s.durationMinutes);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Menit belajar hari ini.
int focusMinutesToday(List<FocusSession> all, DateTime now) =>
    validSessions(all)
        .where((s) => _sameDay(s.endedAt, now))
        .fold<int>(0, (sum, s) => sum + s.durationMinutes);

/// Awal minggu (Senin, 00:00) yang memuat [reference].
DateTime weekStart(DateTime reference) {
  final d = DateTime(reference.year, reference.month, reference.day);
  return d.subtract(Duration(days: d.weekday - 1));
}

/// Menit belajar pekan ini (Senin–Minggu).
int focusMinutesThisWeek(List<FocusSession> all, DateTime now) {
  final start = weekStart(now);
  final end = start.add(const Duration(days: 7));
  return validSessions(all)
      .where((s) => !s.endedAt.isBefore(start) && s.endedAt.isBefore(end))
      .fold<int>(0, (sum, s) => sum + s.durationMinutes);
}

/// Jumlah sesi fokus selesai hari ini.
int focusCountToday(List<FocusSession> all, DateTime now) =>
    validSessions(all).where((s) => _sameDay(s.endedAt, now)).length;
