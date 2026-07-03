import '../domain/app_user.dart';
import '../domain/user_role.dart';

/// Abstraksi autentikasi. Punya dua implementasi:
/// - [LocalAuthRepository]  → mode demo (Hive), tanpa Firebase.
/// - [FirebaseAuthRepository] → Firebase Auth (produksi).
abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();

  AppUser? get currentUser;

  bool get isDemoMode;

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  });

  Future<AppUser> login({
    required String email,
    required String password,
  });

  Future<void> signOut();
}
