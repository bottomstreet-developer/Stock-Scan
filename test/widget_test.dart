import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Renders simple scaffold smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('StockSnap'),
        ),
      ),
    );

    expect(find.text('StockSnap'), findsOneWidget);
  });
}
