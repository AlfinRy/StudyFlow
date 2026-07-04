import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/task_priority.dart';

/// Mapping visual [TaskPriority] → (warna, tint, badge). Badge uppercase sesuai
/// UI_DESIGN.md §6 (URGENT/NORMAL/RENDAH).
@immutable
class TaskPriorityStyle {
  const TaskPriorityStyle({required this.color, required this.badge});

  final Color color;
  final String badge;

  Color get tint => color.withValues(alpha: 0.12);

  static TaskPriorityStyle of(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return const TaskPriorityStyle(color: AppColors.danger, badge: 'URGENT');
      case TaskPriority.medium:
        return const TaskPriorityStyle(
            color: AppColors.warning, badge: 'NORMAL');
      case TaskPriority.low:
        return const TaskPriorityStyle(
            color: AppColors.textSecondary, badge: 'RENDAH');
    }
  }
}
