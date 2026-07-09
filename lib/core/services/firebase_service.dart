import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

/// Inisialisasi Firebase dengan aman (offline-first).
///
/// Memanggil `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.
/// Opsi ini di-generate oleh `flutterfire configure`. Pada platform yang belum
/// dikonfigurasi (cth. iOS/Web/Windows) dilempar exception → ditangkap di sini
/// → app berjalan dalam **mode demo** (auth lokal Hive). Lihat documentation/PROGRESS.md.
class FirebaseService {
  FirebaseService._();

  static bool initialized = false;

  static Future<void> initialize() async {
    if (initialized) return;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      initialized = true;
    } catch (_) {
      // Belum dikonfigurasi — mode demo aktif.
      initialized = false;
    }
  }
}
