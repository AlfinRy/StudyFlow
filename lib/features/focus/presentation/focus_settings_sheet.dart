import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../focus_providers.dart';

/// Sheet pengaturan durasi Pomodoro (fokus, jeda pendek, jeda panjang, siklus,
/// auto-start). Perubahan langsung tersimpan (Hive) & reaktif.
class FocusSettingsSheet extends ConsumerWidget {
  const FocusSettingsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(pomodoroConfigProvider);
    final notifier = ref.read(pomodoroConfigProvider.notifier);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Pengaturan Pomodoro',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Sesuaikan durasi sesuai ritme belajarmu.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.lg),
          _StepperRow(
            label: 'Durasi Fokus',
            unit: 'menit',
            value: config.focusMinutes,
            min: 5,
            max: 90,
            step: 5,
            onChanged: (v) =>
                notifier.update(config.copyWith(focusMinutes: v)),
          ),
          _StepperRow(
            label: 'Jeda Pendek',
            unit: 'menit',
            value: config.shortBreakMinutes,
            min: 1,
            max: 30,
            step: 1,
            onChanged: (v) =>
                notifier.update(config.copyWith(shortBreakMinutes: v)),
          ),
          _StepperRow(
            label: 'Jeda Panjang',
            unit: 'menit',
            value: config.longBreakMinutes,
            min: 5,
            max: 60,
            step: 5,
            onChanged: (v) =>
                notifier.update(config.copyWith(longBreakMinutes: v)),
          ),
          _StepperRow(
            label: 'Siklus sebelum Jeda Panjang',
            unit: 'x',
            value: config.cyclesBeforeLongBreak,
            min: 2,
            max: 8,
            step: 1,
            onChanged: (v) =>
                notifier.update(config.copyWith(cyclesBeforeLongBreak: v)),
          ),
          const Divider(height: AppSpacing.xxl),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mulai jeda otomatis',
                style: TextStyle(fontSize: 14)),
            subtitle: const Text('Lanjut ke istirahat tanpa tekan tombol',
                style: TextStyle(fontSize: 12)),
            value: config.autoStartBreaks,
            onChanged: (v) =>
                notifier.update(config.copyWith(autoStartBreaks: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mulai fokus otomatis',
                style: TextStyle(fontSize: 14)),
            subtitle: const Text('Lanjut ke sesi berikutnya setelah jeda',
                style: TextStyle(fontSize: 12)),
            value: config.autoStartFocus,
            onChanged: (v) =>
                notifier.update(config.copyWith(autoStartFocus: v)),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton(
            onPressed: () => notifier.reset(),
            child: const Text('Kembalikan ke default'),
          ),
        ],
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.unit,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  final String label;
  final String unit;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Text('$value $unit',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Row(
            children: [
              _StepButton(
                icon: Icons.remove_rounded,
                onTap: value > min ? () => onChanged((value - step).clamp(min, max)) : null,
              ),
              SizedBox(
                width: 56,
                child: Text('$value',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              _StepButton(
                icon: Icons.add_rounded,
                onTap: value < max ? () => onChanged((value + step).clamp(min, max)) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? AppColors.accent.withValues(alpha: 0.12) : AppColors.surfaceBorder,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon,
              size: 20,
              color: enabled ? AppColors.accent : AppColors.textSecondary),
        ),
      ),
    );
  }
}
