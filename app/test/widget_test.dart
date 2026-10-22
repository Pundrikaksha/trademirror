import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trademirror/main.dart';

void main() {
  testWidgets('App smoke test finds Import screen title and bottom nav labels',
      (WidgetTester tester) async {
    await tester.pumpWidget(const TradeMirrorApp());
    await tester.pumpAndSettle();

    // Verify Import screen title in AppBar
    expect(find.widgetWithText(AppBar, 'Import CSV'), findsOneWidget);

    // Verify bottom navigation destination labels
    expect(find.text('Import CSV'), findsWidgets);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Habits'), findsOneWidget);
    expect(find.text('Coach'), findsOneWidget);
  });
}
