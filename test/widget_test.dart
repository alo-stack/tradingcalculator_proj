// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('MVP shows calculator list and news sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const TradingCalculatorApp());

    expect(find.text('Forex Calculators'), findsOneWidget);
    expect(find.text('Calculator'), findsOneWidget);
    expect(find.text('News'), findsOneWidget);
    expect(find.text('Pip Calculator'), findsOneWidget);
    expect(find.text('Position Size Calculator'), findsOneWidget);

    await tester.tap(find.text('News'));
    await tester.pumpAndSettle();

    expect(find.text('Market News'), findsOneWidget);
    expect(find.text('Business & Trading News'), findsOneWidget);
  });
}
