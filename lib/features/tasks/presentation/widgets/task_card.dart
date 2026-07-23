import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/deadline_format.dart';
import '../../domain/task.dart';
import 'task_priority_style.dart';

/// Satu baris kartu tugas (UI_DESIGN.md §6): checkbox, badge prioritas +
/// kategori, judul (strikethrough jika selesai), label deadline, dan menu
/// edit/hapus.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.onToggle,
    this.onEdit,
    this.onDelete,
  });

  final Task task;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final done = task.isDone;
    final priority = TaskPriorityStyle.of(task.priority);
    final deadline = formatTaskDeadline(dueDate: task.dueDate, isDone: done);

    return Opacity(
      opacity: done ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Checkbox(
              value: done,
              onChanged: onToggle == null
                  ? null
                  : (_) {
                      HapticFeedback.selectionClick();
                      onToggle!();
                    },
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5)),
              activeColor: AppColors.accent,
              checkColor: Colors.white,
              side: BorderSide(color: AppColors.textSecondary, width: 1.5),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _Badge(
                        text: priority.badge,
                        color: priority.color,
                        tint: priority.tint,
                      ),
                      if ((task.category ?? '').isNotEmpty)
                        _CategoryChip(category: task.category!),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      decoration:
                          done ? TextDecoration.lineThrough : TextDecoration.none,
                      decorationColor: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        done ? Icons.check_circle_outline : Icons.schedule_rounded,
                        size: 14,
                        color: _deadlineColor(deadline.tone),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          deadline.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: deadline.isOverdue
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: _deadlineColor(deadline.tone),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onEdit != null || onDelete != null)
              PopupMenuButton<_TaskMenu>(
                icon: Icon(Icons.more_vert_rounded,
                    color: AppColors.textSecondary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.md)),
                itemBuilder: (_) => [
                  if (onEdit != null)
                    const PopupMenuItem(
                      value: _TaskMenu.edit,
                      child: Row(children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: AppSpacing.sm),
                        Text('Edit'),
                      ]),
                    ),
                  if (onDelete != null)
                    const PopupMenuItem(
                      value: _TaskMenu.delete,
                      child: Row(children: [
                        Icon(Icons.delete_outline_rounded,
                            color: AppColors.danger, size: 20),
                        SizedBox(width: AppSpacing.sm),
                        Text('Hapus', style: TextStyle(color: AppColors.danger)),
                      ]),
                    ),
                ],
                onSelected: (v) {
                  switch (v) {
                    case _TaskMenu.edit:
                      onEdit?.call();
                      break;
                    case _TaskMenu.delete:
                      onDelete?.call();
                      break;
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _deadlineColor(DeadlineTone tone) {
    switch (tone) {
      case DeadlineTone.overdue:
        return AppColors.danger;
      case DeadlineTone.soon:
        return AppColors.warning;
      case DeadlineTone.done:
        return AppColors.success;
      case DeadlineTone.normal:
        return AppColors.textSecondary;
    }
  }
}

enum _TaskMenu { edit, delete }

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color, required this.tint});
  final String text;
  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: color,
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});
  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Text(
        category,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
