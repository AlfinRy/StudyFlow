import 'package:cloud_firestore/cloud_firestore.dart';

/// Balasan pada sebuah topik forum (PRD §5.6). Disimpan di subkoleksi
/// `forum_topics/{topicId}/replies`. Urutan kronologis (terlama di atas).
class ForumReply {
  const ForumReply({
    required this.id,
    required this.topicId,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorPhoto,
    required this.createdAt,
  });

  final String id;
  final String topicId;
  final String content;
  final String authorId;
  final String authorName;
  final String? authorPhoto;
  final DateTime createdAt;

  factory ForumReply.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['createdAt'];
    return ForumReply(
      id: id,
      topicId: (map['topicId'] as String?) ?? '',
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

  /// Map untuk membuat dokumen balasan baru.
  Map<String, Object?> toCreateMap() => {
        'topicId': topicId,
        'content': content,
        'authorId': authorId,
        'authorName': authorName,
        if (authorPhoto != null) 'authorPhoto': authorPhoto,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
