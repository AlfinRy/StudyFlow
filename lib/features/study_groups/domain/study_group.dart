import 'package:cloud_firestore/cloud_firestore.dart';

/// Grup belajar (FEATURE_ROADMAP #11, Tier 4). Cloud-only di koleksi
/// `study_groups`. Keanggotaan disimpan di subkoleksi `members/{uid}`;
/// `memberCount` didenormalisasi agar daftar grup tak perlu memuat semua anggota.
class StudyGroup {
  const StudyGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerUid,
    required this.ownerName,
    required this.memberCount,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final String ownerUid;
  final String ownerName;
  final int memberCount;
  final DateTime createdAt;

  factory StudyGroup.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['createdAt'];
    return StudyGroup(
      id: id,
      name: (map['name'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      ownerUid: (map['ownerUid'] as String?) ?? '',
      ownerName: (map['ownerName'] is String &&
              (map['ownerName'] as String).isNotEmpty)
          ? map['ownerName'] as String
          : 'Anonim',
      memberCount: (map['memberCount'] as num?)?.toInt() ?? 0,
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }

  /// Map untuk membuat grup baru (memberCount = 1 = pembuat).
  Map<String, Object?> toCreateMap() => {
        'name': name,
        'description': description,
        'ownerUid': ownerUid,
        'ownerName': ownerName,
        'memberCount': 1,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

/// Pesan dalam grup belajar (subkoleksi `study_groups/{gid}/messages`).
class GroupMessage {
  const GroupMessage({
    required this.id,
    required this.groupId,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorPhoto,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String content;
  final String authorId;
  final String authorName;
  final String? authorPhoto;
  final DateTime createdAt;

  factory GroupMessage.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['createdAt'];
    return GroupMessage(
      id: id,
      groupId: (map['groupId'] as String?) ?? '',
      content: (map['content'] as String?) ?? '',
      authorId: (map['authorId'] as String?) ?? '',
      authorName: (map['authorName'] is String &&
              (map['authorName'] as String).isNotEmpty)
          ? map['authorName'] as String
          : 'Anonim',
      authorPhoto: map['authorPhoto'] as String?,
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }

  Map<String, Object?> toCreateMap() => {
        'groupId': groupId,
        'content': content,
        'authorId': authorId,
        'authorName': authorName,
        if (authorPhoto != null) 'authorPhoto': authorPhoto,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
