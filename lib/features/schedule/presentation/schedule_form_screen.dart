import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/date_labels.dart';
import '../../../shared_widgets/navy_hero_card.dart';
import '../domain/schedule.dart';
import '../domain/schedule_category.dart';
import '../schedule_providers.dart';
import 'schedule_form_validation.dart';

/// Form tambah/edit jadwal (PRD §5.2). Lengkap & konsisten dengan visual
/// language app (UI_DESIGN.md §6 untuk pola form tugas).
///
/// Kirim [schedule] untuk mode edit; kosongkan untuk mode tambah.
class ScheduleFormScreen extends ConsumerStatefulWidget {
  const ScheduleFormScreen({super.key, this.schedule});

  final Schedule? schedule;

  @override
  ConsumerState<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends ConsumerState<ScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _locationCtrl;

  late int _dayOfWeek;
  late String _startTime;
  late String _endTime;
  ScheduleCategory? _category;
  bool _saving = false;

  bool get _isEdit => widget.schedule != null;

  @override
  void initState() {
    super.initState();
    final s = widget.schedule;
    _titleCtrl = TextEditingController(text: s?.title ?? '');
    _locationCtrl = TextEditingController(text: s?.location ?? '');
    _dayOfWeek = s?.dayOfWeek ?? DateTime.now().weekday;
    _startTime = s?.startTime ?? '08:00';
    _endTime = s?.endTime ?? '09:30';
    _category = s?.category;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final current = parseTimeOfDay(isStart ? _startTime : _endTime);
    final picked = await showTimePicker(
      context: context,
      initialTime: current ?? TimeOfDay.now(),
      helpText: isStart ? 'Pilih jam mulai' : 'Pilih jam selesai',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = formatTimeOfDay(picked);
        } else {
          _endTime = formatTimeOfDay(picked);
        }
      });
    }
  }

  Future<void> _save() async {
    final error = validateScheduleForm(
      title: _titleCtrl.text,
      startTime: _startTime,
      endTime: _endTime,
    );
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _saving = true);
    final notifier = ref.read(scheduleListProvider.notifier);
    final locationValue = _locationCtrl.text.trim();

    if (_isEdit) {
      await notifier.update(widget.schedule!.copyWith(
        title: _titleCtrl.text.trim(),
        dayOfWeek: _dayOfWeek,
        startTime: _startTime,
        endTime: _endTime,
        location: locationValue.isEmpty ? null : locationValue,
        category: _category,
      ));
    } else {
      await notifier.add(Schedule(
        id: '',
        title: _titleCtrl.text.trim(),
        dayOfWeek: _dayOfWeek,
        startTime: _startTime,
        endTime: _endTime,
        location: locationValue.isEmpty ? null : locationValue,
        category: _category,
      ));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit
              ? 'Jadwal diperbarui.'
              : 'Jadwal "${_titleCtrl.text.trim()}" ditambahkan.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Kembali',
        ),
        title: Text(_isEdit ? 'Edit Jadwal' : 'Jadwal Baru'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
            children: [
              NavyHeroCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEdit ? 'Edit Jadwal' : 'Jadwal Baru',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Lengkapi detail jadwal belajarmu di bawah ini.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Judul
              TextFormField(
                controller: _titleCtrl,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Judul Jadwal',
                  hintText: 'cth. Matematika, Belajar Mandiri',
                  prefixIcon: Icon(Icons.book_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Hari (mingguan, recurring)
              const _FieldLabel(label: 'Hari'),
              const SizedBox(height: AppSpacing.sm),
              _DayPicker(selected: _dayOfWeek, onSelect: (d) => setState(() => _dayOfWeek = d)),
              const SizedBox(height: AppSpacing.lg),

              // Jam mulai & selesai
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _TimeField(
                      label: 'Jam Mulai',
                      value: _startTime,
                      onTap: () => _pickTime(true),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _TimeField(
                      label: 'Jam Selesai',
                      value: _endTime,
                      onTap: () => _pickTime(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Kategori
              const _FieldLabel(label: 'Kategori'),
              const SizedBox(height: AppSpacing.sm),
              _CategoryPicker(
                selected: _category,
                onSelect: (c) => setState(() => _category = c),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Lokasi (opsional)
              TextFormField(
                controller: _locationCtrl,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Lokasi / Ruang (opsional)',
                  hintText: 'cth. Lab A, Ruang 12, Online',
                  prefixIcon: Icon(Icons.place_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isEdit ? 'Simpan Perubahan' : 'Simpan Jadwal'),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
                child: const Text('Batalkan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}

class _DayPicker extends StatelessWidget {
  const _DayPicker({required this.selected, required this.onSelect});
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: List.generate(7, (i) {
        final day = i + 1; // 1..7
        final active = day == selected;
        return ChoiceChip(
          label: Text(idnShortWeekday(day)),
          selected: active,
          selectedColor: AppColors.accent,
          labelStyle: TextStyle(
            color: active ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          onSelected: (_) => onSelect(day),
        );
      }),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.schedule_rounded),
        ),
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({required this.selected, required this.onSelect});
  final ScheduleCategory? selected;
  final ValueChanged<ScheduleCategory?> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        ChoiceChip(
          label: const Text('Tanpa kategori'),
          selected: selected == null,
          selectedColor: AppColors.accent,
          labelStyle: TextStyle(
            color: selected == null ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          onSelected: (_) => onSelect(null),
        ),
        ...ScheduleCategory.values.map((c) {
          final active = c == selected;
          return ChoiceChip(
            label: Text(c.label),
            selected: active,
            selectedColor: AppColors.accent,
            labelStyle: TextStyle(
              color: active ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            onSelected: (_) => onSelect(c),
          );
        }),
      ],
    );
  }
}
