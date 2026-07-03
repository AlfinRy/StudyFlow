import 'user_role.dart';

/// Representasi pengguna yang sedang login (lintas Firebase & mode demo).
class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.role,
    this.photoUrl,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole? role;
  final String? photoUrl;

  AppUser copyWith({
    String? name,
    UserRole? role,
    String? photoUrl,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
