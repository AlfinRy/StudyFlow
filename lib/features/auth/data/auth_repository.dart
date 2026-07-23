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

  /// Kirim email verifikasi ke pengguna saat ini (mode Firebase). Mode demo
  /// no-op. Melempar Exception bila belum login.
  Future<void> sendEmailVerification();

  /// Muat ulang data user Firebase (agar status verifikasi email terbaru
  /// tercermin) lalu pancarkan update. Melempar Exception bila belum login.
  Future<AppUser?> reloadCurrentUser();

  /// Kirim email reset password ke [email] (mode Firebase). Mode demo no-op.
  Future<void> sendPasswordResetEmail(String email);

  Future<void> signOut();
}
