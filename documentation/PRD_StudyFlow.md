# StudyFlow — Technical PRD (for Claude Code)

> Dokumen ini adalah turunan teknis dari PRD akademik "PRODUCT REQUIREMENT DOCUMENT (PRD) APLIKASI STUDYFLOW" (Mata Kuliah Pemrograman Android, UMHT). Ditulis ulang agar bisa langsung dipakai sebagai konteks kerja oleh Claude Code di IDE. Dokumen desain UI ada terpisah di `UI_DESIGN.md`.

---

## 1. Ringkasan Proyek

**Nama:** StudyFlow
**Jenis:** Aplikasi manajemen belajar (LMS ringan) — Android
**Target pengguna:** Siswa SMA/SMK, mahasiswa, guru/dosen, self-learner
**Platform:** Android (Flutter)
**Model bisnis:** Free application, tanpa in-app purchase

**Masalah yang diselesaikan:**
- Jadwal belajar/kuliah tersebar dan sulit dikelola
- Tugas & deadline sering terlewat karena tidak ada reminder terintegrasi
- Materi belajar tercecer di banyak platform
- Tidak ada media diskusi terpusat
- Progres belajar tidak terpantau

---

## 2. Tech Stack (Keputusan Final)

| Layer | Teknologi | Alasan |
|---|---|---|
| Bahasa | Dart | Sesuai requirement mata kuliah |
| Framework | Flutter | Cross-platform, requirement mata kuliah |
| State Management | Riverpod (atau Provider bila tim lebih familiar) | Skala kecil-menengah, testable |
| Auth | Firebase Authentication | Perlu akun multi-device untuk fitur forum & progres |
| Database cloud | Cloud Firestore | Untuk data yang perlu shared/real-time: forum diskusi, akun, sinkronisasi progres |
| Database lokal | Hive | Cache offline untuk jadwal, tugas, materi — app tetap jalan tanpa internet |
| Notifikasi lokal | flutter_local_notifications | Reminder deadline tugas & jadwal, tidak perlu server push untuk MVP |
| Editor | VS Code | Sesuai requirement mata kuliah |
| Version control | GitHub | Backup source code |
| Desain UI | Figma / Google Stitch | Lihat `UI_DESIGN.md` |

**Prinsip arsitektur:** *offline-first, cloud-synced*. Semua fitur inti (jadwal, tugas, materi) harus tetap bisa dibaca/ditulis secara lokal (Hive) meski tanpa internet, lalu disinkronkan ke Firestore saat online. Forum diskusi butuh koneksi internet (real-time by nature).

---

## 3. Struktur Folder yang Disarankan

```
lib/
├── main.dart
├── app.dart                     # MaterialApp, routing, theme
├── core/
│   ├── constants/                # warna, spacing, text style (ambil dari UI_DESIGN.md)
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── firestore_service.dart
│   │   ├── hive_service.dart
│   │   └── notification_service.dart
│   └── utils/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/ (screens, widgets)
│   ├── schedule/
│   ├── tasks/
│   ├── materials/
│   ├── discussion/
│   ├── progress/
│   └── profile/
└── shared_widgets/
```

Setiap feature folder mengikuti pola `data / domain / presentation` agar mudah di-generate/di-extend oleh Claude Code per fitur, tanpa saling tabrakan antar modul.

---

## 4. Data Model

### 4.1 Firestore Collections

**`users/{uid}`**
```
{
  name: string,
  email: string,
  role: "student" | "teacher" | "self_learner",
  photoUrl: string?,
  createdAt: timestamp
}
```

**`discussions/{discussionId}`**
```
{
  title: string,
  authorId: string,
  authorName: string,
  content: string,
  tags: string[]?,
  createdAt: timestamp,
  replyCount: number
}
```

**`discussions/{discussionId}/replies/{replyId}`**
```
{
  authorId: string,
  authorName: string,
  content: string,
  createdAt: timestamp
}
```

