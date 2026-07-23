import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/leaderboard_entry.dart';

/// Akses data papan peringkat via Firestore `progress/{uid}`. Cloud-only
/// (butuh internet + Firebase), mirip Forum. Setiap user hanya menulis doc
/// miliknya; leaderboard membaca semua doc untuk pekan berjalan.
class LeaderboardRepository {
  LeaderboardRepository([FirebaseFirestore? firestore])
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _progress =>
      _db.collection('progress');

  /// Stream 50 entri teratas untuk [weekId], terurut XP turun (real-time).
  Stream<List<LeaderboardEntry>> watchTop(String weekId, {String? myUid}) {
    return _progress
        .where('weekId', isEqualTo: weekId)
        .orderBy('weeklyXp', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => LeaderboardEntry.fromMap(d.data(), myUid: myUid))
            .where((e) => e.weeklyXp > 0)
            .toList());
  }

  /// Tulis/perbarui doc progress milik user sendiri (merge). Best-effort:
  /// gagal diam-diam saat offline / aturan keamanan.
  Future<void> upsertMyEntry({
    required String uid,
    required String name,
    required int weeklyXp,
    required String weekId,
    String? photoUrl,
    String? role,
  }) async {
    try {
      await _progress.doc(uid).set({
        'uid': uid,
        'name': name,
        'weeklyXp': weeklyXp,
        'weekId': weekId,
        'photoUrl': photoUrl,
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Offline / aturan — diabaikan.
    }
  }
}
