import 'recurrence.dart';
import 'task_priority.dart';

/// Satu entri tugas (PRD §4.2 box `tasks`).
///
/// Catatan: field `category` (mata pelajaran) TIDAK ada di PRD §4.2, tetapi
/// form Tugas di UI_DESIGN.md §6 jelas membutuhkannya. Ditambahkan sebagai
/// field opsional — penyimpangan terdokumentasi dari PRD.
///
/// Catatan: field `completedAt` juga TIDAK ada di PRD §4.2, tetapi diperlukan
/// oleh Fase 8 (Progres, UI_DESIGN.md §7) untuk menghitung progres mingguan,
/// heatmap aktivitas, dan streak secara akurat. Di-set saat tugas ditandai
/// selesai, di-null-kan saat dibuka kembali (lihat TaskRepository.toggleDone).
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.dueDate,
    this.description,
    this.category,
    this.completedAt,
    this.isDone = false,
    this.reminderEnabled = false,
    this.priority = TaskPriority.medium,
    this.recurrence = Recurrence.none,
    this.isSynced = false,
  });

  final String id;
  final String title;
  final String? description;
  final String? category; // mata pelajaran / kategori (ekstensi UI)
  final DateTime dueDate;
  final DateTime? completedAt; // timestamp penyelesaian (ekstensi Fase 8)
  final bool isDone;
  final bool reminderEnabled;
  final TaskPriority priority;
  final Recurrence recurrence; // pola pengulangan (ekstensi Tier 2)
  final bool isSynced;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'dueDate': dueDate.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'isDone': isDone,
        'reminderEnabled': reminderEnabled,
        'priority': priority.name,
        'recurrence': recurrence.name,
        'isSynced': isSynced,
      };

  factory Task.fromMap(Map<String, dynamic> map) => Task(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String?,
        category: map['category'] as String?,
        dueDate: DateTime.parse(map['dueDate'] as String),
        completedAt: map['completedAt'] == null
            ? null
            : DateTime.parse(map['completedAt'] as String),
        isDone: (map['isDone'] as bool?) ?? false,
        reminderEnabled: (map['reminderEnabled'] as bool?) ?? false,
        priority: TaskPriority.fromString(map['priority'] as String?),
        recurrence: Recurrence.fromName(map['recurrence'] as String?),
        isSynced: (map['isSynced'] as bool?) ?? false,
      );

  Task copyWith({
    String? id,
    String? title,
    Object? description = _sentinel,
    Object? category = _sentinel,
    DateTime? dueDate,
    Object? completedAt = _sentinel,
    bool? isDone,
    bool? reminderEnabled,
    TaskPriority? priority,
    Recurrence? recurrence,
    bool? isSynced,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: identical(description, _sentinel)
          ? this.description
          : description as String?,
      category: identical(category, _sentinel)
          ? this.category
          : category as String?,
      dueDate: dueDate ?? this.dueDate,
      completedAt: identical(completedAt, _sentinel)
          ? this.completedAt
          : completedAt as DateTime?,
      isDone: isDone ?? this.isDone,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      priority: priority ?? this.priority,
      recurrence: recurrence ?? this.recurrence,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          category == other.category &&
          dueDate == other.dueDate &&
          completedAt == other.completedAt &&
          isDone == other.isDone &&
          reminderEnabled == other.reminderEnabled &&
          priority == other.priority &&
          recurrence == other.recurrence &&
          isSynced == other.isSynced;

  @override
  int get hashCode => Object.hash(
        id, title, description, category, dueDate, completedAt, isDone,
        reminderEnabled, priority, recurrence, isSynced);
}

const Object _sentinel = Object();
