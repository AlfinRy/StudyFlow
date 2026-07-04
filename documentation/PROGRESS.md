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
| 7. Beranda | Agregasi jadwal hari ini + tugas mendatang (data real) | ⬜ |
| 8. Progres | Donut chart + statistik (menghitung dari data tugas) | ⬜ |
| 9. Forum Diskusi | Firestore real-time (topik + reply) | ⬜ |
| 10. Profil + Materi | Edit profil (Firestore) + materi pembelajaran | ⬜ |
| 11. Polish | Sesuaikan UI final dengan Figma, testing per acceptance criteria | ⬜ |

## Catatan konfigurasi

- **Fase 1 bisa langsung dijalankan** tanpa konfigurasi apapun (local-first).
- **Mulai Fase 3 (Auth) & Fase 9 (Forum)** dibutuhkan Firebase:
  1. Buat project di [Firebase Console](https://console.firebase.google.com).
  2. Jalankan `dart pub global activate flutterfire_cli` lalu `flutterfire configure`.
  3. Tambahkan plugin `google-services` di `android/build.gradle` (otomatis via flutterfire CLI).
