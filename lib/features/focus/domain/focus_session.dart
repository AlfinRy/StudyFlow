/// Satu sesi fokus Pomodoro yang **selesai** (memberi XP & menit belajar).
/// Disimpan di Hive box `focus_sessions` (offline-first).
class FocusSession {
  const FocusSession({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.durationMinutes,
    this.taskId,
    this.taskTitle,
  });

  final String id;

  /// Kapan sesi dimulai.
  final DateTime startedAt;

  /// Kapan sesi selesai (= saat XP diberikan).
  final DateTime endedAt;

  /// Durasi fokus aktual (menit). Bisa < config bila user skip.
  final int durationMinutes;

  /// Tugas opsional yang dikaitkan dengan sesi ini (boleh null).
  final String? taskId;
  final String? taskTitle;

  Map<String, dynamic> toMap() => {
        'id': id,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt.toIso8601String(),
        'durationMinutes': durationMinutes,
        'taskId': taskId,
        'taskTitle': taskTitle,
      };

  factory FocusSession.fromMap(Map<String, dynamic> map) => FocusSession(
        id: map['id'] as String,
        startedAt: DateTime.parse(map['startedAt'] as String),
        endedAt: DateTime.parse(map['endedAt'] as String),
        durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 0,
        taskId: map['taskId'] as String?,
        taskTitle: map['taskTitle'] as String?,
      );
}
