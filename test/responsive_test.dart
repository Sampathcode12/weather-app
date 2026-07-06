import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/main.dart';

void main() {
  final sizes = [
    Size(360, 800), // phone portrait
    Size(800, 360), // phone landscape
    Size(1024, 1366), // tablet portrait
    Size(1366, 1024), // tablet landscape
  ];

  for (final s in sizes) {
    testWidgets('WeatherHomePage builds at ${s.width.toInt()}x${s.height.toInt()}',
        (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = s;
      tester.binding.window.devicePixelRatioTestValue = 1.0;

      await tester.pumpWidget(const MaterialApp(home: WeatherHomePage()));
      await tester.pumpAndSettle();

      // Basic sanity checks: main header and bottom navigation exist
      expect(find.text('Current Location'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);

      // cleanup test window overrides
      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });
    });
  }
}
