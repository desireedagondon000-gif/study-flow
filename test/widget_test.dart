import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_flow/pages/landing_page.dart';

void main() {
  testWidgets('App loads and shows LandingPage', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaterialApp(home: LandingPage()));

    // Verify that the LandingPage is rendered
    // (We look for the "Welcome to Flow" text we added earlier)
    expect(find.text('Welcome to Flow'), findsOneWidget);
  });
}
