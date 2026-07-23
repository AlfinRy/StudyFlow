import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Jenis momen yang layak dirayakan (confetti + haptic).
enum CelebrationKind { taskDone, focusComplete, levelUp }

/// Sebuah peristiwa rayaan (immutable). [id] menjamin dua peristiwa sejenis
/// berturut-turut tetap terdeteksi sebagai perubahan state.
class CelebrationEvent {
  const CelebrationEvent({required this.id, required this.kind});
  final int id;
  final CelebrationKind kind;
}

/// Bus peristiwa rayaan sederhana (Riverpod Notifier). Widget overlay
/// `ConfettiCelebration` memantau state ini & memutar confetti saat berubah.
final celebrationControllerProvider =
    NotifierProvider<CelebrationController, CelebrationEvent?>(
        CelebrationController.new);

class CelebrationController extends Notifier<CelebrationEvent?> {
  int _seq = 0;

  @override
  CelebrationEvent? build() => null;

  /// Picu rayaan. Aman dipanggil dari mana pun (provider global, bukan
  /// autoDispose).
  void burst(CelebrationKind kind) {
    state = CelebrationEvent(id: ++_seq, kind: kind);
  }
}

/// Helper singkat untuk memicu rayaan dari notifier lain.
void celebrate(Ref ref, CelebrationKind kind) =>
    ref.read(celebrationControllerProvider.notifier).burst(kind);
