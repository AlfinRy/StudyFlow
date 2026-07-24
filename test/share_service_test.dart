import 'package:flutter_test/flutter_test.dart';

import 'package:study_flow/core/services/share_service.dart';

void main() {
  group('buildShareText', () {
    test('menyertakan level, judul, dan metrik utama', () {
      final text = buildShareText(
        levelIndex: 3,
        levelTitle: 'Pelajar Rajin',
        xp: 320,
        streak: 5,
        tasksDone: 16,
      );
      expect(text, contains('Level 3'));
      expect(text, contains('Pelajar Rajin'));
      expect(text, contains('320 XP'));
      expect(text, contains('16 tugas selesai'));
      expect(text, contains('5 hari streak'));
      expect(text, contains('StudyFlow'));
    });

    test('streak 0 tetap valid (tidak crash)', () {
      final text = buildShareText(
        levelIndex: 1,
        levelTitle: 'Pemula',
        xp: 0,
        streak: 0,
        tasksDone: 0,
      );
      expect(text, contains('Level 1'));
      expect(text, contains('0 XP'));
      expect(text, contains('0 hari streak'));
    });

    test('diakhiri tagline ajakan', () {
      final text = buildShareText(
        levelIndex: 2,
        levelTitle: 'Pelajar Aktif',
        xp: 120,
        streak: 2,
        tasksDone: 6,
      );
      expect(text, contains('belajar'));
    });
  });
}
