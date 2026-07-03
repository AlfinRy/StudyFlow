// Smoke test for the Phase 1 app shell.
//
// Note: the real app initialises Hive in main(). These Phase 1 screens are
// pure placeholders that don't touch storage yet, so we can pump the shell
// directly without bootstrapping Hive.

import 'package:flutter_test/flutter_test.dart';

import 'package:study_flow/app.dart';

void main() {
  testWidgets('App shows bottom navigation with 5 tabs', (tester) async {
    await tester.pumpWidget(const StudyFlowApp());

    expect(find.text('Beranda'), findsWidgets);
    expect(find.text('Jadwal'), findsWidgets);
    expect(find.text('Tugas'), findsWidgets);
    expect(find.text('Progres'), findsWidgets);
    expect(find.text('Profil'), findsWidgets);
  });

  testWidgets('Home screen shows greeting hero card', (tester) async {
    await tester.pumpWidget(const StudyFlowApp());
    expect(find.text('Halo, Andi Pratama!'), findsOneWidget);
  });
}
