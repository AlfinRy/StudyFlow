// Reproduksi bug "Daftar Sekarang tidak terjadi apa-apa" (Kasus 3).
// Memompa RegisterScreen langsung dengan repo palsu yang melempar error,
// mengisi form valid, lalu men-tap tombol. Bila tombol menyala, dialog error
// (berisi pesan repo) HARUS muncul. Ini membuktikan wiring tombol benar.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:study_flow/core/services/hive_service.dart';
import 'package:study_flow/features/auth/auth_providers.dart';
import 'package:study_flow/features/auth/data/auth_repository.dart';
import 'package:study_flow/features/auth/domain/app_user.dart';
import 'package:study_flow/features/auth/domain/user_role.dart';
import 'package:study_flow/features/auth/presentation/register_screen.dart';
import 'package:study_flow/features/auth/presentation/widgets/auth_text_field.dart';

class _ThrowingAuthRepo implements AuthRepository {
  @override
  Stream<AppUser?> authStateChanges() => const Stream.empty();
  @override
  AppUser? get currentUser => null;
  @override
  bool get isDemoMode => false;
  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async =>
      throw Exception('TEST_REGISTER_FAIL');
  @override
  Future<AppUser> login({required String email, required String password}) async =>
      throw UnimplementedError();
  @override
  Future<AppUser?> signInWithGoogle() async => throw UnimplementedError();
  @override
  Future<void> updateProfile(
      {String? name, UserRole? role, String? photoUrl}) async {}
  @override
  Future<void> sendEmailVerification() async {}
  @override
  Future<AppUser?> reloadCurrentUser() async => null;
  @override
  Future<void> sendPasswordResetEmail(String email) async {}
  @override
  Future<void> signOut() async {}
}

void main() {
  setUpAll(() async {
    final dir =
        await Directory.systemTemp.createTemp('studyflow_register_button_test');
    Hive.init(dir.absolute.path);
    await HiveService.instance.initialize();
  });

  testWidgets('tombol "Daftar Sekarang" memicu feedback (dialog error)',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_ThrowingAuthRepo()),
        ],
        child: const MaterialApp(home: RegisterScreen()),
      ),
    );
    await tester.pump();

    // Isi form valid: nama, email, role, sandi, konfirmasi.
    await tester.enterText(find.byType(AuthTextField).at(0), 'Budi');
    await tester.enterText(find.byType(AuthTextField).at(1), 'budi@example.com');
    await tester.tap(find.byIcon(Icons.school_outlined)); // role: siswa
    await tester.pump();
    await tester.enterText(find.byType(AuthTextField).at(2), 'rahasia123');
    await tester.enterText(find.byType(AuthTextField).at(3), 'rahasia123');
    // Centang "Saya menyetujui" — pastikan terlihat dulu (di dalam scroll).
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();

    // Pastikan tombol terlihat lalu tap.
    await tester.ensureVisible(find.text('Daftar Sekarang'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daftar Sekarang'));
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Bila tombol menyala → register() dipanggil → melempar → dialog error
    // berisi "TEST_REGISTER_FAIL" muncul. Ini bukti tombol berfungsi.
    expect(find.text('TEST_REGISTER_FAIL'), findsOneWidget,
        reason: 'Tombol Daftar harus memicu register() yang melempar error '
            'ini; bila tidak muncul, tombol tidak menyala (bug wiring).');
  });
}
