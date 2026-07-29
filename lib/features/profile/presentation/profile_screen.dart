import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/settings/settings_providers.dart';
import '../../../shared_widgets/app_avatar.dart';
import '../../../shared_widgets/app_dialogs.dart';
import 'edit_profile_screen.dart';
import 'notification_settings_screen.dart';
import '../../auth/auth_providers.dart';
import '../../auth/domain/study_goal.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isDemo = ref.watch(isDemoModeProvider);

    final name = (user?.name.isNotEmpty ?? false) ? user!.name : 'Pengguna';
    final roleLabel = user?.role?.label ?? 'Pengguna';
    final photoUrl = user?.photoUrl;

    Future<void> logout() async {
      final ok = await showConfirmDialog(
        context,
        title: 'Keluar dari akun?',
        message: 'Anda perlu masuk lagi untuk mengakses akun Anda.',
        confirmLabel: 'Keluar',
        isDestructive: true,
      );
      if (!ok || !context.mounted) return;
      await ref.read(authRepositoryProvider).signOut();
    }

    Future<void> deleteAccount() async {
      final ok = await showConfirmDialog(
        context,
        title: 'Hapus akun & data?',
        message:
            'Tindakan ini permanen dan tidak bisa dibatalkan. Semua data kamu '
            '(profil, tugas, jadwal, materi, sesi fokus, topik & balasan '
            'forum, serta grup belajar) akan dihapus dari server dan '
            'perangkat ini. Akun Firebase kamu juga akan dihapus.',
        confirmLabel: 'Hapus Permanen',
        isDestructive: true,
      );
      if (!ok || !context.mounted) return;

      // Loading sederhana (sesuai gaya app).
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PopScope(
          canPop: false,
          child: Dialog(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text('Menghapus akun...'),
                ],
              ),
            ),
          ),
        ),
      );

      final result = await ref
          .read(accountDeletionServiceProvider)
          .deleteAccount();
      if (!context.mounted) return;
      Navigator.of(context).pop(); // tutup loading

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: Icon(
            result.isSuccess ? Icons.check_circle : Icons.info_outline,
            color: result.isSuccess
                ? AppColors.success
                : AppColors.warning,
          ),
          title: Text(result.isSuccess ? 'Akun Dihapus' : 'Perhatian'),
          content: Text(result.message),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      // Setelah sign-out (otomatis di dalam layanan), auth state → null dan
      // app.dart mengarahkan ke layar login.
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
      children: [
        Row(
          children: [
            AppAvatar(name: name, photoUrl: photoUrl, radius: 34),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    roleLabel,
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (isDemo)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: _DemoBadge(),
          ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: const [
            Expanded(child: _MiniStat(label: 'Tugas Selesai', value: '0')),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: _MiniStat(label: 'Jadwal Aktif', value: '0')),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: _MiniStat(label: 'Hari Streak', value: '0')),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Pengaturan Akun',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _MenuGroup(children: [
          _MenuTile(
            icon: Icons.person_outline,
            label: 'Edit Profil',
            onTap: () async => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ),
          ),
          _MenuTile(
            icon: Icons.flag_outlined,
            label: 'Tujuan Belajar',
            trailing: _goalLabel(ref.watch(studyGoalProvider)),
            onTap: () => _showGoalPicker(context, ref),
          ),
          _MenuTile(
            icon: Icons.dark_mode_outlined,
            label: 'Tema',
            trailing: _themeLabel(ref.watch(themeModeProvider)),
            onTap: () => _showThemePicker(context, ref),
          ),
          _MenuTile(
            icon: Icons.notifications_none,
            label: 'Notifikasi',
            onTap: () async => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const NotificationSettingsScreen(),
              ),
            ),
          ),
          _MenuTile(
            icon: Icons.language,
            label: 'Bahasa',
            trailing: 'Indonesia',
            onTap: () async => showLanguageInfo(context),
          ),
        ]),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Dukungan',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _MenuGroup(children: [
          _MenuTile(
            icon: Icons.help_outline,
            label: 'Bantuan',
            onTap: () async => showComingSoon(context, 'Halaman bantuan'),
          ),
          _MenuTile(
            icon: Icons.info_outline,
            label: 'Tentang Aplikasi',
            onTap: () async => showStudyFlowAbout(context),
          ),
        ]),
        const SizedBox(height: AppSpacing.xl),
        _MenuGroup(children: [
          _MenuTile(
            icon: Icons.logout,
            label: 'Keluar',
            iconColor: AppColors.danger,
            textColor: AppColors.danger,
            onTap: logout,
          ),
        ]),
        if (!isDemo) ...[
          const SizedBox(height: AppSpacing.xl),
          _MenuGroup(children: [
            _MenuTile(
              icon: Icons.person_remove_outlined,
              label: 'Hapus Akun & Data',
              iconColor: AppColors.danger,
              textColor: AppColors.danger,
              onTap: deleteAccount,
            ),
          ]),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              'Minta penghapusan akun juga bisa lewat email/halaman web kami.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: context.textSecondary, fontSize: 11.5, height: 1.4),
            ),
          ),
        ],
      ],
    );
  }
}

