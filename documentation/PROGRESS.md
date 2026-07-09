# StudyFlow — Progress Tracker

Implementasi dilakukan bertahap mengikuti `PRD_StudyFlow.md` bagian 8.

| Fase | Isi | Status |
|------|-----|--------|
| 1. Foundation | Struktur folder, dependencies, design tokens, Hive init, app shell + bottom nav, top bar, shared widgets, 5 placeholder screens | ✅ Selesai |
| 2. Local Data Layer | Model + repository Hive (schedules, tasks, materials) + Riverpod providers + unit test | ✅ Selesai |
| 3. Auth | Firebase Auth (email/password + Google) + fallback demo lokal. Terkonfigurasi (`studyflow-umht`); SHA fingerprint terdaftar, OAuth client aktif. | ✅ Selesai |
| 4. Jadwal (CRUD) | Tambah/edit/hapus jadwal, horizontal date selector | ✅ Selesai |
| 5. Tugas (CRUD + filter + sort) | To-do list, filter tab, sort by deadline | ✅ Selesai |
| 6. Notifikasi | flutter_local_notifications untuk deadline (H-1 & hari-H) | ✅ Selesai |
| 7. Beranda | Agregasi jadwal hari ini + tugas mendatang (data real) | ✅ Selesai |
| 8. Progres | Donut chart + statistik (menghitung dari data tugas) | ✅ Selesai |
| 9. Forum Diskusi | Firestore real-time (topik + reply) | ⬜ |
| 10a. Materi Pembelajaran | UI list (cari + filter kategori), form tambah/edit, hapus, buka file. Diakses via shortcut Beranda (bukan tab ke-6). *Upload file fisik (PDF/Gambar) via file picker ✅; Tautan/Catatan tetap input teks.* | ✅ Selesai |
| 10b. Profil | Edit profil (nama/foto ke Firestore). Saat ini hanya logout yang berfungsi. | ⬜ |
| 11. Polish | Sesuaikan UI final dengan Figma, testing per acceptance criteria | ⬜ |

## Catatan konfigurasi

- **Fase 1 bisa langsung dijalankan** tanpa konfigurasi apapun (local-first).
- **Firebase SUDAH terkonfigurasi (sesi ini):**
  - Project: **`studyflow-umht`** (display "Study Flow") di akun Firebase user.
  - `firebase` CLI 15.22.4 & `flutterfire` CLI 1.4.0 terpasang.
  - `flutterfire configure` dijalankan (android, package `com.example.study_flow`):
    - Generate `android/app/google-services.json` & `lib/firebase_options.dart`.
    - Pasang plugin `com.google.gms.google-services` v4.3.15 di `settings.gradle.kts` + `app/build.gradle.kts`.
  - `FirebaseService.initialize()` kini pakai `DefaultFirebaseOptions.currentPlatform`.
    Fallback demo lokal tetap aktif untuk platform yang belum dikonfigurasi (iOS/Web/Windows).
- **Provider Auth yang di-enable (user, console):** Email/Password ✅ & Google ✅
  di project `studyflow-umht`. Termasuk SHA-1/SHA-256 fingerprint debug keystore
  terdaftar via CLI (`firebase apps:android:sha:create`) + OAuth client
  (client_type 1 & 3) di `google-services.json`.
- **Google Sign-In ✅ (sesi ini):** pakai `google_sign_in` 6.3.0 (API `.signIn()`+
  `.authentication`). Tombol di Login aktif hanya di mode Firebase. Role default
  user Google baru = **Mahasiswa** (Google tak punya field role).
- **Catatan:** akun demo lama (Hive) tidak ikut pindah ke Firebase — daftar akun
  baru setelah aktivasi. (Opsional: ada project `studyflow-f9625` tak terpakai di
  akun — bisa di-delete via console.)

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
- **Upload file fisik ✅ (sesi ini):** tipe `pdf` & `image` kini memakai file
  picker asli (`file_picker`). File disalin ke `<app documents>/materials/`
  agar persisten (bukan path cache sementara). Tipe `link` tetap input URL
  (divalidasi skema http/https + host), `note` tetap input teks.
  - **Buka:** `image` → preview in-app (`Image.file`); `pdf` → aplikasi PDF
    eksternal via `open_filex`; `link` → `url_launcher`; `note` → dialog.
  - **Backward-compat:** data lama pdf/gambar berupa URL tetap dibuka via browser.
  - **Dependency baru:** `file_picker` ^11.0.2, `path_provider` (kini direct),
    `open_filex` ^4.7.0. Tidak perlu permission tambahan (SAF + FileProvider).
  - **Validasi:** tipe file wajib pilih file → "Pilih file terlebih dahulu.".
  - **Catatan minor:** saat materi dihapus, file fisik di storage tidak ikut
    terhapus (orphan) — belum di-wire (opsional dikerjakan nanti).
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

## 📌 Selanjutnya

Firebase Auth lengkap & aktif: Email/Password + Google Sign-In (SHA-1/SHA-256
terdaftar, OAuth client terisi). Tinggal reinstall APK terbaru + test di HP.

1. **Reinstall APK terbaru** (55.8MB) → test Register email, Login email, & tombol
   "Lanjutkan dengan Google". Konfirmasi ke agent.
2. **Fase 10b** — Edit Profil (nama/foto ke Firestore `users/{uid}`).
3. **Fase 9** — Forum Diskusi (Firestore real-time: topik + reply).
4. **Opsional** — hapus file fisik saat materi di-delete (anti-orphan).
5. **Pra-rilis** — ganti `applicationId` (`com.example.study_flow`) & buat
   keystore release sebelum upload Play Store.

State kode: `flutter analyze` 0 issue, 88/88 test lulus, APK release ter-built
(`build/app/outputs/flutter-apk/app-release.apk`, 55.8MB).
