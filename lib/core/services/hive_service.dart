import 'package:hive/hive.dart';

/// Centralized access to Hive boxes (offline-first local storage).
///
/// Boxes store maps (JSON-like values) so we can avoid adapter codegen while
/// iterating. See documentation/PRD_StudyFlow.md section 4.2 for the schema.
class HiveService {
  HiveService._();
  static final HiveService instance = HiveService._();

  static const schedulesBox = 'schedules';
  static const tasksBox = 'tasks';
  static const materialsBox = 'materials';
  static const settingsBox = 'settings';

  late Box<dynamic> schedules;
  late Box<dynamic> tasks;
  late Box<dynamic> materials;
  late Box<dynamic> settings;

  Future<void> initialize() async {
    schedules = await Hive.openBox<dynamic>(schedulesBox);
    tasks = await Hive.openBox<dynamic>(tasksBox);
    materials = await Hive.openBox<dynamic>(materialsBox);
    settings = await Hive.openBox<dynamic>(settingsBox);
  }
}
