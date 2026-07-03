/// Tipe file materi. Disimpan sebagai `name` (string) di Hive.
/// Sumber: PRD §4.2 box `materials`.
enum MaterialFileType {
  pdf('PDF'),
  image('Gambar'),
  link('Tautan'),
  note('Catatan');

  const MaterialFileType(this.label);
  final String label;

  static MaterialFileType fromString(String? value) {
    if (value == null) return MaterialFileType.note;
    for (final t in MaterialFileType.values) {
      if (t.name == value) return t;
    }
    return MaterialFileType.note;
  }
}
