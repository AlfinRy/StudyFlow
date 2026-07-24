// Layanan berbagi pencapaian (share milestone) — ekstensi Tier 4 roadmap
// (akuisisi organik). Kartu prestasi dirender ke gambar PNG lalu dibagikan via
// share sheet sistem (`share_plus`). Bila capture/share gambar gagal, fallback
// ke share teks saja agar fitur tetap berfungsi.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Susun teks caption yang menyertai gambar pencapaian saat dibagikan.
/// MURNI (tanpa dependensi platform) → mudah di-unit-test.
String buildShareText({
  required int levelIndex,
  required String levelTitle,
  required int xp,
  required int streak,
  required int tasksDone,
}) {
  final buffer = StringBuffer()
    ..writeln('🔥 Aku naik ke Level $levelIndex ($levelTitle) di StudyFlow!')
    ..writeln()
    ..writeln('📊 $xp XP · $tasksDone tugas selesai · $streak hari streak')
    ..writeln()
    ..write('Yuk belajar lebih teratur bareng StudyFlow! 📚✨');
  return buffer.toString().trim();
}

/// Hasil operasi berbagi.
enum ShareOutcome {
  /// Kartu gambar berhasil dibagikan.
  imageShared,
  /// Gambar gagal — fallback ke berbagi teks saja (fitur tetap berfungsi).
  textOnlyShared,
  /// Keduanya gagal.
  failed,
}

/// Berbagi kartu prestasi. **Berlapis (robust):** coba render widget di balik
/// [boundaryKey] → PNG → share file; bila gagal (capture/error), fallback ke
/// share teks saja agar fitur tetap berfungsi. Seluruh langkah di-log via
/// `debugPrint` agar penyebab kegagalan terlihat di `flutter logs`.
///
/// `pixelRatio` tinggi (3.0) agar gambar tajam untuk story IG/WA.
Future<ShareOutcome> shareAchievement(
  GlobalKey boundaryKey, {
  String? text,
  double pixelRatio = 3.0,
}) async {
  // 1) Coba capture gambar + share file.
  try {
    final boundary = boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary != null && !boundary.debugNeedsPaint) {
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData != null) {
        final dir = await getTemporaryDirectory();
        final stamp = DateTime.now().millisecondsSinceEpoch;
        final file = File('${dir.path}/studyflow_pencapaian_$stamp.png');
        await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
        debugPrint('[Share] gambar OK → ${file.path} '
            '(${file.lengthSync()} bytes), memanggil share sheet...');
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: text,
            subject: 'Pencapaian StudyFlow',
          ),
        );
        return ShareOutcome.imageShared;
      }
      debugPrint('[Share] byteData PNG null.');
    } else {
      debugPrint('[Share] boundary belum di-paint (debugNeedsPaint) '
          'atau null — fallback teks.');
    }
  } catch (e, st) {
    debugPrint('[Share] capture/share gambar GAGAL: $e\n$st');
  }

  // 2) Fallback: share teks saja.
  try {
    debugPrint('[Share] fallback ke share teks saja.');
    await SharePlus.instance.share(
      ShareParams(text: text ?? '', subject: 'Pencapaian StudyFlow'),
    );
    return ShareOutcome.textOnlyShared;
  } catch (e, st) {
    debugPrint('[Share] share teks JUGA gagal: $e\n$st');
    return ShareOutcome.failed;
  }
}
