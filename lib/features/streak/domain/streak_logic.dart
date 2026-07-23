// Logika streak murni (tanpa Flutter/Hive) agar mudah di-unit-test.
//
// Streak dasar dihitung dari `completedAt` tugas (lihat `progress_stats.dart`).
// Di sini kita tambahkan dua mekanisme retensi:
//   1. **Streak Freeze** — melindungi 1 hari "bolos" agar streak tidak putus.
//   2. **Hadiah harian** — bonus XP tiap hari selama streak aktif, +freeze tiap
//      kelipatan 7 hari (milestone).
//
// Semua fungsi DETERMINISTIK: keluaran hanya bergantung pada masukan.

/// Tanggal tanpa komponen waktu (00:00).
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Kumpulan tanggal "aktif" = hari dengan penyelesaian tugas ATAU dibekukan.
/// Streak dihitung dari gabungan ini.
Set<DateTime> activeDates(
  Set<DateTime> completionDates,
  Set<DateTime> frozenDates,
) =>
    {...completionDates, ...frozenDates};

/// Jumlah hari berturut-turut (berakhir hari ini atau kemarin) dalam [active].
/// 0 bila tidak ada aktivitas yang relevan. (Memiliki tenggat 1 hari "grace".)
int streakFromActive(Set<DateTime> active, DateTime now) {
  if (active.isEmpty) return 0;
  var cursor = dateOnly(now);
  if (!active.contains(cursor)) {
    cursor = cursor.subtract(const Duration(days: 1));
    if (!active.contains(cursor)) return 0;
  }
  var n = 0;
  while (active.contains(cursor)) {
    n++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return n;
}

/// Hasil evaluasi apakah freeze harus dipakai.
class FreezeDecision {
  const FreezeDecision(this.apply, [this.frozenDate]);
  const FreezeDecision.no()
      : apply = false,
        frozenDate = null;

  /// `true` bila satu freeze harus dikonsumsi untuk melindungi "kemarin".
  final bool apply;

  /// Tanggal (date-only) yang akan dibekukan, null bila [apply] false.
  final DateTime? frozenDate;
}

/// Tentukan apakah satu "Streak Freeze" harus dipakai untuk hari ini.
///
/// Aturan: freeze mengisi **kemarin** (tanggal terdekat yang hilang) HANYA bila
/// (a) masih ada freeze tersedia, (b) kemarin belum aktif, (c) ada rantai
/// nyata di **"2 hari lalu"** yang layak dilindungi/dihubungkan, dan
/// (d) membekukannya **benar-benar memperpanjang** streak. Syarat (c) mencegah
/// freeze meng-inflate streak dari nol (hanya lindungi yang sudah ada).
/// Idempoten — bila kemarin sudah completion/frozen, tidak ada yang dilakukan.
FreezeDecision tryApplyFreeze({
  required Set<DateTime> completionDates,
  required Set<DateTime> frozenDates,
  required int freezesAvailable,
  required DateTime now,
}) {
  if (freezesAvailable <= 0) return const FreezeDecision.no();
  final today = dateOnly(now);
  final yesterday = today.subtract(const Duration(days: 1));
  if (completionDates.contains(yesterday) || frozenDates.contains(yesterday)) {
    return const FreezeDecision.no();
  }
  final active = activeDates(completionDates, frozenDates);
  // Harus ada aktivitas nyata di "2 hari lalu" untuk dihubungkan/dilindungi.
  final beforeYesterday = today.subtract(const Duration(days: 2));
  if (!active.contains(beforeYesterday)) return const FreezeDecision.no();
  final streakNow = streakFromActive(active, now);
  final streakIfFreeze = streakFromActive({...active, yesterday}, now);
  if (streakIfFreeze > streakNow) {
    return FreezeDecision(true, yesterday);
  }
  return const FreezeDecision.no();
}

/// Besar XP hadiah harian berdasarkan panjang streak. Semakin panjang semakin
/// besar, dibatasi [min]/[max]. 0 bila tidak ada streak aktif.
int dailyRewardFor(int streak, {int min = 5, int max = 30}) {
  if (streak <= 0) return 0;
  return (min + streak).clamp(min, max);
}

/// Apakah hadiah harian bisa diklaim hari ini? Harus ada streak aktif DAN belum
/// diklaim hari ini.
bool canClaimDaily(DateTime? lastClaimDate, int currentStreak, DateTime now) {
  if (currentStreak <= 0) return false;
  final today = dateOnly(now);
  if (lastClaimDate == null) return true;
  return dateOnly(lastClaimDate) != today;
}

/// Apakah pada panjang streak [streak] ini layak dapat bonus freeze? Diberikan
/// tiap kelipatan 7, sekali per milestone (anti dobel via [lastRewardedAt]).
bool earnsFreezeAt(int streak, int lastRewardedAt) {
  if (streak <= 0) return false;
  if (streak % 7 != 0) return false;
  return streak > lastRewardedAt;
}
