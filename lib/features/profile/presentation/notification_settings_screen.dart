import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/settings/settings_providers.dart';

/// Halaman pengaturan notifikasi (menu Profil → Notifikasi).
///
/// Cakupan: saklar master on/off untuk semua pengingat tugas. Saat dimatikan,
/// semua notifikasi terjadwalkan dibatalkan & tidak ada reminder baru yang
/// dikirim (lihat [NotificationService.scheduleForTask] yang memeriksa
/// pengaturan ini).
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Kembali',
        ),
        title: const Text('Notifikasi'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_active_outlined,
                      color: AppColors.accent),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pengingat Tugas',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Aktif untuk menerima reminder deadline (H-1 & hari-H, pukul 08.00).',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: enabled,
                    onChanged: (v) =>
                        ref.read(notificationsEnabledProvider.notifier).set(v),
                    activeThumbColor: AppColors.accent,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Saat dinonaktifkan, semua pengingat yang sudah dijadwalkan dibatalkan '
              'dan tidak ada reminder baru yang dikirim. Tugas tetap tersimpan — '
              'hanya notifikasinya yang mati. Menyalakan kembali akan menjadwalkan '
              'ulang tugas yang berpengingat.',
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
