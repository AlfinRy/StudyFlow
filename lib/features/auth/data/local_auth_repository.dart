import 'dart:async';

import 'package:hive/hive.dart';

import '../domain/app_user.dart';
import '../domain/user_role.dart';
import 'auth_repository.dart';

/// Autentikasi mode demo yang disimpan di Hive. Dipakai otomatis ketika
/// Firebase belum dikonfigurasi.
///
/// ⚠️ TIDAK AMAN: password disimpan plain-text. Hanya untuk development
/// sebelum `flutterfire configure`. Data tersimpan lokal per perangkat.
class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._box);

  final Box<dynamic> _box;

  static const _kUsers = 'local_auth_users'; // Map<email, Map>
  static const _kSession = 'local_auth_session'; // email?

  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();

  Map<String, Map<String, dynamic>> get _users =>
      (_box.get(_kUsers) as Map?)?.map((k, v) =>
          MapEntry(k as String, Map<String, dynamic>.from(v as Map))) ??
      <String, Map<String, dynamic>>{};

  Future<void> _putUsers(Map<String, Map<String, dynamic>> users) =>
      _box.put(_kUsers, users);

  AppUser? _fromSession() {
    final email = _box.get(_kSession) as String?;
    if (email == null) return null;
    final data = _users[email];
    if (data == null) return null;
    return AppUser(
      uid: data['uid'] as String,
      name: data['name'] as String,
      email: email,
      role: UserRole.fromString(data['role'] as String?),
      photoUrl: data['photoUrl'] as String?,
      // Mode demo tidak punya sistem email → selalu dianggap terverifikasi.
      isEmailVerified: true,
    );
  }

  void _emit() => _controller.add(_fromSession());

  @override
  bool get isDemoMode => true;

  @override
  AppUser? get currentUser => _fromSession();

  @override
  Stream<AppUser?> authStateChanges() {
    // Seed state saat ini setelah listener berlangganan.
    scheduleMicrotask(() => _controller.add(_fromSession()));
    return _controller.stream;
  }

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final e = email.trim();
    final users = _users;
    if (users.containsKey(e)) {
      throw Exception('Email sudah terdaftar.');
    }
    users[e] = {
      'uid': 'local_${DateTime.now().microsecondsSinceEpoch}',
      'name': name.trim(),
      'password': password, // demo only — not secure
      'role': role.name,
    };
    await _putUsers(users);
    await _box.put(_kSession, e);
    _emit();
    return _fromSession()!;
  }

  @override
  Future<AppUser> login({
    required String email,
    required String password,
  }) async {
    final e = email.trim();
    final data = _users[e];
    if (data == null) {
      throw Exception('Email belum terdaftar.');
    }
    if (data['password'] != password) {
      throw Exception('Kata sandi salah.');
    }
    await _box.put(_kSession, e);
    _emit();
    return _fromSession()!;
  }

  @override
  Future<void> signOut() async {
    await _box.delete(_kSession);
    _emit();
  }

  // --- Metode verifikasi email & reset password: no-op di mode demo ---
  // Mode demo tidak punya server email, jadi semuanya dianggap aman/terverifikasi.

  @override
  Future<void> sendEmailVerification() async {
    // Tidak ada yang dilakukan — semua user demo otomatis terverifikasi.
  }

  @override
  Future<AppUser?> reloadCurrentUser() async {
    _emit();
    return _fromSession();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    // Mode demo: reset tidak didukung (data lokal). User bisa hapus & daftar ulang.
    throw Exception('Reset kata sandi tidak tersedia di mode demo.');
  }

  @override
  Future<void> updateProfile({String? name, UserRole? role, String? photoUrl}) async {
    final email = _box.get(_kSession) as String?;
    if (email == null) throw Exception('Belum login.');
    final users = _users;
    final data = users[email];
    if (data == null) throw Exception('Data user tidak ditemukan.');
    if (name != null && name.trim().isNotEmpty) data['name'] = name.trim();
    if (role != null) data['role'] = role.name;
    if (photoUrl != null) data['photoUrl'] = photoUrl.trim();
    users[email] = data;
    await _putUsers(users);
    _emit();
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    throw Exception('Login Google tidak tersedia di mode demo.');
  }
}
