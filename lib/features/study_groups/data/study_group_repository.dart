import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/study_group.dart';

/// Akses data grup belajar via Firestore (real-time, cloud-only). Keanggotaan
/// memakai subkoleksi `members/{uid}`; `memberCount` grup di-increment saat
/// bergabung/keluar (batch atomik).
class StudyGroupRepository {
  StudyGroupRepository([FirebaseFirestore? firestore])
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _groups =>
      _db.collection('study_groups');

  /// Stream seluruh grup (terbaru di atas). Dapat dibaca semua user login
  /// (untuk penemuan/discovery).
  Stream<List<StudyGroup>> watchGroups() {
    return _groups
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => StudyGroup.fromMap(d.id, d.data())).toList());
  }

  /// Stream status keanggotaan `uid` pada `gid` (true bila tergabung).
  Stream<bool> watchMembership(String gid, String uid) {
    return _groups
        .doc(gid)
        .collection('members')
        .doc(uid)
        .snapshots()
        .map((s) => s.exists);
  }

  /// Stream pesan grup (terlama di atas, urutan kronologis).
  Stream<List<GroupMessage>> watchMessages(String gid) {
    return _groups
        .doc(gid)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => GroupMessage.fromMap(d.id, d.data())).toList());
  }

  /// Buat grup baru: dokumen grup + dokumen keanggotaan pembuat (batch).
  /// Mengembalikan id grup baru.
  Future<String> createGroup({
    required String name,
    required String description,
    required String ownerUid,
    required String ownerName,
  }) async {
    final group = StudyGroup(
      id: '',
      name: name.trim(),
      description: description.trim(),
      ownerUid: ownerUid,
      ownerName: ownerName,
      memberCount: 1,
      createdAt: DateTime.now(),
    );
    final batch = _db.batch();
    final groupRef = _groups.doc();
    batch.set(groupRef, group.toCreateMap());
    // Pembuat otomatis menjadi anggota.
    batch.set(groupRef.collection('members').doc(ownerUid), {
      'joinedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    return groupRef.id;
  }

  /// Bergabung: tambah dokumen keanggotaan + naikkan memberCount (batch).
  /// Aman dipanggil ulang (idempoten secara aturan — members/{uid} create).
  Future<void> joinGroup(String gid, String uid) async {
    final batch = _db.batch();
    batch.set(_groups.doc(gid).collection('members').doc(uid), {
      'joinedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _groups.doc(gid),
      {'memberCount': FieldValue.increment(1)},
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  /// Keluar: hapus dokumen keanggotaan + turunkan memberCount (batch).
  Future<void> leaveGroup(String gid, String uid) async {
    final batch = _db.batch();
    batch.delete(_groups.doc(gid).collection('members').doc(uid));
    batch.set(
      _groups.doc(gid),
      {'memberCount': FieldValue.increment(-1)},
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  /// Tambah pesan ke grup.
  Future<void> addMessage({
    required String groupId,
    required String content,
    required String authorId,
    required String authorName,
    String? authorPhoto,
  }) async {
    final msg = GroupMessage(
      id: '',
      groupId: groupId,
      content: content.trim(),
      authorId: authorId,
      authorName: authorName,
      authorPhoto: authorPhoto,
      createdAt: DateTime.now(),
    );
    await _groups.doc(groupId).collection('messages').doc().set(msg.toCreateMap());
  }
}
