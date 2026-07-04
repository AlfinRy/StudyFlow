import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/date_labels.dart';

/// Pemilih tanggal horizontal (UI_DESIGN.md §5). Menampilkan 7 hari mulai
/// dari [startDate] (default: hari ini). Hari terpilih disorot dengan
/// background biru solid.
///
/// Karena jadwal bersifat mingguan (berulang per `dayOfWeek`), pemilihan
/// tanggal hanya menentukan weekday mana yang ditampilkan — bukan tanggal
/// absolut. Lihat PRD §4.2.
class ScheduleDateSelector extends StatelessWidget {
  const ScheduleDateSelector({
    super.key,
    required this.selected,
    this.startDate,
    required this.onSelect,
    this.dayCount = 7,
  });

  final DateTime selected;
  final DateTime? startDate;
  final ValueChanged<DateTime> onSelect;
  final int dayCount;

  List<DateTime> get days {
    final start = startDate ?? DateTime.now();
    return List.generate(dayCount, (i) => start.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final items = days;
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final day = items[i];
          final isSelected = _sameDay(day, selected);
          final isToday = _sameDay(day, todayDateOnly);
          return _DateChip(
            date: day,
            selected: isSelected,
            isToday: isToday,
            onTap: () => onSelect(day),
          );
        },
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 56,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? accent : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: selected ? accent : AppColors.surfaceBorder,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              idnShortWeekday(date.weekday),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white70
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: selected
                    ? Colors.white
                    : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            if (isToday && !selected)
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 5),
          ],
        ),
      ),
    );
  }
}
