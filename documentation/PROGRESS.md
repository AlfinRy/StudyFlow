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
| 9. Forum Diskusi | Firestore real-time (topik + reply). Cloud-only; akses via shortcut Beranda. Rules forum terdeploy. | ✅ Selesai |
| 10a. Materi Pembelajaran | UI list (cari + filter kategori), form tambah/edit, hapus, buka file. Diakses via shortcut Beranda (bukan tab ke-6). *Upload file fisik (PDF/Gambar) via file picker ✅; Tautan/Catatan tetap input teks.* | ✅ Selesai |
| 10b. Profil | Edit profil (nama/role/foto). Foto upload PNG/JPG (base64 di Firestore) + URL. Cloud sync aktif. | ✅ Selesai |
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

## Catatan Fase 10b (Edit Profil)

- **Form edit profil ✅:** nama, peran (role), dan URL foto. Tersimpan via
  `AuthRepository.updateProfile` → cache Hive (`profile_{uid}`) reaktif, jadi
  langsung tercermin di seluruh UI (top bar, profil, dll) tanpa login ulang.
  Email read-only (dari Firebase Auth).
- **Cloud sync Firestore ✅:** `updateProfile` + register/login/Google menulis/
  membaca `users/{uid}` (best-effort, try/catch). DB Firestore di-enable &
  `firestore.rules` sudah di-deploy → cloud sync & lintas-perangkat aktif.
- **`firestore.rules` ✅ terdeploy:** user hanya boleh baca/tulis dokumen
  profilnya sendiri (`users/{uid}`).
- **Foto upload ✅ (base64):** PNG/JPG dari galeri → dikompres
  (`flutter_image_compress`, ~512px JPEG q80) → disimpan sebagai data URI
  base64 di dokumen Firestore `users/{uid}` (gratis, tanpa Storage/Blaze).
  Widget `AppAvatar` merender base64 / URL / inisial. URL foto manual tetap
  tersedia. (Storage tak dipakai: butuh plan Blaze/billing.)
- **`FirebaseAuthRepository.authStateChanges()`** kini via `StreamController`
  (mirip `LocalAuthRepository`) agar edit profil bisa memancarkan update.
- **Perbaikan tampilan foto (user Google):** `_map` kini **cache-first** untuk
  `photoUrl` (`cache['photoUrl'] ?? u.photoURL`) — sebelumnya `u.photoURL` (foto
  Google) selalu menimpa hasil edit; sekarang pilihan user (foto upload)
  diutamakan, foto Google hanya fallback awal.
- **Dependency baru:** `cloud_firestore` 5.6.12, `flutter_image_compress` 2.4.0
  (resize gambar). `firebase_storage` sempat dipasang lalu dilepas (butuh Blaze).

## Catatan Fase 9 (Forum Diskusi)

- **Fitur cloud-only (PRD §5.6):** real-time via Firestore, butuh internet.
  Tidak di-cache Hive (offline-first hanya untuk fitur inti).
- **Struktur:** `lib/features/discussion/` — domain (`ForumTopic`, `ForumReply`),
  data (`ForumRepository` Firestore), providers (`StreamProvider.autoDispose`
  topik & reply), presentation (`ForumScreen` daftar, `TopicDetailScreen` +
  reply input sticky, `NewTopicScreen` form). Widget `TopicCard` & `ReplyBubble`.
- **Akses via shortcut** Beranda (bukan tab ke-6) — `SectionHeader "Forum
  Diskusi"` + `_ShortcutCard` → `ForumScreen`. Sama seperti Materi
  (UI_DESIGN.md §9.2).
- **Real-time:** `StreamProvider` (autoDispose) topik (`createdAt` desc) & reply
  (`createdAt` asc). Topik baru/balasan langsung muncul tanpa refresh.
- **`replyCount` didenormalisasi** di dokumen topik; di-increment atomik via
  batch saat tambah reply (rules: field identitas topik tidak boleh berubah).
- **`firestore.rules` ✅ terdeploy:** forum publik (read) untuk user login;
  create topik/reply wajib `authorId == uid` + field valid; update topik hanya
  `replyCount`; hapus dinonaktifkan (belum ada fitur hapus).
- **`timeAgo()` baru** di `date_labels.dart`: waktu relatif ID ("baru saja",
  "5 menit lalu", "kemarin", dst) — pure, teruji unit test.
- **Mode demo:** forum nonaktif (EmptyState "butuh akun").
- **Unit test ✅:** validasi topik (judul/isi), snippet, & `timeAgo`
  (`test/forum_test.dart`, +16 test → total 104).

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

## 🔧 Perbaikan kecil (dari temuan pengujian — selesai)

1. **Logout → login Google tak muncul account picker ✅:** `signOut()` kini juga
   memanggil `GoogleSignIn().signOut()` agar akun cache terhapus → picker
   muncul lagi saat login.
2. **Konfirmasi logout ✅:** dialog "Keluar dari akun?" (helper generik baru
   `showConfirmDialog` di `app_dialogs.dart`, `isDestructive`) sebelum
   `signOut()` di tile Keluar.

## 📌 Lanjut besok

Hari ini selesai: **Forum Diskusi (Fase 9)** real-time + 2 perbaikan kecil
(Google account picker & konfirmasi logout). **Semua fase inti PRD (1–10) kini
selesai.**

Sisa (opsional / pra-rilis):
1. **Polish (Fase 11)** — sesuaikan UI final dengan Figma, testing per
   acceptance criteria.
2. **Hapus file fisik** saat materi di-delete (anti-orphan).
3. **Forum:** edit/hapus topik & reply (opsional — belum di-PRD).
4. **Pra-rilis** — ganti `applicationId` (`com.example.study_flow`) & buat
   keystore release sebelum upload Play Store.

State kode: `flutter analyze` 0 issue, 104/104 test lulus, APK release ter-built
(`build/app/outputs/flutter-apk/app-release.apk`, 57.1MB).
