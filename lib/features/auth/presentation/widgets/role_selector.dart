import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/user_role.dart';

/// Grid 2x2 pemilih "Daftar Sebagai" (UI_DESIGN.md §3).
class RoleSelector extends StatelessWidget {
  const RoleSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final UserRole? selected;
  final ValueChanged<UserRole> onChanged;

  static const _icons = <UserRole, IconData>{
    UserRole.siswa: Icons.school_outlined,
    UserRole.mahasiswa: Icons.cast_for_education_outlined,
    UserRole.guru: Icons.co_present_outlined,
    UserRole.umum: Icons.person_outline,
  };

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 2.4,
      children: UserRole.values.map((r) {
        return _RoleCard(
          role: r,
          icon: _icons[r] ?? Icons.person_outline,
          active: selected == r,
          onTap: () => onChanged(r),
        );
      }).toList(),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final UserRole role;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? AppColors.accent.withValues(alpha: 0.10)
          : AppColors.background,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: active ? AppColors.accent : AppColors.surfaceBorder,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 22,
                  color: active
                      ? AppColors.accent
                      : AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  role.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: active ? AppColors.accent : AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
