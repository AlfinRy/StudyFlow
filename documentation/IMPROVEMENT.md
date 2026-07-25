## Forum Diskusi

### ✅ 1. Hapus forum oleh pembuat
Pembuat forum (topik) kini dapat menghapus topik yang sudah tidak digunakan.
Penghapusan bersifat **cascade** — seluruh balasan ikut terhapus.
- Diatur aman di **Firestore rules**: hanya `authorId == uid login` yang boleh
  menghapus topik; balasan boleh dihapus oleh pemilik balasan atau pembuat
  topik (untuk moderasi/cascade).
- UI: ikon tempat sampah di AppBar halaman detail (hanya muncul untuk
  pembuat) + dialog konfirmasi.

### ✅ 2. Cegah spam chat (balasan)
Balasan forum kini dibatasi **anti-spam**:
- **Rate limit**: maks. 5 balasan / 30 detik per perangkat (menggunakan
  `RateLimiter` yang sudah ada). Jika melampaui, muncul pesan
  "tunggu X detik sebelum balas lagi".
- **Anti-duplikat konsekutif**: tidak boleh mengirim balasan yang sama
  persis dengan balasan sebelumnya.
