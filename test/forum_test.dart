import 'package:flutter_test/flutter_test.dart';

import 'package:study_flow/core/utils/date_labels.dart';
import 'package:study_flow/features/discussion/domain/forum_topic.dart';
import 'package:study_flow/features/discussion/presentation/forum_topic_validation.dart';

/// Verifikasi logic forum & waktu relatif (PRD §9: uji logic non-UI).
void main() {
  final now = DateTime(2026, 7, 4, 10, 0);

  group('validateTopicTitle', () {
    test('kosong → error', () {
      expect(validateTopicTitle(''), isNotNull);
      expect(validateTopicTitle('   '), isNotNull);
    });

    test('terlalu panjang (>120) → error', () {
      expect(validateTopicTitle('a' * 121), isNotNull);
    });

    test('tepat 120 karakter → valid', () {
      expect(validateTopicTitle('a' * 120), isNull);
    });

    test('normal → valid', () {
      expect(validateTopicTitle('Cara belajar efektif?'), isNull);
    });
  });

  group('validateTopicContent', () {
    test('kosong → error', () {
      expect(validateTopicContent('   '), isNotNull);
    });

    test('terisi → valid', () {
      expect(validateTopicContent('Bagaimana cara kalian?'), isNull);
    });
  });

  group('ForumTopic.snippet', () {
    ForumTopic topic({String content = 'Halo semua'}) => ForumTopic(
          id: 'x',
          title: 't',
          content: content,
          authorId: 'a',
          authorName: 'Budi',
          createdAt: now,
        );

    test('konten pendek → apa adanya', () {
      expect(topic().snippet, 'Halo semua');
    });

    test('konten panjang → terpotong 120 + …', () {
      final t = topic(content: 'a' * 200);
      expect(t.snippet.length, 121); // 120 + …
      expect(t.snippet.endsWith('…'), isTrue);
    });

    test('whitespace berlebih dirapikan', () {
      final t = topic(content: '  halo   dunia  ');
      expect(t.snippet, 'halo dunia');
    });
  });

  group('timeAgo', () {
    test('baru saja (<45 detik / masa depan)', () {
      expect(timeAgo(now, now: now), 'baru saja');
      expect(
          timeAgo(now.subtract(const Duration(seconds: 30)), now: now),
          'baru saja');
      expect(
          timeAgo(now.add(const Duration(minutes: 5)), now: now), 'baru saja');
    });

    test('detik', () {
      expect(timeAgo(now.subtract(const Duration(seconds: 50)), now: now),
          '50 detik lalu');
    });

    test('menit', () {
      expect(timeAgo(now.subtract(const Duration(minutes: 5)), now: now),
          '5 menit lalu');
    });

    test('jam', () {
      expect(
          timeAgo(now.subtract(const Duration(hours: 3)), now: now), '3 jam lalu');
    });

    test('kemarin (tepat 1 hari)', () {
      expect(
          timeAgo(now.subtract(const Duration(days: 1)), now: now), 'kemarin');
    });

    test('N hari (2–6)', () {
      expect(
          timeAgo(now.subtract(const Duration(days: 5)), now: now), '5 hari lalu');
    });

    test('>7 hari → tanggal absolut', () {
      // 4 Jul 2026 - 10 hari = 24 Jun 2026
      expect(timeAgo(now.subtract(const Duration(days: 10)), now: now),
          '24 Jun 2026');
    });
  });
}
