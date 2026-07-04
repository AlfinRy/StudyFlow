/// Waktu reminder tugas (PRD §5.4: H-1 dan hari-H). Field null bila waktu
/// tersebut sudah lewat (tidak perlu dijadwalkan).
class ReminderTimes {
  const ReminderTimes({this.dayBefore, this.onDay});

  /// Reminder H-1 (default pukul [reminderHour]).
  final DateTime? dayBefore;

  /// Reminder hari-H (default pukul [reminderHour]).
  final DateTime? onDay;

  bool get isEmpty => dayBefore == null && onDay == null;
}

/// Hitung waktu reminder untuk sebuah deadline. Hanya waktu di masa depan
/// (relatif terhadap [now]) yang dikembalikan; yang sudah lewat di-null-kan
/// agar service tidak menjadwalkan notifikasi masa lalu.
///
/// Pure & testable — tidak menyentuh plugin notifikasi.
ReminderTimes computeReminderTimes({
  required DateTime dueDate,
  DateTime? now,
  int reminderHour = 8,
}) {
  final n = now ?? DateTime.now();
  final onDay = DateTime(dueDate.year, dueDate.month, dueDate.day, reminderHour);
  final dayBefore = DateTime(
      dueDate.year, dueDate.month, dueDate.day - 1, reminderHour);

  return ReminderTimes(
    dayBefore: dayBefore.isAfter(n) ? dayBefore : null,
    onDay: onDay.isAfter(n) ? onDay : null,
  );
}
