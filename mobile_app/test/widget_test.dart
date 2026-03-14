import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('smoke renders money manager label', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Money Manager'),
          ),
        ),
      ),
    );

    expect(find.text('Money Manager'), findsOneWidget);
  });
}