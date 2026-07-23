import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/security/rate_limiter.dart';
import '../../../shared_widgets/app_logo.dart';
import '../auth_providers.dart';

/// Gate keamanan: user sudah login tapi email belum diverifikasi.
///
/// Mencegah penyalahgunaan pendaftaran memakai email milik orang lain —
/// tanpa akses ke kotak masuk, user tidak bisa melewati layar ini.
/// Memeriksa status verifikasi secara berkala + saat app kembali ke foreground.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _checking = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Cek status verifikasi setiap 10 detik (reload user di Firebase).
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Saat user kembali dari app email → langsung cek.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh({bool silent = false}) async {
    if (_checking) return;
    if (!silent) setState(() => _checking = true);
    try {
      await ref.read(authRepositoryProvider).reloadCurrentUser();
      // canAccessAppProvider reaktif → app.dart otomatis pindah ke MainShell
      // begitu isEmailVerified menjadi true.
    } catch (_) {
      // Offline — diabaikan, akan dicoba lagi periode berikutnya.
    } finally {
      if (mounted && !silent) setState(() => _checking = false);
    }
  }

  Future<void> _resend() async {
    final limiter = ref.read(rateLimiterProvider);
    final result = limiter.tryConsume(RateLimitedAction.sendVerification);
    if (!result.allowed) {
      final secs = result.retryAfter.inSeconds;
      final msg = secs > 60
          ? 'Terlalu banyak permintaan. Coba lagi dalam ${secs ~/ 60} menit.'
          : 'Terlalu banyak permintaan. Coba lagi dalam $secs detik.';
      _toast(msg, error: true);
      return;
    }
    setState(() => _sending = true);
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification();
      _toast('Email verifikasi telah dikirim ulang.');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text(
            'Anda harus memverifikasi email untuk mengakses StudyFlow. '
            'Yakin keluar sekarang?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    ref.read(rateLimiterProvider).reset(RateLimitedAction.sendVerification);
    await ref.read(authRepositoryProvider).signOut();
  }

  void _toast(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.danger : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(currentUserProvider)?.email ?? '';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),
              const _Header(),
              const SizedBox(height: AppSpacing.xl),
              Text(
                email.isEmpty
                    ? 'Periksa email Anda untuk menyelesaikan pendaftaran.'
                    : 'Kami telah mengirim tautan verifikasi ke:',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 16,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              const _StepsCard(),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: _checking ? null : () => _refresh(),
                icon: _checking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.refresh),
                label: const Text('Saya sudah verifikasi'),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: _sending ? null : _resend,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.mark_email_read_outlined),
                label: const Text('Kirim ulang email verifikasi'),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextButton(
                onPressed: _signOut,
                style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                child: const Text('Keluar dari akun'),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.navyGradient,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        children: const [
          AppLogo(size: 56),
          SizedBox(height: AppSpacing.md),
          Icon(Icons.mark_email_unread_outlined, color: Colors.white, size: 40),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Verifikasi Email',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Demikan keamanan akun Anda, konfirmasi email terlebih dahulu '
              'sebelum mengakses StudyFlow.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepsCard extends StatelessWidget {
  const _StepsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Langkah berikutnya',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          SizedBox(height: AppSpacing.md),
          _StepItem(
            n: '1',
            text: 'Buka aplikasi email Anda (cek folder Spam juga).',
          ),
          _StepItem(n: '2', text: 'Tekan tautan "Verifikasi Email" dari kami.'),
          _StepItem(
              n: '3', text: 'Kembali ke sini lalu tekan "Saya sudah verifikasi".'),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  const _StepItem({required this.n, required this.text});
  final String n;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
            ),
            child: Text(n,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
