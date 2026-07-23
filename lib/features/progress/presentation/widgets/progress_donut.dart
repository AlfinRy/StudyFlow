import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Donut chart (lingkaran progres dengan lubang tengah) untuk halaman Progres
/// (UI_DESIGN.md §7). Memakai CustomPainter agar punya kontrol penuh terhadap
/// rounded stroke caps & warna track.
class ProgressDonut extends StatelessWidget {
  const ProgressDonut({
    super.key,
    required this.progress,
    required this.center,
    this.size = 150,
    this.strokeWidth = 16,
    this.progressColor = AppColors.accent,
    this.trackColor,
  });

  /// Proporsi terisi (0.0–1.0). Akan di-clamp otomatis.
  final double progress;

  /// Widget di tengah donut (mis. teks persen).
  final Widget center;

  final double size;
  final double strokeWidth;
  final Color progressColor;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final resolvedTrack = trackColor ?? AppColors.surfaceBorder;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutPainter(
              progress: progress,
              progressColor: progressColor,
              trackColor: resolvedTrack,
              strokeWidth: strokeWidth,
            ),
          ),
          center,
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.progress,
    required this.progressColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color progressColor;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final arcRect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Track (lingkaran penuh).
    paint.color = trackColor;
    canvas.drawArc(
      arcRect.deflate(strokeWidth / 2),
      0,
      2 * pi,
      false,
      paint,
    );

    // Arc progres mulai dari atas (-90°), searah jarum jam.
    final p = progress.clamp(0.0, 1.0);
    if (p > 0) {
      paint.color = progressColor;
      canvas.drawArc(
        arcRect.deflate(strokeWidth / 2),
        -pi / 2,
        2 * pi * p,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress ||
      old.progressColor != progressColor ||
      old.trackColor != trackColor ||
      old.strokeWidth != strokeWidth;
}
