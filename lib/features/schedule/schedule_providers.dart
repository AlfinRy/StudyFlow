import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/hive_service.dart';
import 'data/schedule_repository.dart';
import 'domain/schedule.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository(HiveService.instance.schedules);
});

/// State reaktif untuk seluruh daftar jadwal.
final scheduleListProvider =
    NotifierProvider<ScheduleListNotifier, List<Schedule>>(
        ScheduleListNotifier.new);

class ScheduleListNotifier extends Notifier<List<Schedule>> {
  late final ScheduleRepository _repo;

  @override
  List<Schedule> build() {
    _repo = ref.watch(scheduleRepositoryProvider);
    return _repo.getAll();
  }

  Future<void> add(Schedule schedule) async {
    await _repo.add(schedule);
    state = _repo.getAll();
  }

  Future<void> update(Schedule schedule) async {
    await _repo.update(schedule);
    state = _repo.getAll();
  }

  Future<void> remove(String id) async {
    await _repo.remove(id);
    state = _repo.getAll();
  }

  void refresh() => state = _repo.getAll();
}

/// Jadwal untuk hari tertentu.
final schedulesForDayProvider =
    Provider.family<List<Schedule>, int>((ref, dayOfWeek) {
  return ref.watch(scheduleListProvider)
      .where((s) => s.dayOfWeek == dayOfWeek)
      .toList();
});

/// Jadwal hari ini (untuk dashboard Beranda).
final schedulesForTodayProvider = Provider<List<Schedule>>((ref) {
  final today = DateTime.now().weekday;
  return ref.watch(schedulesForDayProvider(today));
});
