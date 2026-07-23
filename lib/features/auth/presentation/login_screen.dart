import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/security/auth_validators.dart';
import '../../../core/security/rate_limiter.dart';
import '../../../shared_widgets/app_logo.dart';
import '../auth_providers.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import 'widgets/auth_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.isDemoMode = false});

  final bool isDemoMode;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _googleLoading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    // ⚠️ Anti brute-force: batasi percobaan login di level app sebelum
    // memanggil Firebase. Firebase juga punya proteksi `too-many-requests`
    // bawaan, tapi ini memberi feedback cepat ke user.
    final limiter = ref.read(rateLimiterProvider);
    final result = limiter.tryConsume(RateLimitedAction.login);
    if (!result.allowed) {
      final secs = result.retryAfter.inSeconds;
      _showError(secs > 60
          ? 'Terlalu banyak percobaan. Coba lagi dalam ${secs ~/ 60} menit.'
          : 'Terlalu banyak percobaan. Coba lagi dalam $secs detik.');
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(authRepositoryProvider).login(
            email: _email.text,
            password: _password.text,
          );
      // Login berhasil → reset slot rate-limit.
      limiter.reset(RateLimitedAction.login);
      // authStateProvider memancarkan user → root berganti ke MainShell
      // (atau VerifyEmailScreen bila belum verifikasi).
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    final clean = msg.replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(clean)));
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _googleLoading = true);
    try {
      // Null = user batal pilih akun ATAU Google Play Services tidak ada
      // (umum di emulator). Beri pesan singkat agar tidak terkesan "diam".
      final result =
          await ref.read(authRepositoryProvider).signInWithGoogle();
      if (result == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Login Google dibatalkan atau gagal. Jika di emulator, '
              'pastikan memakai system image "Google Play"/"Google APIs".',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      }
      // authStateProvider memancarkan user → root berganti ke MainShell.
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _googleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.lg),
                const _Header(),
                if (widget.isDemoMode) ...[
                  const SizedBox(height: AppSpacing.md),
                  const _DemoBanner(),
                ],
                const SizedBox(height: AppSpacing.xl),
                AuthTextField(
                  controller: _email,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: validateEmail,
                ),
                const SizedBox(height: AppSpacing.md),
                AuthTextField(
                  controller: _password,
                  label: 'Kata Sandi',
                  icon: Icons.lock_outline,
                  obscure: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Kata sandi wajib diisi.'
                      : null,
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _loading
                        ? null
                        : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ForgotPasswordScreen()),
                            ),
                    child: const Text('Lupa password?'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Masuk →'),
                ),
                const SizedBox(height: AppSpacing.lg),
                const _OrDivider(),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: (_loading || _googleLoading || widget.isDemoMode)
                      ? null
                      : _signInWithGoogle,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                  icon: _googleLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        )
                      : const Icon(Icons.g_mobiledata),
                  label: Text(
                    _googleLoading
                        ? 'Memproses...'
                        : (widget.isDemoMode
                            ? 'Google (butuh Firebase)'
                            : 'Lanjutkan dengan Google'),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Belum punya akun? '),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen()),
                      ),
                      child: const Text(
                        'Daftar',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLogo(),
              SizedBox(width: AppSpacing.sm),
              Text(
                'StudyFlow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Selamat Datang',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Silakan masuk ke akun Anda',
            style: TextStyle(color: Colors.white70, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.warning, size: 18),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Mode demo aktif — Firebase belum dikonfigurasi. Data tersimpan '
              'lokal di perangkat ini.',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text('atau',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ),
        Expanded(child: Divider()),
      ],
    );
  }
}
