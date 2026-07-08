import '../domain/material_file_type.dart';

/// Validasi murni untuk form materi (PRD §9: uji logic non-UI).
/// Mengembalikan pesan error jika ada, atau null jika valid.
String? validateMaterialForm({
  required String title,
  required String source,
  required MaterialFileType type,
}) {
  if (title.trim().isEmpty) {
    return 'Judul materi tidak boleh kosong.';
  }
  if (source.trim().isEmpty) {
    return (type == MaterialFileType.pdf || type == MaterialFileType.image)
        ? 'Pilih file terlebih dahulu.'
        : 'Isi materi tidak boleh kosong.';
  }
  // Untuk tipe tautan, pastikan bentuk URL valid (skema http/https).
  if (type == MaterialFileType.link) {
    final uri = Uri.tryParse(source.trim());
    if (uri == null ||
        uri.host.isEmpty ||
        !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return 'Masukkan URL yang valid (mis. https://...).';
    }
  }
  return null;
}

/// Kategori materi yang umum (UI_DESIGN.md §9.1 chip kategori).
const List<String> defaultMaterialCategories = [
  'Sains',
  'Matematika',
  'Bahasa',
  'Sosial',
  'Seni',
  'Umum',
];
