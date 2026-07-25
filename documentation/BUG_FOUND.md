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

## 3. Daftar melalui email — ✅ FIXED (akar: RateLimiter crash diam-diam)
**Gejala:** Klik "Daftar Sekarang" tidak terjadi apa-apa (Kasus 3).
**Akar masalah (DITEMUKAN via test):** `RateLimiter._read()` mengembalikan
`const <int>[]` (list **tidak bisa diubah**) saat belum ada data tersimpan.
`tryConsume()` lalu memanggil `ts.add(...)` → melempar `UnsupportedError:
Cannot add to an unmodifiable list`. Panggilan rate limiter ini berada **di luar
blok try/catch** di `_submit` → exception tidak tertangkap → **gagal diam-diam**
→ tombol terkesan "diam". Bug ini ada di **semua versi APK** (kode rate limiter
tak berubah sejak Phase 12) — bukan masalah APK stale! Berdampak pada register,
login, verifikasi, & lupa sandi (semua gagal pada pemanggilan pertama).
**Fix:** `_read()` kini mengembalikan list **bisa diubah** (`List<int>.from(raw)`
atau `<int>[]`). Dikonfirmasi via test `register_button_test.dart` yang mereproduksi
Kasus 3 (sebelumnya gagal, kini lulus — register end-to-end berfungsi).
**Tambahan:** feedback daftar kini tidak mungkin terlewat — overlay loading
layar penuh + dialog error (bukan snackbar transient); logging `[Register]`/
`[Auth]` di setiap tahap.

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
