# StudyFlow — Progress Tracker

Implementasi dilakukan bertahap mengikuti `PRD_StudyFlow.md` bagian 8.

| Fase | Isi | Status |
|------|-----|--------|
| 1. Foundation | Struktur folder, dependencies, design tokens, Hive init, app shell + bottom nav, top bar, shared widgets, 5 placeholder screens | ✅ Selesai |
| 2. Local Data Layer | Model + repository Hive (schedules, tasks, materials) + Riverpod providers + unit test | ✅ Selesai |
| 3. Auth | Firebase Auth (login/register/onboarding) + fallback demo lokal. *Butuh `flutterfire configure` untuk mode produksi.* | ✅ Selesai |
| 3. Auth | Firebase Auth (login/register/onboarding). *Butuh `flutterfire configure`.* | ⬜ |
| 4. Jadwal (CRUD) | Tambah/edit/hapus jadwal, horizontal date selector | ✅ Selesai |
| 5. Tugas (CRUD + filter + sort) | To-do list, filter tab, sort by deadline | ✅ Selesai |
| 6. Notifikasi | flutter_local_notifications untuk deadline (H-1 & hari-H) | ✅ Selesai |
| 7. Beranda | Agregasi jadwal hari ini + tugas mendatang (data real) | ✅ Selesai |
| 8. Progres | Donut chart + statistik (menghitung dari data tugas) | ✅ Selesai |
| 9. Forum Diskusi | Firestore real-time (topik + reply) | ⬜ |
| 10a. Materi Pembelajaran | UI list (cari + filter kategori), form tambah/edit, hapus, buka tautan. Diakses via shortcut Beranda (bukan tab ke-6). *Upload file fisik belum; saat ini URL/path/catatan.* | ✅ Selesai |
| 10b. Profil | Edit profil (nama/foto ke Firestore). Saat ini hanya logout yang berfungsi. | ⬜ |
| 11. Polish | Sesuaikan UI final dengan Figma, testing per acceptance criteria | ⬜ |

## Catatan konfigurasi

- **Fase 1 bisa langsung dijalankan** tanpa konfigurasi apapun (local-first).
- **Mulai Fase 3 (Auth) & Fase 9 (Forum)** dibutuhkan Firebase:
  1. Buat project di [Firebase Console](https://console.firebase.google.com).
  2. Jalankan `dart pub global activate flutterfire_cli` lalu `flutterfire configure`.
  3. Tambahkan plugin `google-services` di `android/build.gradle` (otomatis via flutterfire CLI).

## Catatan Fase 10a (Materi Pembelajaran)

- **Diakses via shortcut** dari Beranda (section "Materi Pembelajaran" +
  tombol "Lihat semua"/tap kartu), bukan menambah tab ke-6 di bottom nav —
  sesuai rekomendasi UI_DESIGN.md §9.1 agar bottom nav tetap 5 item.
- **Backend sudah siap sebelumnya** (`MaterialRepository` + Riverpod
  `materialListProvider`, box Hive `materials`); fase ini hanya melengkapi
  lapisan presentation.
- **CRUD lengkap & reaktif**: tambah/edit/hapus langsung tercermin di list.
- **Buka**: tipe `link`/`pdf`/`image` membuka URI via `url_launcher`
  (dependency baru); tipe `note` ditampilkan sebagai dialog isi catatan.
- **Upload file fisik belum**: tidak ada file picker. Saat ini PDF/gambar
  memakai URL/path referensi, tautan divalidasi (skema http/https + host),
  catatan berupa teks. Upload asli menyusul saat ditambahkan picker +
  penyimpanan file.
- **Cloud sync `materials` (Firestore)** belum (seluruh fitur inti tetap
  offline-first via Hive).

## Catatan Fase 8 (Progres Belajar)

- **Perubahan model:** field `completedAt` (nullable) ditambahkan ke `Task`
  (penyimpangan terdokumentasi, backward-compatible via Hive map) agar progres
  mingguan, heatmap aktivitas, dan streak bisa dihitung akurat. Di-set saat
  tugas ditandai selesai, di-null-kan saat dibuka kembali.
- **Semua metrik real (bukan difabrikasi):** persen tugas selesai, jumlah
  tugas, waktu belajar terjadwal (dari durasi jadwal), streak harian, XP/level
  (deterministik dari tugas selesai), dan pencapaian (milestone dari jumlah
  tugas/streak).
- **Sinkronisasi cloud `progress/{uid}` (PRD §5.5)** belum aktif — menunggu
  konfigurasi Firebase (Fase 9). Seluruh perhitungan sudah akurat dari sumber
  lokal dan reaktif lewat Riverpod.
- **Widget test** memakai provider override in-memory (bukan tulis Hive) untuk
  menghindari interaksi Hive + flutter_test FakeAsync.
