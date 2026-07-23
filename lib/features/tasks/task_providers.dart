import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/celebration_service.dart';
import '../../core/services/hive_service.dart';
import '../../core/services/notification_service.dart';
import 'data/task_repository.dart';
import 'domain/task.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(HiveService.instance.tasks);
});

/// Layanan notifikasi untuk reminder deadline (PRD §5.4).
final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService.instance);

/// State reaktif untuk seluruh daftar tugas.
final taskListProvider =
    NotifierProvider<TaskListNotifier, List<Task>>(TaskListNotifier.new);

class TaskListNotifier extends Notifier<List<Task>> {
  late final TaskRepository _repo;
  late final NotificationService _notifications;

  @override
  List<Task> build() {
    _repo = ref.watch(taskRepositoryProvider);
    _notifications = ref.watch(notificationServiceProvider);
    return _repo.getAll();
  }

  Future<void> add(Task task) async {
    final saved = await _repo.add(task);
    await _notifications.scheduleForTask(saved);
    state = _repo.getAll();
  }

  Future<void> update(Task task) async {
    await _repo.update(task);
    // Batalkan jadwal lama lalu jadwalkan ulang (judul/jam mungkin berubah).
    await _notifications.scheduleForTask(task);
    state = _repo.getAll();
  }

  Future<void> remove(String id) async {
    await _notifications.cancelForTask(id);
    await _repo.remove(id);
    state = _repo.getAll();
  }

  Future<void> toggleDone(Task task) async {
    final updated = await _repo.toggleDone(task);
    if (updated.isDone) {
      // Tugas selesai → tidak ada notifikasi "nyangkut" (AC §5.4).
      await _notifications.cancelForTask(updated.id);
      // Rayakan penyelesaian tugas (confetti + haptic).
      celebrate(ref, CelebrationKind.taskDone);
      // Tugas berulang → buat instance berikutnya & jadwalkan pengingatnya.
      // add() mempersist + menjadwalkan notifikasi + me-refresh state.
      final next = _repo.generateNextOccurrence(updated);
      if (next != null) {
        await add(next);
        return;
      }
    } else {
      await _notifications.scheduleForTask(updated);
    }
    state = _repo.getAll();
  }

  void refresh() => state = _repo.getAll();
}

/// Tugas yang belum selesai (untuk dashboard "tugas mendatang").
final incompleteTasksProvider = Provider<List<Task>>(
    (ref) => ref.watch(taskListProvider).where((t) => !t.isDone).toList());

final completedTasksProvider = Provider<List<Task>>(
    (ref) => ref.watch(taskListProvider).where((t) => t.isDone).toList());
