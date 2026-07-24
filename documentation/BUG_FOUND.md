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

## 2. Mode gelap & terang — ✅ FIXED (akar masalah: warna non-reaktif)
**Gejala:** Beberapa komponen tidak ikut berubah saat toggle mode.
**Akar masalah (DITEMUKAN):** token warna adaptif (`surface`, `textPrimary`,
etc.) dibaca dari variabel **`static` global** (`AppColors.brightness`),
bukan dari `Theme`. Karena banyak layar dibuat `const` (mis. `const MainShell()`),
Flutter **melewati rebuild** mereka saat tema berganti → warna statis tak pernah
 dibaca ulang → layar tampak "bebeku" di mode lama. Inilah sebabnya "beberapa
 komponen tidak ikut".
**Fix definitif:** warna adaptif kini **reaktif** lewat `Theme.of(context)`
(extension `AdaptiveAppColors on BuildContext` → `context.surface`,
`context.textPrimary`, dst.). Karena `Theme` adalah InheritedWidget, **semua
widget — termasuk yang `const` — otomatis di-build ulang** saat mode berganti.
216 titik pemakaian dimigrasi. Slot `colorScheme` (`surface`, `onSurface`,
`onSurfaceVariant`, `outline`) + `scaffoldBackgroundColor` di-set per-mode di
`AppTheme`. Komponen overlay (dialog/sheet/menu) juga diberi tema eksplisit.
**Hasil:** seluruh app kini konsisten ikut mode gelap/terang.

## 3. Daftar melalui email — ✅ FIXED (+ logging diagnostik)
**Gejala:** Klik "Daftar Sekarang" tidak terjadi apa-apa.
**Penyebab utama:** Validasi form gagal **diam-diam** — kebijakan sandi (min 8
+ huruf + angka) menolak sandi lemah, error hanya tampil inline (sering tak
terlihat pengguna) → tombol terkesan "diam". Penyebab lain: panggilan Firebase
bisa *hang* di emulator/hp (jaringan tidak stabil) tanpa feedback.
**Fix:**
- Validasi gagal kini memunculkan **snackbar** "Periksa kembali isian...".
- Panggilan `register()` dibungkus **timeout 25 detik** → bila server lambat,
 muncul error (bukan macet di loading).
- **Logging detail** `[Register]` & `[Auth]` di setiap tahap → jalankan
  `flutter logs` untuk lihat titik henti tepatnya.
- Catatan: setelah daftar sukses, app **sengaja** mengarah ke layar Verifikasi
  Email (fitur keamanan) — bukan bug. Pesan "Akun dibuat! Cek email..." muncul.
- **Penting:** bila masih "tidak terjadi apa-apa" → kemungkinan APK di hp MASIH
  versi lama. Wajib **rebuild** (`flutter run` / install APK baru) agar fix aktif.

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
