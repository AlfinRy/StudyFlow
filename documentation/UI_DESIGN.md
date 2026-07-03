# StudyFlow — UI Design Reference (for Claude Code)

> Dokumen ini mendeskripsikan desain UI StudyFlow berdasarkan screen yang sudah dibuat di Figma/Google Stitch. Gunakan ini sebagai acuan visual saat mengimplementasikan widget di Flutter, berpasangan dengan `PRD_StudyFlow_ClaudeCode.md` untuk logic/data.
>
> **Status:** 11 layar sudah didesain dan dikonfirmasi dari screenshot asli. 2 layar (Materi Pembelajaran, Forum Diskusi) **belum didesain** — bagian 9 berisi usulan layout yang konsisten dengan visual language yang ada, sifatnya draft dan perlu direview/didesain ulang di Figma sebelum final.

---

## 1. Design Tokens

### 1.1 Warna

| Token | Perkiraan Hex | Penggunaan |
|---|---|---|
| `primaryDark` | `#0F2A47` – `#16324F` (gradient navy) | Header/hero card, splash background, top bar gelap |
| `primaryAccent` | `#2E6FE0` – `#3B82F6` (biru terang) | Tombol utama, ikon aktif, progress indicator, tab terpilih |
| `background` | `#FFFFFF` / `#F7F9FC` | Background layar utama (light mode) |
| `surfaceCard` | `#FFFFFF` dengan border tipis abu | Card jadwal/tugas/materi |
| `textPrimary` | `#0F172A` (hampir hitam) | Judul, teks utama |
| `textSecondary` | `#64748B` (abu) | Subteks, deskripsi, placeholder |
| `success` | `#16A34A` / hijau | Status "Selesai" |
| `warning` | `#F59E0B` / oranye | Prioritas "Normal", "Rendah" |
| `danger` | `#DC2626` / merah | Prioritas "Urgent", deadline dekat |
| `infoBlue` | `#2563EB` | Badge "Online", info tambahan |

> Catatan: hex di atas adalah estimasi visual dari screenshot. Saat implementasi, ambil nilai exact dari Figma (via inspect/export) agar presisi.

### 1.2 Tipografi

- Font terlihat seperti sans-serif modern (mirip **Inter** atau **Plus Jakarta Sans**) — konfirmasi nama font asli di Figma.
- Heading besar (contoh "Halo, Andi Pratama!"): bold, ~20-24sp
- Judul card/section (contoh "Jadwal Hari Ini"): semi-bold, ~16sp
- Body/teks item: regular, ~14sp
- Label kecil/badge (contoh "URGENT", "2 hari lagi"): bold, ~10-11sp, uppercase pada badge

### 1.3 Komponen Umum

- **Top App Bar:** hamburger menu (kiri), logo "StudyFlow" + ikon buku kecil, ikon notifikasi (lonceng) di kanan. Di halaman Profil ada tambahan avatar kecil di pojok kanan.
- **Bottom Navigation Bar:** 5 item tetap di semua halaman utama — **Beranda, Jadwal, Tugas, Progres, Profil** — masing-masing dengan ikon + label, item aktif berwarna `primaryAccent` dengan background pill.
- **Floating Action Button (+):** muncul di halaman Beranda, Jadwal, dan Tugas — warna `primaryAccent`, posisi kanan-bawah, untuk aksi tambah cepat.
- **Card:** rounded corners (~12-16px), shadow tipis, padding konsisten ~16px.
- **Progress indicator:** dua varian — linear progress bar (di dashboard, tugas) dan circular/donut chart (di halaman Progres).
- **Badge/Tag:** pill-shaped kecil dengan warna semantik (urgent=merah, normal=oranye/kuning, selesai=hijau, online=biru).
- **Checkbox list item:** dipakai di halaman Tugas untuk menandai selesai.

---

## 2. Onboarding & Splash

**Screen 1 — Intro "Mengatur Jadwal Belajar"**
- Background navy gradient dengan ilustrasi buku terbuka + elemen abstrak
- Judul + deskripsi singkat, tombol "Lewati" (text button, kiri bawah) dan "Lanjut →" (filled button, kanan bawah)
- Indikator progress onboarding (dots/bar) di atas tombol

**Screen 2 — Splash "StudyFlow"**
- Logo besar di tengah, tagline "Belajar lebih efektif, terorganisir, dan menyenangkan"
- Teks kecil "ACADEMIC EXCELLENCE" di bawah sebagai closing branding

---

## 3. Autentikasi

**Login ("Selamat Datang")**
- Header card navy dengan logo, judul "Selamat Datang", subjudul "Silakan masuk ke akun Anda"
- Input Email (dengan ikon amplop)
- Input Kata Sandi (dengan ikon gembok + toggle show/hide password), link "Lupa password?" sejajar label
- Tombol "Masuk →" (filled, full width, warna navy/biru gelap)
- Divider "atau"
- Tombol sekunder "Lanjutkan dengan Google" (outline, dengan ikon Google)
- Footer: "Belum punya akun? Daftar" (link)

