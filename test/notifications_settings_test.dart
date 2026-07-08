import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:study_flow/core/services/hive_service.dart';
import 'package:study_flow/core/settings/settings_providers.dart';

/// Verifikasi pengaturan master notifikasi: default aktif, persistensi ke Hive,
/// dan state reaktif (PRD §9: uji logic non-UI).
void main() {
  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('studyflow_settings_test');
    Hive.init(dir.absolute.path);
    await HiveService.instance.initialize();
  });

  setUp(() async {
    // Bersihkan box settings tiap test agar default deterministik (true).
    await HiveService.instance.settings.clear();
  });

  test('default aktif (true)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(notificationsEnabledProvider), isTrue);
  });

  test('set(false) mematikan + tersimpan di box', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(notificationsEnabledProvider.notifier).set(false);
    expect(container.read(notificationsEnabledProvider), isFalse);
    expect(
      HiveService.instance.settings
          .get(HiveService.notificationsEnabledKey),
      isFalse,
    );
  });

  test('set(true) menyalakan kembali', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(notificationsEnabledProvider.notifier).set(false);
    await container.read(notificationsEnabledProvider.notifier).set(true);
    expect(container.read(notificationsEnabledProvider), isTrue);
    expect(
      HiveService.instance.settings
          .get(HiveService.notificationsEnabledKey),
      isTrue,
    );
  });
}
