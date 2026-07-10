// Validasi murni untuk form topik forum (PRD §9: uji logic non-UI).
// Mengembalikan pesan error jika ada, atau null jika valid.

/// Validasi judul topik.
String? validateTopicTitle(String title) {
  final t = title.trim();
  if (t.isEmpty) return 'Judul topik tidak boleh kosong.';
  if (t.length > 120) return 'Judul maksimal 120 karakter.';
  return null;
}

/// Validasi isi topik.
String? validateTopicContent(String content) {
  final c = content.trim();
  if (c.isEmpty) return 'Isi topik tidak boleh kosong.';
  return null;
}
