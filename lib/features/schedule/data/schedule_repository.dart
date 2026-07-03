import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../domain/schedule.dart';

/// Akses data jadwal dari Hive box `schedules` (offline-first).
class ScheduleRepository {
  ScheduleRepository(this._box);

  final Box<dynamic> _box;
  static const _uuid = Uuid();

  /// Semua jadwal, diurutkan berdasarkan jam mulai.
  List<Schedule> getAll() {
    final items = _box.values
        .map((v) => Schedule.fromMap(Map<String, dynamic>.from(v as Map)))
        .toList();
    items.sort((a, b) => a.startTime.compareTo(b.startTime));
    return items;
  }

  /// Jadwal untuk hari tertentu (1=Senin ... 7=Minggu).
  List<Schedule> forDay(int dayOfWeek) =>
      getAll().where((s) => s.dayOfWeek == dayOfWeek).toList();

  /// Tambah jadwal. Meng-generate id jika kosong.
  Future<Schedule> add(Schedule schedule) async {
    final id = schedule.id.isEmpty ? _uuid.v4() : schedule.id;
    final item = schedule.id.isEmpty ? schedule.copyWith(id: id) : schedule;
    await _box.put(id, item.toMap());
    return item;
  }

  Future<void> update(Schedule schedule) async {
    await _box.put(schedule.id, schedule.toMap());
  }

  Future<void> remove(String id) async {
    await _box.delete(id);
  }
}
