import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_theme.dart';
import 'features/auth/auth_providers.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/onboarding_screen.dart';
import 'features/auth/presentation/splash_screen.dart';
import 'features/shell/presentation/main_shell.dart';

class StudyFlowApp extends ConsumerWidget {
  const StudyFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingDone = ref.watch(onboardingCompleteProvider);
    final authAsync = ref.watch(authStateProvider);
    final isDemo = ref.watch(isDemoModeProvider);

    Widget home;
    if (!onboardingDone) {
      home = const OnboardingScreen();
    } else if (authAsync.isLoading) {
      home = const SplashScreen();
    } else if (authAsync.valueOrNull == null) {
      home = LoginScreen(isDemoMode: isDemo);
    } else {
      home = const MainShell();
    }

    return MaterialApp(
      title: 'StudyFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: home,
    );
  }
}
