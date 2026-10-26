import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trademirror/app/router.dart';
import 'package:trademirror/app/store.dart';
import 'package:trademirror/core/mirror.dart';
import 'package:trademirror/core/tradebook.dart';
import 'package:trademirror/features/tips/tips_screen.dart';
import 'package:trademirror/main.dart';

void main() {
  final sample = File('assets/sample/$sampleAssetPathFile').readAsStringSync();

  setUp(() {
    mirrorStore.clear();
    appRouter.go('/import');
  });

  testWidgets('shell shows Import screen and four tabs', (tester) async {
    await tester.pumpWidget(const TradeMirrorApp());
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Import CSV'), findsOneWidget);
    expect(find.text('Load sample (synthetic) tradebook'), findsOneWidget);
    expect(find.text('Pick CSV file'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Habits'), findsOneWidget);
    expect(find.text('Tips'), findsOneWidget);
    expect(find.text('Coach'), findsNothing);
  });

  testWidgets('dashboard empty state, then totals after import', (
    tester,
  ) async {
    await tester.pumpWidget(const TradeMirrorApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing imported yet'), findsOneWidget);

    mirrorStore.importText(sample, name: 'sample.csv', sample: true);
    await tester.pumpAndSettle();
    expect(find.textContaining('SYNTHETIC DATA'), findsOneWidget);
    expect(find.text('-₹16,401.50'), findsOneWidget);
    expect(find.text('₹2,664.85'), findsWidgets);
    expect(find.text('-₹19,066.35'), findsOneWidget);
    expect(find.text('Where the charges went'), findsOneWidget);
  });

  testWidgets('habits screen shows counts and disclaimer', (tester) async {
    mirrorStore.importText(sample, name: 'sample.csv', sample: true);
    await tester.pumpWidget(const TradeMirrorApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Habits'));
    await tester.pumpAndSettle();
    expect(find.text('Revenge trades'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Educational only'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('Educational only'), findsOneWidget);
  });

  testWidgets('bad file shows an error card', (tester) async {
    await tester.pumpWidget(const TradeMirrorApp());
    await tester.pumpAndSettle();
    mirrorStore.importText('a,b\n1,2\n', name: 'bad.csv');
    await tester.pumpAndSettle();
    expect(find.text("Couldn't import this file"), findsOneWidget);
    expect(find.textContaining('Missing column'), findsOneWidget);
  });

  test('tips never tell the user to buy or sell', () {
    final tips = buildTips(analyse(parseKotakNeoTradebook(sample)));
    expect(tips.length, 5);
    for (final t in tips) {
      final text = '${t.title} ${t.body}'.toLowerCase();
      expect(text, isNot(matches(RegExp(r'\b(buy|sell)\b'))));
    }
  });
}
