import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive/hive.dart';

import '../../../core/services/hive_service.dart';
import '../domain/app_user.dart';
import '../domain/user_role.dart';
import 'auth_repository.dart';

/// Autentikasi produksi via Firebase Auth + profil tersinkron ke Firestore
/// `users/{uid}`. `name`, `role`, & `photoUrl` di-cache di Hive (offline-first)
/// agar UI tetap reaktif dan dapat dipakai tanpa internet. Setiap operasi
/// Firestore dibungkus try/catch — gagal diam-diam saat offline / aturan
/// keamanan, cache lokal tetap menjadi sumber kebenaran UI.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository() {
    // Teruskan perubahan status auth Firebase ke controller, agar [updateProfile]
    // juga bisa memancarkan update ke listener (UI reaktif setelah edit profil).
    _auth.authStateChanges().listen((u) => _emit(u));
  }

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  Box<dynamic> get _box => HiveService.instance.settings;

  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();

  void _emit([User? u]) => _controller.add(_map(u ?? _auth.currentUser));

  AppUser? _map(User? u) {
    if (u == null) return null;
    final cache = _profile(u.uid);
    final cachedName = cache['name'] as String?;
    return AppUser(
      uid: u.uid,
      name: (cachedName != null && cachedName.isNotEmpty)
          ? cachedName
          : (u.displayName ?? ''),
      email: u.email ?? '',
      role: UserRole.fromString(cache['role'] as String?),
      // Cache-first: pilihan user (termasuk hasil edit foto base64) selalu
      // diutamakan; baru fallback ke photoURL Firebase (cth. foto Google).
      photoUrl: (cache['photoUrl'] as String?) ?? u.photoURL,
      // Status verifikasi email langsung dari Firebase.
      isEmailVerified: u.emailVerified,
    );
  }

  Map<String, dynamic> _profile(String uid) {
    final raw = _box.get('profile_$uid');
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  Future<void> _saveProfile(
    String uid, {
    String? name,
    UserRole? role,
    String? photoUrl,
  }) async {
    final cur = _profile(uid);
    if (name != null) cur['name'] = name;
    if (role != null) cur['role'] = role.name;
    if (photoUrl != null) cur['photoUrl'] = photoUrl;
    await _box.put('profile_$uid', cur);
  }

  /// Tulis profil ke Firestore `users/{uid}` (merge). Best-effort: gagal
  /// diam-diam saat offline / aturan keaman belum di-set.
  Future<void> _writeFirestoreProfile(
    User user, {
    String? name,
    UserRole? role,
    String? photoUrl,
  }) async {
    try {
      final data = <String, Object?>{
        'uid': user.uid,
        'email': user.email ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (name != null) data['name'] = name;
      if (role != null) data['role'] = role.name;
      if (photoUrl != null) data['photoUrl'] = photoUrl;
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(data, SetOptions(merge: true));
    } catch (_) {
      // Offline / aturan keaman — diabaikan (offline-first).
    }
  }

  /// Tarik profil dari Firestore ke cache lokal (best-effort). Dipakai saat
  /// login agar profil tersinkron antar perangkat.
  Future<void> _syncFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final d = doc.data()!;
        await _saveProfile(
          uid,
          name: d['name'] as String?,
          role: UserRole.fromString(d['role'] as String?),
          photoUrl: d['photoUrl'] as String?,
        );
      }
    } catch (_) {
      // Offline — cache lokal tetap dipakai.
    }
  }

  @override
  bool get isDemoMode => false;

  @override
  AppUser? get currentUser => _map(_auth.currentUser);

  @override
  Stream<AppUser?> authStateChanges() {
    // Seed state saat ini setelah listener berlangganan.
    scheduleMicrotask(() => _emit());
    return _controller.stream;
  }

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
      final user = cred.user!;
      await user.updateDisplayName(name.trim());
      await _saveProfile(user.uid, name: name.trim(), role: role);
      await _writeFirestoreProfile(user, name: name.trim(), role: role);
      // ⚠️ KEAMANAN: kirim email verifikasi segera setelah daftar. Tanpa ini,
      // siapa pun bisa mendaftar memakai email milik orang lain. User belum
      // verifikasi tidak bisa mengakses app (gate di app.dart).
      await _sendVerificationEmail(user);
      final u = _map(user);
      if (u == null) throw Exception('Pendaftaran gagal. Coba lagi.');
      _emit(user);
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
      final user = cred.user!;
      await _syncFromFirestore(user.uid); // sinkron profil antar perangkat
      final u = _map(user);
      if (u == null) throw Exception('Login gagal. Coba lagi.');
      _emit(user);
      return u;
    } on FirebaseAuthException catch (e) {
      throw Exception(authErrorMessage(e));
    }
  }

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
      // Coba tarik profil yang sudah ada (sinkron antar perangkat).
      await _syncFromFirestore(user.uid);
      // User baru (belum ada role) → buat default.
      if (_profile(user.uid)['role'] == null) {
        final defaultName = user.displayName ??
            user.email?.split('@').first ??
            'Pengguna Google';
        await _saveProfile(
          user.uid,
          name: defaultName,
          role: UserRole.mahasiswa,
          photoUrl: user.photoURL,
        );
        await _writeFirestoreProfile(
          user,
          name: defaultName,
          role: UserRole.mahasiswa,
          photoUrl: user.photoURL,
        );
      }
      final u = _map(user);
      if (u == null) throw Exception('Login Google gagal. Coba lagi.');
      _emit(user);
      return u;
    } on FirebaseAuthException catch (e) {
      throw Exception(authErrorMessage(e));
    } on Exception {
      rethrow;
    } catch (_) {
      throw Exception('Login Google gagal. Coba lagi.');
    }
  }

  @override
  Future<void> updateProfile({
    String? name,
    UserRole? role,
    String? photoUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Belum login.');
    final uid = user.uid;
    final cleanName = name?.trim();
    final cleanPhoto = photoUrl?.trim();

    await _writeFirestoreProfile(
      user,
      name: (cleanName?.isNotEmpty ?? false) ? cleanName : null,
      role: role,
      photoUrl: cleanPhoto,
    );
    await _saveProfile(
      uid,
      name: (cleanName?.isNotEmpty ?? false) ? cleanName : null,
      role: role,
      photoUrl: cleanPhoto,
    );
    if (cleanName != null && cleanName.isNotEmpty) {
      try {
        await user.updateDisplayName(cleanName);
      } catch (_) {}
    }
    if (cleanPhoto != null &&
        cleanPhoto.isNotEmpty &&
        !cleanPhoto.startsWith('data:')) {
      try {
        await user.updatePhotoURL(cleanPhoto);
      } catch (_) {}
    }
    _emit(user); // pancarkan update ke seluruh UI
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    // Bersihkan akun Google yang di-cache agar picker muncul lagi saat login
    // berikutnya. Tanpa ini, google_sign_in diam-diam memakai akun terakhir.
    try {
      await GoogleSignIn().signOut();
    } catch (_) {
      // Diabaikan: tidak ada akun Google yang sedang aktif.
    }
  }

  /// Helper kirim email verifikasi. No-op bila sudah diverifikasi.
  Future<void> _sendVerificationEmail(User user) async {
    if (user.emailVerified) return;
    try {
      await user.sendEmailVerification();
    } catch (_) {
      // Offline / rate-limit bawaan Firebase — tetap lanjutkan, user bisa
      // meminta ulang dari layar verifikasi.
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Belum login.');
    await user.sendEmailVerification();
  }

  @override
  Future<AppUser?> reloadCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    await user.reload();
    // Ambil instance terbaru — status emailVerified baru terlihat di sini.
    final fresh = _auth.currentUser;
    _emit(fresh);
    return _map(fresh);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(authErrorMessage(e));
    }
  }
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
    case 'invalid-action-code':
      return 'Tautan tidak valid atau sudah kedaluwarsa.';
    case 'email-already-in-use':
      return 'Email sudah terdaftar.';
    case 'weak-password':
      return 'Kata sandi terlalu lemah (min. 6 karakter).';
    case 'network-request-failed':
      return 'Tidak ada koneksi internet.';
    case 'too-many-requests':
      return 'Terlalu banyak percobaan. Coba lagi nanti.';
    case 'operation-not-allowed':
      return 'Metode login belum diaktifkan di Firebase.';
    default:
      return (e.message != null && e.message!.isNotEmpty)
          ? e.message!
          : 'Terjadi kesalahan. Coba lagi.';
  }
}
