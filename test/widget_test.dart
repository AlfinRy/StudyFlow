// Root gate tests (Phase 3). Uses provider overrides so no Firebase is
// required. Hive diinisialisasi di temp dir karena MainShell kini membangun
// layar sungguhan yang membaca provider data lokal (Fase 4+).

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:study_flow/app.dart';
import 'package:study_flow/core/services/hive_service.dart';
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
  Future<AppUser?> signInWithGoogle() async => throw UnimplementedError();
  @override
  Future<void> updateProfile({String? name, UserRole? role, String? photoUrl}) async {}
  @override
  Future<void> sendEmailVerification() async {}
  @override
  Future<AppUser?> reloadCurrentUser() async => _user;
  @override
  Future<void> sendPasswordResetEmail(String email) async {}
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

const _fakeUser = AppUser(
  uid: 'u1',
  name: 'Andi',
  email: 'a@b.com',
  role: UserRole.mahasiswa,
  isEmailVerified: true,
);

const _fakeUserUnverified = AppUser(
  uid: 'u2',
  name: 'Budi',
  email: 'b@c.com',
  role: UserRole.mahasiswa,
  // isEmailVerified default false.
);

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
  setUpAll(() async {
    final dir = await Directory.systemTemp.createTemp('studyflow_widget_test');
    Hive.init(dir.absolute.path);
    await HiveService.instance.initialize();
  });

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

  testWidgets('verify email tampil saat login tapi belum verifikasi',
      (tester) async {
    // Gate keamanan: user belum verifikasi tidak boleh masuk MainShell.
    await _pump(tester, [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepo(_fakeUserUnverified)),
      onboardingCompleteProvider.overrideWith(() => _OnboardingTrue()),
    ]);
    expect(find.text('Verifikasi Email'), findsOneWidget);
    expect(find.text('Beranda'), findsNothing);
  });
}
