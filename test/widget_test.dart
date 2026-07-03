// Root gate tests (Phase 3). Uses provider overrides so no Hive/Firebase is
// required. Screens' deeper flows are exercised manually on a device.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:study_flow/app.dart';
import 'package:study_flow/features/auth/auth_providers.dart';
import 'package:study_flow/features/auth/data/auth_repository.dart';
import 'package:study_flow/features/auth/domain/app_user.dart';
import 'package:study_flow/features/auth/domain/user_role.dart';

class _FakeAuthRepo implements AuthRepository {
  _FakeAuthRepo(this._user);
  final AppUser? _user;

  @override
  Stream<AppUser?> authStateChanges() => Stream.value(_user);
  @override
  AppUser? get currentUser => _user;
  @override
  bool get isDemoMode => false;
  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async =>
      throw UnimplementedError();
  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async =>
      throw UnimplementedError();
  @override
  Future<void> signOut() async {}
}

// Override build() tanpa menyentuh Hive.
class _OnboardingTrue extends OnboardingNotifier {
  @override
  bool build() => true;
}

class _OnboardingFalse extends OnboardingNotifier {
  @override
  bool build() => false;
}

const _fakeUser =
    AppUser(uid: 'u1', name: 'Andi', email: 'a@b.com', role: UserRole.mahasiswa);

Future<void> _pump(WidgetTester tester, List<Override> overrides) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: const StudyFlowApp(),
    ),
  );
  // Biarkan StreamProvider memancarkan & frame rebuild (tanpa pumpAndSettle
  // karena SplashScreen punya spinner tak-terbatas saat loading).
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  testWidgets('onboarding tampil saat first run', (tester) async {
    await _pump(tester, [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepo(null)),
      onboardingCompleteProvider.overrideWith(() => _OnboardingFalse()),
    ]);
    expect(find.text('Atur Jadwal Belajar'), findsOneWidget);
  });

  testWidgets('login tampil saat onboarding selesai & belum login',
      (tester) async {
    await _pump(tester, [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepo(null)),
      onboardingCompleteProvider.overrideWith(() => _OnboardingTrue()),
    ]);
    expect(find.text('Selamat Datang'), findsOneWidget);
  });

  testWidgets('main shell tampil saat sudah login', (tester) async {
    await _pump(tester, [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepo(_fakeUser)),
      onboardingCompleteProvider.overrideWith(() => _OnboardingTrue()),
    ]);
    expect(find.text('Beranda'), findsWidgets);
    expect(find.textContaining('Halo'), findsOneWidget);
  });
}
