import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/services/hive_service.dart';
import '../tasks/domain/task.dart';
import '../tasks/task_providers.dart';
import 'data/focus_repository.dart';
import 'domain/focus_session.dart';
import 'domain/pomodoro_config.dart';

import 'presentation/focus_timer_controller.dart';

/// Repository sesi fokus (Hive).
final focusRepositoryProvider = Provider<FocusRepository>(
    (ref) => FocusRepository(HiveService.instance.focusSessions));

/// Konfigurasi Pomodoro, persisten di box settings.
final pomodoroConfigProvider =
    NotifierProvider<PomodoroConfigNotifier, PomodoroConfig>(
        PomodoroConfigNotifier.new);

class PomodoroConfigNotifier extends Notifier<PomodoroConfig> {
  late final Box<dynamic> _box;

  static const _key = 'pomodoro_config';

  @override
  PomodoroConfig build() {
    _box = HiveService.instance.settings;
    final raw = _box.get(_key);
    if (raw is Map) {
      return PomodoroConfig.fromMap(Map<String, dynamic>.from(raw));
    }
    return const PomodoroConfig();
  }

  Future<void> update(PomodoroConfig config) async {
    await _box.put(_key, config.toMap());
    state = config;
  }

  Future<void> reset() async {
    await _box.delete(_key);
    state = const PomodoroConfig();
  }
}

/// Daftar sesi fokus reaktif (terbaru di atas).
final focusSessionListProvider =
    NotifierProvider<FocusSessionListNotifier, List<FocusSession>>(
        FocusSessionListNotifier.new);

class FocusSessionListNotifier extends Notifier<List<FocusSession>> {
  late final FocusRepository _repo;

  @override
  List<FocusSession> build() {
    _repo = ref.watch(focusRepositoryProvider);
    return _repo.getAll();
  }

  Future<void> add(FocusSession session) async {
    await _repo.add(session);
    state = _repo.getAll();
  }

  Future<void> remove(String id) async {
    await _repo.remove(id);
    state = _repo.getAll();
  }

  void refresh() => state = _repo.getAll();
}

/// Tugas yang belum selesai — untuk pilihan "fokus pada tugas" di layar timer.
final focusableTasksProvider = Provider<List<Task>>(
    (ref) => ref.watch(incompleteTasksProvider));

/// Controller mesin timer Pomodoro (persisten — tidak autoDispose agar timer
/// tetap berjalan walau user pindah tab).
final pomodoroTimerProvider =
    StateNotifierProvider<PomodoroTimerController, PomodoroTimerState>(
  (ref) => PomodoroTimerController(ref, ref.read(pomodoroConfigProvider)),
);
