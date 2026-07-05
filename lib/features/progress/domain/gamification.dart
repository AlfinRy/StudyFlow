// Gamifikasi progres belajar (UI_DESIGN.md §7) — PURE, tanpa Flutter.
//
// XP & level diturunkan DETERMINISTIK dari jumlah tugas selesai (tidak
// difabrikasi): setiap tugas selesai = [xpPerTask] XP. Milestone (pencapaian)
// terbuka berdasarkan jumlah tugas selesai / streak — juga dari data nyata.

/// Jenis syarat membuka sebuah milestone.
enum MilestoneKind { taskCount, streak }

/// Level belajar beserta rentang XP-nya.
class StudyLevel {
  const StudyLevel({
    required this.index,
    required this.minXp,
    required this.maxXp,
    required this.title,
  });

  final int index; // 1-based
  final int minXp; // inklusif
  final int maxXp; // eksklusif (level terakhir pakai [_maxXpSentinel])
  final String title;
}

/// XP yang diperoleh per tugas yang diselesaikan.
const int xpPerTask = 20;

// Sentinel besar agar level terakhir praktis tak terhingga (aman di VM & web).
const int _maxXpSentinel = 1000000000;

/// Katalog level (urut naik). Sesuaikan threshold bila ingin kurva berbeda.
const List<StudyLevel> studyLevels = [
  StudyLevel(index: 1, minXp: 0, maxXp: 100, title: 'Pemula'),
  StudyLevel(index: 2, minXp: 100, maxXp: 250, title: 'Pelajar Aktif'),
  StudyLevel(index: 3, minXp: 250, maxXp: 500, title: 'Pelajar Rajin'),
  StudyLevel(index: 4, minXp: 500, maxXp: 1000, title: 'Sarjana Muda'),
  StudyLevel(index: 5, minXp: 1000, maxXp: _maxXpSentinel, title: 'Sarjana Handal'),
];

/// Level untuk jumlah XP tertentu.
StudyLevel levelForXp(int xp) {
  for (final l in studyLevels) {
    if (xp >= l.minXp && xp < l.maxXp) return l;
  }
  return studyLevels.last;
}

/// Level berikutnya, atau null bila sudah di level tertinggi.
StudyLevel? nextLevel(StudyLevel current) {
  final i = studyLevels.indexOf(current);
  if (i < 0 || i + 1 >= studyLevels.length) return null;
  return studyLevels[i + 1];
}

/// Progres (0.0–1.0) menuju level berikutnya. 1.0 bila sudah maksimum.
double levelProgress(int xp) {
  final l = levelForXp(xp);
  final n = nextLevel(l);
  if (n == null) return 1;
  final span = n.minXp - l.minXp;
  if (span <= 0) return 1;
  return ((xp - l.minXp) / span).clamp(0.0, 1.0);
}

// ---------------------------------------------------------------------------
// Milestone
// ---------------------------------------------------------------------------

/// Apakah milestone dengan syarat [kind]/[threshold] sudah terbuka.
bool milestoneUnlocked(
  MilestoneKind kind,
  int threshold, {
  required int doneCount,
  required int streak,
}) {
  switch (kind) {
    case MilestoneKind.taskCount:
      return doneCount >= threshold;
    case MilestoneKind.streak:
      return streak >= threshold;
  }
}

/// Tanggal milestone "tugas ke-[threshold]" tercapai, yaitu tanggal
/// `completedAt` ke-`threshold` secara urut naik dari [completionDates].
/// Null bila belum tercapai atau tidak cukup data.
DateTime? taskMilestoneReachedAt(int threshold, List<DateTime> completionDates) {
  if (threshold <= 0) return null;
  final sorted = [...completionDates]..sort();
  if (threshold > sorted.length) return null;
  return sorted[threshold - 1];
}
