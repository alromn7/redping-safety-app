import '../models/subscription_tier.dart';
import '../models/subscription_plan.dart';
import 'subscription_service.dart';
import 'feature_access_service.dart';

/// Comprehensive access controller for subscription-based feature restrictions
/// Implements the REDP!NG subscription plan blueprint
class SubscriptionAccessController {
  static final SubscriptionAccessController _instance =
      SubscriptionAccessController._internal();
  factory SubscriptionAccessController() => _instance;
  SubscriptionAccessController._internal();

  final SubscriptionService _subscriptionService = SubscriptionService.instance;
  final FeatureAccessService _featureAccessService =
      FeatureAccessService.instance;

  /// Check if user has access to a specific feature based on their subscription
  bool hasFeatureAccess(String feature) {
    return _featureAccessService.hasFeatureAccess(feature);
  }

  /// Get the required subscription tier for a feature
  SubscriptionTier? getRequiredTierForFeature(String feature) {
    return _featureAccessService.getRequiredTierForFeature(feature);
  }

  /// Check if user can access a feature with usage limits
  bool canUseFeatureWithLimit(String feature) {
    if (!hasFeatureAccess(feature)) {
      return false;
    }

    final subscription = _subscriptionService.currentSubscription;
    if (subscription == null) {
      return false;
    }

    // Check usage limits
    final limit = _featureAccessService.getFeatureLimit(feature);
    if (limit == 0) {
      return false; // Feature not available for this tier
    }

    // TODO: Implement actual usage tracking check
    // For now, assume user hasn't exceeded limits
    return true;
  }

  /// Get feature usage information
  Map<String, dynamic> getFeatureUsageInfo(String feature) {
    final subscription = _subscriptionService.currentSubscription;
    final limit = _featureAccessService.getFeatureLimit(feature);

    return {
      'hasAccess': hasFeatureAccess(feature),
      'limit': limit,
      'used': 0, // TODO: Get actual usage from usage tracking service
      'remaining': limit,
      'requiredTier': getRequiredTierForFeature(feature),
      'currentTier': subscription?.plan.tier,
    };
  }

  /// Get subscription plan recommendations for a feature
  List<SubscriptionPlan> getRecommendedPlansForFeature(String feature) {
    final requiredTier = getRequiredTierForFeature(feature);
    if (requiredTier == null) {
      return []; // Feature is free
    }

    final availablePlans = _subscriptionService.availablePlans;
    return availablePlans.where((plan) {
      // Include plans that have the required tier or higher
      return _isTierHigherOrEqual(plan.tier, requiredTier);
    }).toList();
  }

  /// Check if a tier is higher or equal to another tier
  bool _isTierHigherOrEqual(SubscriptionTier tier1, SubscriptionTier tier2) {
    const tierOrder = {
      SubscriptionTier.free: 0,
      SubscriptionTier.essentialPlus: 1,
      SubscriptionTier.pro: 2,
      SubscriptionTier.ultra: 3,
      SubscriptionTier.family: 4,
    };

    return (tierOrder[tier1] ?? 0) >= (tierOrder[tier2] ?? 0);
  }

  /// Get feature access summary for current user
  Map<String, dynamic> getFeatureAccessSummary() {
    final subscription = _subscriptionService.currentSubscription;
    if (subscription == null) {
      return {
        'tier': 'free',
        'features': _featureAccessService.getAvailableFeatures(
          SubscriptionTier.free,
        ),
        'restrictions': _getRestrictionSummary(SubscriptionTier.free),
      };
    }

    return {
      'tier': subscription.plan.tier.name,
      'planName': subscription.plan.name,
      'features': _featureAccessService.getAvailableFeatures(
        subscription.plan.tier,
      ),
      'restrictions': _getRestrictionSummary(subscription.plan.tier),
      'limits': subscription.plan.limits,
    };
  }

