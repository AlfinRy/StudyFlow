import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/date_labels.dart';
import '../../../shared_widgets/empty_state.dart';
import '../../materials/domain/study_material.dart';
import '../../materials/material_providers.dart';
import '../../materials/presentation/materials_screen.dart';
import '../../materials/presentation/widgets/material_file_type_style.dart';
import '../../shell/shell_providers.dart';
import '../../tasks/domain/task.dart';
import '../../tasks/task_providers.dart';

/// Pencarian global (FEATURE_ROADMAP #10). Mencari materi (judul, kategori,
/// tag) dan tugas (judul) sekaligus, lalu menampilkan hasil bergrup. Diakses
/// dari Beranda lewat search bar.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _openMaterial(StudyMaterial m) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MaterialsScreen()),
    );
  }

  void _openTask() {
    ref.read(activeTabProvider.notifier).state = 2; // tab Tugas
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final hasQuery = q.isNotEmpty;

    final materials = hasQuery
        ? ref.watch(materialListProvider).where((m) {
            return m.title.toLowerCase().contains(q) ||
                m.category.toLowerCase().contains(q) ||
                m.tags.any((t) => t.toLowerCase().contains(q));
          }).toList()
        : <StudyMaterial>[];

    final tasks = hasQuery
        ? ref.watch(taskListProvider).where((t) {
            return t.title.toLowerCase().contains(q) ||
                (t.description ?? '').toLowerCase().contains(q);
          }).toList()
        : <Task>[];

    final hasResults = materials.isNotEmpty || tasks.isNotEmpty;

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Kembali',
        ),
        titleSpacing: 0,
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          textInputAction: TextInputAction.search,
          textCapitalization: TextCapitalization.sentences,
          onChanged: (v) => setState(() => _query = v),
          decoration: const InputDecoration(
            hintText: 'Cari materi atau tugas...',
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Hapus',
              onPressed: () {
                _ctrl.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: SafeArea(
        child: !hasQuery
            ? const Center(
                child: EmptyState(
                  icon: Icons.search_rounded,
                  title: 'Cari apa saja',
                  subtitle: 'Ketik untuk mencari materi & tugas kamu.',
                ),
              )
            : !hasResults
                ? Center(
                    child: EmptyState(
                      icon: Icons.sentiment_dissatisfied_rounded,
                      title: 'Tidak ada hasil',
                      subtitle: 'Coba kata kunci lain untuk "$_query".',
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
                    children: [
                      if (materials.isNotEmpty) ...[
                        _SectionLabel(
                            icon: Icons.folder_open_rounded,
                            text: 'Materi (${materials.length})'),
                        const SizedBox(height: AppSpacing.sm),
                        for (final m in materials)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _MaterialResult(
                              material: m,
                              onTap: () => _openMaterial(m),
                            ),
                          ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      if (tasks.isNotEmpty) ...[
                        _SectionLabel(
                            icon: Icons.checklist_rounded,
                            text: 'Tugas (${tasks.length})'),
                        const SizedBox(height: AppSpacing.sm),
                        for (final t in tasks)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _TaskResult(
                              task: t,
                              onTap: _openTask,
                            ),
                          ),
                      ],
                    ],
                  ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.textSecondary),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _MaterialResult extends StatelessWidget {
  const _MaterialResult({required this.material, required this.onTap});
  final StudyMaterial material;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = MaterialFileTypeStyle.of(material.fileType);
    return Material(
      color: context.surface,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: context.surfaceBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: style.tint,
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, size: 20, color: style.color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        material.fileType.label,
                        if (material.category.isNotEmpty) material.category,
                        ...material.tags.map((t) => '#$t'),
                      ].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12, color: context.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.surfaceBorder),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskResult extends StatelessWidget {
  const _TaskResult({required this.task, required this.onTap});
  final Task task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.surface,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: context.surfaceBorder),
          ),
          child: Row(
            children: [
              Icon(
                task.isDone
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 22,
                color: task.isDone ? AppColors.success : context.textSecondary,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                        decoration:
                            task.isDone ? TextDecoration.lineThrough : null,
                        decorationColor: context.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      task.isDone
                          ? 'Selesai'
                          : 'Deadline ${idnFormatDateCompact(task.dueDate)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12, color: context.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: context.surfaceBorder),
            ],
          ),
        ),
      ),
    );
  }
}
