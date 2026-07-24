# Bug Found & Resolution

> Status per perbaikan. Lihat detail penyebab & langkah di bawah.

## 1. Papan Peringkat — ✅ FIXED
**Gejala:** `[cloud_firestore/failed-precondition] The query requires an index.`
**Penyebab:** Query leaderboard `where('weekId') + orderBy('weeklyXp')` butuh
*composite index* di Firestore. Index belum pernah dibuat.
**Fix:** Dibuat `firestore.indexes.json` (collection `progress`: `weekId` ASC,
`weeklyXp` DESC) + didaftarkan di `firebase.json`, lalu **dideploy** ke
`studyflow-umht` (`firebase deploy --only firestore:indexes`). Sekarang query
real-time Top-50 berjalan tanpa error.

## 2. Mode gelap & terang — ✅ FIXED (komponen tema dilengkapi)
**Gejala:** Beberapa komponen tidak ikut berubah saat toggle mode.
**Investigasi:** Audit menyeluruh — semua background/surface/teks sudah pakai
token adaptif (`AppColors.surface` dst., getter yang membaca zone brightness);
tidak ditemukan warna terang hardcoded sebagai surface. Akar masalahnya:
beberapa **widget Material default** (Dialog, BottomSheet, PopupMenu,
ListTile, SnackBar) tidak diberi tema eksplisit sehingga penyesuaian mode
tidak konsisten (termasuk *surface tint elevation* Material 3 yang memudar).
**Fix:** `app_theme.dart` kini mendefinisikan `dialogTheme`, `bottomSheetTheme`,
`popupMenuTheme`, `listTileTheme`, `snackBarTheme`, `dividerColor` dengan palet
per-mode + `surfaceTintColor: transparent`. Semua komponen overlay kini ikut
mode gelap/terang secara konsisten.

## 3. Daftar melalui email — ✅ FIXED
**Gejala:** Klik "Daftar Sekarang" tidak terjadi apa-apa.
**Penyebab utama:** Validasi form gagal **diam-diam** — kebijakan sandi (min 8
+ huruf + angka) menolak sandi lemah, error hanya tampil inline (sering tak
terlihat pengguna) → tombol terkesan "diam". Penyebab lain: panggilan Firebase
bisa *hang* di emulator (jaringan tidak stabil) tanpa feedback.
**Fix:**
- Validasi gagal kini memunculkan **snackbar** "Periksa kembali isian...".
- Panggilan `register()` dibungkus **timeout 25 detik** → bila server lambat,
  muncul error (bukan macet di loading).
- **Logging detail** di `register()` (`[Auth]` steps) → jalankan `flutter logs`
  untuk lihat titik henti tepatnya bila masih bermasalah.
- Catatan: setelah daftar sukses, app **sengaja** mengarah ke layar Verifikasi
  Email (fitur keamanan) — bukan bug.

## 4. Bagikan Pencapaian — ✅ FIXED
**Gejala:** Klik Bagikan → "Gagal membagikan. Coba lagi".
**Penyebab:** `share_plus` melempar exception saat share gambar (capture/file
share sensitif terhadap environment, terutama emulator).
**Fix:** `share_service.dart` dijadikan **berlapis (robust)**:
- Coba render kartu → PNG → share gambar.
- **Fallback otomatis**: bila share gambar gagal, bagikan **teks** saja (fitur
  tetap berfungsi) + snackbar informatif.
- **Logging detail** (`[Share]` steps) tiap tahap → `flutter logs` menunjukkan
  penyebab asli.
- Pesan error kini sesuai outcome (gambar OK / fallback teks / gagal total).