**`progress/{uid}`** (ringkasan progres per user, disinkron dari data lokal)
```
{
  totalTasksCompleted: number,
  totalTasksCreated: number,
  weeklyStudyMinutes: number?,
  lastUpdated: timestamp
}
```

### 4.2 Hive Boxes (lokal, offline-first)

**Box: `schedules`**
```
{
  id: string,
  title: string,
  dayOfWeek: int,        // 1-7
  startTime: string,     // "08:00"
  endTime: string,
  location: string?,
  category: string?,     // "kuliah" | "sekolah" | "pribadi"
  isSynced: bool
}
```

**Box: `tasks`**
```
{
  id: string,
  title: string,
  description: string?,
  dueDate: DateTime,
  isDone: bool,
  reminderEnabled: bool,
  priority: string?,     // "low" | "medium" | "high"
  isSynced: bool
}
```

**Box: `materials`**
```
{
  id: string,
  title: string,
  category: string,
  filePathOrUrl: string,
  fileType: string,       // "pdf" | "image" | "link" | "note"
  createdAt: DateTime
}
```

> Catatan: field `isSynced` dipakai untuk menandai data lokal yang belum ter-push ke Firestore — penting untuk strategi sync sederhana (push saat online, retry saat gagal).

---

## 5. Spesifikasi Fitur

Setiap fitur ditulis dengan format: **Deskripsi → Functional Requirements → Acceptance Criteria**, supaya Claude Code bisa langsung menerjemahkan jadi task implementasi.

### 5.1 Autentikasi (Register/Login)
**Deskripsi:** Pengguna membuat akun dan login menggunakan Firebase Auth (email/password minimal untuk MVP).

**Functional Requirements:**
- Register dengan nama, email, password
- Login dengan email/password
- Validasi input (format email, password minimal 6 karakter)
- Session persistence (auto-login jika sudah pernah login)
- Logout

**Acceptance Criteria:**
- [ ] User baru bisa register dan otomatis masuk ke dashboard
- [ ] User terdaftar bisa login dengan kredensial yang benar
- [ ] Error message jelas untuk kredensial salah / email sudah terdaftar
- [ ] Sesi tetap aktif setelah app ditutup-buka kembali

### 5.2 Jadwal Belajar
**Deskripsi:** CRUD jadwal harian/mingguan, disimpan lokal di Hive.

**Functional Requirements:**
- Tambah/edit/hapus jadwal (judul, hari, jam mulai-selesai, kategori)
- Tampilan per hari dan per minggu
- Highlight jadwal hari ini di dashboard

**Acceptance Criteria:**
- [ ] Jadwal baru langsung muncul di list tanpa reload
- [ ] Edit dan hapus berfungsi tanpa merusak data lain
- [ ] Data tetap ada setelah app di-restart (persist di Hive)

### 5.3 To-Do List / Tugas
**Deskripsi:** Pengguna mencatat tugas dengan deadline, bisa ditandai selesai.

**Functional Requirements:**
- Tambah/edit/hapus tugas
- Tandai selesai/belum selesai
- Filter: semua / belum selesai / selesai
- Sort berdasarkan deadline terdekat

**Acceptance Criteria:**
- [ ] Tugas baru masuk ke list dan tersimpan lokal
- [ ] Toggle status selesai berubah instan di UI
- [ ] Data tugas dipakai sebagai basis perhitungan Progress Belajar (5.5)

### 5.4 Pengingat Deadline
**Deskripsi:** Notifikasi lokal untuk tugas yang mendekati deadline.

**Functional Requirements:**
- Jadwalkan local notification saat tugas dibuat (jika `reminderEnabled = true`)
- Reminder default: H-1 dan pada hari-H
- Batalkan notifikasi otomatis jika tugas ditandai selesai atau dihapus

**Acceptance Criteria:**
- [ ] Notifikasi muncul sesuai waktu yang dijadwalkan
- [ ] Tidak ada notifikasi "nyangkut" untuk tugas yang sudah selesai/dihapus
- [ ] Berfungsi walau app di background

