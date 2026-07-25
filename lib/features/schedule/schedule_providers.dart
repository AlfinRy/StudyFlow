import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/hive_service.dart';
import 'data/ical_parser.dart';
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

  /// Impor jadwal dari konten file .ics (FEATURE_ROADMAP #5). Tiap VEVENT
  /// diurai menjadi slot mingguan, lalu hanya yang belum ada (dedup key
  /// judul + hari + jam mulai) yang disimpan. Mengembalikan jumlah jadwal
  /// baru yang ditambahkan.
  Future<int> importFromIcs(String content) async {
    final parsed = parseIcsToSchedules(content);
    final existing = <String>{
      for (final s in state) _dedupKey(s),
    };
    var added = 0;
    for (final s in parsed) {
      final key = _dedupKey(s);
      if (!existing.add(key)) continue;
      await _repo.add(s);
      added++;
    }
    if (added > 0) state = _repo.getAll();
    return added;
  }

  static String _dedupKey(Schedule s) =>
      '${s.title}|${s.dayOfWeek}|${s.startTime}';

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
