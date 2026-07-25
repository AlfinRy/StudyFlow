import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/study_group_repository.dart';
import 'domain/study_group.dart';

final studyGroupRepositoryProvider = Provider<StudyGroupRepository>((ref) {
  return StudyGroupRepository();
});

/// Stream seluruh grup belajar (terbaru di atas).
final studyGroupsProvider =
    StreamProvider.autoDispose<List<StudyGroup>>((ref) {
  return ref.watch(studyGroupRepositoryProvider).watchGroups();
});

/// Status keanggotaan user pada sebuah grup (true = tergabung).
final groupMembershipProvider =
    StreamProvider.autoDispose.family<bool, ({String gid, String uid})>(
        (ref, key) {
  return ref
      .watch(studyGroupRepositoryProvider)
      .watchMembership(key.gid, key.uid);
});

/// Stream pesan sebuah grup (terlama di atas).
final groupMessagesProvider =
    StreamProvider.autoDispose.family<List<GroupMessage>, String>((ref, gid) {
  return ref.watch(studyGroupRepositoryProvider).watchMessages(gid);
});
