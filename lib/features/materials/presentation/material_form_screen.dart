import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared_widgets/navy_hero_card.dart';
import '../domain/material_file_type.dart';
import '../domain/study_material.dart';
import '../material_providers.dart';
import 'material_form_validation.dart';

/// Form tambah/edit materi (PRD §4.2 box `materials`, UI_DESIGN.md §9.1).
/// Konsisten dengan pola form tugas/jadwal.
///
/// Tipe **PDF** & **Gambar** mengunggah file asli (dipilih via file picker,
/// disalin ke penyimpanan app agar persisten). Tipe **Tautan** berupa URL
/// (divalidasi), **Catatan** berupa teks.
///
/// Kirim [material] untuk mode edit; kosongkan untuk mode tambah.
class MaterialFormScreen extends ConsumerStatefulWidget {
  const MaterialFormScreen({super.key, this.material});

  final StudyMaterial? material;

  @override
  ConsumerState<MaterialFormScreen> createState() => _MaterialFormScreenState();
}

class _MaterialFormScreenState extends ConsumerState<MaterialFormScreen> {
  final _titleCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController(); // dipakai untuk tipe link/note

  late MaterialFileType _type;
  late String _category;
  bool _saving = false;

  /// Path file lokal untuk tipe PDF/Gambar (hasil salinan ke penyimpanan app).
  /// Null bila belum memilih file.
  String? _filePath;

  bool get _isEdit => widget.material != null;
  bool get _isFileType =>
      _type == MaterialFileType.pdf || _type == MaterialFileType.image;

