import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared_widgets/confirm_delete_dialog.dart';
import '../../../shared_widgets/empty_state.dart';
import '../../../shared_widgets/navy_hero_card.dart';
import '../domain/material_file_type.dart';
import '../domain/study_material.dart';
import '../material_providers.dart';
import 'material_form_screen.dart';
import 'widgets/material_card.dart';

/// Halaman Materi Pembelajaran (PRD §4.2 box `materials`, UI_DESIGN.md §9.1).
///
/// Diakses via shortcut dari Beranda (bukan tab bottom nav) supaya bottom nav
/// tetap 5 item — lihat catatan UI_DESIGN.md §9.1. Fitur: cari judul, filter
/// kategori, daftar card materi, tambah/edit/hapus, dan buka tautan.
class MaterialsScreen extends ConsumerStatefulWidget {
  const MaterialsScreen({super.key});

  @override
  ConsumerState<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends ConsumerState<MaterialsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String? _category; // null = Semua

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openForm([StudyMaterial? material]) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MaterialFormScreen(material: material)),
    );
  }

  Future<void> _confirmDelete(StudyMaterial material) async {
    final ok = await showConfirmDeleteDialog(
      context,
      title: 'Hapus materi?',
      message: 'Materi "${material.title}" akan dihapus permanen.',
    );
    if (ok) {
      await ref.read(materialListProvider.notifier).remove(material.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Materi dihapus.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _open(StudyMaterial material) async {
    // Catatan dibuka sebagai dialog (isinya teks, bukan URI).
    if (material.fileType == MaterialFileType.note) {
      _showNoteDialog(material);
      return;
    }
    final uri = Uri.tryParse(material.filePathOrUrl.trim());
    if (uri == null || !uri.hasAbsolutePath) {
      _showOpenError();
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) _showOpenError();
  }

  void _showNoteDialog(StudyMaterial material) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(material.title),
        content: SingleChildScrollView(
          child: Text(
            material.filePathOrUrl,
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showOpenError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tidak dapat membuka tautan ini.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<StudyMaterial> _applyFilters(List<StudyMaterial> all) {
    final q = _query.trim().toLowerCase();
    return all.where((m) {
      final matchQuery = q.isEmpty || m.title.toLowerCase().contains(q);
      final matchCategory = _category == null || m.category == _category;
      return matchQuery && matchCategory;
    }).toList();
  }

  List<String> _uniqueCategories(List<StudyMaterial> all) {
    final set = <String>{};
    for (final m in all) {
      if (m.category.isNotEmpty) set.add(m.category);
    }
    return set.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(materialListProvider);
    final visible = _applyFilters(all);
    final categories = _uniqueCategories(all);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Kembali',
        ),
        title: const Text('Materi Pembelajaran'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
          children: [
            NavyHeroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Materi Pembelajaran',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pusatkan materi belajarmu — PDF, gambar, tautan, & catatan.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Search bar (UI_DESIGN.md §9.1)
            TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Cari materi...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Hapus pencarian',
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Filter kategori (chip horizontal)
            if (categories.isNotEmpty) ...[
              _CategoryChips(
                categories: categories,
                selected: _category,
                onSelect: (c) => setState(() => _category = c),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            if (visible.isEmpty)
              EmptyState(
                icon: Icons.folder_open_rounded,
                title: all.isEmpty
                    ? 'Belum ada materi'
                    : 'Materi tidak ditemukan',
                subtitle: all.isEmpty
                    ? 'Tambah materi menggunakan tombol + di bawah.'
                    : 'Coba ubah kata kunci atau kategori.',
                action: all.isEmpty
                    ? FilledButton.icon(
                        onPressed: () => _openForm(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Tambah Materi'),
                      )
                    : null,
              )
            else
              Column(
                children: [
                  for (final m in visible)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: MaterialCard(
                        material: m,
                        onOpen: () => _open(m),
                        onEdit: () => _openForm(m),
                        onDelete: () => _confirmDelete(m),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Filter kategori horizontal (reuse pola chip dari date selector Jadwal).
/// Index 0 = "Semua" (nilai null).
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<String> categories;
  final String? selected; // null = Semua
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final chips = <String>['Semua', ...categories];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final label = chips[i];
          final value = i == 0 ? null : label;
          final active = selected == value;
          return _Chip(
            label: label,
            active: active,
            onTap: () => onSelect(value),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
          border: Border.all(
              color: active ? AppColors.accent : AppColors.surfaceBorder),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
