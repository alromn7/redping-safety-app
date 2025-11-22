/// Debug script to investigate SAR access control issues
/// Run this to see exactly what's happening with subscription and access levels
library;

import 'lib/services/feature_access_service.dart';
import 'lib/services/subscription_service.dart';
import 'lib/models/sar_access_level.dart';

void main() async {
  print('🔍 SAR ACCESS DEBUG INVESTIGATION');
  print('==================================');

  try {
    // Initialize services first
    await _initializeServices();

    await _debugSubscriptionState();
    await _debugSARAccessLevel();
    await _debugFeatureAccess();
    _debugSubscriptionServiceLogic();
    _debugFeatureAccessServiceFlow();

    _printDebugInstructions();

    print('\n🎉 Debug investigation completed successfully!');
  } catch (e) {
    print('❌ Error during debug investigation: $e');
    print('This might indicate initialization issues with the services.');
  }
}

/// Initialize services before debugging
Future<void> _initializeServices() async {
  print('🔧 Initializing services...');

  try {
    // Initialize subscription service
    await SubscriptionService.instance.initialize();
    print('✅ SubscriptionService initialized');

    // Initialize feature access service
    FeatureAccessService.instance.initialize();
    print('✅ FeatureAccessService initialized');
  } catch (e) {
    print('⚠️ Service initialization warning: $e');
    print('Continuing with debug investigation...');
  }
}

Future<void> _debugSubscriptionState() async {
  print('\n📋 SUBSCRIPTION STATE:');

  final subscriptionService = SubscriptionService.instance;
  final currentSubscription = subscriptionService.currentSubscription;

  print('Current Subscription: ${currentSubscription?.toString() ?? "NULL"}');

  if (currentSubscription != null) {
    print('Plan: ${currentSubscription.plan.name}');
    print('Tier: ${currentSubscription.plan.tier}');
    print('Is Active: ${currentSubscription.isActive}');
    print('Limits: ${currentSubscription.plan.limits}');
    print(
      'SAR Participation Limit: ${currentSubscription.plan.limits['sarParticipation']}',
    );
  } else {
    print('❌ NO ACTIVE SUBSCRIPTION FOUND');
  }
}

Future<void> _debugSARAccessLevel() async {
  print('\n🎯 SAR ACCESS LEVEL:');

  final featureAccessService = FeatureAccessService.instance;
  final accessLevel = await featureAccessService.getSARAccessLevel();

  print('Current SAR Access Level: ${accessLevel.displayName}');
  print('Description: ${accessLevel.description}');
  print('Available Features: ${accessLevel.availableFeatures.join(", ")}');
}

Future<void> _debugFeatureAccess() async {
  print('\n🔧 FEATURE ACCESS TESTS:');

  final featureAccessService = FeatureAccessService.instance;

  final testFeatures = [
    'sarObserver',
    'sarParticipation',
    'sarVolunteerRegistration',
    'sarTeamManagement',
    'organizationManagement',
  ];

  for (final feature in testFeatures) {
    final hasAccess = featureAccessService.hasFeatureAccess(feature);
    print('$feature: ${hasAccess ? "✅ ALLOWED" : "❌ DENIED"}');
  }

  // Test the specific issue
  print('\n🚨 EMERGENCY RESPONSE TEST:');
  final canRespond = featureAccessService.hasFeatureAccess('sarParticipation');
  print(
    'Can respond to emergencies: ${canRespond ? "❌ YES (THIS IS THE PROBLEM!)" : "✅ NO (CORRECT)"}',
  );
}

// Additional debugging functions

void _debugSubscriptionServiceLogic() {
  print('\n🔍 SUBSCRIPTION SERVICE DEBUG:');

  final subscriptionService = SubscriptionService.instance;

  // Test the hasFeatureAccess method directly
  final directSARAccess = subscriptionService.hasFeatureAccess(
    'sarParticipation',
  );
  print(
    'Direct SubscriptionService.hasFeatureAccess("sarParticipation"): $directSARAccess',
  );

  // Check if the subscription service is bypassing our logic
  if (directSARAccess) {
    print(
      '❌ ISSUE FOUND: SubscriptionService is allowing sarParticipation for Essential users',
    );
  }
}

void _debugFeatureAccessServiceFlow() {
  print('\n🔍 FEATURE ACCESS SERVICE DEBUG:');

  final featureAccessService = FeatureAccessService.instance;

  // This should help us understand which path the code is taking
  print('Testing hasFeatureAccess("sarParticipation") flow...');

  // Test the actual feature access
  final hasAccess = featureAccessService.hasFeatureAccess('sarParticipation');
  print(
    'FeatureAccessService.hasFeatureAccess("sarParticipation"): $hasAccess',
  );

  // We can't easily debug the internal flow without modifying the actual service,
  // but we can test different scenarios

  print(
    hasAccess
        ? '❌ SAR access control is being bypassed!'
        : '✅ SAR access control working correctly',
  );
}

/// Additional debug information and usage instructions
void _printDebugInstructions() {
  print('\n📖 DEBUG INSTRUCTIONS:');
  print('This script investigates SAR access control issues. Look for:');
  print('1. What subscription tier is actually active');
  print('2. What SAR access level is being returned');
  print('3. Which features are being allowed/denied');
  print(
    '4. Whether the issue is in subscription service or feature access service',
  );
  print(
    '5. If Essential tier users are incorrectly getting SAR participation access',
  );
}
