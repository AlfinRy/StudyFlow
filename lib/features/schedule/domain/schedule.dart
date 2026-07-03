import 'schedule_category.dart';

/// Satu entri jadwal belajar (PRD §4.2 box `schedules`).
///
/// `dayOfWeek`: 1 = Senin ... 7 = Minggu (konsisten dengan `DateTime.weekday`).
/// `startTime`/`endTime`: format "HH:mm" agar mudah di-sort & ditampilkan.
class Schedule {
  const Schedule({
    required this.id,
    required this.title,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.location,
    this.category,
    this.isSynced = false,
  });

  final String id;
  final String title;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final String? location;
  final ScheduleCategory? category;
  final bool isSynced;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'dayOfWeek': dayOfWeek,
        'startTime': startTime,
        'endTime': endTime,
        'location': location,
        'category': category?.name,
        'isSynced': isSynced,
      };

  factory Schedule.fromMap(Map<String, dynamic> map) => Schedule(
        id: map['id'] as String,
        title: map['title'] as String,
        dayOfWeek: map['dayOfWeek'] as int,
        startTime: map['startTime'] as String,
        endTime: map['endTime'] as String,
        location: map['location'] as String?,
        category: ScheduleCategory.fromString(map['category'] as String?),
        isSynced: (map['isSynced'] as bool?) ?? false,
      );

  /// copyWith mendukung set field nullable ke null (pakai sentinel).
  Schedule copyWith({
    String? id,
    String? title,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    String? location,
    Object? category = _sentinel,
    bool? isSynced,
  }) {
    return Schedule(
      id: id ?? this.id,
      title: title ?? this.title,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      category: identical(category, _sentinel)
          ? this.category
          : category as ScheduleCategory?,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Schedule &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          dayOfWeek == other.dayOfWeek &&
          startTime == other.startTime &&
          endTime == other.endTime &&
          location == other.location &&
          category == other.category &&
          isSynced == other.isSynced;

  @override
  int get hashCode => Object.hash(
        id, title, dayOfWeek, startTime, endTime, location, category, isSynced);
}

const Object _sentinel = Object();
