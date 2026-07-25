import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_flow/features/study_groups/domain/study_group.dart';

/// Uji model grup belajar & pesan (FEATURE_ROADMAP #11).
void main() {
  group('StudyGroup', () {
    test('fromMap memetakan field & fallback aman', () {
      final ts = Timestamp.fromDate(DateTime(2026, 1, 5));
      final g = StudyGroup.fromMap('g1', {
        'name': 'Belajar UTBK',
        'description': 'Bareng latihan soal',
        'ownerUid': 'u1',
        'ownerName': 'Andi',
        'memberCount': 3,
        'createdAt': ts,
      });
      expect(g.id, 'g1');
      expect(g.name, 'Belajar UTBK');
      expect(g.description, 'Bareng latihan soal');
      expect(g.ownerUid, 'u1');
      expect(g.ownerName, 'Andi');
      expect(g.memberCount, 3);
      expect(g.createdAt, DateTime(2026, 1, 5));
    });

    test('ownerName kosong → "Anonim"', () {
      final g = StudyGroup.fromMap('g1', {
        'name': 'X',
        'ownerUid': 'u1',
        'ownerName': '',
        'memberCount': 1,
      });
      expect(g.ownerName, 'Anonim');
    });

    test('memberCount hilang → default 0', () {
      final g = StudyGroup.fromMap('g1', {'name': 'X', 'ownerUid': 'u'});
      expect(g.memberCount, 0);
    });

    test('toCreateMap berisi field wajib & memberCount=1', () {
      final g = StudyGroup(
        id: '',
        name: 'Grup',
        description: '',
        ownerUid: 'u1',
        ownerName: 'Andi',
        memberCount: 1,
        createdAt: DateTime(2026, 1, 5),
      );
      final map = g.toCreateMap();
      expect(map['name'], 'Grup');
      expect(map['ownerUid'], 'u1');
      expect(map['ownerName'], 'Andi');
      expect(map['memberCount'], 1);
      expect(map['createdAt'], isA<FieldValue>());
    });
  });

  group('GroupMessage', () {
    test('fromMap & toCreateMap konsisten', () {
      final ts = Timestamp.fromDate(DateTime(2026, 1, 5, 8, 0));
      final m = GroupMessage.fromMap('m1', {
        'groupId': 'g1',
        'content': 'Halo semua',
        'authorId': 'u1',
        'authorName': 'Andi',
        'createdAt': ts,
      });
      expect(m.groupId, 'g1');
      expect(m.content, 'Halo semua');
      expect(m.authorName, 'Andi');

      final map = m.toCreateMap();
      expect(map['content'], 'Halo semua');
      expect(map['authorId'], 'u1');
      expect(map['createdAt'], isA<FieldValue>());
    });
  });
}
