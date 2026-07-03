import 'task_priority.dart';

/// Satu entri tugas (PRD §4.2 box `tasks`).
///
/// Catatan: field `category` (mata pelajaran) TIDAK ada di PRD §4.2, tetapi
/// form Tugas di UI_DESIGN.md §6 jelas membutuhkannya. Ditambahkan sebagai
/// field opsional — penyimpangan terdokumentasi dari PRD.
class Task {
  const Task({
    required this.id,
    required this.title,
    required this.dueDate,
    this.description,
    this.category,
    this.isDone = false,
    this.reminderEnabled = false,
    this.priority = TaskPriority.medium,
    this.isSynced = false,
  });

  final String id;
  final String title;
  final String? description;
  final String? category; // mata pelajaran / kategori (ekstensi UI)
  final DateTime dueDate;
  final bool isDone;
  final bool reminderEnabled;
  final TaskPriority priority;
  final bool isSynced;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'dueDate': dueDate.toIso8601String(),
        'isDone': isDone,
        'reminderEnabled': reminderEnabled,
        'priority': priority.name,
        'isSynced': isSynced,
      };

  factory Task.fromMap(Map<String, dynamic> map) => Task(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String?,
        category: map['category'] as String?,
        dueDate: DateTime.parse(map['dueDate'] as String),
        isDone: (map['isDone'] as bool?) ?? false,
        reminderEnabled: (map['reminderEnabled'] as bool?) ?? false,
        priority: TaskPriority.fromString(map['priority'] as String?),
        isSynced: (map['isSynced'] as bool?) ?? false,
      );

  Task copyWith({
    String? id,
    String? title,
    Object? description = _sentinel,
    Object? category = _sentinel,
    DateTime? dueDate,
    bool? isDone,
    bool? reminderEnabled,
    TaskPriority? priority,
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
      isDone: isDone ?? this.isDone,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      priority: priority ?? this.priority,
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
          isDone == other.isDone &&
          reminderEnabled == other.reminderEnabled &&
          priority == other.priority &&
          isSynced == other.isSynced;

  @override
  int get hashCode => Object.hash(
        id, title, description, category, dueDate, isDone, reminderEnabled,
        priority, isSynced);
}

const Object _sentinel = Object();