class _DemoBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Text(
        'Mode demo — data tersimpan lokal di perangkat ini.',
        style: TextStyle(color: context.textPrimary, fontSize: 12),
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: context.surfaceBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              Divider(height: 1, color: context.surfaceBorder),
          ],
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: context.surfaceBorder),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.iconColor,
    this.textColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? trailing;
  final Color? iconColor;
  final Color? textColor;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? context.textSecondary),
      title: Text(
        label,
        style: TextStyle(
          color: textColor ?? context.textPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      trailing: trailing != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  trailing!,
                  style: TextStyle(
                      color: context.textSecondary, fontSize: 13),
                ),
                Icon(Icons.chevron_right,
                    color: context.surfaceBorder),
              ],
            )
          : Icon(Icons.chevron_right, color: context.surfaceBorder),
      onTap: onTap,
    );
  }
}

/// Label singkat mode tema untuk tile Profil.
String _themeLabel(ThemeMode mode) => switch (mode) {
      ThemeMode.system => 'Ikuti Sistem',
      ThemeMode.light => 'Terang',
      ThemeMode.dark => 'Gelap',
    };

/// Pemilih mode tema (Sistem / Terang / Gelap).
Future<void> _showThemePicker(BuildContext context, WidgetRef ref) async {
  final current = ref.read(themeModeProvider);
  final picked = await showDialog<ThemeMode>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('Pilih Tema'),
      children: [
        for (final mode in ThemeMode.values)
          ListTile(
            leading: Icon(
              mode == ThemeMode.system
                  ? Icons.brightness_auto_outlined
                  : mode == ThemeMode.light
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
              color: AppColors.accent,
            ),
            title: Text(_themeLabel(mode)),
            trailing: mode == current
                ? const Icon(Icons.check_rounded, color: AppColors.accent)
                : null,
            onTap: () => Navigator.pop(ctx, mode),
          ),
      ],
    ),
  );
  if (picked != null && picked != current) {
    await ref.read(themeModeProvider.notifier).set(picked);
  }
}

/// Label singkat tujuan belajar untuk tile Profil.
String _goalLabel(StudyGoal? g) => g?.label ?? 'Belum dipilih';

/// Pemilih tujuan belajar (dapat diubah kapan saja dari Profil).
Future<void> _showGoalPicker(BuildContext context, WidgetRef ref) async {
  final current = ref.read(studyGoalProvider);
  final picked = await showDialog<StudyGoal>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: const Text('Pilih Tujuan Belajar'),
      children: [
        for (final g in StudyGoal.values)
          ListTile(
            leading: Text(g.emoji, style: const TextStyle(fontSize: 22)),
            title: Text(g.label),
            subtitle:
                Text(g.description, style: const TextStyle(fontSize: 12)),
            trailing: g == current
                ? const Icon(Icons.check_rounded, color: AppColors.accent)
                : null,
            onTap: () => Navigator.pop(ctx, g),
          ),
      ],
    ),
  );
  if (picked != null && picked != current) {
    await ref.read(studyGoalProvider.notifier).set(picked);
  }
}
