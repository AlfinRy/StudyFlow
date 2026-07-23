/// Satu entri papan peringkat (denormalisasi dari `progress/{uid}`).
/// Hanya berisi data tampilan + XP mingguan — bukan data sensitif.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.name,
    required this.weeklyXp,
    this.photoUrl,
    this.role,
    this.isMe = false,
  });

  final String uid;
  final String name;
  final int weeklyXp;
  final String? photoUrl;
  final String? role;
  final bool isMe;

  factory LeaderboardEntry.fromMap(Map<String, dynamic> m, {String? myUid}) =>
      LeaderboardEntry(
        uid: m['uid'] as String? ?? '',
        name: (m['name'] as String?)?.isNotEmpty == true
            ? m['name'] as String
            : 'Pengguna',
        weeklyXp: (m['weeklyXp'] as num?)?.toInt() ?? 0,
        photoUrl: m['photoUrl'] as String?,
        role: m['role'] as String?,
        isMe: myUid != null && (m['uid'] as String?) == myUid,
      );

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'weeklyXp': weeklyXp,
        'photoUrl': photoUrl,
        'role': role,
      };
}

/// ID minggu dari tanggal referensi: tanggal Senin awal pekan dalam format
/// "YYYY-MM-DD". Tiap pekan unik & monoton, jadi leaderboard otomatis reset
/// tiap minggu tanpa Cloud Function (dokumen minggu lalu tak terbaca karena
/// weekId-nya beda).
String weekIdOf(DateTime reference) {
  final d = DateTime(reference.year, reference.month, reference.day);
  final monday = d.subtract(Duration(days: d.weekday - 1));
  final m = monday.month.toString().padLeft(2, '0');
  final day = monday.day.toString().padLeft(2, '0');
  return '${monday.year}-$m-$day';
}
