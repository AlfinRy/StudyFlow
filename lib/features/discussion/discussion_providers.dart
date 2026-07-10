import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/forum_repository.dart';
import 'domain/forum_reply.dart';
import 'domain/forum_topic.dart';

final forumRepositoryProvider = Provider<ForumRepository>((ref) {
  return ForumRepository();
});

/// Stream real-time seluruh topik (terbaru di atas). `autoDispose` menutup
/// listener saat user meninggalkan halaman forum.
final forumTopicsProvider =
    StreamProvider.autoDispose<List<ForumTopic>>((ref) {
  return ref.watch(forumRepositoryProvider).watchTopics();
});

/// Stream real-time balasan sebuah topik (terlama di atas).
final forumRepliesProvider =
    StreamProvider.autoDispose.family<List<ForumReply>, String>((ref, topicId) {
  return ref.watch(forumRepositoryProvider).watchReplies(topicId);
});
