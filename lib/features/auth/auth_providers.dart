import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../../core/services/firebase_service.dart';
import '../../../core/services/hive_service.dart';
import 'data/auth_repository.dart';
import 'data/firebase_auth_repository.dart';
import 'data/local_auth_repository.dart';
import 'domain/app_user.dart';

/// Memilih implementasi auth: Firebase bila sudah dikonfigurasi, jika tidak
/// gunakan mode demo lokal (Hive).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (FirebaseService.initialized) {
    return FirebaseAuthRepository();
  }
  return LocalAuthRepository(HiveService.instance.settings);
});

/// State autentikasi reaktif (null = belum login).
final authStateProvider = StreamProvider<AppUser?>(
    (ref) => ref.watch(authRepositoryProvider).authStateChanges());

final currentUserProvider =
    Provider<AppUser?>((ref) => ref.watch(authStateProvider).valueOrNull);

final isDemoModeProvider =
    Provider<bool>((ref) => ref.watch(authRepositoryProvider).isDemoMode);

/// Apakah onboarding sudah selesai (first-run gate).
final onboardingCompleteProvider =
    NotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);

class OnboardingNotifier extends Notifier<bool> {
  late final Box<dynamic> _box;

  @override
  bool build() {
    _box = HiveService.instance.settings;
    return (_box.get('onboarding_complete') as bool?) ?? false;
  }

  Future<void> complete() async {
    await _box.put('onboarding_complete', true);
    state = true;
  }

  /// Hanya untuk keperluan testing / reset.
  Future<void> reset() async {
    await _box.delete('onboarding_complete');
    state = false;
  }
}
