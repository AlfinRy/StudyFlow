import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/security/rate_limiter.dart';
import '../../../core/utils/date_labels.dart';
import '../../../shared_widgets/app_avatar.dart';
import '../../../shared_widgets/section_header.dart';
import '../../auth/auth_providers.dart';
import '../discussion_providers.dart';
import '../domain/forum_reply.dart';
import '../domain/forum_topic.dart';
import 'widgets/reply_bubble.dart';

/// Detail topik forum (PRD §5.6, UI_DESIGN.md §9.2): isi topik lengkap di atas,
/// daftar balasan di bawah (real-time), dan input balasan sticky di bawah.
class TopicDetailScreen extends ConsumerStatefulWidget {
  const TopicDetailScreen({super.key, required this.topic});

  final ForumTopic topic;

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
  final _replyCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  bool _deleting = false;
  String? _lastSent; // anti-duplikat konsekutif.

  @override
  void dispose() {
    _replyCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _jumpToBottom() {
    if (!_scrollCtrl.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String msg) {
    final clean = msg.replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(clean), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _send() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) {
      _showError('Balasan tidak boleh kosong.');
      return;
    }
    final user = ref.read(currentUserProvider);
    if (user == null) {
      _showError('Belum login.');
      return;
    }
    if (text == _lastSent) {
      _showError('Balasan sama dengan sebelumnya. Tulis pesan berbeda ya 😊');
      return;
    }

    // Anti-spam: batasi frekuensi balasan (5 / 30 detik).
    final result = ref
        .read(rateLimiterProvider)
        .tryConsume(RateLimitedAction.forumReply);
    if (!result.allowed) {
      final secs = result.retryAfter.inSeconds + 1;
      _showError('Pelan-pelan ya 😊 tunggu $secs detik sebelum balas lagi.');
      return;
    }

    setState(() => _sending = true);
    try {
      await ref.read(forumRepositoryProvider).addReply(
            topicId: widget.topic.id,
            content: text,
            authorId: user.uid,
            authorName: user.name,
            authorPhoto: user.photoUrl,
          );
      _lastSent = text;
      _replyCtrl.clear();
      _jumpToBottom();
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// Konfirmasi hapus topik (hanya pembuat). Minta persetujuan lalu cascade
  /// hapus topik + balasan via repository.
  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus topik ini?'),
        content: const Text(
          'Topik beserta semua balasannya akan dihapus permanen. '
          'Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(forumRepositoryProvider).deleteTopic(widget.topic.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        _showError('Gagal menghapus topik. Coba lagi.');
        setState(() => _deleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final replies =
        ref.watch(forumRepliesProvider(widget.topic.id)).valueOrNull ??
            <ForumReply>[];

    // Auto-scroll ke bawah saat ada balasan baru.
    _jumpToBottom();

    final topic = widget.topic;
    final isAuthor = ref.watch(currentUserProvider)?.uid == topic.authorId;
    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Kembali',
        ),
        title: Text(
          topic.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (isAuthor)
            IconButton(
              icon: _deleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.accent),
                    )
                  : const Icon(Icons.delete_outline_rounded),
              tooltip: 'Hapus topik',
              onPressed: _deleting ? null : _confirmDelete,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
                children: [
                  // Header topik
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: context.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                      border: Border.all(color: context.surfaceBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppAvatar(
                              name: topic.authorName,
                              photoUrl: topic.authorPhoto,
                              radius: 18,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    topic.authorName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: context.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    timeAgo(topic.createdAt),
                                    style: TextStyle(
                                        color: context.textSecondary,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          topic.title,
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          topic.content,
                          style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 14.5,
                              height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SectionHeader(title: 'Balasan (${replies.length})'),
                  const SizedBox(height: AppSpacing.sm),
                  if (replies.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: context.surface,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.cardRadius),
                        border: Border.all(color: context.surfaceBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 20, color: context.textSecondary),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Jadilah yang pertama membalas topik ini.',
                              style: TextStyle(
                                  color: context.textSecondary,
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final r in replies)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: ReplyBubble(reply: r),
                          ),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
            // Input balasan sticky di bawah
            Container(
              decoration: BoxDecoration(
                color: context.surface,
                border:
                    Border(top: BorderSide(color: context.surfaceBorder)),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: SafeArea(
                top: false,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: 'Tulis balasan...',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.md, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton.filled(
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
