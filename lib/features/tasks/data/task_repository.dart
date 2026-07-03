import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../domain/task.dart';

/// Akses data tugas dari Hive box `tasks` (offline-first).
class TaskRepository {
  TaskRepository(this._box);

  final Box<dynamic> _box;
  static const _uuid = Uuid();

  /// Semua tugas, diurutkan berdasarkan deadline terdekat.
  List<Task> getAll() {
    final items = _box.values
        .map((v) => Task.fromMap(Map<String, dynamic>.from(v as Map)))
        .toList();
    items.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return items;
  }

  List<Task> get incomplete => getAll().where((t) => !t.isDone).toList();
  List<Task> get completed => getAll().where((t) => t.isDone).toList();

  /// Tambah tugas. Meng-generate id jika kosong.
  Future<Task> add(Task task) async {
    final id = task.id.isEmpty ? _uuid.v4() : task.id;
    final item = task.id.isEmpty ? task.copyWith(id: id) : task;
    await _box.put(id, item.toMap());
    return item;
  }

  Future<void> update(Task task) async => _box.put(task.id, task.toMap());

  Future<void> remove(String id) async => _box.delete(id);

  /// Toggle status selesai.
  Future<Task> toggleDone(Task task) async {
    final updated = task.copyWith(isDone: !task.isDone);
    await _box.put(updated.id, updated.toMap());
    return updated;
  }
}
