import 'package:flutter/foundation.dart';

/// Validator berbagi pakai untuk form autentikasi (login/register/reset).
///
/// Menghilangkan duplikasi regex email antar layar & memusatkan kebijakan
/// kekuatan kata sandi. Pure functions → mudah diuji
/// (lihat `test/auth_validators_test.dart`).

/// Regex format email sederhana (tidak menjamin domain ada, hanya sintaksis).
/// Wajib: lokal@host.tld, memperbolehkan titik/plus/garis-bawah pada lokal.
final RegExp _emailRegex =
    RegExp(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

/// Pesan error verifikasi email. `null` = valid.
String? validateEmail(String? value) {
  final s = value?.trim() ?? '';
  if (s.isEmpty) return 'Email wajib diisi.';
  if (s.length > 254) return 'Email terlalu panjang.';
  if (!_emailRegex.hasMatch(s)) return 'Format email tidak valid.';
  return null;
}

/// Kebijakan kekuatan kata sandi StudyFlow.
class PasswordPolicy {
  const PasswordPolicy({
    this.minLength = 8,
    this.requireLetter = true,
    this.requireNumber = true,
  });

  /// Default: minimal 8 karakter, mengandung huruf & angka.
  static const PasswordPolicy standard = PasswordPolicy();

  final int minLength;
  final bool requireLetter;
  final bool requireNumber;
}

/// Hasil pemeriksaan kekuatan kata sandi.
@immutable
class PasswordStrength {
  const PasswordStrength._({
    required this.score,
    required this.valid,
    this.error,
  });

  /// Skor 0–4 (untuk indikator visual). Bukan syarat validitas.
  final int score;

  /// Memenuhi [policy]?
  final bool valid;

  /// Pesan error bila tidak valid.
  final String? error;

  factory PasswordStrength.evaluate(String password,
      {PasswordPolicy policy = PasswordPolicy.standard}) {
    final p = password;
    var score = 0;
    if (p.length >= policy.minLength) score++;
    if (p.length >= 12) score++;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) score++;
    if (score > 4) score = 4;

    if (p.isEmpty) {
      return const PasswordStrength._(
          score: 0, valid: false, error: 'Kata sandi wajib diisi.');
    }
    if (p.length < policy.minLength) {
      return PasswordStrength._(
        score: score,
        valid: false,
        error: 'Kata sandi minimal ${policy.minLength} karakter.',
      );
    }
    if (policy.requireLetter && !RegExp(r'[A-Za-z]').hasMatch(p)) {
      return PasswordStrength._(
          score: score, valid: false, error: 'Kata sandi harus mengandung huruf.');
    }
    if (policy.requireNumber && !RegExp(r'[0-9]').hasMatch(p)) {
      return PasswordStrength._(
          score: score, valid: false, error: 'Kata sandi harus mengandung angka.');
    }

    return PasswordStrength._(score: score, valid: true);
  }

  /// Evaluasi konfirmasi sandi: harus [valid] & sama dengan [match].
  factory PasswordStrength.evaluateConfirm(String? value,
      {required String match,
      PasswordPolicy policy = PasswordPolicy.standard}) {
    final v = value ?? '';
    final s = PasswordStrength.evaluate(v, policy: policy);
    if (!s.valid) return s;
    if (v != match) {
      return const PasswordStrength._(
          score: 0, valid: false, error: 'Konfirmasi sandi tidak cocok.');
    }
    return s;
  }
}
