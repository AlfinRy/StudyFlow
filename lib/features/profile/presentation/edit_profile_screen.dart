import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared_widgets/navy_hero_card.dart';
import '../../auth/auth_providers.dart';
import '../../auth/domain/user_role.dart';

/// Form edit profil (PRD §10b). Menyimpan nama/role/foto via
/// [AuthRepository.updateProfile] → Firestore `users/{uid}` + cache Hive.
/// Email bersifat read-only (dari Firebase Auth). Lihat documentation/PROGRESS.md.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _photoCtrl = TextEditingController();
  late UserRole _role;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameCtrl.text = user?.name ?? '';
    _photoCtrl.text = user?.photoUrl ?? '';
    _role = user?.role ?? UserRole.mahasiswa;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _photoCtrl.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    final clean = msg.replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(clean), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showError('Nama tidak boleh kosong.');
      return;
    }
    final photo = _photoCtrl.text.trim();
    if (photo.isNotEmpty) {
      final uri = Uri.tryParse(photo);
      if (uri == null || uri.host.isEmpty ||
          !(uri.scheme == 'http' || uri.scheme == 'https')) {
        _showError('URL foto tidak valid (harus http/https).');
        return;
      }
    }

    setState(() => _saving = true);
    try {
      await ref.read(authRepositoryProvider).updateProfile(
            name: name,
            role: _role,
            photoUrl: photo,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil diperbarui.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final email = user?.email ?? '-';
    final photoUrl = (_photoCtrl.text.trim().isNotEmpty)
        ? _photoCtrl.text.trim()
        : user?.photoUrl;
    final initial =
        (_nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : '?')
            .substring(0, 1)
            .toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Kembali',
        ),
        title: const Text('Edit Profil'),
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
                  const Text(
                    'Edit Profil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Perbarui nama, peran, dan foto profil Anda.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Pratinjau avatar
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: AppColors.accent,
                backgroundImage:
                    (photoUrl != null && photoUrl.isNotEmpty)
                        ? NetworkImage(photoUrl)
                        : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Nama
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Nama',
                hintText: 'cth. Budi Santoso',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Email (read-only)
            TextFormField(
              initialValue: email,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
                helperText: 'Email tidak dapat diubah.',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Role
            DropdownButtonFormField<UserRole>(
              initialValue: _role,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Daftar Sebagai',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              items: UserRole.values
                  .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _role = v);
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // URL Foto (opsional)
            TextFormField(
              controller: _photoCtrl,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}), // refresh pratinjau avatar
              decoration: const InputDecoration(
                labelText: 'URL Foto (opsional)',
                hintText: 'cth. https://.../foto.jpg',
                prefixIcon: Icon(Icons.link_outlined),
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
              label: const Text('Simpan Perubahan'),
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
