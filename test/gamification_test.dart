import 'package:flutter_test/flutter_test.dart';

import 'package:study_flow/features/progress/domain/gamification.dart';

/// Verifikasi gamifikasi (Fase 8): XP/level & milestone diturunkan dari data
/// nyata (jumlah tugas selesai / streak).
void main() {
  group('XP & level', () {
    test('xpPerTask deterministik', () {
      expect(xpPerTask, 20);
    });

    test('level 1 untuk XP rendah', () {
      expect(levelForXp(0).index, 1);
      expect(levelForXp(99).index, 1);
    });

    test('transisi level pada threshold', () {
      expect(levelForXp(100).index, 2);
      expect(levelForXp(249).index, 2);
      expect(levelForXp(250).index, 3);
      expect(levelForXp(500).index, 4);
      expect(levelForXp(1000).index, 5);
    });

    test('nextLevel null di level tertinggi', () {
      expect(nextLevel(levelForXp(9999)), isNull);
      expect(nextLevel(levelForXp(0))?.index, 2);
    });

    test('levelProgress di awal level = 0, akhir level = ~1', () {
      expect(levelProgress(100), closeTo(0.0, 1e-9));
      // 249 → (249-100)/(250-100) = 149/150
      expect(levelProgress(249), closeTo(149 / 150, 1e-9));
      // maksimum
      expect(levelProgress(99999), 1);
    });
  });

  group('milestoneUnlocked', () {
    test('taskCount terbuka saat doneCount >= threshold', () {
      expect(
        milestoneUnlocked(MilestoneKind.taskCount, 5,
            doneCount: 4, streak: 0),
        isFalse,
      );
      expect(
        milestoneUnlocked(MilestoneKind.taskCount, 5,
            doneCount: 5, streak: 0),
        isTrue,
      );
      expect(
        milestoneUnlocked(MilestoneKind.taskCount, 5,
            doneCount: 9, streak: 0),
        isTrue,
      );
    });

    test('streak terbuka saat streak >= threshold', () {
      expect(
        milestoneUnlocked(MilestoneKind.streak, 3,
            doneCount: 100, streak: 2),
        isFalse,
      );
      expect(
        milestoneUnlocked(MilestoneKind.streak, 3,
            doneCount: 100, streak: 3),
        isTrue,
      );
    });
  });

  group('taskMilestoneReachedAt', () {
    final dates = [
      DateTime(2026, 7, 1),
      DateTime(2026, 7, 3),
      DateTime(2026, 7, 5),
    ];

    test('tanggal completion ke-N (1-based, urut naik)', () {
      expect(taskMilestoneReachedAt(1, dates), DateTime(2026, 7, 1));
      expect(taskMilestoneReachedAt(2, dates), DateTime(2026, 7, 3));
      expect(taskMilestoneReachedAt(3, dates), DateTime(2026, 7, 5));
    });

    test('null bila belum tercapai / threshold invalid', () {
      expect(taskMilestoneReachedAt(4, dates), isNull);
      expect(taskMilestoneReachedAt(0, dates), isNull);
      expect(taskMilestoneReachedAt(1, const []), isNull);
    });

    test('tidak memutasi input list', () {
      final copy = [...dates];
      taskMilestoneReachedAt(2, dates);
      expect(dates, copy);
    });
  });
}
