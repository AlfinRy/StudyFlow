import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared_widgets/app_dialogs.dart';
import 'notification_settings_screen.dart';
import '../../auth/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final isDemo = ref.watch(isDemoModeProvider);

    final name = (user?.name.isNotEmpty ?? false) ? user!.name : 'Pengguna';
    final roleLabel = user?.role?.label ?? 'Pengguna';

    Future<void> logout() async {
      await ref.read(authRepositoryProvider).signOut();
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
      children: [
        Row(
          children: [
            const CircleAvatar(
              radius: 34,
              backgroundColor: AppColors.accent,
              child: Icon(Icons.person, color: Colors.white, size: 34),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    roleLabel,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
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
        const Text(
          'Pengaturan Akun',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _MenuGroup(children: [
          _MenuTile(
            icon: Icons.person_outline,
            label: 'Edit Profil',
            onTap: () async => showComingSoon(context, 'Edit profil'),
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
        const Text(
          'Dukungan',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
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
      child: const Text(
        'Mode demo — data tersimpan lokal di perangkat ini.',
        style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Divider(height: 1, color: AppColors.surfaceBorder),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
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
    this.iconColor = AppColors.textSecondary,
    this.textColor = AppColors.textPrimary,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? trailing;
  final Color iconColor;
  final Color textColor;
  final Future<void> Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        label,
        style: TextStyle(
          color: textColor,
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
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                const Icon(Icons.chevron_right,
                    color: AppColors.surfaceBorder),
              ],
            )
          : const Icon(Icons.chevron_right, color: AppColors.surfaceBorder),
      onTap: onTap,
    );
  }
}
