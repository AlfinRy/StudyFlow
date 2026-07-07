import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/material_file_type.dart';

/// Mapping visual [MaterialFileType] → (icon, warna). Domain tetap bebas
/// Flutter; mapper ini hidup di lapisan presentation (lihat UI_DESIGN.md §9.1).
/// Konvensi sama dengan [TaskPriorityStyle] / [ScheduleCategoryStyle].
@immutable
class MaterialFileTypeStyle {
  const MaterialFileTypeStyle({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  /// Chip tint (background lembut) diturunkan dari [color].
  Color get tint => color.withValues(alpha: 0.12);

  static MaterialFileTypeStyle of(MaterialFileType type) {
    switch (type) {
      case MaterialFileType.pdf:
        return const MaterialFileTypeStyle(
            icon: Icons.picture_as_pdf_rounded, color: AppColors.danger);
      case MaterialFileType.image:
        return const MaterialFileTypeStyle(
            icon: Icons.image_outlined, color: AppColors.info);
      case MaterialFileType.link:
        return const MaterialFileTypeStyle(
            icon: Icons.link_rounded, color: AppColors.accent);
      case MaterialFileType.note:
        return const MaterialFileTypeStyle(
            icon: Icons.sticky_note_2_outlined, color: AppColors.warning);
    }
  }
}
