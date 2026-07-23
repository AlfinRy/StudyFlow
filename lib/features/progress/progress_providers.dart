import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../focus/domain/focus_stats.dart';
import '../focus/focus_providers.dart';
import '../tasks/task_providers.dart';
import 'domain/gamification.dart';

/// Total XP pengguna dari sumber nyata: tugas selesai + sesi fokus.
/// Reaktif — berubah saat tugas diselesaikan atau sesi fokus selesai.
final totalXpProvider = Provider<int>((ref) {
  final doneCount = ref.watch(completedTasksProvider).length;
  final sessions = ref.watch(focusSessionListProvider);
  return doneCount * xpPerTask + focusXp(sessions);
});

/// Level saat ini, diturunkan dari [totalXpProvider]. Dipakai MainShell untuk
/// mendeteksi kenaikan level → memicu confetti & notifikasi.
final currentLevelProvider =
    Provider<StudyLevel>((ref) => levelForXp(ref.watch(totalXpProvider)));
