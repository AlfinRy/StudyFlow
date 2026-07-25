import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/security/rate_limiter.dart';
import '../../../shared_widgets/app_avatar.dart';
import '../../auth/auth_providers.dart';
import '../../discussion/domain/forum_reply.dart';
import '../../discussion/presentation/widgets/reply_bubble.dart' show ReplyBubble;
import '../domain/study_group.dart';
import '../study_group_providers.dart';

/// Detail grup belajar (FEATURE_ROADMAP #11): info grup, status keanggotaan
/// (gabung/keluar), dan chat real-time (hanya untuk anggota). Anti-spam
/// memakai rate-limit `forumReply` yang sudah ada.
class GroupDetailScreen extends ConsumerStatefulWidget {
  const GroupDetailScreen({super.key, required this.group});

  final StudyGroup group;

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;
  bool _toggling = false;
  String? _lastSent;

  @override
  void dispose() {
    _msgCtrl.dispose();
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

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _toggleMembership(bool isMember) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _toggling = true);
    try {
      final repo = ref.read(studyGroupRepositoryProvider);
      if (isMember) {
        await repo.leaveGroup(widget.group.id, user.uid);
      } else {
        await repo.joinGroup(widget.group.id, user.uid);
      }
    } catch (_) {
      if (mounted) _snack('Gagal. Coba lagi.');
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _send(bool isMember) async {
    if (!isMember) {
      _snack('Bergabung dulu untuk mengirim pesan.');
      return;
    }
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) {
      _snack('Pesan tidak boleh kosong.');
      return;
    }
    if (text == _lastSent) {
      _snack('Pesan sama dengan sebelumnya. Tulis pesan berbeda ya 😊');
      return;
    }
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    // Anti-spam (reuse kebijakan forumReply: 5 / 30 detik).
    final result = ref
        .read(rateLimiterProvider)
        .tryConsume(RateLimitedAction.forumReply);
    if (!result.allowed) {
      final secs = result.retryAfter.inSeconds + 1;
      _snack('Pelan-pelan ya 😊 tunggu $secs detik sebelum kirim lagi.');
      return;
    }

    setState(() => _sending = true);
    try {
      await ref.read(studyGroupRepositoryProvider).addMessage(
            groupId: widget.group.id,
            content: text,
            authorId: user.uid,
            authorName: user.name,
            authorPhoto: user.photoUrl,
          );
      _lastSent = text;
      _msgCtrl.clear();
      _jumpToBottom();
    } catch (_) {
      if (mounted) _snack('Gagal mengirim pesan.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final uid = user?.uid ?? '';
    final g = widget.group;
    final isOwner = g.ownerUid == uid;

    final isMemberAsync =
        ref.watch(groupMembershipProvider((gid: g.id, uid: uid)));
    final isMember = isMemberAsync.valueOrNull ?? isOwner; // owner pasti anggota

    final messages =
        ref.watch(groupMessagesProvider(g.id)).valueOrNull ?? <GroupMessage>[];
    _jumpToBottom();

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Kembali',
        ),
        title: Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header grup
            Container(
              margin: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
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
                      AppAvatar(name: g.ownerName, radius: 16),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Dibuat oleh ${g.ownerName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: context.textSecondary, fontSize: 12.5),
                        ),
                      ),
                      Icon(Icons.people_outline_rounded,
                          size: 14, color: AppColors.accent),
                      const SizedBox(width: 3),
                      Text('${g.memberCount} anggota',
                          style: const TextStyle(
                              color: AppColors.accent, fontSize: 12.5)),
                    ],
                  ),
                  if (g.description.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(g.description,
                        style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 13.5,
                            height: 1.4)),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  // Tombol gabung/keluar (pembuat tidak bisa keluar).
                  if (!isOwner)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: _toggling
                            ? null
                            : () => _toggleMembership(isMember),
                        icon: _toggling
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2))
                            : Icon(isMember
                                ? Icons.logout_rounded
                                : Icons.group_add_rounded),
                        label: Text(isMember ? 'Keluar Grup' : 'Gabung Grup'),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Icon(Icons.star_rounded,
                            size: 16, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text('Anda pembuat grup ini',
                            style: TextStyle(
                                color: context.textSecondary, fontSize: 12.5)),
                      ],
                    ),
                ],
              ),
            ),

            // Daftar pesan
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          isMember
                              ? 'Belum ada pesan. Sapa grupmu! 👋'
                              : 'Bergabung untuk melihat & mengirim pesan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: context.textSecondary, fontSize: 13),
                        ),
                      ),
                    )
                  : ListView(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                          AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
                      children: [
                        for (final m in messages)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            // Konversi GroupMessage → ForumReply agar reuse
                            // ReplyBubble (struktur identik).
                            child: ReplyBubble(
                              reply: ForumReply(
                                id: m.id,
                                topicId: m.groupId,
                                content: m.content,
                                authorId: m.authorId,
                                authorName: m.authorName,
                                authorPhoto: m.authorPhoto,
                                createdAt: m.createdAt,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),

            // Input pesan (hanya anggota)
            if (isMember)
              Container(
                decoration: BoxDecoration(
                  color: context.surface,
                  border: Border(top: BorderSide(color: context.surfaceBorder)),
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
                          controller: _msgCtrl,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(isMember),
                          decoration: const InputDecoration(
                            hintText: 'Tulis pesan...',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.md, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton.filled(
                        onPressed: _sending ? null : () => _send(isMember),
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
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
