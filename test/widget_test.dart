// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'package:redping_14v/main.dart';
import 'package:redping_14v/core/routing/app_router.dart';
import 'package:redping_14v/core/test_overrides.dart';

void main() {
  testWidgets('RedPing app smoke test', (WidgetTester tester) async {
    // Ensure test binding is initialized for router/material app
    TestWidgetsFlutterBinding.ensureInitialized();
    // Enable test mode to use lightweight init and test-only overlay
    TestOverrides.enableTestMode();
    // Build our app and trigger a frame.
    await tester.pumpWidget(RedPingApp(routerConfig: AppRouter.router));
    // Pump a single frame to render the test overlay
    await tester.pump();

    // The splash texts should be present initially (at least once)
    expect(find.byKey(const ValueKey('testOverlayRedPing')), findsOneWidget);
    expect(find.byKey(const ValueKey('testOverlaySubtitle')), findsOneWidget);
  });
}
