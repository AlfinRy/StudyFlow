import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/settings/settings_providers.dart';
import '../auth_providers.dart';
import '../domain/study_goal.dart';

/// Onboarding first-run (UI_DESIGN.md §2). Dua halaman perkenalan fitur,
/// lalu langkah personalisasi: memilih tujuan belajar (FEATURE_ROADMAP #8).
/// Tujuan dipakai Beranda untuk sapaan & saran yang dipersonalisasi.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  StudyGoal? _goal; // pilihan tujuan belajar pada langkah personalisasi.

  static const _pages = <_OnboardingPage>[
    _OnboardingPage(
      icon: Icons.event_note_outlined,
      title: 'Atur Jadwal Belajar',
      desc:
          'Kelola jadwal, tugas, dan materi pembelajaran dalam satu tempat.',
    ),
    _OnboardingPage(
      icon: Icons.notifications_active_outlined,
      title: 'Tetap Fokus & Raih Tujuan',
      desc: 'Pengingat deadline otomatis dan progres belajar yang mudah '
          'dipantau.',
    ),
  ];

  /// Jumlah total halaman: perkenalan + langkah pilih tujuan.
  int get _pageCount => _pages.length + 1;
  bool get _isGoalPage => _page == _pages.length;

  void _finish() {
    // Simpan tujuan bila dipilih (boleh dilewati → tetap null / generik).
    final g = _goal;
    if (g != null) ref.read(studyGoalProvider.notifier).set(g);
    ref.read(onboardingCompleteProvider.notifier).complete();
  }

  void _next() {
    if (_page < _pageCount - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } else {
      _finish();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tombol "Mulai" pada langkah tujuan hanya aktif setelah memilih.
    final canProceed = !_isGoalPage || _goal != null;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.navyGradient),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Lewati',
                      style: TextStyle(color: Colors.white70)),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pageCount,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) {
                    if (i < _pages.length) return _buildIntro(_pages[i]);
                    return _buildGoalStep();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Row(
                  children: [
                    // Indikator titik
                    Row(
                      children: List.generate(_pageCount, (i) {
                        final active = i == _page;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 6),
                          width: active ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active ? AppColors.accent : Colors.white24,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: canProceed ? _next : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_isGoalPage ? 'Mulai →' : 'Lanjut →'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Halaman perkenalan fitur (ikon besar + judul + deskripsi).
  Widget _buildIntro(_OnboardingPage p) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: const BoxDecoration(
              color: Colors.white10,
              shape: BoxShape.circle,
            ),
            child: Icon(p.icon, size: 72, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            p.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            p.desc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Langkah personalisasi: pilih tujuan belajar.
  Widget _buildGoalStep() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const Text(
            'Apa tujuan belajarmu? 🎯',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Pilih yang paling sesuai — bisa diubah nanti di Profil.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            // Center saat singkat, scroll saat ruang sempit.
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final g in StudyGoal.values) _buildGoalCard(g),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Kartu pilihan tujuan belajar (selected state memakai aksen biru).
  Widget _buildGoalCard(StudyGoal g) {
    final selected = _goal == g;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: selected
            ? AppColors.accent.withValues(alpha: 0.28)
            : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: InkWell(
          onTap: () => setState(() => _goal = g),
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(
                color: selected ? AppColors.accent : Colors.white24,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Text(g.emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        g.description,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12.5, height: 1.3),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle_rounded,
                      color: Colors.white, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.desc,
  });
  final IconData icon;
  final String title;
  final String desc;
}
