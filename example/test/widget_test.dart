import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('Example app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ExampleApp());

    // Verify that the home page appears with buttons
    expect(find.text('Choose Device Mode'), findsOneWidget);
    expect(find.text('Receiver (Tablet/POS)'), findsOneWidget);
    expect(find.text('Scanner (Phone)'), findsOneWidget);
  });
}