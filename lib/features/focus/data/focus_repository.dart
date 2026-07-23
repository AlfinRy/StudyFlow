import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../domain/focus_session.dart';

/// Akses data sesi fokus dari Hive box `focus_sessions` (offline-first).
/// Sesi hanya disimpan saat **selesai** (memberi XP & menit belajar).
class FocusRepository {
  FocusRepository(this._box);

  final Box<dynamic> _box;
  static const _uuid = Uuid();

  /// Semua sesi, terbaru di atas.
  List<FocusSession> getAll() {
    final items = _box.values
        .map((v) => FocusSession.fromMap(Map<String, dynamic>.from(v as Map)))
        .toList();
    items.sort((a, b) => b.endedAt.compareTo(a.endedAt));
    return items;
  }

  Future<FocusSession> add(FocusSession session) async {
    final id = session.id.isEmpty ? _uuid.v4() : session.id;
    final item = session.id.isEmpty
        ? FocusSession(
            id: id,
            startedAt: session.startedAt,
            endedAt: session.endedAt,
            durationMinutes: session.durationMinutes,
            taskId: session.taskId,
            taskTitle: session.taskTitle,
          )
        : session;
    await _box.put(id, item.toMap());
    return item;
  }

  Future<void> remove(String id) async => _box.delete(id);
}