**Register ("Daftar Akun Baru")**
- Icon app kecil di atas, judul + subjudul "Mulai perjalanan akademik cerdasmu hari ini."
- Input: Nama Lengkap, Alamat Email
- **Selector "Daftar Sebagai"**: 4 pilihan dalam grid 2x2 (Siswa, Mahasiswa, Guru, Umum) — bentuk card selectable dengan ikon, state terpilih pakai border/background biru muda
- Input Kata Sandi, Konfirmasi Sandi
- Checkbox persetujuan "Ketentuan Layanan" & "Kebijakan Privasi" (teks link berwarna biru)
- Tombol "Daftar Sekarang" (filled navy, full width)
- Footer: "Sudah punya akun? Masuk di sini"

> **Mapping ke data model:** field "Daftar Sebagai" berkorespondensi ke `role` di collection `users/{uid}` pada PRD teknis (`student` / `teacher` / `self_learner` — perlu tambahan value untuk "Siswa" vs "Mahasiswa" jika ingin dibedakan, atau digabung jadi "student" saja, perlu keputusan tim).

---

## 4. Beranda (Dashboard)

- Top bar standar
- **Hero card** navy: tanggal + "Halo, [Nama]!" + kalimat motivasi dinamis (mis. jumlah jadwal hari ini)
- **Ringkasan progres**: persentase besar + mini donut indicator di kanan, label "Target mingguan"
- **Sesi Belajar Terlama**: durasi + progress bar tipis
- **Section "Jadwal hari ini"** (dengan link "Lihat semua"): list card jadwal — ikon kategori, nama mata pelajaran, jam, lokasi/ruang, chevron kanan
- **Section "Tugas mendatang"**: card dengan badge tipe (TUGAS/PROYEK), badge urgensi waktu ("2 hari lagi", "5 hari lagi"), judul tugas, info lampiran (mis. "PDF, 2MB", "Figma File")
- FAB (+) kanan bawah
- Bottom nav aktif di "Beranda"

---

## 5. Jadwal Belajar

**State terisi:**
- Top bar dengan logo kecil (bukan hamburger penuh)
- Judul "Jadwal Belajar" + bulan berjalan ("Oktober 2023")
- **Horizontal date selector**: 6-7 hari ditampilkan sebagai chip tanggal (hari + tanggal), hari terpilih di-highlight dengan background biru solid
- Section "Jadwal Hari Ini": list card — ikon mata pelajaran (warna berbeda per kategori: matematika/fisika/bahasa/lainnya), nama pelajaran, jam mulai-selesai, badge lokasi (RUANG, LAB, PERPUSTAKAAN) atau badge "ONLINE"
- Card ringkasan "Progres Belajar 85% Selesai" dengan progress bar horizontal di bagian bawah
- FAB (+) kanan bawah

**State kosong ("Belum ada jadwal hari ini"):**
- Ilustrasi bulat besar (siluet buku bercahaya) di tengah atas
- Judul + deskripsi ajakan menambah jadwal
- Tombol "+ Tambah Jadwal" (filled navy)
- Shortcut tambahan di bawah: "Import Kalender" dan "Saran Template" (dua button outline berdampingan)

---

## 6. Tugas

**List Tugas**
- Hero card navy "Tetap Fokus / Kelola Tugas Kamu" + ringkasan jumlah tugas
- **Filter tab**: Semua / Berjalan / Selesai (segmented control/pill tabs)
- List item tugas berupa card dengan:
  - Checkbox di kiri
  - Badge prioritas (URGENT=merah, NORMAL=oranye, RENDAH=kuning/abu) + nama mata pelajaran
  - Judul tugas (bold)
  - Info deadline atau status ("Deadline: 15 Okt", "Selesai kemarin")
  - Menu titik tiga (opsi edit/hapus) di kanan
  - Card tugas yang sudah selesai: teks strikethrough / opacity lebih rendah, checkbox tercentang
- Card statistik bawah: "Statistik Pekan" (progress bar "12/15 Tugas selesai") berdampingan dengan card "Streak Belajar 5 Hari" (ikon petir)
- FAB (+) kanan bawah

**Form Tambah Tugas**
- Tombol back (←) di top bar
- Hero card navy "Tugas Baru" + deskripsi
- Input "Judul Tugas" (dengan ikon)
- Row dua kolom: "Kategori" (dropdown, mis. "Sains") dan "Lampiran" (tombol "Upload")
- Textarea "Deskripsi" (multiline, placeholder "Detail tugas, referensi, atau catatan tambahan...")
- Row dua kolom: "Tanggal Deadline" (date picker, format mm/dd/y) dan "Waktu" (time picker, format --:-- --)
- Toggle switch "Aktifkan Pengingat" dengan subtext "NOTIFIKASI 1 JAM SEBELUM"
- Tombol "💾 Simpan Tugas" (filled navy, full width) + tombol teks "Batalkan" di bawahnya
- Bottom summary bar: dua kolom kecil "Tugas Selesai 12/15" dan "Poin Belajar 480"

