import 'package:flutter_test/flutter_test.dart';
import 'package:study_flow/features/auth/domain/study_goal.dart';

/// Verifikasi metadata enum StudyGoal (FEATURE_ROADMAP #8).
void main() {
  test('Semua StudyGoal punya metadata non-kosong', () {
    for (final g in StudyGoal.values) {
      expect(g.label.isNotEmpty, true, reason: '${g.name}: label kosong');
      expect(g.emoji.isNotEmpty, true, reason: '${g.name}: emoji kosong');
      expect(g.description.isNotEmpty, true,
          reason: '${g.name}: description kosong');
      expect(g.tip.isNotEmpty, true, reason: '${g.name}: tip kosong');
    }
  });

  test('nama unik (kunci persistence Hive)', () {
    final names = StudyGoal.values.map((g) => g.name).toSet();
    expect(names.length, StudyGoal.values.length);
  });

  test('minimal ada opsi umum (UTBK, Kuliah, Mandiri)', () {
    expect(StudyGoal.values.map((g) => g.name).toSet(),
        containsAll(const ['utbk', 'kuliah', 'mandiri']));
  });
}
