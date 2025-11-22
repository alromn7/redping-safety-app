import 'lib/services/subscription_service.dart';
import 'lib/services/feature_access_service.dart';
import 'lib/services/subscription_access_controller.dart';
import 'lib/models/subscription_tier.dart';

/// Test script to demonstrate comprehensive subscription access control
/// Based on REDP!NG subscription plan blueprint
void main() async {
  print('🔒 REDP!NG SUBSCRIPTION ACCESS CONTROL TEST');
  print('============================================');
  print('');

  try {
    // Initialize services
    await _initializeServices();

    // Test different subscription tiers
    await _testSubscriptionTiers();

    // Test feature access restrictions
    await _testFeatureAccessRestrictions();

    // Test upgrade recommendations
    await _testUpgradeRecommendations();

    // Test comprehensive access control
    await _testComprehensiveAccessControl();

    print('');
    print('✅ All subscription access control tests completed successfully!');
  } catch (e) {
    print('❌ Error during testing: $e');
  }
}

/// Initialize required services
Future<void> _initializeServices() async {
  print('🔧 Initializing services...');

  try {
    // Initialize subscription service
    await SubscriptionService.instance.initialize();
    print('✅ SubscriptionService initialized');

    // Initialize feature access service
    FeatureAccessService.instance.initialize();
    print('✅ FeatureAccessService initialized');

    print('✅ All services initialized successfully');
  } catch (e) {
    print('⚠️ Service initialization warning: $e');
  }

  print('');
}

/// Test different subscription tiers and their features
Future<void> _testSubscriptionTiers() async {
  print('📊 TESTING SUBSCRIPTION TIERS');
  print('=============================');

  // Removed unused accessController variable

  final tiers = [
    SubscriptionTier.free,
    SubscriptionTier.essentialPlus,
    SubscriptionTier.essentialPlus,
    SubscriptionTier.pro,
    SubscriptionTier.ultra,
    SubscriptionTier.family,
  ];

  for (final tier in tiers) {
    print('');
    print('🔍 Testing ${tier.name.toUpperCase()} tier:');

    final summary = _simulateTierAccess(tier);
    print('   Features: ${summary['features'].length} available');
    print(
      '   Restrictions: ${summary['restrictions'].keys.length} limitations',
    );

    // Show key restrictions
    final restrictions = summary['restrictions'] as Map<String, String>;
    restrictions.forEach((key, value) {
      print('   • $key: $value');
    });
  }

  print('');
}

/// Simulate tier access for testing
Map<String, dynamic> _simulateTierAccess(SubscriptionTier tier) {
  final featureAccessService = FeatureAccessService.instance;

  return {
    'tier': tier.name,
    'features': featureAccessService.getAvailableFeatures(tier),
    'restrictions': _getRestrictionSummary(tier),
  };
}

/// Get restriction summary for a tier
Map<String, String> _getRestrictionSummary(SubscriptionTier tier) {
  switch (tier) {
    case SubscriptionTier.free:
      return {
        'sosAlerts': 'Limited to 5 per month',
        'emergencyContacts': 'Limited to 2 contacts',
        'redpingHelp': 'Limited to 5 requests per month',
        'sarFeatures': 'Not available',
        'communityFeatures': 'Read-only access',
        'aiAssistant': 'Not available',
        'hazardAlerts': 'Not available',
        'medicalInfo': 'Not available',
      };

    case SubscriptionTier.essentialPlus:
      return {
        'sosAlerts': 'Unlimited',
        'emergencyContacts': 'Unlimited',
        'redpingHelp': 'Unlimited',
        'sarFeatures': 'Enhanced observer access',
        'communityFeatures': 'Limited participation',
        'aiAssistant': 'Basic AI assistant',
        'hazardAlerts': 'Enhanced alerts',
        'medicalInfo': 'Basic medical info',
      };

    case SubscriptionTier.pro:
      return {
        'sosAlerts': 'Unlimited',
        'emergencyContacts': 'Unlimited',
        'redpingHelp': 'Unlimited',
        'sarFeatures': 'Full participation',
        'communityFeatures': 'Full access',
        'aiAssistant': 'Full AI assistant',
        'hazardAlerts': 'Full monitoring',
        'medicalInfo': 'Full medical management',
      };

    case SubscriptionTier.ultra:
      return {
        'sosAlerts': 'Unlimited + Priority',
        'emergencyContacts': 'Unlimited',
        'redpingHelp': 'Unlimited + Priority',
        'sarFeatures': 'Team management & coordination',
        'communityFeatures': 'Full access + management',
        'aiAssistant': 'Enterprise AI assistant',
        'hazardAlerts': 'Advanced monitoring + management',
        'medicalInfo': 'Full medical management + analytics',
      };

    case SubscriptionTier.family:
      return {
        'sosAlerts': 'Unlimited for family',
        'emergencyContacts': 'Shared family contacts',
        'redpingHelp': 'Unlimited for family',
        'sarFeatures': 'Family SAR coordination',
        'communityFeatures': 'Family community features',
        'aiAssistant': 'Family AI assistant',
        'hazardAlerts': 'Family hazard monitoring',
        'medicalInfo': 'Family medical management',
      };
  }
}

