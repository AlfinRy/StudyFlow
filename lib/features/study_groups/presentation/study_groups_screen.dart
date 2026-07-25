import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared_widgets/empty_state.dart';
import '../../../shared_widgets/navy_hero_card.dart';
import '../../auth/auth_providers.dart';
import '../domain/study_group.dart';
import '../study_group_providers.dart';
import 'group_detail_screen.dart';

/// Halaman Grup Belajar (FEATURE_ROADMAP #11). Cloud-only: daftar grup real-time
/// dari Firestore. Diakses via shortcut Forum. Mirip pola Forum namun dengan
/// keanggotaan (join/leave) + chat grup.
class StudyGroupsScreen extends ConsumerWidget {
  const StudyGroupsScreen({super.key});

  Future<void> _openCreate(BuildContext context, WidgetRef ref) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) => _CreateGroupDialog(ownerUid: user.uid, ownerName: user.name),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDemo = ref.watch(isDemoModeProvider);
    final groupsAsync = ref.watch(studyGroupsProvider);

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Kembali',
        ),
        title: const Text('Grup Belajar'),
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
                    'Grup Belajar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Bentuk kelompok belajar bareng teman — diskusi & saling '
                    'menyemangati.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (!isDemo)
              FilledButton.icon(
                onPressed: () => _openCreate(context, ref),
                icon: const Icon(Icons.group_add_rounded),
                label: const Text('Buat Grup'),
              )
            else
              const SizedBox(
                height: 240,
                child: EmptyState(
                  icon: Icons.lock_outline_rounded,
                  title: 'Grup butuh akun',
                  subtitle: 'Login dengan akun Firebase untuk membuat & '
                      'bergabung di grup belajar.',
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            if (!isDemo) _GroupList(groupsAsync: groupsAsync),
          ],
        ),
      ),
    );
  }
}

class _GroupList extends StatelessWidget {
  const _GroupList({required this.groupsAsync});
  final AsyncValue<List<StudyGroup>> groupsAsync;

  @override
  Widget build(BuildContext context) {
    return groupsAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const SizedBox(
        height: 200,
        child: EmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Tidak dapat memuat grup',
          subtitle: 'Pastikan kamu terhubung ke internet, lalu tarik untuk '
              'menyegarkan.',
        ),
      ),
      data: (groups) {
        if (groups.isEmpty) {
          return const SizedBox(
            height: 200,
            child: EmptyState(
              icon: Icons.groups_outlined,
              title: 'Belum ada grup',
              subtitle: 'Jadilah yang pertama membuat grup belajar.',
            ),
          );
        }
        return Column(
          children: [
            for (final g in groups)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _GroupCard(group: g),
              ),
          ],
        );
      },
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group});
  final StudyGroup group;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.surface,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => GroupDetailScreen(group: group)),
        ),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(color: context.surfaceBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.groups_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (group.description.isNotEmpty)
                      Text(
                        group.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 13,
                            height: 1.4),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded,
                            size: 14, color: context.textSecondary),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            group.ownerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: context.textSecondary, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Icon(Icons.people_outline_rounded,
                            size: 14, color: AppColors.accent),
                        const SizedBox(width: 3),
                        Text(
                          '${group.memberCount} anggota',
                          style: const TextStyle(
                              color: AppColors.accent, fontSize: 12),
                        ),
                      ],
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

class _CreateGroupDialog extends ConsumerStatefulWidget {
  const _CreateGroupDialog({required this.ownerUid, required this.ownerName});
  final String ownerUid;
  final String ownerName;

  @override
  ConsumerState<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends ConsumerState<_CreateGroupDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nama grup wajib diisi.'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(studyGroupRepositoryProvider).createGroup(
            name: name,
            description: _descCtrl.text.trim(),
            ownerUid: widget.ownerUid,
            ownerName: widget.ownerName,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Gagal membuat grup. Coba lagi.'),
              behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Buat Grup Belajar'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Nama Grup',
              hintText: 'cth. Belajar UTBK Bareng',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _descCtrl,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Deskripsi (opsional)',
              hintText: 'Tujuan / aturan singkat grup',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Buat'),
        ),
      ],
    );
  }
}
