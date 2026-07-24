import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared_widgets/app_avatar.dart';
import '../../../shared_widgets/empty_state.dart';
import '../../../shared_widgets/navy_hero_card.dart';
import '../domain/leaderboard_entry.dart';
import '../leaderboard_providers.dart';

/// Papan peringkat mingguan (PRD-fitur baru, retensi sosial). Membaca Top-50
/// berdasarkan XP pekan ini dari Firestore (real-time). Opt-in (privasi).
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = ref.watch(leaderboardAvailableProvider);
    final asyncTop = ref.watch(leaderboardTopProvider);

    return Scaffold(
      backgroundColor: context.background,
      appBar: AppBar(title: const Text('Papan Peringkat')),
      body: SafeArea(
        child: !available
            ? const _UnavailableState()
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 96),
                children: [
                  const _Hero(),
                  const SizedBox(height: AppSpacing.md),
                  const _ShareToggle(),
                  const SizedBox(height: AppSpacing.lg),
                  asyncTop.when(
                    data: (entries) => entries.isEmpty
                        ? const EmptyState(
                            icon: Icons.emoji_events_outlined,
                            title: 'Belum ada peringkat pekan ini',
                            subtitle:
                                'Selesaikan tugas & sesi fokus untuk naik '
                                'papan peringkat. Aktifkan bagikan di atas '
                                'agar Anda ikut dihitung.',
                          )
                        : _RankList(entries: entries),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(AppSpacing.xxl),
                      child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                    error: (e, _) => EmptyState(
                      icon: Icons.cloud_off_outlined,
                      title: 'Gagal memuat',
                      subtitle: e.toString().replaceFirst('Exception: ', ''),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return NavyHeroCard(
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD54F), size: 40),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Peringkat Mingguan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Bersaing sehat dengan pengguna lain. Reset tiap Senin.',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareToggle extends ConsumerWidget {
  const _ShareToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final share = ref.watch(shareOnLeaderboardProvider);
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: context.surfaceBorder),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: const Text('Bagikan progres saya',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(
          share
              ? 'Nama & XP mingguan Anda terlihat pengguna lain.'
              : 'Privasi aktif — progres Anda tidak ditampilkan.',
          style: TextStyle(fontSize: 12, color: context.textSecondary),
        ),
        value: share,
        onChanged: (v) =>
            ref.read(shareOnLeaderboardProvider.notifier).set(v),
      ),
    );
  }
}

class _RankList extends StatelessWidget {
  const _RankList({required this.entries});
  final List<LeaderboardEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          _RankTile(rank: i + 1, entry: entries[i]),
      ],
    );
  }
}

class _RankTile extends StatelessWidget {
  const _RankTile({required this.rank, required this.entry});
  final int rank;
  final LeaderboardEntry entry;

  Color _medalColor(BuildContext context) => switch (rank) {
        1 => const Color(0xFFFFD54F), // gold
        2 => const Color(0xFFB0BEC5), // silver
        3 => const Color(0xFFCD7F32), // bronze
        _ => context.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: entry.isMe
            ? AppColors.accent.withValues(alpha: 0.08)
            : context.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: entry.isMe ? AppColors.accent : context.surfaceBorder,
          width: entry.isMe ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: rank <= 3
                ? Icon(Icons.emoji_events_rounded, color: _medalColor(context), size: 24)
                : Text(
                    '$rank',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: context.textSecondary,
                    ),
                  ),
          ),
          const SizedBox(width: AppSpacing.md),
          AppAvatar(
            name: entry.name,
            photoUrl: entry.photoUrl,
            radius: 18,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.isMe ? '${entry.name} (Anda)' : entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: entry.isMe ? FontWeight.w700 : FontWeight.w600,
                    color: context.textPrimary,
                  ),
                ),
                Text(
                  '${entry.weeklyXp} XP minggu ini',
                  style: TextStyle(
                      fontSize: 12, color: context.textSecondary),
                ),
              ],
            ),
          ),
          if (entry.isMe)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(AppSpacing.pillRadius),
              ),
              child: const Text('Anda',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

class _UnavailableState extends StatelessWidget {
  const _UnavailableState();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.lock_outline,
      title: 'Papan peringkat belum tersedia',
      subtitle: 'Fitur ini butuh akun terverifikasi & koneksi internet. '
          'Masuk dengan email terverifikasi atau Google untuk mengaktifkan.',
    );
  }
}
