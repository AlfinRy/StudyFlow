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

  /// Login via Google (hanya mode Firebase). Mengembalikan `null` bila user
  /// membatalkan pemilihan akun.
  Future<AppUser?> signInWithGoogle();

  /// Perbarui profil (nama/role/foto). Mode Firebase menulis ke Firestore
  /// `users/{uid}` + cache lokal; mode demo hanya cache lokal.
  Future<void> updateProfile({String? name, UserRole? role, String? photoUrl});

  Future<void> signOut();
}
