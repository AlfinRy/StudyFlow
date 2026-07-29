import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Tujuan belajar utama pengguna (FEATURE_ROADMAP #8 — Onboarding
/// personalisasi). Dipilih saat onboarding & dapat diubah di Profil.
///
/// Menentukan sapaan & saran yang dipersonalisasi di Beranda. Disimpan lokal
/// (Hive `settings` via [studyGoalProvider]) — tidak terikat akun Firebase
/// karena pemilihan terjadi sebelum login.
enum StudyGoal {
  utbk(
    label: 'UTBK / SNBT',
    icon: LucideIcons.target,
    description: 'Persiapan masuk PTN lewat jalur tes nasional.',
    tip: 'Latih soal tiap hari & simulasi tes di akhir pekan.',
  ),
  ujian(
    label: 'Ujian Sekolah',
    icon: LucideIcons.school,
    description: 'Fokus pada ulangan & ujian semester.',
    tip: 'Bagi materi per bab lalu ulang berkala sebelum ujian.',
  ),
  kuliah(
    label: 'Tugas Sekolah / Kuliah',
    icon: LucideIcons.listTodo,
    description: 'Manajemen tugas, deadline, & proyek sekolah/kuliah.',
    tip: 'Pecah tugas besar jadi sub-tugas dengan deadline bertahap.',
  ),
  mandiri(
    label: 'Belajar Mandiri',
    icon: LucideIcons.bookOpen,
    description: 'Belajar rutin untuk pengembangan diri.',
    tip: 'Tetapkan jadwal belajar konsisten setiap hari.',
  );

  const StudyGoal({
    required this.label,
    required this.icon,
    required this.description,
    required this.tip,
  });

  /// Nama singkat untuk ditampilkan (cth. kartu pilihan, chip Beranda).
  final String label;

  /// Ikon representatif (Lucide) — tampil besar di kartu pilihan & chip.
  final IconData icon;

  /// Penjelasan singkat tujuan (di kartu pilihan & dialog Profil).
  final String description;

  /// Saran belajar kontekstual yang ditampilkan di Beranda saat tak ada
  /// jadwal/tugas mendesak.
  final String tip;
}
