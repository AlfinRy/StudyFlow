import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/hive_service.dart';
import 'data/task_repository.dart';
import 'domain/task.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(HiveService.instance.tasks);
});

/// State reaktif untuk seluruh daftar tugas.
final taskListProvider =
    NotifierProvider<TaskListNotifier, List<Task>>(TaskListNotifier.new);

class TaskListNotifier extends Notifier<List<Task>> {
  late final TaskRepository _repo;

  @override
  List<Task> build() {
    _repo = ref.watch(taskRepositoryProvider);
    return _repo.getAll();
  }

  Future<void> add(Task task) async {
    await _repo.add(task);
    state = _repo.getAll();
  }

  Future<void> update(Task task) async {
    await _repo.update(task);
    state = _repo.getAll();
  }

  Future<void> remove(String id) async {
    await _repo.remove(id);
    state = _repo.getAll();
  }

  Future<void> toggleDone(Task task) async {
    await _repo.toggleDone(task);
    state = _repo.getAll();
  }

  void refresh() => state = _repo.getAll();
}

/// Tugas yang belum selesai (untuk dashboard "tugas mendatang").
final incompleteTasksProvider = Provider<List<Task>>(
    (ref) => ref.watch(taskListProvider).where((t) => !t.isDone).toList());

final completedTasksProvider = Provider<List<Task>>(
    (ref) => ref.watch(taskListProvider).where((t) => t.isDone).toList());
