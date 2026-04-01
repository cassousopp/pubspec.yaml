// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap
// and scroll gestures. You can also use WidgetTester to find child
// widgets in the widget tree, read text, and verify that the
// values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:nexus_app/main.dart';

void main() {
  testWidgets('NEXUS app launches correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NexusApp());

    // Verify that the splash screen or login shows up
    expect(find.byType(NexusApp), findsOneWidget);
    expect(find.text('NEXUS'), findsWidgets); // Le logo ou le texte apparaît
  });
}