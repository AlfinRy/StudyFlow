import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../focus/domain/focus_stats.dart';
import '../focus/focus_providers.dart';
import '../streak/streak_providers.dart';
import '../tasks/task_providers.dart';
import 'domain/gamification.dart';

/// Total XP pengguna dari sumber nyata: tugas selesai + sesi fokus + bonus
/// hadiah harian (streak). Reaktif — berubah saat sumber mana pun berubah.
final totalXpProvider = Provider<int>((ref) {
  final doneCount = ref.watch(completedTasksProvider).length;
  final sessions = ref.watch(focusSessionListProvider);
  final bonus = ref.watch(streakProfileProvider).totalBonusXp;
  return doneCount * xpPerTask + focusXp(sessions) + bonus;
});

/// Level saat ini, diturunkan dari [totalXpProvider]. Dipakai MainShell untuk
/// mendeteksi kenaikan level → memicu confetti & notifikasi.
final currentLevelProvider =
    Provider<StudyLevel>((ref) => levelForXp(ref.watch(totalXpProvider)));
