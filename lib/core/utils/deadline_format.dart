import 'date_labels.dart';

/// "Warna nada" label deadline — dipakai UI untuk memilih warna teks.
enum DeadlineTone { normal, soon, overdue, done }

/// Hasil pemformatan deadline tugas.
class DeadlineLabel {
  const DeadlineLabel(this.text, this.tone);

  final String text;
  final DeadlineTone tone;

  bool get isOverdue => tone == DeadlineTone.overdue;
  bool get isDone => tone == DeadlineTone.done;
}

/// Format deadline tugas menjadi label relatif/absolut (UI_DESIGN.md §6):
/// "Selesai", "Jatuh tempo hari ini", "Besok", "2 hari lagi", "Deadline: 15 Okt",
/// atau "Terlambat N hari" untuk yang sudah lewat.
///
/// Pure & testable. `now` opsional untuk keperluan test.
DeadlineLabel formatTaskDeadline({
  required DateTime dueDate,
  required bool isDone,
  DateTime? now,
}) {
  if (isDone) return const DeadlineLabel('Selesai', DeadlineTone.done);

  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
  final days = due.difference(today).inDays;

  if (days < 0) {
    final overdue = -days;
    return DeadlineLabel(
      'Terlambat $overdue hari',
      DeadlineTone.overdue,
    );
  }
  if (days == 0) {
    return const DeadlineLabel('Jatuh tempo hari ini', DeadlineTone.soon);
  }
  if (days == 1) {
    return const DeadlineLabel('Besok', DeadlineTone.soon);
  }
  if (days <= 7) {
    return DeadlineLabel('$days hari lagi',
        days <= 3 ? DeadlineTone.soon : DeadlineTone.normal);
  }
  return DeadlineLabel(
    'Deadline: ${dueDate.day} ${idnShortMonth(dueDate.month)}',
    DeadlineTone.normal,
  );
}
