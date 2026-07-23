import 'package:flutter_test/flutter_test.dart';
import 'package:study_flow/core/security/rate_limiter.dart';

/// Uji pure logic rate-limiter (tanpa Hive).
void main() {
  const now = 1_000_000; // ms
  const window = 60_000; // 60 detik

  group('evaluateRateLimit', () {
    test('belum ada percobaan → allowed, sisa = max', () {
      final r = evaluateRateLimit(
        timestamps: const [],
        now: now,
        maxAttempts: 5,
        windowMs: window,
      );
      expect(r.allowed, isTrue);
      expect(r.remaining, 5);
      expect(r.retryAfter, Duration.zero);
    });

    test('di bawah batas → allowed, sisa berkurang', () {
      final r = evaluateRateLimit(
        timestamps: const [now - 10_000, now - 5_000],
        now: now,
        maxAttempts: 5,
        windowMs: window,
      );
      expect(r.allowed, isTrue);
      expect(r.remaining, 3);
    });

    test('mencapai batas → blocked', () {
      final r = evaluateRateLimit(
        timestamps: const [now - 10_000, now - 9_000, now - 8_000],
        now: now,
        maxAttempts: 3,
        windowMs: window,
      );
      expect(r.allowed, isFalse);
      expect(r.remaining, 0);
    });

    test('blocked → retryAfter dihitung dari timestamp tertua', () {
      // Tertua = now-10s → bebas dalam (60-10)=50 detik.
      final r = evaluateRateLimit(
        timestamps: const [now - 10_000, now - 5_000],
        now: now,
        maxAttempts: 2,
        windowMs: window,
      );
      expect(r.allowed, isFalse);
      expect(r.retryAfter.inSeconds, closeTo(50, 1));
    });

    test('timestamp di luar jendela diabaikan (sliding)', () {
      // 1 timestamp 70 detik lalu (di luar jendela 60s) + 1 baru.
      final r = evaluateRateLimit(
        timestamps: const [now - 70_000, now - 5_000],
        now: now,
        maxAttempts: 2,
        windowMs: window,
      );
      expect(r.allowed, isTrue);
      expect(r.remaining, 1);
    });

    test('semua timestamp di luar jendela → allowed kembali (sisa = max)', () {
      final r = evaluateRateLimit(
        timestamps: const [now - 120_000, now - 90_000],
        now: now,
        maxAttempts: 2,
        windowMs: window,
      );
      expect(r.allowed, isTrue);
      expect(r.remaining, 2);
    });
  });

  group('RateLimitedAction kebijakan', () {
    test('login: 5 percobaan / 1 menit', () {
      expect(RateLimitedAction.login.maxAttempts, 5);
      expect(RateLimitedAction.login.window, const Duration(minutes: 1));
    });

    test('sendVerification: 3 / 1 jam', () {
      expect(RateLimitedAction.sendVerification.maxAttempts, 3);
      expect(RateLimitedAction.sendVerification.window, const Duration(hours: 1));
    });
  });
}