  /// Get restriction summary for a tier
  Map<String, dynamic> _getRestrictionSummary(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return {
          'sosAlerts': 'Unlimited (manual only)',
          'emergencyContacts': '2 contacts',
          'redpingHelp': 'Unlimited (all categories)',
          'communityChat': 'Full participation',
          'quickCall': 'Available',
          'mapAccess': 'Basic maps',
          'medicalProfile': 'Not available',
          'acfd': 'Not available',
          'redpingMode': 'Not available',
          'hazardAlerts': 'Not available',
          'aiAssistant': 'Not available',
          'sosSMS': 'Not available',
          'gadgetIntegration': 'Not available',
          'sarDashboard': 'View only',
          'sarAdmin': 'Not available',
        };

      case SubscriptionTier.essentialPlus:
        return {
          'sosAlerts': 'Unlimited',
          'emergencyContacts': '5 contacts',
          'redpingHelp': 'Unlimited (all categories)',
          'communityChat': 'Full participation',
          'quickCall': 'Available',
          'mapAccess': 'Enhanced maps',
          'medicalProfile': 'Full medical profile',
          'acfd': 'Auto + Manual detection',
          'redpingMode': 'Not available',
          'hazardAlerts': 'Weather & disasters',
          'aiAssistant': 'Not available',
          'sosSMS': 'SMS alerts enabled',
          'gadgetIntegration': 'Not available',
          'sarDashboard': 'View only',
          'sarAdmin': 'Not available',
        };

      case SubscriptionTier.pro:
        return {
          'sosAlerts': 'Unlimited',
          'emergencyContacts': 'Unlimited',
          'redpingHelp': 'Unlimited (all categories)',
          'communityChat': 'Full participation',
          'quickCall': 'Available',
          'mapAccess': 'Advanced maps',
          'medicalProfile': 'Profile Pro + Medical',
          'acfd': 'Auto + Manual detection',
          'redpingMode': 'All activity modes',
          'hazardAlerts': 'Advanced alerts',
          'aiAssistant': 'Full AI (24 commands)',
          'sosSMS': 'SMS alerts enabled',
          'gadgetIntegration': 'All devices',
          'sarDashboard': 'Full access',
          'sarAdmin': 'Not available',
        };

      case SubscriptionTier.ultra:
        return {
          'sosAlerts': 'Unlimited + Priority',
          'emergencyContacts': 'Unlimited',
          'redpingHelp': 'Unlimited + Priority',
          'communityChat': 'Full participation',
          'quickCall': 'Priority calling',
          'mapAccess': 'Enterprise maps',
          'medicalProfile': 'Enterprise profile',
          'acfd': 'Auto + Manual detection',
          'redpingMode': 'All modes + Custom',
          'hazardAlerts': 'Enterprise monitoring',
          'aiAssistant': 'Enterprise AI',
          'sosSMS': 'SMS alerts enabled',
          'gadgetIntegration': 'All devices + API',
          'sarDashboard': 'Full access',
          'sarAdmin': 'Full admin management',
          'additionalMembers': r'$5 per Pro member',
        };

      case SubscriptionTier.family:
        return {
          'sosAlerts': 'Unlimited (4 accounts)',
          'emergencyContacts': 'Shared unlimited',
          'redpingHelp': 'Unlimited (all accounts)',
          'communityChat': 'Full participation',
          'quickCall': 'Available (all)',
          'mapAccess': 'Family-wide tracking',
          'medicalProfile': 'All accounts',
          'acfd': 'All accounts',
          'redpingMode': 'Pro account only',
          'hazardAlerts': 'All accounts',
          'aiAssistant': 'Pro account only',
          'sosSMS': 'All accounts',
          'gadgetIntegration': 'Pro account only',
          'sarDashboard': 'Pro: Full, Essential+: View',
          'sarAdmin': 'Not available',
          'accounts': '1 Pro + 3 Essential+',
        };
    }
  }

  /// Check if user can upgrade to access a feature
  bool canUpgradeForFeature(String feature) {
    final requiredTier = getRequiredTierForFeature(feature);
    if (requiredTier == null) {
      return false; // Feature is free, no upgrade needed
    }

    final subscription = _subscriptionService.currentSubscription;
    if (subscription == null) {
      return true; // Free user can upgrade
    }

    return !_isTierHigherOrEqual(subscription.plan.tier, requiredTier);
  }

  /// Get upgrade recommendation for a feature
  Map<String, dynamic> getUpgradeRecommendation(String feature) {
    final recommendedPlans = getRecommendedPlansForFeature(feature);
    if (recommendedPlans.isEmpty) {
      return {'canUpgrade': false, 'reason': 'Feature is available for free'};
    }

    // Get the lowest tier plan that provides access
    final recommendedPlan = recommendedPlans.first;

    return {
      'canUpgrade': true,
      'recommendedPlan': recommendedPlan.name,
      'requiredTier': recommendedPlan.tier.name,
      'monthlyPrice': recommendedPlan.monthlyPrice,
      'yearlyPrice': recommendedPlan.yearlyPrice,
      'yearlySavings': recommendedPlan.yearlySavingsPercent,
      'features': recommendedPlan.features,
    };
  }

  /// Get all restricted features for current user
  List<Map<String, dynamic>> getRestrictedFeatures() {
    final allFeatures = [
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

    return allFeatures
        .where((feature) => !hasFeatureAccess(feature))
        .map(
          (feature) => {
            'feature': feature,
            'requiredTier': getRequiredTierForFeature(feature),
            'upgradeRecommendation': getUpgradeRecommendation(feature),
          },
        )
        .toList();
  }
}
