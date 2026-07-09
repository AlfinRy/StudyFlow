import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';

import '../../../core/services/hive_service.dart';
import '../domain/app_user.dart';
import '../domain/user_role.dart';
import 'auth_repository.dart';

/// Autentikasi produksi via Firebase Auth.
///
/// `name` & `role` di-cache di Hive (keyed by uid) karena Firebase Auth tidak
/// menyimpan role kustom tanpa custom claims. Sinkronisasi ke Firestore
/// `users/{uid}` dilakukan di fase berikutnya (forum/profil).
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  Box<dynamic> get _box => HiveService.instance.settings;

  AppUser? _map(User? u) {
    if (u == null) return null;
    final cache = _profile(u.uid);
    return AppUser(
      uid: u.uid,
      name: (cache['name'] as String?) ?? (u.displayName ?? ''),
      email: u.email ?? '',
      role: UserRole.fromString(cache['role'] as String?),
      photoUrl: u.photoURL ?? (cache['photoUrl'] as String?),
    );
  }

  Map<String, dynamic> _profile(String uid) {
    final raw = _box.get('profile_$uid');
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  Future<void> _saveProfile(String uid,
      {String? name, UserRole? role}) async {
    final cur = _profile(uid);
    if (name != null) cur['name'] = name;
    if (role != null) cur['role'] = role.name;
    await _box.put('profile_$uid', cur);
  }

  @override
  bool get isDemoMode => false;

  @override
  AppUser? get currentUser => _map(_auth.currentUser);

  @override
  Stream<AppUser?> authStateChanges() => _auth.authStateChanges().map(_map);

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await cred.user?.updateDisplayName(name.trim());
      await _saveProfile(cred.user!.uid, name: name.trim(), role: role);
      final u = _map(cred.user);
      if (u == null) throw Exception('Pendaftaran gagal. Coba lagi.');
      return u;
    } on FirebaseAuthException catch (e) {
      throw Exception(authErrorMessage(e));
    }
  }

  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final u = _map(cred.user);
      if (u == null) throw Exception('Login gagal. Coba lagi.');
      return u;
    } on FirebaseAuthException catch (e) {
      throw Exception(authErrorMessage(e));
    }
  }

  /// Login via Google. Memerlukan provider Google di-enable di Firebase
  /// Console + SHA-1 fingerprint terdaftar. `name` & `role` di-cache di Hive
  /// (role default `mahasiswa` untuk user baru via Google).
  @override
  Future<AppUser?> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // user batal / tidak ada akun
      final googleAuth = await googleUser.authentication;
      final userCred = await _auth.signInWithCredential(
        GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        ),
      );
      final user = userCred.user;
      if (user == null) throw Exception('Login Google gagal. Coba lagi.');
      // User baru via Google belum punya role → default mahasiswa + nama Google.
      if (_profile(user.uid)['role'] == null) {
        await _saveProfile(
          user.uid,
          name: user.displayName ??
              user.email?.split('@').first ??
              'Pengguna Google',
          role: UserRole.mahasiswa,
        );
      }
      return _map(user) ??
          (throw Exception('Login Google gagal. Coba lagi.'));
    } on FirebaseAuthException catch (e) {
      throw Exception(authErrorMessage(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Login Google gagal. Coba lagi.');
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();
}

/// Memetakan kode error Firebase Auth ke pesan dalam Bahasa Indonesia.
String authErrorMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-email':
      return 'Format email tidak valid.';
    case 'user-disabled':
      return 'Akun ini dinonaktifkan.';
    case 'user-not-found':
    case 'wrong-password':
    case 'invalid-credential':
      return 'Email atau kata sandi salah.';
    case 'email-already-in-use':
      return 'Email sudah terdaftar.';
    case 'weak-password':
      return 'Kata sandi terlalu lemah (min. 6 karakter).';
    case 'network-request-failed':
      return 'Tidak ada koneksi internet.';
    case 'too-many-requests':
      return 'Terlalu banyak percobaan. Coba lagi nanti.';
    default:
      return (e.message != null && e.message!.isNotEmpty)
          ? e.message!
          : 'Terjadi kesalahan. Coba lagi.';
  }
}
