import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_colors.dart';
import '../core/services/celebration_service.dart';

/// Overlay confetti yang bereaksi pada [celebrationControllerProvider].
/// Letakkan di dalam [Stack] pada layar yang ingin merayakan momen tertentu.
///
/// [kinds] membatasi jenis rayaan yang ditanggapi layar ini (mis. layar Fokus
/// hanya menanggapi `focusComplete`, MainShell menanggapi `taskDone`/`levelUp`)
/// agar tidak ada confetti ganda yang tak terlihat.
class ConfettiCelebration extends ConsumerStatefulWidget {
  const ConfettiCelebration({
    super.key,
    this.alignment = Alignment.topCenter,
    this.kinds = const [
      CelebrationKind.taskDone,
      CelebrationKind.focusComplete,
      CelebrationKind.levelUp,
    ],
  });

  final Alignment alignment;
  final List<CelebrationKind> kinds;

  @override
  ConsumerState<ConfettiCelebration> createState() =>
      _ConfettiCelebrationState();
}

class _ConfettiCelebrationState extends ConsumerState<ConfettiCelebration> {
  late final ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        ConfettiController(duration: const Duration(milliseconds: 1400));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onEvent(CelebrationEvent? event) {
    if (event == null) return;
    if (!widget.kinds.contains(event.kind)) return;
    _controller.play();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CelebrationEvent?>(celebrationControllerProvider,
        (_, next) => _onEvent(next));

    return Align(
      alignment: widget.alignment,
      child: ConfettiWidget(
        confettiController: _controller,
        blastDirectionality: BlastDirectionality.explosive,
        maxBlastForce: 18,
        minBlastForce: 7,
        emissionFrequency: 0.06,
        numberOfParticles: 14,
        gravity: 0.25,
        shouldLoop: false,
        colors: const [
          AppColors.accent,
          AppColors.success,
          AppColors.warning,
          AppColors.info,
          AppColors.accentDark,
        ],
        createParticlePath: _drawConfetti,
      ),
    );
  }

  // Partikel berbentuk persegi kecil (bukan default lingkaran) — terlihat lebih
  // seperti potongan kertas confetti.
  Path _drawConfetti(Size size) {
    final path = Path();
    path.addRect(Rect.fromCenter(
      center: Offset.zero,
      width: size.width * 0.8,
      height: size.height * 0.5,
    ));
    return path;
  }
}
