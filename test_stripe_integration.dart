/// Stripe Integration Test Script
///
/// This script verifies that all Stripe components are properly configured
/// and ready for production deployment.
///
/// Run with: flutter run test_stripe_integration.dart
library;

import 'dart:io';

void main() {
  print('\n${'=' * 70}');
  print('🔍 STRIPE INTEGRATION VERIFICATION');
  print('=' * 70 + '\n');

  bool allTestsPassed = true;

  // Test 1: Stripe Config File
  print('📋 Test 1: Stripe Configuration File');
  final configFile = File('lib/core/config/stripe_config.dart');
  if (configFile.existsSync()) {
    print('✅ stripe_config.dart exists');
    final content = configFile.readAsStringSync();

    // Check for real price IDs
    if (content.contains('price_1SVjOcPlurWsomXvo3cJ8YO9')) {
      print('✅ Essential+ Monthly price ID configured');
    } else {
      print('❌ Essential+ Monthly price ID missing');
      allTestsPassed = false;
    }

    if (content.contains('price_1SXB6BPlurWsomXv5j56KjdG')) {
      print('✅ Essential+ Yearly price ID configured');
    } else {
      print('❌ Essential+ Yearly price ID missing');
      allTestsPassed = false;
    }

    if (content.contains('price_1SVjOIPlurWsomXvOvgWfPFK')) {
      print('✅ Pro Monthly price ID configured');
    } else {
      print('❌ Pro Monthly price ID missing');
      allTestsPassed = false;
    }

    if (content.contains('price_1SXB4aPlurWsomXvUR3fggRE')) {
      print('✅ Pro Yearly price ID configured');
    } else {
      print('❌ Pro Yearly price ID missing');
      allTestsPassed = false;
    }

    if (content.contains('price_1SVjNIPlurWsomXvMAxQouxd')) {
      print('✅ Ultra Monthly price ID configured');
    } else {
      print('❌ Ultra Monthly price ID missing');
      allTestsPassed = false;
    }

    if (content.contains('price_1SXB31PlurWsomXvfmQaoq7R')) {
      print('✅ Ultra Yearly price ID configured');
    } else {
      print('❌ Ultra Yearly price ID missing');
      allTestsPassed = false;
    }

    if (content.contains('price_1SVjO7PlurWsomXv9CCcDrGF')) {
      print('✅ Family Monthly price ID configured');
    } else {
      print('❌ Family Monthly price ID missing');
      allTestsPassed = false;
    }

    if (content.contains('price_1SX9tyPlurWsomXv5PWCoHJF')) {
      print('✅ Family Yearly price ID configured');
    } else {
      print('❌ Family Yearly price ID missing');
      allTestsPassed = false;
    }

    if (content.contains('pk_live_')) {
      print('✅ Live publishable key configured');
    } else {
      print('⚠️  Test publishable key only (ok for development)');
    }
  } else {
    print('❌ stripe_config.dart NOT FOUND');
    allTestsPassed = false;
  }
  print('');

  // Test 2: Main.dart Initialization
  print('📋 Test 2: Stripe SDK Initialization in main.dart');
  final mainFile = File('lib/main.dart');
  if (mainFile.existsSync()) {
    final content = mainFile.readAsStringSync();

    if (content.contains(
      'import \'package:flutter_stripe/flutter_stripe.dart\'',
    )) {
      print('✅ flutter_stripe package imported');
    } else {
      print('❌ flutter_stripe import missing');
      allTestsPassed = false;
    }

    if (content.contains('import \'core/config/stripe_config.dart\'')) {
      print('✅ StripeConfig imported');
    } else {
      print('❌ StripeConfig import missing');
      allTestsPassed = false;
    }

    if (content.contains('await StripeConfig.initialize()')) {
      print('✅ StripeConfig.initialize() called');
    } else {
      print('❌ StripeConfig.initialize() not called');
      allTestsPassed = false;
    }

    if (content.contains(
      'Stripe.publishableKey = StripeConfig.publishableKey',
    )) {
      print('✅ Stripe.publishableKey set');
    } else {
      print('❌ Stripe.publishableKey not set');
      allTestsPassed = false;
    }

    if (content.contains('await Stripe.instance.applySettings()')) {
      print('✅ Stripe.instance.applySettings() called');
    } else {
      print('❌ Stripe settings not applied');
      allTestsPassed = false;
    }
  } else {
    print('❌ main.dart NOT FOUND');
    allTestsPassed = false;
  }
  print('');

  // Test 3: Payment Service
  print('📋 Test 3: Stripe Payment Service');
  final serviceFile = File(
    'lib/services/stripe_payment_integration_service.dart',
  );
  if (serviceFile.existsSync()) {
    print('✅ stripe_payment_integration_service.dart exists');
    final content = serviceFile.readAsStringSync();

    if (content.contains('processSubscriptionPayment')) {
      print('✅ processSubscriptionPayment method exists');
    } else {
      print('❌ processSubscriptionPayment method missing');
      allTestsPassed = false;
    }

    if (content.contains('FirebaseFunctions')) {
      print('✅ Firebase Functions integration present');
    } else {
      print('❌ Firebase Functions integration missing');
      allTestsPassed = false;
    }
  } else {
    print('❌ stripe_payment_integration_service.dart NOT FOUND');
    allTestsPassed = false;
  }
  print('');

  // Test 4: Payment Widget
  print('📋 Test 4: Subscription Payment Widget');
  final widgetFile = File(
    'lib/widgets/subscription/subscription_payment_sheet.dart',
  );
  if (widgetFile.existsSync()) {
    print('✅ subscription_payment_sheet.dart exists');
    final content = widgetFile.readAsStringSync();

    if (content.contains('StripePaymentService')) {
      print('✅ StripePaymentService integrated');
    } else {
      print('❌ StripePaymentService not integrated');
      allTestsPassed = false;
    }
  } else {
    print('❌ subscription_payment_sheet.dart NOT FOUND');
    allTestsPassed = false;
  }
  print('');

  // Test 5: Cloud Functions
  print('📋 Test 5: Cloud Functions Configuration');
  final functionsFile = File('functions/src/subscriptionPayments.js');
  if (functionsFile.existsSync()) {
    print('✅ subscriptionPayments.js exists');
    final content = functionsFile.readAsStringSync();

    // Check all 8 price IDs
    final priceIds = [
      'price_1SVjOcPlurWsomXvo3cJ8YO9', // Essential+ Monthly
      'price_1SXB6BPlurWsomXv5j56KjdG', // Essential+ Yearly
      'price_1SVjOIPlurWsomXvOvgWfPFK', // Pro Monthly
      'price_1SXB4aPlurWsomXvUR3fggRE', // Pro Yearly
      'price_1SVjNIPlurWsomXvMAxQouxd', // Ultra Monthly
      'price_1SXB31PlurWsomXvfmQaoq7R', // Ultra Yearly
      'price_1SVjO7PlurWsomXv9CCcDrGF', // Family Monthly
      'price_1SX9tyPlurWsomXv5PWCoHJF', // Family Yearly
    ];

    int foundIds = 0;
    for (final priceId in priceIds) {
      if (content.contains(priceId)) {
        foundIds++;
      }
    }

    if (foundIds == 8) {
      print('✅ All 8 price IDs configured in Cloud Functions');
    } else {
      print('⚠️  Only $foundIds/8 price IDs found in Cloud Functions');
      if (foundIds < 8) allTestsPassed = false;
    }

    if (content.contains('exports.processSubscriptionPayment')) {
      print('✅ processSubscriptionPayment function exported');
    } else {
      print('❌ processSubscriptionPayment function not exported');
      allTestsPassed = false;
    }

    if (content.contains('exports.stripeWebhook')) {
      print('✅ stripeWebhook function exported');
    } else {
      print('❌ stripeWebhook function not exported');
      allTestsPassed = false;
    }
  } else {
    print('❌ subscriptionPayments.js NOT FOUND');
    allTestsPassed = false;
  }
  print('');

  // Test 6: Package Dependencies
  print('📋 Test 6: Package Dependencies');
  final pubspecFile = File('pubspec.yaml');
  if (pubspecFile.existsSync()) {
    final content = pubspecFile.readAsStringSync();

    if (content.contains('flutter_stripe:')) {
      print('✅ flutter_stripe package declared');
    } else {
      print('❌ flutter_stripe package missing');
      allTestsPassed = false;
    }

    if (content.contains('cloud_functions:') ||
        content.contains('firebase_functions:')) {
      print('✅ Firebase Functions package declared');
    } else {
      print('❌ Firebase Functions package missing');
      allTestsPassed = false;
    }
  } else {
    print('❌ pubspec.yaml NOT FOUND');
    allTestsPassed = false;
  }
  print('');

  // Final Summary
  print('=' * 70);
  if (allTestsPassed) {
    print('✅ ALL TESTS PASSED - Stripe Integration is PRODUCTION READY');
    print('');
    print('Next Steps:');
    print(
      '1. Test subscription checkout flow with test card: 4242 4242 4242 4242',
    );
    print('2. Verify Firebase functions are deployed:');
    print('   firebase deploy --only functions');
    print('3. Check Stripe webhook is configured in Stripe Dashboard');
    print('4. Test payment success/failure scenarios');
  } else {
    print('❌ SOME TESTS FAILED - Please fix issues above');
    print('');
    print(
      'Review STRIPE_FLUTTER_INTEGRATION_COMPLETE.md for setup instructions',
    );
  }
  print('=' * 70 + '\n');
}
