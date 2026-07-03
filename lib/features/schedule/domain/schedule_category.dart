/// Kategori jadwal. Disimpan sebagai `name` (string) di Hive.
/// Sumber: PRD §4.2 box `schedules`.
enum ScheduleCategory {
  kuliah('Kuliah'),
  sekolah('Sekolah'),
  pribadi('Pribadi');

  const ScheduleCategory(this.label);
  final String label;

  static ScheduleCategory? fromString(String? value) {
    if (value == null) return null;
    for (final c in ScheduleCategory.values) {
      if (c.name == value) return c;
    }
    return null;
  }
}
