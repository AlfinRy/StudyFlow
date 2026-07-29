import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'hive_service.dart';

/// Hasil upaya penghapusan akun.
enum AccountDeletionOutcome {
  success,
  /// Data sudah dihapus, tapi akun Firebase Auth butuh sign-in terbaru untuk
  /// dihapus permanen → minta user masuk lagi lalu ulangi.
  needsReauthentication,
  notSignedIn,
  error,
}

class AccountDeletionResult {
  const AccountDeletionResult(this.outcome, this.message);

  final AccountDeletionOutcome outcome;
  final String message;

  bool get isSuccess => outcome == AccountDeletionOutcome.success;
}

/// Menghapus akun + **seluruh data pengguna** (Firestore, penyimpanan lokal
/// Hive, dan akun Firebase Auth). Memenuhi kebijakan Google Play "Account &
/// Data Deletion". Dipanggil dari menu Profil "Hapus Akun & Data".
///
/// Cascade (batch, ≤400 dokumen per batch):
/// 1. Profil `users/{uid}`.
/// 2. Entri leaderboard `progress/{uid}`.
/// 3. Topik forum milik user + balasan pada topik itu.
/// 4. Balasan user pada topik orang lain (collectionGroup).
/// 5. Pesan grup milik user (collectionGroup).
/// 6. Keanggotaan grup user (collectionGroup).
/// 7. Grup milik user (owner) + anggota & pesan grup itu.
/// Lalu: bersihkan Hive lokal → hapus akun Firebase Auth.
class AccountDeletionService {
  AccountDeletionService();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  Future<AccountDeletionResult> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      return const AccountDeletionResult(
          AccountDeletionOutcome.notSignedIn, 'Belum login.');
    }
    final uid = user.uid;

    // Akumulator batch (batas Firestore 500/batch; pakai 400 aman).
    final batches = <WriteBatch>[];
    var batch = _db.batch();
    var ops = 0;
    void deleteDoc(DocumentReference ref) {
      batch.delete(ref);
      ops++;
      if (ops >= 400) {
        batches.add(batch);
        batch = _db.batch();
        ops = 0;
      }
    }

    try {
      // 1 & 2. Profil + entri leaderboard.
      deleteDoc(_db.collection('users').doc(uid));
      deleteDoc(_db.collection('progress').doc(uid));

      // 3. Topik forum milik user + balasan pada topik tersebut (cascade).
      final myTopics = await _db
          .collection('forum_topics')
          .where('authorId', isEqualTo: uid)
          .get();
      for (final t in myTopics.docs) {
        deleteDoc(t.reference);
        final reps = await t.reference.collection('replies').get();
        for (final r in reps.docs) {
          deleteDoc(r.reference);
        }
      }

      // 4. Balasan user pada topik orang lain.
      final myReplies = await _db
          .collectionGroup('replies')
          .where('authorId', isEqualTo: uid)
          .get();
      for (final r in myReplies.docs) {
        deleteDoc(r.reference);
      }

      // 5. Pesan grup milik user.
      final myMessages = await _db
          .collectionGroup('messages')
          .where('authorId', isEqualTo: uid)
          .get();
      for (final m in myMessages.docs) {
        deleteDoc(m.reference);
      }

      // 6. Keanggotaan grup user.
      final myMemberships = await _db
          .collectionGroup('members')
          .where('uid', isEqualTo: uid)
          .get();
      for (final m in myMemberships.docs) {
        deleteDoc(m.reference);
      }

      // 7. Grup milik user (owner) + anggota & pesannya (cascade).
      final ownedGroups = await _db
          .collection('study_groups')
          .where('ownerUid', isEqualTo: uid)
          .get();
      for (final g in ownedGroups.docs) {
        deleteDoc(g.reference);
        final gMembers = await g.reference.collection('members').get();
        for (final m in gMembers.docs) {
          deleteDoc(m.reference);
        }
        final gMessages = await g.reference.collection('messages').get();
        for (final m in gMessages.docs) {
          deleteDoc(m.reference);
        }
      }

      if (ops > 0) batches.add(batch);
      for (final b in batches) {
        await b.commit();
      }

      // 8. Bersihkan seluruh data lokal (factory reset).
      await _clearLocalData();

      // 9. Hapus akun Firebase Auth. Dapat memerlukan sign-in terbaru.
      try {
        await user.delete();
        return const AccountDeletionResult(
          AccountDeletionOutcome.success,
          'Akun dan seluruh data berhasil dihapus.',
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          await _auth.signOut();
          return const AccountDeletionResult(
            AccountDeletionOutcome.needsReauthentication,
            'Data aplikasi sudah dihapus. Demi keamanan, masuk lagi lalu '
            'ketuk "Hapus Akun" sekali lagi untuk menghapus akun permanen.',
          );
        }
        rethrow;
      }
    } catch (e, st) {
      debugPrint('[AccountDeletion] error: $e\n$st');
      return const AccountDeletionResult(
        AccountDeletionOutcome.error,
        'Gagal menghapus akun. Periksa koneksi internet lalu coba lagi, '
        'atau hubungi pengembang.',
      );
    }
  }

  Future<void> _clearLocalData() async {
    try {
      final h = HiveService.instance;
      await h.tasks.clear();
      await h.schedules.clear();
      await h.materials.clear();
      await h.focusSessions.clear();
      await h.settings.clear();
    } catch (_) {
      // Diabaikan — data lokal sisa (jika ada) terhapus saat uninstall.
    }
  }
}
