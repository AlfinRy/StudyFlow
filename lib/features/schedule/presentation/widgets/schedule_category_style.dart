import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/schedule_category.dart';

/// Mapping visual [ScheduleCategory] → (icon, warna). Domain tetap bebas
/// Flutter; mapper ini hidup di lapisan presentation (lihat UI_DESIGN.md §5).
@immutable
class ScheduleCategoryStyle {
  const ScheduleCategoryStyle({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  /// Chip tint (background lembut) diturunkan dari [color].
  Color get tint => color.withValues(alpha: 0.12);

  static const _default =
      ScheduleCategoryStyle(icon: Icons.event_note_rounded, color: AppColors.info);

  static ScheduleCategoryStyle of(ScheduleCategory? category) {
    switch (category) {
      case ScheduleCategory.kuliah:
        return const ScheduleCategoryStyle(
            icon: Icons.school_rounded, color: AppColors.accent);
      case ScheduleCategory.sekolah:
        return const ScheduleCategoryStyle(
            icon: Icons.menu_book_rounded, color: AppColors.info);
      case ScheduleCategory.pribadi:
        return const ScheduleCategoryStyle(
            icon: Icons.person_rounded, color: AppColors.warning);
      case null:
        return _default;
    }
  }
}
