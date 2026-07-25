import 'package:flutter_test/flutter_test.dart';
import 'package:study_flow/features/materials/domain/material_file_type.dart';
import 'package:study_flow/features/materials/domain/study_material.dart';

/// Uji field `tags` pada StudyMaterial (FEATURE_ROADMAP #10).
void main() {
  StudyMaterial sample({List<String> tags = const []}) => StudyMaterial(
        id: 'm1',
        title: 'Modul Fisika',
        category: 'Sains',
        filePathOrUrl: 'note',
        fileType: MaterialFileType.note,
        createdAt: DateTime(2026, 1, 5),
        tags: tags,
      );

  test('round-trip toMap/fromMap mempertahankan tags', () {
    final m = sample(tags: const ['ujian', 'bab 3', 'penting']);
    final restored = StudyMaterial.fromMap(m.toMap());
    expect(restored.tags, ['ujian', 'bab 3', 'penting']);
  });

  test('data lama tanpa field tags → default kosong (backward-compat)', () {
    final restored = StudyMaterial.fromMap(const {
      'id': 'm1',
      'title': 'Lama',
      'category': 'Umum',
      'filePathOrUrl': 'x',
      'fileType': 'note',
      'createdAt': '2026-01-05T00:00:00.000',
    });
    expect(restored.tags, isEmpty);
  });

  test('default tags kosong', () {
    expect(sample().tags, isEmpty);
  });

  test('equality memperhitungkan tags', () {
    expect(sample(tags: const ['a']), isNot(equals(sample(tags: const ['b']))));
    expect(sample(tags: const ['a']), equals(sample(tags: const ['a'])));
  });
}
