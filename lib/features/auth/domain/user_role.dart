/// Peran pengguna. Nilai mengikuti grid "Daftar Sebagai" di UI_DESIGN.md §3
/// (4 pilihan). Disimpan sebagai `name` (string).
///
/// Catatan: PRD §4.1 menyebut role "student | teacher | self_learner";
/// di sini dipakai 4 nilai agar cocok dengan desain register.
enum UserRole {
  siswa('Siswa'),
  mahasiswa('Mahasiswa'),
  guru('Guru'),
  umum('Umum');

  const UserRole(this.label);
  final String label;

  static UserRole? fromString(String? value) {
    if (value == null) return null;
    for (final r in UserRole.values) {
      if (r.name == value) return r;
    }
    return null;
  }
}
