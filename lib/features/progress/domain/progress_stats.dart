// Helper perhitungan progres belajar (PRD §5.5, UI_DESIGN.md §7) — PURE,
// tanpa dependensi Flutter, agar mudah di-unit-test.
//
// Semua window waktu memakai minggu Senin–Minggu (DateTime.weekday:
// 1 = Senin ... 7 = Minggu) agar konsisten dengan label `idnWeekday`.

import '../../../core/utils/date_labels.dart';
import '../../schedule/domain/schedule.dart';
import '../../tasks/domain/task.dart';

/// Ringkasan progres tugas: total vs selesai, turun ke persentase.
class ProgressSummary {
  const ProgressSummary({required this.total, required this.done});

  final int total;
  final int done;

  int get incomplete => total - done;

  /// Proporsi selesai (0.0–1.0). 0 bila tidak ada tugas.
  double get percent => total == 0 ? 0 : done / total;
}

// ---------------------------------------------------------------------------
// Window waktu (minggu / bulan)
// ---------------------------------------------------------------------------

/// Awal hari (00:00) dari tanggal referensi.
DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Awal minggu (Senin, 00:00) yang memuat [reference].
DateTime weekStart(DateTime reference) {
  final d = _dateOnly(reference);
  return d.subtract(Duration(days: d.weekday - 1));
}

/// Akhir minggu (Minggu, 23:59:59.999) yang memuat [reference].
DateTime weekEnd(DateTime reference) =>
    weekStart(reference).add(const Duration(days: 7)).subtract(
      const Duration(milliseconds: 1),
    );

/// Awal bulan (hari 1, 00:00) dari [reference].
DateTime monthStart(DateTime reference) => DateTime(reference.year, reference.month);

/// Akhir bulan (hari terakhir, 23:59:59.999) dari [reference].
DateTime monthEnd(DateTime reference) =>
    DateTime(reference.year, reference.month + 1, 0, 23, 59, 59, 999);

// ---------------------------------------------------------------------------
// Ringkasan tugas
// ---------------------------------------------------------------------------

/// Ringkasan SEMUA tugas (tanpa filter window).
ProgressSummary summaryAll(List<Task> tasks) {
  var done = 0;
  for (final t in tasks) {
    if (t.isDone) done++;
  }
  return ProgressSummary(total: tasks.length, done: done);
}

/// Ringkasan tugas yang ber-`dueDate` di dalam window [start, end] inklusif.
ProgressSummary summaryInWindow(
  List<Task> tasks,
  DateTime start,
  DateTime end,
) {
  var total = 0;
  var done = 0;
  for (final t in tasks) {
    if (!t.dueDate.isBefore(start) && !t.dueDate.isAfter(end)) {
      total++;
      if (t.isDone) done++;
    }
  }
  return ProgressSummary(total: total, done: done);
}

// ---------------------------------------------------------------------------
// Aktivitas mingguan (heatmap)
// ---------------------------------------------------------------------------

/// Satu hari pada heatmap aktivitas mingguan.
class DailyCompletion {
  const DailyCompletion({
    required this.date,
    required this.label,
    required this.count,
    required this.isToday,
  });

  final DateTime date;
  final String label; // "Sen".."Min"
  final int count; // jumlah tugas selesai di tanggal ini
  final bool isToday;
}

const _idnShortWeekLetters = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

/// Aktivitas penyelesaian tugas per hari (Sen..Min) untuk minggu yang memuat
/// [now]. Menghitung [Task.completedAt] yang jatuh tepat pada tanggal tsb.
List<DailyCompletion> weeklyCompletions(List<Task> tasks, DateTime now) {
  final start = weekStart(now);
  final today = _dateOnly(now);
  final result = <DailyCompletion>[];
  for (var i = 0; i < 7; i++) {
    final date = start.add(Duration(days: i));
    var count = 0;
    for (final t in tasks) {
      final c = t.completedAt;
      if (c == null) continue;
      if (c.year == date.year && c.month == date.month && c.day == date.day) {
        count++;
      }
    }
    result.add(DailyCompletion(
      date: date,
      label: _idnShortWeekLetters[i],
      count: count,
      isToday: date.year == today.year &&
          date.month == today.month &&
          date.day == today.day,
    ));
  }
  return result;
}

// ---------------------------------------------------------------------------
// Streak
// ---------------------------------------------------------------------------

/// Jumlah hari berturut-turut (berakhir hari ini atau kemarin) yang memiliki
/// ≥1 tugas dengan `completedAt`. 0 bila tidak ada riwayat penyelesaian.
int completionStreak(List<Task> tasks, DateTime now) {
  final days = <DateTime>{};
  for (final t in tasks) {
    final c = t.completedAt;
    if (c != null) days.add(_dateOnly(c));
  }
  if (days.isEmpty) return 0;

  var cursor = _dateOnly(now);
  // Streak masih dianggap aktif bila hari ini belum ada completion tapi kemarin ada.
  if (!days.contains(cursor)) {
    cursor = cursor.subtract(const Duration(days: 1));
    if (!days.contains(cursor)) return 0;
  }
  var streak = 0;
  while (days.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

// ---------------------------------------------------------------------------
// Waktu belajar (terjadwal)
// ---------------------------------------------------------------------------

/// Total menit sesi belajar terjadwal per pekan. Tiap [Schedule] dihitung
/// sekali (jadwal bersifat mingguan berulang) berdasarkan selisih
/// `startTime`–`endTime`.
int scheduledMinutesPerWeek(List<Schedule> schedules) {
  var minutes = 0;
  for (final s in schedules) {
    final start = scheduleTimeToMinutes(s.startTime);
    final end = scheduleTimeToMinutes(s.endTime);
    if (start != null && end != null && end > start) {
      minutes += end - start;
    }
  }
  return minutes;
}