  @override
  void initState() {
    super.initState();
    final m = widget.material;
    _titleCtrl.text = m?.title ?? '';
    _sourceCtrl.text = m?.filePathOrUrl ?? '';
    _type = m?.fileType ?? MaterialFileType.note;
    _category = (m?.category.isNotEmpty ?? false) ? m!.category : 'Umum';
    // Saat edit materi PDF/Gambar, sumbernya adalah path file lokal.
    if (m != null && _isFileType) {
      _filePath = m.filePathOrUrl;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _sourceCtrl.dispose();
    super.dispose();
  }

  String get _sourceLabel {
    switch (_type) {
      case MaterialFileType.pdf:
        return 'File PDF';
      case MaterialFileType.image:
        return 'File Gambar';
      case MaterialFileType.link:
        return 'Tautan URL';
      case MaterialFileType.note:
        return 'Isi Catatan';
    }
  }

  String? get _sourceHint {
    switch (_type) {
      case MaterialFileType.link:
        return 'cth. https://situs.com';
      case MaterialFileType.note:
        return 'Tuliskan ringkasan / catatan materi di sini...';
      case MaterialFileType.pdf:
      case MaterialFileType.image:
        return null; // field pakai placeholder sendiri
    }
  }

  IconData get _sourceIcon {
    switch (_type) {
      case MaterialFileType.pdf:
        return Icons.picture_as_pdf_outlined;
      case MaterialFileType.image:
        return Icons.image_outlined;
      case MaterialFileType.link:
        return Icons.link_outlined;
      case MaterialFileType.note:
        return Icons.notes_rounded;
    }
  }

  /// Pilih file (PDF/Gambar) lalu salin ke folder `materials/` di penyimpanan
  /// app agar persisten (file hasil pick dari cache bisa dibersihkan OS).
  Future<void> _pickFile() async {
    FilePickerResult? result;
    if (_type == MaterialFileType.image) {
      result = await FilePicker.pickFiles(type: FileType.image);
    } else {
      result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
    }
    if (result == null || result.files.isEmpty) return;
    final pf = result.files.single;
    final pickedPath = pf.path;
    if (pickedPath == null) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final materialsDirPath = '${dir.path}/materials';
      final materialsDir = Directory(materialsDirPath);
      if (!await materialsDir.exists()) {
        await materialsDir.create(recursive: true);
      }
      var destName = _sanitizeName(pf.name);
      if (destName.isEmpty) destName = 'materi${_extOf(pf.name)}';
      var destPath = '$materialsDirPath/$destName';
      // Hindari menimpa file materi lain.
      if (await File(destPath).exists()) {
        destName =
            '${_baseNoExt(destName)}_${DateTime.now().millisecondsSinceEpoch}${_extOf(destName)}';
        destPath = '$materialsDirPath/$destName';
      }
      await File(pickedPath).copy(destPath);
      setState(() => _filePath = destPath);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan file. Coba lagi.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _sanitizeName(String name) =>
      name.replaceAll(RegExp(r'[^\w.-]'), '_');

  String _extOf(String name) {
    final i = name.lastIndexOf('.');
    return i >= 0 ? name.substring(i) : '';
  }

  String _baseNoExt(String name) {
    final i = name.lastIndexOf('.');
    return i >= 0 ? name.substring(0, i) : name;
  }

  Future<void> _save() async {
    final source = _isFileType ? (_filePath ?? '').trim() : _sourceCtrl.text.trim();
    final error = validateMaterialForm(
      title: _titleCtrl.text,
      source: source,
      type: _type,
    );
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _saving = true);
    final notifier = ref.read(materialListProvider.notifier);
    final title = _titleCtrl.text.trim();

    if (_isEdit) {
      await notifier.update(widget.material!.copyWith(
        title: title,
        filePathOrUrl: source,
        fileType: _type,
        category: _category,
      ));
    } else {
      await notifier.add(StudyMaterial(
        id: '',
        title: title,
        filePathOrUrl: source,
        fileType: _type,
        category: _category,
        createdAt: DateTime.now(),
      ));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(_isEdit ? 'Materi diperbarui.' : 'Materi "$title" ditambahkan.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNote = _type == MaterialFileType.note;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Kembali',
        ),
        title: Text(_isEdit ? 'Edit Materi' : 'Materi Baru'),
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
                    _isEdit ? 'Edit Materi' : 'Materi Baru',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Simpan PDF, gambar, tautan, atau catatan materi belajarmu.',
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
                labelText: 'Judul Materi',
                hintText: 'cth. Modul Fisika Bab 3',
                prefixIcon: Icon(Icons.folder_outlined),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Kategori + Tipe
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _CategoryDropdown(
                    value: _category,
                    onChanged: (v) => setState(() => _category = v ?? 'Umum'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _TypeDropdown(
                    value: _type,
                    onChanged: (v) => setState(() => _type = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Sumber: PDF/Gambar = upload file; Tautan/Catatan = input teks.
            if (_isFileType)
              _FilePickerField(
                label: _sourceLabel,
                icon: _sourceIcon,
                hint: _type == MaterialFileType.image
                    ? 'Pilih gambar (PNG/JPG)'
                    : 'Pilih file PDF',
                hasValue: _filePath != null && _filePath!.isNotEmpty,
                valueText: (_filePath != null && _filePath!.isNotEmpty)
                    ? _filePath!.split('/').last
                    : null,
                onTap: _pickFile,
              )
            else
              TextFormField(
                controller: _sourceCtrl,
                maxLines: isNote ? 4 : 1,
                keyboardType:
                    isNote ? TextInputType.multiline : TextInputType.url,
                textCapitalization: isNote
                    ? TextCapitalization.sentences
                    : TextCapitalization.none,
                decoration: InputDecoration(
                  labelText: _sourceLabel,
                  hintText: _sourceHint,
                  prefixIcon: Icon(_sourceIcon),
                  alignLabelWithHint: isNote,
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
              label: Text(_isEdit ? 'Simpan Perubahan' : 'Simpan Materi'),
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

/// Field pemilih file (mirip _PickerField tanggal/waktu). Menampilkan nama
/// file terpilih atau placeholder; ikon centang hijau saat sudah ada file.
class _FilePickerField extends StatelessWidget {
  const _FilePickerField({
    required this.label,
    required this.icon,
    required this.hint,
    required this.hasValue,
    required this.valueText,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String hint;
  final bool hasValue;
  final String? valueText;
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
          suffixIcon: hasValue
              ? const Icon(Icons.check_circle_rounded, color: AppColors.success)
              : Icon(Icons.upload_file_rounded,
                  color: AppColors.textSecondary),
        ),
        child: Text(
          valueText ?? hint,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: hasValue ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({required this.value, required this.onChanged});
  final String value;
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
      items: defaultMaterialCategories
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _TypeDropdown extends StatelessWidget {
  const _TypeDropdown({required this.value, required this.onChanged});
  final MaterialFileType value;
  final ValueChanged<MaterialFileType> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<MaterialFileType>(
      initialValue: value,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Tipe',
        prefixIcon: Icon(Icons.category_outlined),
      ),
      items: MaterialFileType.values
          .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
