// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('MVP shows calculator list and news sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const QuickPipsApp());
    await tester.pumpAndSettle();

    expect(find.text('FOREX CALCULATORS'), findsOneWidget);
    expect(find.text('Calculators'), findsOneWidget);
    expect(find.text('Pip Calculator'), findsOneWidget);
    expect(find.text('Position Size Calculator'), findsOneWidget);

    // On compact widths the tools menu lives in a Drawer.
    if (find.text('News Calendar').evaluate().isEmpty) {
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('News Calendar'));
    await tester.pumpAndSettle();

    expect(find.text('Market News'), findsOneWidget);
    expect(find.text('CRYPTO'), findsWidgets);
    expect(find.text('FOREX'), findsWidgets);
    expect(find.text('FUTURES'), findsWidgets);
  });
}
