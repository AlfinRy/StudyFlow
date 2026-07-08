import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'hive_service.dart';
import '../utils/task_reminder_schedule.dart';
import '../../features/tasks/domain/task.dart';

/// Layanan notifikasi lokal untuk reminder deadline tugas (PRD §5.4).
///
/// Menggunakan [AndroidScheduleMode.inexactAllowWhileIdle] agar tidak perlu
/// permission exact-alarm (yang di-batasi sejak Android 14). Reminder mungkin
/// meleset beberapa menit namun tetap terkirim dan hemat baterai.
///
/// Semua pemanggilan plugin dibungkus try/catch agar app tidak pernah crash
/// karena notifikasi (mis. plugin belum siap / environment tanpa native).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const String _channelId = 'task_deadlines';
  static const String _channelName = 'Deadline Tugas';
  static const int _reminderHour = 8;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _permissionRequested = false;

  /// Apakah notifikasi diaktifkan secara global (pengaturan master di Profil
  /// → Notifikasi). Default true. Dibaca langsung dari Hive agar penjadwalan
  /// tetap hormat pengaturan walau dipanggil dari mana pun.
  bool get notificationsEnabled {
    try {
      return (HiveService.instance.settings
              .get(HiveService.notificationsEnabledKey) as bool?) ??
          true;
    } catch (_) {
      return true;
    }
  }

  /// Inisialisasi plugin + timezone. Aman dipanggil berulang.
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings();
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: darwin, macOS: darwin),
      );
      await _configureLocalTimezone();
      _initialized = true;
    } catch (_) {
      // Gagal graceful — notifikasi non-esensial.
    }
  }

  Future<void> _configureLocalTimezone() async {
    try {
      tz_data.initializeTimeZones();
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Fallback: UTC. Notifikasi tetap dijadwalkan (kemungkinan meleset zona).
    }
  }

  /// Minta permission tampilkan notifikasi (Android 13+ / iOS). Hanya prompt
  /// sekali (sisanya di-cache OS). Dipanggil saat menjadwalkan reminder.
  Future<void> _ensurePermission() async {
    if (_permissionRequested) return;
    _permissionRequested = true;
    try {
      if (Platform.isAndroid) {
        final android = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await android?.requestNotificationsPermission();
      } else if (Platform.isIOS || Platform.isMacOS) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }
    } catch (_) {
      // Abaikan — penjadwalan tetap dicoba.
    }
  }

  /// Jadwalkan ulang semua reminder untuk sebuah tugas. Membatalkan jadwal lama
  /// terlebih dahulu agar tidak menumpuk saat edit. No-op bila reminder
  /// dimatikan atau tugas sudah selesai.
  Future<void> scheduleForTask(Task task) async {
    await initialize();
    await cancelForTask(task.id);
    if (!task.reminderEnabled || task.isDone) return;

    // Hormati pengaturan master notifikasi (Profil → Notifikasi).
    if (!notificationsEnabled) return;

    await _ensurePermission();
    final times = computeReminderTimes(
        dueDate: task.dueDate, reminderHour: _reminderHour);
    if (times.isEmpty) return;

    try {
      if (times.dayBefore != null) {
        await _schedule(
          id: _hMinusOneId(task.id),
          at: times.dayBefore!,
          task: task,
          isDayBefore: true,
        );
      }
      if (times.onDay != null) {
        await _schedule(
          id: _onDayId(task.id),
          at: times.onDay!,
          task: task,
          isDayBefore: false,
        );
      }
    } catch (_) {
      // Gagal graceful.
    }
  }

  /// Batalkan kedua reminder untuk sebuah tugas (mis. saat selesai/dihapus).
  Future<void> cancelForTask(String taskId) async {
    try {
      await _plugin.cancel(_hMinusOneId(taskId));
      await _plugin.cancel(_onDayId(taskId));
    } catch (_) {
      // Gagal graceful.
    }
  }

  /// Batalkan SEMUA notifikasi terjadwalkan (saat pengingat dimatikan global).
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {
      // Gagal graceful.
    }
  }

  Future<void> _schedule({
    required int id,
    required DateTime at,
    required Task task,
    required bool isDayBefore,
  }) async {
    final scheduled = tz.TZDateTime.from(at, tz.local);
    await _plugin.zonedSchedule(
      id,
      'Pengingat Tugas',
      isDayBefore
          ? 'Besok deadline: ${task.title}'
          : 'Hari ini deadline: ${task.title}',
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Pengingat deadline tugas StudyFlow.',
          importance: Importance.high,
          priority: Priority.high,
          // TODO: ganti dengan ikon monokrom (drawable) agar konsisten di
          // status bar Android. Untuk sementara memakai launcher icon.
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: task.id,
    );
  }

  // ID stabil per task: base dari hashCode (30-bit), lalu dipisah untuk dua
  // reminder (onDay = genap, hMinusOne = ganjil). Catatan: risiko tabrakan
  // hashCode sangat kecil untuk pemakaian lokal.
  int _onDayId(String taskId) => _base(taskId) * 2;
  int _hMinusOneId(String taskId) => _base(taskId) * 2 + 1;
  int _base(String taskId) => taskId.hashCode & 0x3FFFFFFF;
}
