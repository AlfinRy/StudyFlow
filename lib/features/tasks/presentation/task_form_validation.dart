/// Validasi murni untuk form tugas (PRD §9: uji logic non-UI).
/// Mengembalikan pesan error jika ada, atau null jika valid.
String? validateTaskForm(String title) {
  if (title.trim().isEmpty) {
    return 'Judul tugas tidak boleh kosong.';
  }
  return null;
}

/// Kategori mata pelajaran yang umum (UI_DESIGN.md §6 "Kategori" dropdown).
const List<String> defaultTaskCategories = [
  'Sains',
  'Matematika',
  'Bahasa',
  'Sosial',
  'Seni',
  'Olahraga',
  'Umum',
];
