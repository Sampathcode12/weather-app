// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:weather_app/main.dart';

void main() {
  testWidgets('Shows Google sign-in gate before weather content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const WeatherApp());

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Sign in with your Google account to continue'), findsOneWidget);
    expect(find.text('Current Location'), findsNothing);
  });
}
