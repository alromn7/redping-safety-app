import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:redping_14v/main.dart';
import 'package:redping_14v/core/routing/app_router.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Magic link sign-in routes to main for non-SAR users', (WidgetTester tester) async {
    // Start the app
    await tester.pumpWidget(const RedPingApp());
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Navigate to email-link sign-in page with a dummy universal link
    AppRouter.router.go('/auth/email-link', extra: {
      'link': 'https://redping.app/auth?oobCode=TEST_OOB',
    });
    await tester.pumpAndSettle();

    // Enter email
    final emailField = find.byType(TextFormField);
    expect(emailField, findsOneWidget);
    await tester.enterText(emailField, 'test@example.com');

    // Tap Sign In
    final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
    expect(signInButton, findsOneWidget);
    await tester.tap(signInButton);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Assert we navigated to /main
    final currentLocation = AppRouter.router.routeInformationProvider.value.location;
    expect(currentLocation, '/main');
  });
}
