import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:redping_14v/main.dart' as app;

/// End-to-end tests for critical SOS flow functionality
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('SOS Flow E2E Tests', () {
    testWidgets('SOS button activation and countdown', (
      WidgetTester tester,
    ) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Wait for app to initialize
      await tester.pump(const Duration(seconds: 2));

      // Find the SOS button
      final sosButton = find.byKey(const Key('sos_button'));
      expect(sosButton, findsOneWidget);

      // Tap the SOS button to start countdown
      await tester.tap(sosButton);
      await tester.pump();

      // Verify countdown is active
      expect(find.text('SOS ACTIVATED'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Wait for countdown to complete (if not cancelled)
      await tester.pump(const Duration(seconds: 6));

      // Verify SOS is active
      expect(find.text('SOS ACTIVE'), findsOneWidget);
    });

    testWidgets('SOS cancellation during countdown', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      // Start SOS countdown
      final sosButton = find.byKey(const Key('sos_button'));
      await tester.tap(sosButton);
      await tester.pump();

      // Cancel SOS before activation
      final cancelButton = find.text('Cancel');
      expect(cancelButton, findsOneWidget);

      await tester.tap(cancelButton);
      await tester.pump();

      // Verify SOS is cancelled
      expect(find.text('SOS ACTIVATED'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('Emergency contacts notification', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      // Activate SOS
      final sosButton = find.byKey(const Key('sos_button'));
      await tester.tap(sosButton);
      await tester.pump();

      // Wait for countdown
      await tester.pump(const Duration(seconds: 6));

      // Verify emergency contacts are notified
      expect(find.text('Emergency contacts notified'), findsOneWidget);
    });

    testWidgets('Location sharing during SOS', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      // Activate SOS
      final sosButton = find.byKey(const Key('sos_button'));
      await tester.tap(sosButton);
      await tester.pump();

      await tester.pump(const Duration(seconds: 6));

      // Verify location sharing is active
      expect(find.text('Location shared'), findsOneWidget);
    });

    testWidgets('Voice verification during SOS', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      // Activate SOS
      final sosButton = find.byKey(const Key('sos_button'));
      await tester.tap(sosButton);
      await tester.pump();

      await tester.pump(const Duration(seconds: 6));

      // Verify voice verification prompt
      expect(find.text('Are you OK?'), findsOneWidget);
      expect(find.text('I\'m OK'), findsOneWidget);
    });
  });
}

