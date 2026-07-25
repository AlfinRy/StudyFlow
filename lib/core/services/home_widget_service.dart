import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/tasks/domain/task.dart';

/// Menjembatani data app ke widget layar utama Android (FEATURE_ROADMAP #4).
///
/// Widget berjalan di proses terpisah (AppWidgetService) sehingga tidak bisa
/// memanggil Flutter/Hive langsung. Maka ringkasan tugas hari ini disalin ke
/// `SharedPreferences` (yang dibaca widget native), lalu pembaruan widget
/// dipicu lewat MethodChannel `studyflow/widget` di `MainActivity`.
///
/// Semua operasi dibungkus try/catch: widget bersifat opsional — kegagalan
/// tidak boleh mengganggu alur utama app.
class HomeWidgetService {
  static const _prefsKey = 'widget_today_tasks';
  static const _channel = MethodChannel('studyflow/widget');

  /// Simpan ringkasan tugas hari ini (belum selesai) & picu refresh widget.
  static Future<void> saveTodayTasks(List<Task> allTasks) async {
    try {
      final now = DateTime.now();
      final items = allTasks
          .where((t) => !t.isDone && _isSameDay(t.dueDate, now))
          .take(4)
          .map((t) => {
                'title': t.title,
                'time': _hhmm(t.dueDate),
              })
          .toList();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        jsonEncode({'count': items.length, 'items': items}),
      );
      // Minta widget yang sedang ada di home screen untuk menggambar ulang.
      await _channel.invokeMethod<void>('updateWidget');
    } catch (_) {
      // Non-fatal: tidak ada widget / engine belum siap → abaikan.
    }
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _hhmm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}
