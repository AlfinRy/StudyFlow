import 'package:flutter_test/flutter_test.dart';

import 'package:study_flow/features/streak/domain/streak_logic.dart';

/// Helper: tanggal date-only relatif dari [ref], maju (+) / mundur (-) hari.
DateTime _d(DateTime ref, int deltaDays) =>
    DateTime(ref.year, ref.month, ref.day + deltaDays);

void main() {
  // Anggap "sekarang" = siang hari agar logika hari-ini/kemarin jelas.
  final now = DateTime(2026, 3, 11, 14, 0); // Rab 11 Mar 2026

  group('streakFromActive', () {
    test('0 bila tidak ada aktivitas', () {
      expect(streakFromActive({}, now), 0);
    });

    test('berakhir hari ini: hitung termasuk hari ini', () {
      // aktif: kemarin(10), hari ini(11) → streak 2.
      final active = {_d(now, -1), _d(now, 0)};
      expect(streakFromActive(active, now), 2);
    });

    test('grace 1 hari: hari ini kosong tapi kemarin aktif → streak tetap', () {
      // aktif: 9, 10 (hari ini 11 kosong). cursor mundu ke kemarin(10) → streak 2.
      final active = {_d(now, -2), _d(now, -1)};
      expect(streakFromActive(active, now), 2);
    });

    test('putus bila hari ini & kemarin keduanya kosong', () {
      // aktif hanya 8 (2 hari lalu) → streak 0 (grace lewat).
      final active = {_d(now, -3)};
      expect(streakFromActive(active, now), 0);
    });
  });

  group('tryApplyFreeze', () {
    test('tidak apply bila tidak ada freeze tersedia', () {
      final d = tryApplyFreeze(
        completionDates: {_d(now, -2), _d(now, -1)}, // streak 2 aktif
        frozenDates: {},
        freezesAvailable: 0,
        now: now,
      );
      expect(d.apply, isFalse);
    });

    test('apply freeze untuk mengisi "kemarin" & memperpanjang streak', () {
      // Hari ini aktif, kemarin kosong, 2 hari lalu aktif.
      // Tanpa freeze: streak = 1 (hanya hari ini, terputus di kemarin).
      // Freeze kemarin → terhubung ke 2 hari lalu → streak 3.
      final d = tryApplyFreeze(
        completionDates: {_d(now, 0), _d(now, -2)},
        frozenDates: {},
        freezesAvailable: 1,
        now: now,
      );
      expect(d.apply, isTrue);
      expect(d.frozenDate, _d(now, -1)); // kemarin dibekukan
    });

    test('apply freeze saat hari ini juga kosong (restorasi total)', () {
      // Hari ini & kemarin kosong; 2 hari lalu aktif.
      // Tanpa freeze: streak 0. Freeze kemarin → cursor ke kemarin aktif → 2.
      final d = tryApplyFreeze(
        completionDates: {_d(now, -2)},
        frozenDates: {},
        freezesAvailable: 1,
        now: now,
      );
      expect(d.apply, isTrue);
      expect(d.frozenDate, _d(now, -1));
    });

    test('tidak apply bila kemarin sudah completion (idempoten)', () {
      final d = tryApplyFreeze(
        completionDates: {_d(now, 0), _d(now, -1)},
        frozenDates: {},
        freezesAvailable: 1,
        now: now,
      );
      expect(d.apply, isFalse);
    });

    test('tidak apply bila freeze tidak membantu (tidak ada rantai lama)', () {
      // Hanya hari ini aktif, sebelumnya kosong total. Freeze kemarin tak
      // menambah (kemarin & 2 hari lalu kosong) → streak tetap 1.
      final d = tryApplyFreeze(
        completionDates: {_d(now, 0)},
        frozenDates: {},
        freezesAvailable: 1,
        now: now,
      );
      expect(d.apply, isFalse);
    });

    test('tidak apply dobel: kemarin sudah dibekukan sebelumnya', () {
      final d = tryApplyFreeze(
        completionDates: {_d(now, 0), _d(now, -2)},
        frozenDates: {_d(now, -1)}, // sudah dibekukan
        freezesAvailable: 1,
        now: now,
      );
      expect(d.apply, isFalse);
    });
  });

  group('dailyRewardFor', () {
    test('0 bila tidak ada streak', () {
      expect(dailyRewardFor(0), 0);
    });

    test('bertambah dengan streak, dibatasi atas', () {
      expect(dailyRewardFor(1), 6); // 5 + 1
      expect(dailyRewardFor(7), 12); // 5 + 7
      expect(dailyRewardFor(30), 30); // clamp ke max
      expect(dailyRewardFor(100), 30); // tetap di max
    });
  });

  group('canClaimDaily', () {
    test('bisa klaim bila ada streak & belum pernah klaim', () {
      expect(canClaimDaily(null, 3, now), isTrue);
    });

    test('tidak bisa klaim bila streak 0', () {
      expect(canClaimDaily(null, 0, now), isFalse);
    });

    test('tidak bisa klaim dua kali di hari yang sama', () {
      // lastClaimDate = hari ini → sudah diklaim.
      expect(canClaimDaily(_d(now, 0), 3, now), isFalse);
    });

    test('bisa klaim lagi keesokan harinya', () {
      expect(canClaimDaily(_d(now, -1), 3, now), isTrue);
    });
  });

  group('earnsFreezeAt', () {
    test('dapat bonus freeze tiap kelipatan 7', () {
      expect(earnsFreezeAt(7, 0), isTrue);
      expect(earnsFreezeAt(14, 7), isTrue);
    });

    test('tidak dapat di streak bukan kelipatan 7', () {
      expect(earnsFreezeAt(6, 0), isFalse);
      expect(earnsFreezeAt(10, 0), isFalse);
    });

    test('anti dobel: milestone sama tidak diberi dua kali', () {
      expect(earnsFreezeAt(7, 7), isFalse);
    });

    test('0 streak tidak dapat', () {
      expect(earnsFreezeAt(0, 0), isFalse);
    });
  });
}
