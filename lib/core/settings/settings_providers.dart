import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../services/hive_service.dart';
import '../services/notification_service.dart';
import '../../features/tasks/task_providers.dart';

/// Provider reaktif untuk pengaturan master notifikasi (on/off). Disimpan di
/// Hive box `settings` ([HiveService.notificationsEnabledKey]). Default: aktif.
///
/// Saat dimatikan: semua notifikasi terjadwalkan dibatalkan & tidak ada
/// reminder baru yang dijadwalkan (dipaksakan di [NotificationService.scheduleForTask]).
/// Saat dinyalakan: tugas berpengingat dijadwalkan ulang.
final notificationsEnabledProvider =
    NotifierProvider<NotificationsEnabledNotifier, bool>(
        NotificationsEnabledNotifier.new);

class NotificationsEnabledNotifier extends Notifier<bool> {
  late final Box<dynamic> _box;

  @override
  bool build() {
    _box = HiveService.instance.settings;
    return (_box.get(HiveService.notificationsEnabledKey) as bool?) ?? true;
  }

  Future<void> set(bool enabled) async {
    await _box.put(HiveService.notificationsEnabledKey, enabled);
    state = enabled;

    final notifications = ref.read(notificationServiceProvider);
    if (!enabled) {
      // Matikan semua pengingat yang sudah dijadwalkan.
      await notifications.cancelAll();
    } else {
      // Nyalakan kembali: jadwalkan ulang tugas yang berpengingat & belum selesai.
      final tasks = ref
          .read(taskListProvider)
          .where((t) => t.reminderEnabled && !t.isDone);
      for (final t in tasks) {
        await notifications.scheduleForTask(t);
      }
    }
  }
}