### 5.5 Progress Belajar
**Deskripsi:** Ringkasan visual progres berdasarkan tugas selesai vs total tugas.

**Functional Requirements:**
- Hitung persentase tugas selesai (mingguan/keseluruhan)
- Tampilkan dalam bentuk chart sederhana (progress bar / donut chart)
- Sinkron ringkasan ke Firestore (`progress/{uid}`) agar bisa diakses lintas device

**Acceptance Criteria:**
- [ ] Angka progres akurat sesuai data tugas aktual
- [ ] Update otomatis saat status tugas berubah
- [ ] Data tersinkron ke cloud saat online

### 5.6 Forum Diskusi
**Deskripsi:** Ruang diskusi berbasis Firestore (real-time), pengguna bisa membuat topik dan membalas.

**Functional Requirements:**
- Buat topik diskusi baru (judul + isi)
- Lihat daftar topik (sorted by terbaru)
- Balas topik (reply)
- Real-time update (listener Firestore, bukan polling)

**Acceptance Criteria:**
- [ ] Topik baru langsung muncul di list semua user
- [ ] Reply baru langsung terlihat tanpa refresh manual
- [ ] Menampilkan nama pembuat topik/reply

### 5.7 Profil Pengguna
**Deskripsi:** Kelola data akun dasar.

**Functional Requirements:**
- Edit nama, foto profil
- Lihat email (read-only)
- Logout

**Acceptance Criteria:**
- [ ] Perubahan profil tersimpan ke Firestore dan tercermin di UI
- [ ] Logout mengembalikan user ke halaman login dan clear session

---

## 6. Non-Functional Requirements

- **Usability:** UI konsisten dengan `UI_DESIGN.md`, navigasi maksimal 2 tap ke fitur utama dari dashboard
- **Performance:** Transisi antar layar < 300ms untuk data lokal (Hive)
- **Security:** Rules Firestore membatasi user hanya bisa edit data miliknya sendiri (kecuali baca forum yang publik)
- **Offline support:** Jadwal, tugas, materi tetap bisa dibaca/ditulis tanpa internet
- **Compatibility:** Android minSdkVersion mengikuti default Flutter stable terbaru

---

## 7. Out of Scope (Scope Out)

- Sistem pembayaran
- Video conference
- Marketplace pendidikan
- Integrasi IoT
- LMS penuh (grading, kurikulum, dsb.)
- Sinkronisasi otomatis dengan aplikasi pihak ketiga (Google Classroom, dll.)

---

## 8. Urutan Implementasi yang Disarankan untuk Claude Code

1. **Setup project** — struktur folder, dependencies (`firebase_core`, `firebase_auth`, `cloud_firestore`, `hive`, `hive_flutter`, `flutter_local_notifications`, state management pilihan)
2. **Auth flow** (5.1) — dasar untuk semua fitur lain
3. **Local data layer** — Hive boxes untuk schedules & tasks (5.2, 5.3)
4. **Reminder/notification** (5.4) — bergantung pada data tugas
5. **Dashboard** — agregasi jadwal hari ini + tugas mendatang
6. **Progress belajar** (5.5) — bergantung pada data tugas
7. **Forum diskusi** (5.6) — fitur cloud-only, independen
8. **Profil** (5.7)
9. **Polish UI** sesuai `UI_DESIGN.md`, testing manual per acceptance criteria di atas

---

## 9. Catatan untuk Claude Code

- Ikuti struktur folder di bagian 3 agar setiap fitur bisa digenerate/direvisi secara independen.
- Gunakan model data persis seperti di bagian 4 kecuali ada perubahan yang didiskusikan dulu.
- Style/warna/komponen visual **jangan ditebak** — selalu rujuk ke `UI_DESIGN.md` yang menyertai dokumen ini.
- Setiap fitur baru sebaiknya disertai widget test dasar untuk logic non-UI (misalnya perhitungan progress, validasi form).
