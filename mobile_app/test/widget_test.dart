import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cityscan_flutter/main.dart';

void main() {
  testWidgets('Dashboard smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CityScanApp());

    // Verify that the app title is present.
    expect(find.text('CityScan'), findsWidgets);
    expect(find.text('Global Vitality Index'), findsOneWidget);
  });
}
