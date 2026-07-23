import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../domain/schedule.dart';
import 'schedule_category_style.dart';

/// Satu baris kartu jadwal (UI_DESIGN.md §5): ikon kategori berwarna, judul,
/// rentang jam, badge lokasi, dan chevron.
class ScheduleCard extends StatelessWidget {
  const ScheduleCard({
    super.key,
    required this.schedule,
    this.onTap,
  });

  final Schedule schedule;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = ScheduleCategoryStyle.of(schedule.category);
    final locationBadge = _LocationBadge(location: schedule.location);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: style.tint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(style.icon, color: style.color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      schedule.title,
                      maxLines: 1,
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
                        Icon(Icons.access_time_rounded,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${schedule.startTime} – ${schedule.endTime}',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (locationBadge.visible) ...[
                          const SizedBox(width: AppSpacing.sm),
                          locationBadge,
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge lokasi/ruang. Deteksi "online" (case-insensitive) → badge info biru;
/// selainnya teks lokasi sebagai pill netral. (UI_DESIGN.md §5: RUANG/LAB/
/// PERPUSTAKAAN/ONLINE.)
class _LocationBadge extends StatelessWidget {
  const _LocationBadge({this.location});

  final String? location;

  bool get visible => location != null && location!.trim().isNotEmpty;
  bool get _isOnline =>
      visible && location!.trim().toLowerCase().contains('online');

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final online = _isOnline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: online
            ? AppColors.info.withValues(alpha: 0.12)
            : AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
        border: Border.all(
          color: online ? AppColors.info : AppColors.surfaceBorder,
        ),
      ),
      child: Text(
        online ? 'ONLINE' : location!.trim().toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: online ? AppColors.info : AppColors.textSecondary,
        ),
      ),
    );
  }
}
