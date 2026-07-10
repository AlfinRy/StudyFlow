import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared_widgets/app_avatar.dart';
import '../../../shared_widgets/navy_hero_card.dart';
import '../../auth/auth_providers.dart';
import '../../auth/domain/user_role.dart';

/// Form edit profil (PRD §10b). Menyimpan nama/role/foto via
/// [AuthRepository.updateProfile] → Firestore `users/{uid}` + cache Hive.
/// Email read-only (dari Firebase Auth). Foto dapat diunggah dari galeri
/// (PNG/JPG) → dikompres & disimpan sebagai base64 di Firestore (gratis, tanpa
/// Storage), atau via URL. Lihat documentation/PROGRESS.md.
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
  bool _uploading = false;

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

  /// Pilih gambar (PNG/JPG) dari galeri, kompres ke ~512px JPEG, lalu simpan
  /// sebagai data URI base64 pada field foto (disimpan ke Firestore saat Save).
  /// Hanya tersedia di mode Firebase.
  Future<void> _pickPhoto() async {
    final result = await FilePicker.pickFiles(type: FileType.image);
    if (result == null || result.files.isEmpty) return;
    final pickedPath = result.files.single.path;
    if (pickedPath == null) return;

    setState(() => _uploading = true);
    try {
      final bytes = await FlutterImageCompress.compressWithFile(
        pickedPath,
        minWidth: 512,
        minHeight: 512,
        quality: 80,
      );
      if (bytes == null) throw Exception('Gagal memproses gambar.');
      final dataUri = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      setState(() => _photoCtrl.text = dataUri);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto dipilih. Tekan Simpan untuk menyimpan.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      _showError('Nama tidak boleh kosong.');
      return;
    }
    final photo = _photoCtrl.text.trim();
    // Data URI base64 valid langsung; URL dicek skema http/https + host.
    if (photo.isNotEmpty && !photo.startsWith('data:image/')) {
      final uri = Uri.tryParse(photo);
      if (uri == null ||
          uri.host.isEmpty ||
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
    final isDemo = ref.watch(isDemoModeProvider);
    final email = user?.email ?? '-';
    final photo = _photoCtrl.text.trim();
    final displayName = _nameCtrl.text.trim();

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
                children: const [
                  Text(
                    'Edit Profil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Perbarui nama, peran, dan foto profil Anda.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Pratinjau avatar + tombol unggah foto
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AppAvatar(
                    name: displayName,
                    photoUrl: photo.isNotEmpty ? photo : user?.photoUrl,
                    radius: 52,
                  ),
                  if (_uploading)
                    const SizedBox(
                      width: 116,
                      height: 116,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (!isDemo)
              Center(
                child: FilledButton.tonalIcon(
                  onPressed: (_uploading || _saving) ? null : _pickPhoto,
                  icon: const Icon(Icons.photo_camera_back_outlined),
                  label: Text(_uploading ? 'Memproses...' : 'Ganti Foto'),
                ),
              )
            else
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Text(
                    'Upload foto butuh Firebase (tidak tersedia di mode demo).',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
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

            // Foto: bila sudah ada → indikator + hapus; bila belum → input URL.
            if (photo.isNotEmpty)
              _PhotoSetRow(onClear: () => setState(() => _photoCtrl.clear()))
            else
              TextFormField(
                controller: _photoCtrl,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
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

/// Baris indikator "foto terpasang" + tombol hapus, dipakai saat field foto
/// sudah berisi (data URI base64 maupun URL).
class _PhotoSetRow extends StatelessWidget {
  const _PhotoSetRow({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 20),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text(
              'Foto profil terpasang',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
