import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_colors.dart';
import 'core/constants/app_theme.dart';
import 'core/settings/settings_providers.dart';
import 'features/auth/auth_providers.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/onboarding_screen.dart';
import 'features/auth/presentation/splash_screen.dart';
import 'features/auth/presentation/verify_email_screen.dart';
import 'features/shell/presentation/main_shell.dart';

class StudyFlowApp extends ConsumerWidget {
  const StudyFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingDone = ref.watch(onboardingCompleteProvider);
    final authAsync = ref.watch(authStateProvider);
    final isDemo = ref.watch(isDemoModeProvider);
    final user = authAsync.valueOrNull;
    final canAccess = ref.watch(canAccessAppProvider);

    Widget home;
    if (!onboardingDone) {
      home = const OnboardingScreen();
    } else if (authAsync.isLoading) {
      home = const SplashScreen();
    } else if (user == null) {
      home = LoginScreen(isDemoMode: isDemo);
    } else if (!canAccess) {
      // Gate keamanan: user login tapi email belum terverifikasi → blokir
      // akses MainStream sampai memverifikasi email (anti penyalahgunaan email).
      home = const VerifyEmailScreen();
    } else {
      home = const MainShell();
    }

    return MaterialApp(
      title: 'StudyFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      // Zone kecerahan: perbarui token AppColors sebelum subtree dibangun
      // ulang, agar widget yang membaca getter ikut mode gelap/terang.
      builder: (context, child) {
        AppColors.brightness = Theme.of(context).brightness;
        return child!;
      },
      home: home,
    );
  }
}