/// Test feature access restrictions
Future<void> _testFeatureAccessRestrictions() async {
  print('🔐 TESTING FEATURE ACCESS RESTRICTIONS');
  print('=====================================');

  final accessController = SubscriptionAccessController();

  final testFeatures = [
    'sosTesting',
    'medicalInfo',
    'sarParticipation',
    'hazardAlerts',
    'emergencyMessaging',
    'communityFeatures',
    'aiAssistant',
    'satelliteComm',
    'organizationManagement',
    'sarTeamManagement',
  ];

  for (final feature in testFeatures) {
    print('');
    print('🔍 Testing $feature:');

    final hasAccess = accessController.hasFeatureAccess(feature);
    final requiredTier = accessController.getRequiredTierForFeature(feature);
    final usageInfo = accessController.getFeatureUsageInfo(feature);

    print('   Access: ${hasAccess ? "✅ Granted" : "❌ Denied"}');
    print('   Required Tier: ${requiredTier?.name ?? "Free"}');
    print('   Limit: ${usageInfo['limit']}');
    print('   Used: ${usageInfo['used']}');
    print('   Remaining: ${usageInfo['remaining']}');
  }

  print('');
}

/// Test upgrade recommendations
Future<void> _testUpgradeRecommendations() async {
  print('📈 TESTING UPGRADE RECOMMENDATIONS');
  print('==================================');

  final accessController = SubscriptionAccessController();

  final restrictedFeatures = [
    'sosTesting',
    'medicalInfo',
    'sarParticipation',
    'hazardAlerts',
    'emergencyMessaging',
    'communityFeatures',
  ];

  for (final feature in restrictedFeatures) {
    print('');
    print('🔍 Upgrade recommendation for $feature:');

    final canUpgrade = accessController.canUpgradeForFeature(feature);
    final recommendation = accessController.getUpgradeRecommendation(feature);

    print('   Can Upgrade: ${canUpgrade ? "✅ Yes" : "❌ No"}');

    if (recommendation['canUpgrade'] == true) {
      print('   Recommended Plan: ${recommendation['recommendedPlan']}');
      print('   Required Tier: ${recommendation['requiredTier']}');
      print('   Monthly Price: \$${recommendation['monthlyPrice']}');
      print('   Yearly Price: \$${recommendation['yearlyPrice']}');
      print(
        '   Yearly Savings: ${recommendation['yearlySavings']?.toStringAsFixed(1)}%',
      );
    } else {
      print('   Reason: ${recommendation['reason']}');
    }
  }

  print('');
}

/// Test comprehensive access control
Future<void> _testComprehensiveAccessControl() async {
  print('🎯 TESTING COMPREHENSIVE ACCESS CONTROL');
  print('======================================');

  final accessController = SubscriptionAccessController();

  // Test feature access summary
  print('📊 Feature Access Summary:');
  final summary = accessController.getFeatureAccessSummary();
  print('   Current Tier: ${summary['tier']}');
  print('   Plan Name: ${summary['planName'] ?? "Free Plan"}');
  print('   Available Features: ${summary['features'].length}');
  print('   Restrictions: ${summary['restrictions'].keys.length}');

  print('');

  // Test restricted features
  print('🚫 Restricted Features:');
  final restrictedFeatures = accessController.getRestrictedFeatures();
  for (final feature in restrictedFeatures) {
    print(
      '   • ${feature['feature']}: Requires ${feature['requiredTier']?.name ?? "Free"}',
    );

    final recommendation =
        feature['upgradeRecommendation'] as Map<String, dynamic>;
    if (recommendation['canUpgrade'] == true) {
      print(
        '     → Upgrade to: ${recommendation['recommendedPlan']} (\$${recommendation['monthlyPrice']}/month)',
      );
    }
  }

  print('');
}

// Removed unused subscription plan comparison helper
