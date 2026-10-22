import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test - verifies Flutter environment is operational', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Classy-One Mobile'),
          ),
        ),
      ),
    );

    expect(find.text('Classy-One Mobile'), findsOneWidget);
  });
}