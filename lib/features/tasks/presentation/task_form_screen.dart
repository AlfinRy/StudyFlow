import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/date_labels.dart';
import '../../../shared_widgets/navy_hero_card.dart';
import '../domain/task.dart';
import '../domain/task_priority.dart';
import '../task_providers.dart';
import 'task_form_validation.dart';

/// Form tambah/edit tugas (PRD §5.3, UI_DESIGN.md §6). Konsisten dengan pola
/// form jadwal. Field "Lampiran/Upload" belum diimplementasi karena tidak ada
/// di model Task (PRD §4.2) — menyusul saat attachment ditambahkan ke data
/// model.
///
/// Kirim [task] untuk mode edit; kosongkan untuk mode tambah.
class TaskFormScreen extends ConsumerStatefulWidget {
  const TaskFormScreen({super.key, this.task});

  final Task? task;

  @override
  ConsumerState<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends ConsumerState<TaskFormScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  late DateTime _dueDate;
  late TimeOfDay _dueTime;
  late TaskPriority _priority;
  late String? _category;
  late bool _reminder;
  bool _saving = false;

  bool get _isEdit => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleCtrl.text = t?.title ?? '';
    _descCtrl.text = t?.description ?? '';
    _dueDate = t?.dueDate ?? DateTime.now();
    _dueTime = t != null
        ? TimeOfDay(hour: t.dueDate.hour, minute: t.dueDate.minute)
        : const TimeOfDay(hour: 23, minute: 59);
    _priority = t?.priority ?? TaskPriority.medium;
    _category = t?.category;
    _reminder = t?.reminderEnabled ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Pilih tanggal deadline',
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime,
      helpText: 'Pilih waktu deadline',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueTime = picked);
  }

  DateTime get _combinedDue =>
      DateTime(_dueDate.year, _dueDate.month, _dueDate.day,
          _dueTime.hour, _dueTime.minute);

  Future<void> _save() async {
    final error = validateTaskForm(_titleCtrl.text);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _saving = true);
    final notifier = ref.read(taskListProvider.notifier);
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (_isEdit) {
      await notifier.update(widget.task!.copyWith(
        title: title,
        description: desc.isEmpty ? null : desc,
        dueDate: _combinedDue,
        priority: _priority,
        category: _category,
        reminderEnabled: _reminder,
      ));
    } else {
      await notifier.add(Task(
        id: '',
        title: title,
        description: desc.isEmpty ? null : desc,
        dueDate: _combinedDue,
        priority: _priority,
        category: _category,
        reminderEnabled: _reminder,
      ));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Tugas diperbarui.' : 'Tugas "$title" ditambahkan.'),
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
        title: Text(_isEdit ? 'Edit Tugas' : 'Tugas Baru'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
          children: [
            NavyHeroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isEdit ? 'Edit Tugas' : 'Tugas Baru',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Catat tugas dan deadlinya agar tidak terlewat.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Judul
            TextFormField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Judul Tugas',
                hintText: 'cth. Mengerjakan Esai Bahasa Inggris',
                prefixIcon: Icon(Icons.task_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Kategori + Prioritas
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _CategoryDropdown(
                    value: _category,
                    onChanged: (v) => setState(() => _category = v),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _PriorityDropdown(
                    value: _priority,
                    onChanged: (v) => setState(() => _priority = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Deskripsi
            TextFormField(
              controller: _descCtrl,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                alignLabelWithHint: true,
                hintText: 'Detail tugas, referensi, atau catatan tambahan...',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Deadline + Waktu
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _PickerField(
                    label: 'Tanggal Deadline',
                    icon: Icons.event_outlined,
                    value: idnFormatDateCompact(_dueDate),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _PickerField(
                    label: 'Waktu',
                    icon: Icons.schedule_rounded,
                    value: formatTimeOfDay(_dueTime),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Toggle reminder (notifikasi = Fase 6, flag disimpan sekarang)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_outlined,
                      color: AppColors.accent),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Aktifkan Pengingat',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Pengingat H-1 & hari-H, pukul 08.00',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _reminder,
                    onChanged: (v) => setState(() => _reminder = v),
                    activeThumbColor: AppColors.accent,
                  ),
                ],
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
              label: Text(_isEdit ? 'Simpan Perubahan' : 'Simpan Tugas'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
              child: const Text('Batalkan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.icon,
    required this.value,
    required this.onTap,
  });

  final String label;
  final IconData icon;
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
          prefixIcon: Icon(icon),
        ),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({required this.value, required this.onChanged});
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Kategori',
        prefixIcon: Icon(Icons.label_outlined),
      ),
      items: [
        const DropdownMenuItem(value: null, child: Text('Tanpa kategori')),
        ...defaultTaskCategories.map(
          (c) => DropdownMenuItem(value: c, child: Text(c)),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _PriorityDropdown extends StatelessWidget {
  const _PriorityDropdown({required this.value, required this.onChanged});
  final TaskPriority value;
  final ValueChanged<TaskPriority> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<TaskPriority>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Prioritas',
        prefixIcon: Icon(Icons.flag_outlined),
      ),
      items: TaskPriority.values
          .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
