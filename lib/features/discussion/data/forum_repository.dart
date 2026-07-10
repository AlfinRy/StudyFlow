import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/forum_reply.dart';
import '../domain/forum_topic.dart';

/// Akses data forum via Firestore (real-time). Forum bersifat cloud-only
/// (PRD §5.6 & §6 offline-support): butuh internet; kegagalan ditangani UI
/// sebagai state loading/error. Tidak di-cache di Hive.
class ForumRepository {
  ForumRepository([FirebaseFirestore? firestore])
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _topics =>
      _db.collection('forum_topics');

  /// Stream seluruh topik, terbaru di atas (real-time listener).
  Stream<List<ForumTopic>> watchTopics() {
    return _topics
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ForumTopic.fromMap(d.id, d.data())).toList());
  }

  /// Stream balasan sebuah topik, terlama di atas (urutan kronologis).
  Stream<List<ForumReply>> watchReplies(String topicId) {
    return _topics
        .doc(topicId)
        .collection('replies')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ForumReply.fromMap(d.id, d.data())).toList());
  }

  /// Buat topik baru. `createdAt` pakai serverTimestamp; `replyCount` = 0.
  Future<void> createTopic({
    required String title,
    required String content,
    required String authorId,
    required String authorName,
    String? authorPhoto,
  }) async {
    final topic = ForumTopic(
      id: '',
      title: title.trim(),
      content: content.trim(),
      authorId: authorId,
      authorName: authorName,
      authorPhoto: authorPhoto,
      createdAt: DateTime.now(),
    );
    await _topics.doc().set(topic.toCreateMap());
  }

  /// Tambah balasan + tambah `replyCount` topik (batch atomik).
  Future<void> addReply({
    required String topicId,
    required String content,
    required String authorId,
    required String authorName,
    String? authorPhoto,
  }) async {
    final reply = ForumReply(
      id: '',
      topicId: topicId,
      content: content.trim(),
      authorId: authorId,
      authorName: authorName,
      authorPhoto: authorPhoto,
      createdAt: DateTime.now(),
    );
    final batch = _db.batch();
    final replyRef = _topics.doc(topicId).collection('replies').doc();
    batch.set(replyRef, reply.toCreateMap());
    // Denormalisasi jumlah balasan (dipakai di card daftar topik).
    batch.set(
      _topics.doc(topicId),
      {'replyCount': FieldValue.increment(1)},
      SetOptions(merge: true),
    );
    await batch.commit();
  }
}
