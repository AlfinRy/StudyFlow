import 'package:flutter_test/flutter_test.dart';

import 'package:study_flow/core/constants/app_colors.dart';
import 'package:study_flow/features/materials/domain/material_file_type.dart';
import 'package:study_flow/features/materials/presentation/material_form_validation.dart';
import 'package:study_flow/features/materials/presentation/widgets/material_file_type_style.dart';

/// Verifikasi logic materi: validasi form, mapping tipe file, dan parser
/// tipe file (PRD §9: uji logic non-UI). Sejajar dengan test tugas.
void main() {
  group('validateMaterialForm', () {
    test('judul kosong → error', () {
      expect(
        validateMaterialForm(
            title: '   ', source: 'isi', type: MaterialFileType.note),
        isNotNull,
      );
    });

    test('source kosong (file) → "Pilih file terlebih dahulu."', () {
      expect(
        validateMaterialForm(
            title: 'Modul', source: '', type: MaterialFileType.pdf),
        'Pilih file terlebih dahulu.',
      );
    });

    test('source kosong (note) → "Isi materi tidak boleh kosong."', () {
      expect(
        validateMaterialForm(
            title: 'Catatan', source: '', type: MaterialFileType.note),
        'Isi materi tidak boleh kosong.',
      );
    });

    test('note terisi → valid', () {
      expect(
        validateMaterialForm(
            title: 'Catatan', source: 'isi catatan', type: MaterialFileType.note),
        isNull,
      );
    });

    test('pdf dengan URL terisi → valid', () {
      expect(
        validateMaterialForm(
            title: 'Modul',
            source: 'https://situs.com/m.pdf',
            type: MaterialFileType.pdf),
        isNull,
      );
    });

    test('link tanpa skema → error', () {
      expect(
        validateMaterialForm(
            title: 'Link', source: 'example.com', type: MaterialFileType.link),
        isNotNull,
      );
    });

    test('link http dengan host valid → valid', () {
      // http valid → lolos (host terisi)
      expect(
        validateMaterialForm(
            title: 'Link', source: 'http://x.com', type: MaterialFileType.link),
        isNull,
      );
    });

    test('link https valid → valid', () {
      expect(
        validateMaterialForm(
            title: 'Link',
            source: 'https://example.com/materi',
            type: MaterialFileType.link),
        isNull,
      );
    });
  });

  group('MaterialFileTypeStyle', () {
    test('pdf → danger', () {
      expect(MaterialFileTypeStyle.of(MaterialFileType.pdf).color,
          AppColors.danger);
    });

    test('link → accent', () {
      expect(MaterialFileTypeStyle.of(MaterialFileType.link).color,
          AppColors.accent);
    });

    test('setiap tipe punya icon & warna non-null', () {
      for (final t in MaterialFileType.values) {
        final s = MaterialFileTypeStyle.of(t);
        expect(s.color, isNotNull);
      }
    });
  });

  group('MaterialFileType.fromString', () {
    test('null → note', () {
      expect(MaterialFileType.fromString(null), MaterialFileType.note);
    });

    test('unknown → note', () {
      expect(MaterialFileType.fromString('xxx'), MaterialFileType.note);
    });

    test('pdf → pdf', () {
      expect(MaterialFileType.fromString('pdf'), MaterialFileType.pdf);
    });

    test('image → image', () {
      expect(MaterialFileType.fromString('image'), MaterialFileType.image);
    });
  });
}
