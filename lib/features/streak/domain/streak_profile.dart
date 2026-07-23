/// Profil streak pengguna: pembekuan (freeze), rekor, & hadiah harian
/// (ekstensi Tier 3 roadmap, terinspirasi Duolingo).
///
/// Disimpan sebagai satu map di Hive box `settings` (lihat
/// `streak_providers.dart`). `frozenDates` hanya menyimpan tanggal yang
/// **benar-benar** dibekukan (date-only, 00:00).
class StreakProfile {
  const StreakProfile({
    this.freezesAvailable = 1,
    this.longestStreak = 0,
    this.frozenDates = const [],
    this.lastClaimDate,
    this.totalBonusXp = 0,
    this.lastFreezeRewardStreak = 0,
  });

  /// Jumlah "Streak Freeze" tersisa (melindungi 1 hari bolos).
  final int freezesAvailable;

  /// Rekor streak terpanjang yang pernah dicapai (persisten).
  final int longestStreak;

  /// Tanggal yang dilindungi freeze (date-only). Mencegah konsumsi ganda.
  final List<DateTime> frozenDates;

  /// Tanggal terakhir hadiah harian diklaim (date-aware).
  final DateTime? lastClaimDate;

  /// Akumulasi XP bonus dari klaim hadiah harian (ditambahkan ke total XP).
  final int totalBonusXp;

  /// Streak saat bonus freeze terakhir diberikan (anti dobel, tiap kelipatan 7).
  final int lastFreezeRewardStreak;

  Map<String, dynamic> toMap() => {
        'freezesAvailable': freezesAvailable,
        'longestStreak': longestStreak,
        'frozenDates': frozenDates.map((d) => d.toIso8601String()).toList(),
        'lastClaimDate': lastClaimDate?.toIso8601String(),
        'totalBonusXp': totalBonusXp,
        'lastFreezeRewardStreak': lastFreezeRewardStreak,
      };

  factory StreakProfile.fromMap(Map<String, dynamic> map) => StreakProfile(
        freezesAvailable: (map['freezesAvailable'] as num?)?.toInt() ?? 1,
        longestStreak: (map['longestStreak'] as num?)?.toInt() ?? 0,
        frozenDates: ((map['frozenDates'] as List?) ?? const [])
            .map((d) => DateTime.parse(d as String))
            .toList(),
        lastClaimDate: map['lastClaimDate'] == null
            ? null
            : DateTime.parse(map['lastClaimDate'] as String),
        totalBonusXp: (map['totalBonusXp'] as num?)?.toInt() ?? 0,
        lastFreezeRewardStreak:
            (map['lastFreezeRewardStreak'] as num?)?.toInt() ?? 0,
      );

  StreakProfile copyWith({
    int? freezesAvailable,
    int? longestStreak,
    List<DateTime>? frozenDates,
    Object? lastClaimDate = _sentinel,
    int? totalBonusXp,
    int? lastFreezeRewardStreak,
  }) {
    return StreakProfile(
      freezesAvailable: freezesAvailable ?? this.freezesAvailable,
      longestStreak: longestStreak ?? this.longestStreak,
      frozenDates: frozenDates ?? this.frozenDates,
      lastClaimDate: identical(lastClaimDate, _sentinel)
          ? this.lastClaimDate
          : lastClaimDate as DateTime?,
      totalBonusXp: totalBonusXp ?? this.totalBonusXp,
      lastFreezeRewardStreak:
          lastFreezeRewardStreak ?? this.lastFreezeRewardStreak,
    );
  }

  static const empty = StreakProfile();
}

const Object _sentinel = Object();
