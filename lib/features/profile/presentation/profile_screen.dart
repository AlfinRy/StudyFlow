import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                children: const [
                  Text(
                    'Andi Pratama',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Mahasiswa',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            children: const [
              _MenuTile(icon: Icons.person_outline, label: 'Edit Profil'),
              Divider(height: 1, color: AppColors.surfaceBorder),
              _MenuTile(icon: Icons.notifications_none, label: 'Notifikasi'),
              Divider(height: 1, color: AppColors.surfaceBorder),
              _MenuTile(
                  icon: Icons.language, label: 'Bahasa', trailing: 'Indonesia'),
            ],
          ),
        ),
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
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            children: const [
              _MenuTile(icon: Icons.help_outline, label: 'Bantuan'),
              Divider(height: 1, color: AppColors.surfaceBorder),
              _MenuTile(
                  icon: Icons.info_outline, label: 'Tentang Aplikasi'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: const _MenuTile(
            icon: Icons.logout,
            label: 'Keluar',
            iconColor: AppColors.danger,
            textColor: AppColors.danger,
          ),
        ),
      ],
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
  });
  final IconData icon;
  final String label;
  final String? trailing;
  final Color iconColor;
  final Color textColor;

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
                const Icon(Icons.chevron_right, color: AppColors.surfaceBorder),
              ],
            )
          : const Icon(Icons.chevron_right, color: AppColors.surfaceBorder),
      onTap: () {},
    );
  }
}
