import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/date_labels.dart';
import '../../domain/material_file_type.dart';
import '../../domain/study_material.dart';
import 'material_file_type_style.dart';

/// Satu baris kartu materi (UI_DESIGN.md §9.1): ikon tipe file (lingkaran
/// tinted), badge tipe + chip kategori, judul, tanggal ditambahkan, dan menu
/// buka/lihat, edit, hapus. Struktur konsisten dengan [TaskCard].
class MaterialCard extends StatelessWidget {
  const MaterialCard({
    super.key,
    required this.material,
    this.onOpen,
    this.onEdit,
    this.onDelete,
  });

  final StudyMaterial material;
  final VoidCallback? onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final style = MaterialFileTypeStyle.of(material.fileType);
    final isNote = material.fileType == MaterialFileType.note;

    return Container(
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: style.tint,
              shape: BoxShape.circle,
            ),
            child: Icon(style.icon, size: 22, color: style.color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _TypeBadge(text: material.fileType.label, color: style.color),
                    if (material.category.isNotEmpty)
                      _CategoryChip(category: material.category),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  material.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'Ditambahkan ${idnFormatDateCompact(material.createdAt)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onOpen != null || onEdit != null || onDelete != null)
            PopupMenuButton<_MaterialMenu>(
              icon: Icon(Icons.more_vert_rounded,
                  color: AppColors.textSecondary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.md)),
              itemBuilder: (_) => [
                if (onOpen != null)
                  PopupMenuItem(
                    value: _MaterialMenu.open,
                    child: Row(children: [
                      Icon(
                          isNote
                              ? Icons.visibility_outlined
                              : Icons.open_in_new_rounded,
                          size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(isNote ? 'Lihat' : 'Buka'),
                    ]),
                  ),
                if (onEdit != null)
                  const PopupMenuItem(
                    value: _MaterialMenu.edit,
                    child: Row(children: [
                      Icon(Icons.edit_outlined, size: 20),
                      SizedBox(width: AppSpacing.sm),
                      Text('Edit'),
                    ]),
                  ),
                if (onDelete != null)
                  const PopupMenuItem(
                    value: _MaterialMenu.delete,
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
                  case _MaterialMenu.open:
                    onOpen?.call();
                    break;
                  case _MaterialMenu.edit:
                    onEdit?.call();
                    break;
                  case _MaterialMenu.delete:
                    onDelete?.call();
                    break;
                }
              },
            ),
        ],
      ),
    );
  }
}

enum _MaterialMenu { open, edit, delete }

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
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
