import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared_widgets/empty_state.dart';
import '../../../shared_widgets/navy_hero_card.dart';
import '../../auth/auth_providers.dart';
import '../discussion_providers.dart';
import '../domain/forum_topic.dart';
import 'new_topic_screen.dart';
import 'topic_detail_screen.dart';
import 'widgets/topic_card.dart';

/// Halaman Forum Diskusi (PRD §5.6, UI_DESIGN.md §9.2). Cloud-only: daftar
/// topik real-time dari Firestore. Diakses via shortcut Beranda (bukan tab
/// bottom nav) — lihat UI_DESIGN.md §9.2.
class ForumScreen extends ConsumerWidget {
  const ForumScreen({super.key});

  Future<void> _openNewTopic(BuildContext context) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const NewTopicScreen()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDemo = ref.watch(isDemoModeProvider);
    final topicsAsync = ref.watch(forumTopicsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Kembali',
        ),
        title: const Text('Forum Diskusi'),
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
                    'Forum Diskusi',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Diskusi & tanya jawab seputar pelajaran bareng pengguna lain.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (!isDemo)
              FilledButton.icon(
                onPressed: () => _openNewTopic(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Topik Baru'),
              )
            else
              const SizedBox(
                height: 280,
                child: EmptyState(
                  icon: Icons.lock_outline_rounded,
                  title: 'Forum butuh akun',
                  subtitle: 'Login dengan akun Firebase untuk mengakses forum '
                      '(tidak tersedia di mode demo).',
                ),
              ),
            const SizedBox(height: AppSpacing.xl),
            if (!isDemo) _TopicList(topicsAsync: topicsAsync),
          ],
        ),
      ),
    );
  }
}

/// Daftar topik reaktif terhadap stream Firestore.
class _TopicList extends StatelessWidget {
  const _TopicList({required this.topicsAsync});
  final AsyncValue<List<ForumTopic>> topicsAsync;

  @override
  Widget build(BuildContext context) {
    return topicsAsync.when(
      loading: () => const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const SizedBox(
        height: 240,
        child: EmptyState(
          icon: Icons.cloud_off_rounded,
          title: 'Tidak dapat memuat topik',
          subtitle: 'Pastikan kamu terhubung ke internet, lalu tarik untuk '
              'menyegarkan.',
        ),
      ),
      data: (topics) {
        if (topics.isEmpty) {
          return const SizedBox(
            height: 240,
            child: EmptyState(
              icon: Icons.forum_outlined,
              title: 'Belum ada topik',
              subtitle: 'Jadilah yang pertama membuat topik diskusi.',
            ),
          );
        }
        return Column(
          children: [
            for (final t in topics)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: TopicCard(
                  topic: t,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TopicDetailScreen(topic: t),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
