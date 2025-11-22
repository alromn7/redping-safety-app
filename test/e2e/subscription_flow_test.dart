import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:redping_14v/main.dart' as app;
import 'package:redping_14v/core/routing/app_router.dart';
import 'package:redping_14v/features/subscription/presentation/widgets/subscription_plan_card.dart';
import 'package:redping_14v/security/secure_storage_service.dart';
import 'package:redping_14v/core/test_overrides.dart';

/// End-to-end tests for subscription and family management flows
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Subscription Flow E2E Tests', () {
    testWidgets('Subscription tier selection', (WidgetTester tester) async {
      // Initialize plugin mocks for widget/integration test environment
      final userJson = jsonEncode({
        'id': 'test_user',
        'email': 'test@example.com',
        'displayName': 'Test User',
        'isEmailVerified': true,
      });
      SharedPreferences.setMockInitialValues({
        'auth_user': userJson,
        'auth_token': 'test_token',
        'onboarding_completed': true,
        'has_seen_ai_permission': true,
      });
      SecureStorageService.instance.enableInMemoryMock();
      TestOverrides.enableTestMode();

      app.main();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      // Navigate to Subscription Plans via router (stable entry)
      AppRouter.router.go(AppRouter.subscriptionPlans);
      await tester.pumpAndSettle();

      // Verify we're on the plans page
      expect(find.text('REDP!NG Subscription Plans'), findsOneWidget);

      // Select Essential+ tier by finding its card and tapping SUBSCRIBE NOW
      final essentialTitle = find.text('ESSENTIAL+');
      expect(essentialTitle, findsOneWidget);

      final essentialCard = find.ancestor(
        of: essentialTitle,
        matching: find.byType(SubscriptionPlanCard),
      );
      final subscribeNow = find.descendant(
        of: essentialCard,
        matching: find.text('SUBSCRIBE NOW'),
      );

      await tester.tap(subscribeNow);
      await tester.pumpAndSettle();

      // Verify we navigated to Payment page
      expect(find.text('Payment'), findsOneWidget);
    });

    testWidgets('Family package subscription', (WidgetTester tester) async {
      // Initialize plugin mocks for widget/integration test environment
      final userJson = jsonEncode({
        'id': 'test_user',
        'email': 'test@example.com',
        'displayName': 'Test User',
        'isEmailVerified': true,
      });
      SharedPreferences.setMockInitialValues({
        'auth_user': userJson,
        'auth_token': 'test_token',
        'onboarding_completed': true,
        'has_seen_ai_permission': true,
      });
      SecureStorageService.instance.enableInMemoryMock();
      TestOverrides.enableTestMode();

      app.main();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));

      // Navigate to Subscription Plans via router (stable entry)
      AppRouter.router.go(AppRouter.subscriptionPlans);
      await tester.pumpAndSettle();

      // Switch to Family Package tab
      await tester.tap(find.text('Family Package'));
      await tester.pumpAndSettle();

      // Tap Start Family Plan
      final startFamilyPlan = find.text('START FAMILY PLAN');
      expect(startFamilyPlan, findsOneWidget);
      await tester.tap(startFamilyPlan);
      await tester.pumpAndSettle();

      // Verify we navigated to Payment page
      expect(find.text('Payment'), findsOneWidget);
    });

    // NOTE: The following flows require an active Family subscription
    // and are covered in dedicated tests once backend state is prepared.
    testWidgets(
      'Add family member',
      (WidgetTester tester) async {},
      skip: true,
    );

    testWidgets(
      'Family location sharing',
      (WidgetTester tester) async {},
      skip: true,
    );

    testWidgets(
      'Subscription upgrade flow',
      (WidgetTester tester) async {},
      skip: true,
    );

    testWidgets(
      'Family member removal',
      (WidgetTester tester) async {},
      skip: true,
    );
  });
}
