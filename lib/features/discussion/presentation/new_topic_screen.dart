import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared_widgets/navy_hero_card.dart';
import '../../auth/auth_providers.dart';
import '../discussion_providers.dart';
import 'forum_topic_validation.dart';

/// Form buat topik diskusi baru (PRD §5.6). Judul + isi → Firestore.
class NewTopicScreen extends ConsumerStatefulWidget {
  const NewTopicScreen({super.key});

  @override
  ConsumerState<NewTopicScreen> createState() => _NewTopicScreenState();
}

class _NewTopicScreenState extends ConsumerState<NewTopicScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    final clean = msg.replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(clean), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _save() async {
    final titleErr = validateTopicTitle(_titleCtrl.text);
    if (titleErr != null) {
      _showError(titleErr);
      return;
    }
    final contentErr = validateTopicContent(_contentCtrl.text);
    if (contentErr != null) {
      _showError(contentErr);
      return;
    }
    final user = ref.read(currentUserProvider);
    if (user == null) {
      _showError('Belum login.');
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(forumRepositoryProvider).createTopic(
            title: _titleCtrl.text,
            content: _contentCtrl.text,
            authorId: user.uid,
            authorName: user.name,
            authorPhoto: user.photoUrl,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Topik dibuat.'),
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Kembali',
        ),
        title: const Text('Topik Baru'),
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
                    'Mulai Diskusi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tulis judul & pertanyaan kamu. Topik terlihat semua user.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            TextFormField(
              controller: _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              maxLength: 120,
              decoration: const InputDecoration(
                labelText: 'Judul Topik',
                hintText: 'cth. Cara efektif belajar kalkulus?',
                prefixIcon: Icon(Icons.title_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              controller: _contentCtrl,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 8,
              minLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Isi Topik',
                hintText: 'Tulis pertanyaan atau materi diskusimu...',
                alignLabelWithHint: true,
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
                  : const Icon(Icons.send_rounded),
              label: const Text('Buat Topik'),
            ),
          ],
        ),
      ),
    );
  }
}
