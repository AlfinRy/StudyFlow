import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../core/services/celebration_service.dart';
import '../../core/services/hive_service.dart';
import '../tasks/task_providers.dart';
import 'domain/streak_logic.dart';
import 'domain/streak_profile.dart';

/// Info streak terkonsolidasi untuk konsumsi UI (read-only).
class StreakInfo {
  const StreakInfo({
    required this.currentStreak,
    required this.longestStreak,
    required this.freezesAvailable,
    required this.frozenCount,
    required this.canClaim,
    required this.reward,
    required this.totalBonusXp,
  });

  final int currentStreak;
  final int longestStreak;
  final int freezesAvailable;
  final int frozenCount;
  final bool canClaim;
  final int reward; // XP yang akan didapat bila klaim sekarang
  final int totalBonusXp;
}

/// Profil streak persisten (Hive box `settings`, key `streak_profile`).
final streakProfileProvider =
    NotifierProvider<StreakProfileNotifier, StreakProfile>(
        StreakProfileNotifier.new);

class StreakProfileNotifier extends Notifier<StreakProfile> {
  static const _key = 'streak_profile';

  late final Box<dynamic> _box;

  @override
  StreakProfile build() {
    _box = HiveService.instance.settings;
    final raw = _box.get(_key);
    if (raw is Map) {
      return StreakProfile.fromMap(Map<String, dynamic>.from(raw));
    }
    return const StreakProfile();
  }

  Future<void> _save() => _box.put(_key, state.toMap());

  /// Rekonsiliasi harian: bila streak akan putus hari ini, otomatis konsumsi
  /// satu "Streak Freeze" untuk melindungi kemarin. **Idempoten** — aman
  /// dipanggil berulang (kemarin yang sudah completion/frozen tak diproses dua
  /// kali). Panggil saat app dibuka (MainShell) atau layar Progres dibuka.
  Future<void> reconcile(DateTime now) async {
    final completionDates = _completionDates();
    final decision = tryApplyFreeze(
      completionDates: completionDates,
      frozenDates: state.frozenDates.toSet(),
      freezesAvailable: state.freezesAvailable,
      now: now,
    );
    if (!decision.apply || decision.frozenDate == null) return;

    final newFrozen = [...state.frozenDates, decision.frozenDate!];
    final newStreak =
        streakFromActive({...completionDates, ...newFrozen.toSet()}, now);
    state = state.copyWith(
      freezesAvailable: state.freezesAvailable - 1,
      frozenDates: newFrozen,
      longestStreak: max(state.longestStreak, newStreak),
    );
    await _save();
  }

  /// Klaim hadiah harian. Mengembalikan XP yang didapat (0 bila tak bisa).
  /// Memicu confetti & memberi +1 freeze tiap kelipatan 7 hari streak.
  Future<int> claimDaily(DateTime now) async {
    final currentStreak = ref.read(streakInfoProvider).currentStreak;
    if (!canClaimDaily(state.lastClaimDate, currentStreak, now)) return 0;

    final reward = dailyRewardFor(currentStreak);
    var freezes = state.freezesAvailable;
    var lastMilestone = state.lastFreezeRewardStreak;
    if (earnsFreezeAt(currentStreak, lastMilestone)) {
      freezes += 1;
      lastMilestone = currentStreak;
    }

    state = state.copyWith(
      totalBonusXp: state.totalBonusXp + reward,
      lastClaimDate: now,
      freezesAvailable: freezes,
      lastFreezeRewardStreak: lastMilestone,
      longestStreak: max(state.longestStreak, currentStreak),
    );
    await _save();
    celebrate(ref, CelebrationKind.dailyReward);
    return reward;
  }

  Set<DateTime> _completionDates() => ref
      .read(completedTasksProvider)
      .map((t) => t.completedAt)
      .whereType<DateTime>()
      .map(dateOnly)
      .toSet();
}

/// Streak info reaktif (membaca profil + tugas selesai). Untuk UI.
final streakInfoProvider = Provider<StreakInfo>((ref) {
  final profile = ref.watch(streakProfileProvider);
  final completionDates = ref
      .watch(completedTasksProvider)
      .map((t) => t.completedAt)
      .whereType<DateTime>()
      .map(dateOnly)
      .toSet();
  final frozen = profile.frozenDates.toSet();
  final currentStreak =
      streakFromActive(activeDates(completionDates, frozen), DateTime.now());
  return StreakInfo(
    currentStreak: currentStreak,
    longestStreak: max(profile.longestStreak, currentStreak),
    freezesAvailable: profile.freezesAvailable,
    frozenCount: profile.frozenDates.length,
    canClaim: canClaimDaily(profile.lastClaimDate, currentStreak, DateTime.now()),
    reward: dailyRewardFor(currentStreak),
    totalBonusXp: profile.totalBonusXp,
  );
});
