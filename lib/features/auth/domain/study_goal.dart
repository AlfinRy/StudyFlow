/// Tujuan belajar utama pengguna (FEATURE_ROADMAP #8 — Onboarding
/// personalisasi). Dipilih saat onboarding & dapat diubah di Profil.
///
/// Menentukan sapaan & saran yang dipersonalisasi di Beranda. Disimpan lokal
/// (Hive `settings` via [studyGoalProvider]) — tidak terikat akun Firebase
/// karena pemilihan terjadi sebelum login.
enum StudyGoal {
  utbk(
    label: 'UTBK / SNBT',
    emoji: '🎯',
    description: 'Persiapan masuk PTN lewat jalur tes nasional.',
    tip: 'Latih soal tiap hari & simulasi tes di akhir pekan.',
  ),
  ujian(
    label: 'Ujian Sekolah',
    emoji: '📝',
    description: 'Fokus pada ulangan & ujian semester.',
    tip: 'Bagi materi per bab lalu ulang berkala sebelum ujian.',
  ),
  kuliah(
    label: 'Tugas Kuliah',
    emoji: '🎓',
    description: 'Manajemen tugas, deadline, & proyek mata kuliah.',
    tip: 'Pecah tugas besar jadi sub-tugas dengan deadline bertahap.',
  ),
  mandiri(
    label: 'Belajar Mandiri',
    emoji: '📚',
    description: 'Belajar rutin untuk pengembangan diri.',
    tip: 'Tetapkan jadwal belajar konsisten setiap hari.',
  );

  const StudyGoal({
    required this.label,
    required this.emoji,
    required this.description,
    required this.tip,
  });

  /// Nama singkat untuk ditampilkan (cth. kartu pilihan, chip Beranda).
  final String label;

  /// Emoji representatif (tampil besar di kartu pilihan).
  final String emoji;

  /// Penjelasan singkat tujuan (di kartu pilihan & dialog Profil).
  final String description;

  /// Saran belajar kontekstual yang ditampilkan di Beranda saat tak ada
  /// jadwal/tugas mendesak.
  final String tip;
}
