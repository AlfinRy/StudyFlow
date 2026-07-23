# StudyFlow — Feature Roadmap (User Acquisition & Retention)

> Hasil eksplorasi fitur yang bisa menarik & mempertahankan pengguna,
> dikelompokkan berdasarkan **dampak vs effort**, dan **didasarkan pada
> arsitektur yang sudah ada** (offline-first Hive + Firebase + Riverpod +
* fondasi gamifikasi). Status implementasi fitur inti: Fase 1–10 PRD selesai,
> Fase 12 (hardening keamanan) selesai.

Metode prioritisasi: **ICE-lite** (Impact / Confidence / Ease).

---

## 🏆 Tier 1 — Pemenang retensi (Dampak tinggi, fondasi sudah ada)

### 1. Pomodoro / Focus Timer ⭐ prioritas tertinggi
**Kenapa:** Fitur pembeda yang dicari di hampir semua app belajar (Forest,
Todoist, Notion). Tanpa ini, StudyFlow "hanya" planner. Dengan ini, jadi
*learning companion*.

**Manfaat retensi:** sesi fokus adalah *daily habit loop* → user balik tiap hari.
**Fondasi yang bisa dipakai:**
- Gamifikasi (`gamification.dart`) → XP per sesi fokus (mirip `xpPerTask`).
- `progress/{uid}.weeklyStudyMinutes` (PRD §4.1) — field sudah dirancang, belum dipakai → pomodoro mengisinya.
- Tugas lokal (Hive) → timer bisa "taruh pada sebuah tugas".

**Estimasi effort:** sedang. State: timer service + layar + integrasi XP.
**UI (prinsip impeccable):** satu layar penuh, lingkaran progres besar
(donut yang sudah ada di Progres bisa di-reuse), warna `navyGradient`,
presisi detik, haptic feedback saat selesai. **Bukan** hero-metric template.

### 2. Leaderboard Mingguan (cloud)
**Kenapa:** kompetisi sosial = motivasi terkuat untuk demografi siswa/mahasiswa.
**Fondasi:** Firestore real-time (sama pola dengan Forum), XP deterministik
sudah dihitung. Cukup tambah collection `leaderboards/{week}` sinkron dari
`progress/{uid}`.
**Catatan keamanan:** anonimisasi opsional, opt-in (privasi), rate-limit tulis
(sudak ada utility `RateLimiter`).
**Estimasi effort:** sedang. Butuh Cloud Function ( Blaze plan) atau scheduled
write untuk reset mingguan — alternatif: kalkulasi client-side dari `progress`.

---

## 🥈 Tier 2 — Produktivitas dalam (mengurangi gesekan, naikkan stickiness)

### 3. Tugas berulang (Recurring Tasks) ✅
"Ulang setiap Senin", "tiap 2 minggu". Mengurangi input manual rutin.
**Effort:** rendah–sedang (field `recurrence` di model Task Hive).
**Status:** ✅ Selesai (Fase 14). Enum `Recurrence` (none/daily/weekly/
biweekly/monthly) + logika `nextDueDate`. Saat tugas berulang diselesaikan,
instance berikutnya otomatis dibuat (deadline maju, pengingat dijadwalkan
ulang) seperti Todoist; instance selesai dipertahankan agar XP/streak akurat.
Dropdown pengulangan di form + badge di kartu tugas.

### 4. Widget layar utama (Android AppWidget)
Tampilkan tugas hari ini + countdown di home screen → *passive engagement*.
**Effort:** tinggi (native Kotlin di `android/`), tapi *high impact* untuk
retensi mobile.

### 5. Impor Kalender (.ics) & Sinkronisasi
Tombol placeholder "Import Kalender" sudah ada di empty state Jadwal
(UI_DESIGN.md §5). Baca `.ics` → jadwal.
**Effort:** sedang.

### 6. Dark Mode & Theming
**Effort:** rendah. Design tokens (`app_colors.dart`) tinggal dibuat adaptif.
Sesuai prinsip impeccable: *dark is never a default* — pilih berdasarkan scene
(siswa belajar malam di kamar → dark memang tepat).

---

## 🥉 Tier 3 — Kesenangan & diferensiasi (impeccable `delight`/`animate`)

### 7. Confetti & haptic saat selesaikan tugas / naik level
Payoff gamifikasi yang sudah ada. Micro-interaction = kesan "hidup".
**Effort:** rendah (`confetti` package + `HapticFeedback`).

### 8. Onboarding personalisasi
Pilih tujuan belajar (UTBK, ujian, tugas kuliah) → dashboard & saran template
jadwal disesuaikan. Meningkatkan aktivasi first-run.

### 9. Streak freeze & reward harian ✅
Mirip Duolingo: streak (sudah dihitung!) + "freeze" untuk hari libur +
daily check-in reward. Retensi harian ekstrem.
**Status:** ✅ Selesai (Fase 15). Modul `lib/features/streak/`: profil
persisten (Hive `settings`), logika murni (`streakFromActive`,
`tryApplyFreeze`, `dailyRewardFor`, `canClaimDaily`, `earnsFreezeAt`).
Freeze otomatis dipakai saat streak akan putus (rekonsiliasi saat Progres
 dibuka) — hanya melindungi rantai nyata, tidak meng-inflate streak dari nol.
Hadiah harian: +XP (skala dgn streak, 5–30) + bonus freeze tiap kelipatan 7
hari. Bonus XP tergabung ke `totalXpProvider`. UI: kartu streak dengan jumlah
freeze, rekor, & tombol klaim (confetti saat diklaim).

### 10. Pencarian global + tag materi
Saat data materi/forum tumbuh, search menjadi kebutuhan.

---

## 🔌 Tier 4 — Sosial / akuisisi viral

### 11. Grup belajar / Jadwal bersama
Perluas Forum → "Study Room" dengan jadwal/tugas bersama. Viral loop:
satu user mengajak teman.

### 12. Bagikan pencapaian (Share milestone)
Generate kartu prestasi → share ke IG/WA. Akuisisi organik.

---

## Rekomendasi eksekusi berikutnya

| Urut | Fitur | Status |
|------|-------|--------|
| 1 | **Pomodoro** | ✅ Selesai (Fase 13) |
| 2 | **Confetti + haptic** | ✅ Selesai (Fase 13) |
| 3 | **Leaderboard** | ✅ Selesai (Fase 13) |
| 4 | **Dark mode** | ✅ Selesai (Fase 13) |
| 5 | **Tugas berulang** (Tier 2) | ✅ Selesai (Fase 14) |
| 6 | **Streak freeze & reward harian** (Tier 3) | ✅ Selesai (Fase 15) |

Enam fitur sudah terimplementasi. Progress berikutnya dilakukan bertahap
(satu fitur per commit). Kandidat lanjutan (Tier 2–4): widget layar utama
Android, impor kalender .ics, onboarding personalisasi, pencarian global,
grup belajar, bagikan pencapaian.

## Catatan skill (find-skills)
Pencarian `npx skills find` untuk Flutter/gamifikasi mengembalikan skill
ber-install rendah (<400) & kurang mapan (cth. Godot, generic). **Tidak
direkomendasikan** pasang otomatis. Untuk UI, gunakan **impeccable** — meski
berbasis web, prinsipnya (kontras ≥4.5:1, hierarki tipografi, ritme spacing,
motion purposeful, anti-pattern: gradient-text, nested cards, eyebrow-every-
section) berlaku langsung untuk komponen Flutter Material.