---

## 7. Progres Belajar

- Judul "Progres Belajar" + subjudul deskriptif
- Tab switch "Mingguan / Bulanan"
- Filter pill "Semua / Berjalan / Selesai" (konsisten dengan halaman Tugas)
- **Donut chart besar** di kiri: persentase selesai ("85% SELESAI") di tengah lingkaran
- Dua card statistik di kanan donut: "Tugas Selesai: 24 dari 28" dan "Waktu Belajar: 32j minggu ini"
- Card "Capaian Minggu Ini": teks insight motivasional (mis. perbandingan produktivitas vs minggu lalu)
- Section "Tugas Mingguan": card kalender mini per huruf hari (S S R K J S M) — kemungkinan heatmap aktivitas per hari
- Section "Milestone Terakhir" (link "Lihat semua"): list achievement dengan ikon (trofi, buku, bintang), judul, deskripsi singkat, timestamp relatif ("Hari ini", "Kemarin", "3 Mar")
- **Card gamifikasi "Level Berikutnya: 'Sarjana Handal'"**: deskripsi XP yang dibutuhkan, progress bar XP (mis. "680 XP / 1000 XP"), ilustrasi logo app di bawah
- Bottom nav aktif di "Progres"

---

## 8. Profil

- Top bar dengan avatar kecil di kanan (bukan ikon notifikasi biasa)
- **Header profil**: avatar besar bulat (dengan badge verifikasi kecil), nama lengkap, role ("Mahasiswa")
- 3 kartu statistik ringkas berdampingan: "12 Tugas Selesai", "4 Jadwal Aktif", "7 Hari Streak"
- **Section "Pengaturan Akun"**: list menu dengan ikon — Edit Profil, Notifikasi, Bahasa (dengan value "Indonesia" di kanan)
- **Section "Dukungan"**: list menu — Bantuan, Tentang Aplikasi
- Item "Keluar" (logout) berwarna merah, terpisah di paling bawah list
- Bottom nav aktif di "Profil"

---

## 9. Rekomendasi Layout — Fitur Belum Didesain

> ⚠️ Dua bagian di bawah ini **belum ada desainnya di Figma/Stitch**. Ini adalah usulan struktur yang mengikuti visual language existing (warna, tipe card, bottom nav) supaya Claude Code punya sesuatu untuk mulai coding, tapi sebaiknya didesain ulang di Figma dan file ini di-update begitu desain aslinya ada.

### 9.1 Materi Pembelajaran (draft)
- Top bar standar
- Hero card navy "Materi Pembelajaran" + search bar di bawahnya (ikuti gaya input pada form tugas)
- Filter kategori berupa horizontal chip (mis. "Semua", "Sains", "Bahasa", "Umum") — reuse pola chip dari date selector di halaman Jadwal
- List card materi: ikon tipe file (PDF/gambar/link/catatan), judul, kategori, tanggal ditambahkan, menu titik tiga (buka/hapus)
- FAB (+) untuk upload materi baru, konsisten posisi dengan halaman lain
- Bottom nav: perlu keputusan apakah "Materi" masuk sebagai tab ke-6 (nav jadi lebih padat) atau diakses dari dalam halaman lain (mis. shortcut di Beranda) — direkomendasikan opsi kedua agar bottom nav tetap 5 item.

### 9.2 Forum Diskusi (draft)
- Top bar standar
- Hero card navy "Forum Diskusi" + tombol "+ Topik Baru"
- List topik: card dengan nama pembuat + avatar kecil, judul topik, cuplikan isi (1-2 baris), jumlah balasan, timestamp relatif
- Halaman detail topik: isi topik lengkap di atas, list reply di bawah (bubble/card sederhana dengan nama + waktu), input reply sticky di bagian bawah layar
- Sama seperti Materi, disarankan diakses via shortcut (dari Beranda atau menu hamburger) daripada menambah item ke-6 di bottom nav.

---

## 10. Catatan Implementasi untuk Claude Code

- Semua warna/spacing di dokumen ini adalah **estimasi visual**. Sebelum coding komponen final, ambil nilai exact (hex, spacing, radius, font) dari Figma langsung — bisa lewat inspect panel atau MCP Figma jika kuota tersedia lagi.
- Bottom navigation bar sebaiknya diimplementasikan sebagai satu shared widget (`shared_widgets/main_bottom_nav.dart`) dan dipakai di semua halaman utama, bukan diduplikasi per halaman.
- Badge warna semantik (urgent/normal/rendah/selesai) sebaiknya di-define sebagai satu helper/enum agar konsisten dipakai di halaman Tugas maupun Jadwal.
- Untuk 2 fitur yang belum didesain (bagian 9), implementasi UI final ditunda sampai desain Figma tersedia — tapi struktur data & routing bisa disiapkan lebih dulu mengacu ke `PRD_StudyFlow_ClaudeCode.md` bagian 5.6 (Forum Diskusi) supaya tidak menghambat development fitur lain.
