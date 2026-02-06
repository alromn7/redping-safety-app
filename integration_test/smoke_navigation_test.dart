import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:redping_14v/main_sos.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Smoke: Navigation', () {
    testWidgets('app boots and renders a MaterialApp', (tester) async {
      app.main();

      // Allow initial frames
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Verify MaterialApp exists
      expect(find.byType(MaterialApp), findsOneWidget);

      // Verify we have some widget tree on screen (e.g., Scaffold or MediaQuery)
      expect(find.byType(Scaffold), findsAny);
      expect(find.byType(MediaQuery), findsWidgets);
    });
  });
}
