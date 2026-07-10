import 'package:cloud_firestore/cloud_firestore.dart';

/// Topik diskusi forum (PRD §5.6). Disimpan di koleksi Firestore
/// `forum_topics`. `replyCount` didenormalisasi agar daftar topik tidak perlu
/// memuat seluruh balasan. Berbeda dari model Hive, ini murni cloud
/// (real-time) — lihat `ForumRepository`.
class ForumTopic {
  const ForumTopic({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorPhoto,
    required this.createdAt,
    this.replyCount = 0,
  });

  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final String? authorPhoto;
  final DateTime createdAt;
  final int replyCount;

  /// Cuplikan isi untuk daftar (1–2 baris).
  String get snippet {
    final clean = content.trim().replaceAll(RegExp(r'\s+'), ' ');
    return clean.length > 120 ? '${clean.substring(0, 120)}…' : clean;
  }

  factory ForumTopic.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['createdAt'];
    return ForumTopic(
      id: id,
      title: (map['title'] as String?) ?? '',
      content: (map['content'] as String?) ?? '',
      authorId: (map['authorId'] as String?) ?? '',
      authorName: (map['authorName'] is String &&
              (map['authorName'] as String).isNotEmpty)
          ? map['authorName'] as String
          : 'Anonim',
      authorPhoto: map['authorPhoto'] as String?,
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      replyCount: (map['replyCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// Map untuk membuat dokumen baru (id & serverTimestamp diisi Firestore).
  Map<String, Object?> toCreateMap() => {
        'title': title,
        'content': content,
        'authorId': authorId,
        'authorName': authorName,
        if (authorPhoto != null) 'authorPhoto': authorPhoto,
        'replyCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
