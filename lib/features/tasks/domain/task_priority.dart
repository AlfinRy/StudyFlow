/// Prioritas tugas. Disimpan sebagai `name` (string) di Hive.
/// Sumber: PRD §4.2 box `tasks`. Label mengikuti badge di UI_DESIGN.md §6.
enum TaskPriority {
  low('Rendah'),
  medium('Normal'),
  high('Urgent');

  const TaskPriority(this.label);
  final String label;

  static TaskPriority fromString(String? value) {
    if (value == null) return TaskPriority.medium;
    for (final p in TaskPriority.values) {
      if (p.name == value) return p;
    }
    return TaskPriority.medium;
  }
}
