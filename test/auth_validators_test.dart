import 'package:flutter_test/flutter_test.dart';
import 'package:study_flow/core/security/auth_validators.dart';

/// Uji validator email & kekuatan kata sandi (pure functions).
void main() {
  group('validateEmail', () {
    test('kosong → error', () {
      expect(validateEmail(''), isNotNull);
      expect(validateEmail('   '), isNotNull);
      expect(validateEmail(null), isNotNull);
    });

    test('format valid → null (bebas error)', () {
      expect(validateEmail('andi@example.com'), isNull);
      expect(validateEmail('budi.siswa@kampus.ac.id'), isNull);
      expect(validateEmail('a+b@gmail.co.uk'), isNull);
    });

    test('format invalid → error', () {
      expect(validateEmail('bukanemail'), isNotNull);
      expect(validateEmail('kurang@domain'), isNotNull);
      expect(validateEmail('@tidakadalokal.com'), isNotNull);
      expect(validateEmail('spasi @domain.com'), isNotNull);
      expect(validateEmail('email@.com'), isNotNull);
    });
  });

  group('PasswordStrength.evaluate', () {
    test('kosong → tidak valid', () {
      final s = PasswordStrength.evaluate('');
      expect(s.valid, isFalse);
      expect(s.error, isNotNull);
    });

    test('terlalu pendek → tidak valid', () {
      expect(PasswordStrength.evaluate('ab1').valid, isFalse);
      expect(PasswordStrength.evaluate('abcde1').valid, isFalse); // 6 < 8
    });

    test('8+ karakter tanpa angka → tidak valid', () {
      final s = PasswordStrength.evaluate('abcdefgh');
      expect(s.valid, isFalse);
      expect(s.error, contains('angka'));
    });

    test('8+ karakter tanpa huruf → tidak valid', () {
      final s = PasswordStrength.evaluate('12345678');
      expect(s.valid, isFalse);
      expect(s.error, contains('huruf'));
    });

    test('huruf + angka, >=8 → valid', () {
      expect(PasswordStrength.evaluate('abc12345').valid, isTrue);
    });

    test('skor naik dengan kompleksitas (0..4)', () {
      final lemah = PasswordStrength.evaluate('abc12345');
      final kuat = PasswordStrength.evaluate('Abcdef12!@#xyz');
      expect(kuat.score, greaterThan(lemah.score));
      expect(kuat.score, lessThanOrEqualTo(4));
    });
  });

  group('PasswordStrength.evaluateConfirm', () {
    test('cocok → valid', () {
      final s = PasswordStrength.evaluateConfirm('abc12345', match: 'abc12345');
      expect(s.valid, isTrue);
    });

    test('tidak cocok → error konfirmasi', () {
      final s = PasswordStrength.evaluateConfirm('abc12345', match: 'beda1234');
      expect(s.valid, isFalse);
      expect(s.error, contains('tidak cocok'));
    });

    test('valid tapi lemah → prioritaskan error kekuatan', () {
      final s = PasswordStrength.evaluateConfirm('123', match: '123');
      expect(s.valid, isFalse);
    });
  });
}
