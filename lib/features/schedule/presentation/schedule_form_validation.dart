import '../../../core/utils/date_labels.dart';

/// Hasil validasi form jadwal. `null` berarti valid.
typedef ScheduleFormError = String?;

/// Validasi murni untuk form jadwal (PRD §9: uji logic non-UI).
/// Mengembalikan pesan error jika ada, atau null jika valid.
ScheduleFormError validateScheduleForm({
  required String title,
  required String startTime,
  required String endTime,
}) {
  if (title.trim().isEmpty) {
    return 'Judul jadwal tidak boleh kosong.';
  }
  final start = scheduleTimeToMinutes(startTime);
  final end = scheduleTimeToMinutes(endTime);
  if (start == null || end == null) {
    return 'Format jam mulai/selesai tidak valid.';
  }
  if (start >= end) {
    return 'Jam selesai harus setelah jam mulai.';
  }
  return null;
}
