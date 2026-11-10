import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:incident_report/auth_screens.dart';

void main() {
  testWidgets('Login screen displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));

    expect(find.text('Incident Report'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text("Don't have an account? Register"), findsOneWidget);
  });
}
