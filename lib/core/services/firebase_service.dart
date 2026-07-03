import 'package:firebase_core/firebase_core.dart';

/// Inisialisasi Firebase dengan aman (offline-first).
///
/// Memanggil `Firebase.initializeApp()` hanya berhasil kalau sudah dikonfigurasi
/// (`flutterfire configure` + google-services.json). Jika belum, dilempar
/// exception yang ditangkap di sini → app berjalan dalam **mode demo**
/// (auth lokal Hive). Lihat documentation/PROGRESS.md.
class FirebaseService {
  FirebaseService._();

  static bool initialized = false;

  static Future<void> initialize() async {
    if (initialized) return;
    try {
      await Firebase.initializeApp();
      initialized = true;
    } catch (_) {
      // Belum dikonfigurasi — mode demo aktif.
      initialized = false;
    }
  }
}
