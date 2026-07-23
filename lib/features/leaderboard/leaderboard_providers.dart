import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:study_flow/core/services/firebase_service.dart';
import 'package:study_flow/core/services/hive_service.dart';
import 'package:study_flow/features/auth/auth_providers.dart';
import 'package:study_flow/features/progress/progress_providers.dart';
import 'data/leaderboard_repository.dart';
import 'domain/leaderboard_entry.dart';

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>(
    (ref) => LeaderboardRepository());

/// ID pekan berjalan.
final currentWeekIdProvider = Provider<String>(
    (ref) => weekIdOf(DateTime.now()));

/// Apakah leaderboard aktif (mode Firebase + user sudah verifikasi).
final leaderboardAvailableProvider = Provider<bool>((ref) {
  if (!FirebaseService.initialized) return false;
  return ref.watch(canAccessAppProvider);
});

/// Stream Top-50 entri papan peringkat pekan ini.
final leaderboardTopProvider =
    StreamProvider.autoDispose<List<LeaderboardEntry>>((ref) {
  if (!ref.watch(leaderboardAvailableProvider)) {
    return Stream.value(const <LeaderboardEntry>[]);
  }
  final weekId = ref.watch(currentWeekIdProvider);
  final myUid = ref.watch(currentUserProvider)?.uid;
  return ref
      .watch(leaderboardRepositoryProvider)
      .watchTop(weekId, myUid: myUid);
});

/// Pengaturan opt-in leaderboard (privasi). Default: nonaktif.
final shareOnLeaderboardProvider =
    NotifierProvider<ShareOnLeaderboardNotifier, bool>(
        ShareOnLeaderboardNotifier.new);

class ShareOnLeaderboardNotifier extends Notifier<bool> {
  @override
  bool build() {
    final raw = HiveService.instance.settings.get('share_on_leaderboard');
    return raw is bool ? raw : false;
  }

  Future<void> set(bool value) async {
    await HiveService.instance.settings.put('share_on_leaderboard', value);
    state = value;
  }
}

/// Sinkronisasi XP mingguan ke Firestore (best-effort, opt-in). Dipasang
/// (di-keep-alive) di MainShell lewat `ref.watch`. Menulis ulang saat XP,
/// status opt-in, atau user berubah.
final leaderboardSyncProvider = Provider<void>((ref) {
  Future<void> sync() async {
    if (!ref.read(leaderboardAvailableProvider)) return;
    final share = ref.read(shareOnLeaderboardProvider);
    final user = ref.read(currentUserProvider);
    if (!share || user == null) return;
    final xp = ref.read(totalXpProvider);
    final weekId = ref.read(currentWeekIdProvider);
    await ref.read(leaderboardRepositoryProvider).upsertMyEntry(
          uid: user.uid,
          name: user.name,
          weeklyXp: xp,
          weekId: weekId,
          photoUrl: user.photoUrl,
          role: user.role?.name,
        );
  }

  ref.listen(totalXpProvider, (_, _) => sync());
  ref.listen(shareOnLeaderboardProvider, (_, _) => sync());
  ref.listen(currentUserProvider, (_, _) => sync());
});
