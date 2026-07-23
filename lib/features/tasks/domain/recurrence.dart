/// Pola pengulangan tugas (recurring task, ekstensi Tier 2 roadmap).
///
/// Saat sebuah tugas berulang ditandai selesai, instance berikutnya otomatis
/// dibuat dengan deadline maju sesuai pola ini (lihat
/// `TaskRepository.generateNextOccurrence`). Instance yang selesai dipertahankan
/// agar riwayat (XP/streak Fase 8) tetap akurat.
///
/// Disimpan sebagai `name` (string) di Hive — konsisten dengan `TaskPriority`.
enum Recurrence {
  none('Tidak berulang'),
  daily('Setiap hari'),
  weekly('Setiap minggu'),
  biweekly('Setiap 2 minggu'),
  monthly('Setiap bulan');

  const Recurrence(this.label);

  final String label;

  /// Apakah pola ini aktif (bukan none).
  bool get isActive => this != Recurrence.none;

  /// Deadline instance berikutnya relatif terhadap [from].
  ///
  /// Waktu (jam:menit) dipertahankan. Untuk `monthly`, overflow tanggal
  /// dinormalisasi oleh konstruktor `DateTime` (cth. 31 Jan → akhir Feb).
  DateTime nextDueDate(DateTime from) {
    switch (this) {
      case Recurrence.none:
        return from;
      case Recurrence.daily:
        return from.add(const Duration(days: 1));
      case Recurrence.weekly:
        return from.add(const Duration(days: 7));
      case Recurrence.biweekly:
        return from.add(const Duration(days: 14));
      case Recurrence.monthly:
        return DateTime(
          from.year,
          from.month + 1,
          from.day,
          from.hour,
          from.minute,
          from.second,
        );
    }
  }

  /// Parse dari nilai string Hive. Default `none` jika tidak dikenal/kosong.
  static Recurrence fromName(String? value) {
    if (value == null) return Recurrence.none;
    for (final r in Recurrence.values) {
      if (r.name == value) return r;
    }
    return Recurrence.none;
  }
}
