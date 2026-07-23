import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

/// Hasil evaluasi rate-limit.
@immutable
class RateLimitResult {
  const RateLimitResult._({
    required this.allowed,
    required this.remaining,
    required this.retryAfter,
  });

  /// Boleh melakukan aksi lagi.
  final bool allowed;

  /// Sisa percobaan yang tersisa dalam jendela waktu aktif.
  final int remaining;

  /// Berapa lama lagi (mulai dari `now`) sebelum jendela direset. Nol bila
  /// [allowed] = true.
  final Duration retryAfter;

  factory RateLimitResult.allowed({required int remaining}) =>
      RateLimitResult._(
        allowed: true,
        remaining: remaining,
        retryAfter: Duration.zero,
      );

  factory RateLimitResult.blocked({required Duration retryAfter}) =>
      RateLimitResult._(
        allowed: false,
        remaining: 0,
        retryAfter: retryAfter,
      );
}

/// **Pure logic** untuk mengevaluasi apakah sebuah aksi masih diperbolehkan
/// berdasarkan riwayat percobaan (timestamps) dalam suatu jendela waktu.
///
/// Dipisah dari storage agar mudah diuji tanpa Hive (lihat
/// `test/rate_limiter_test.dart`).
///
/// Algoritma: *fixed-window sliding* — hanya timestamp yang berumur kurang dari
/// [windowMs] (relatif terhadap [now]) yang dihitung. Bila jumlahnya sudah
/// menyentuh [maxAttempts], aksi diblokir sampai timestamp tertua keluar dari
/// jendela.
@visibleForTesting
RateLimitResult evaluateRateLimit({
  required List<int> timestamps,
  required int now,
  required int maxAttempts,
  required int windowMs,
}) {
  final recent = timestamps.where((t) => now - t < windowMs).toList();
  if (recent.length >= maxAttempts) {
    // Timestamp tertua menentukan kapan slot pertama bebas kembali.
    final oldest = recent.reduce((a, b) => a < b ? a : b);
    final retryAfterMs = windowMs - (now - oldest);
    return RateLimitResult.blocked(
      retryAfter: Duration(milliseconds: retryAfterMs < 0 ? 0 : retryAfterMs),
    );
  }
  return RateLimitResult.allowed(remaining: maxAttempts - recent.length);
}

/// Tindakan yang dibatasi rate-limit di aplikasi. Tiap aksi punya kebijakan
/// (jumlah maksimum + jendela waktu) yang berbeda.
enum RateLimitedAction {
  /// Percobaan login (anti brute-force password).
  login(maxAttempts: 5, window: Duration(minutes: 1)),

  /// Pendaftaran akun baru (anti pembuatan akun massal / spam).
  register(maxAttempts: 5, window: Duration(minutes: 1)),

  /// Kirim ulang email verifikasi (anti spam email).
  sendVerification(maxAttempts: 3, window: Duration(hours: 1)),

  /// Kirim email reset password (anti spam email).
  sendPasswordReset(maxAttempts: 3, window: Duration(hours: 1));

  const RateLimitedAction({
    required this.maxAttempts,
    required this.window,
  });

  final int maxAttempts;
  final Duration window;
}

/// Pembungkus Hive dari [evaluateRateLimit]. Menyimpan riwayat percobaan per
/// aksi secara persisten (tahan app restart). Dipakai oleh layar auth untuk
/// membatasi brute-force / spam sebelum memanggil Firebase.
class RateLimiter {
  RateLimiter(this._box);

  final Box<dynamic> _box;

  static const _prefix = 'rate_limit_';

  String _key(RateLimitedAction a) => '$_prefix${a.name}';

  List<int> _read(RateLimitedAction a) {
    final raw = _box.get(_key(a));
    if (raw is List) return raw.cast<int>();
    return const <int>[];
  }

  /// Evaluasi tanpa merekam. Gunakan untuk menampilkan sisa percobaan ke UI
  /// atau memutuskan apakah aksi boleh dijalankan.
  RateLimitResult check(RateLimitedAction a, {DateTime? now}) {
    return evaluateRateLimit(
      timestamps: _read(a),
      now: (now ?? DateTime.now()).millisecondsSinceEpoch,
      maxAttempts: a.maxAttempts,
      windowMs: a.window.inMilliseconds,
    );
  }

  /// Evaluasi lalu rekam percobaan bila masih diperbolehkan. Mengembalikan
  /// hasil evaluasi (sebelum rekam) agar UI bisa menampilkan sisa/blokir.
  RateLimitResult tryConsume(RateLimitedAction a, {DateTime? now}) {
    final result = check(a, now: now);
    if (result.allowed) {
      final ts = _read(a);
      ts.add((now ?? DateTime.now()).millisecondsSinceEpoch);
      _box.put(_key(a), ts);
    }
    return result;
  }

  /// Hapus riwayat sebuah aksi (cth. setelah login berhasil agar slot bebas).
  void reset(RateLimitedAction a) => _box.delete(_key(a));
}
