// Layanan berbagi pencapaian (share milestone) — ekstensi Tier 4 roadmap
// (akuisisi organik). Kartu prestasi dirender ke gambar PNG lalu dibagikan via
// share sheet sistem (`share_plus`).

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

/// Render widget di balik [boundaryKey] menjadi PNG, tulis ke direktori temp,
/// lalu buka share sheet sistem. Mengembalikan `true` bila berhasil dibagikan,
/// `false` bila widget tak ter-render (mis. belum di-layout).
///
/// `pixelRatio` tinggi (3.0) agar gambar tajam untuk story IG/WA.
Future<bool> shareBoundaryAsImage(
  GlobalKey boundaryKey, {
  String? text,
  double pixelRatio = 3.0,
}) async {
  final boundary = boundaryKey.currentContext?.findRenderObject()
      as RenderRepaintBoundary?;
  if (boundary == null || boundary.debugNeedsPaint) return false;

  final image = await boundary.toImage(pixelRatio: pixelRatio);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) return false;

  final bytes = byteData.buffer.asUint8List();
  final dir = await getTemporaryDirectory();
  final stamp = DateTime.now().millisecondsSinceEpoch;
  final file = File('${dir.path}/studyflow_pencapaian_$stamp.png');
  await file.writeAsBytes(bytes, flush: true);

  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(file.path)],
      text: text,
      subject: 'Pencapaian StudyFlow',
    ),
  );
  return true;
}
