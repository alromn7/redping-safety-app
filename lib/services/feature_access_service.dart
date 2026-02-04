import 'package:flutter/material.dart';
import 'package:redping_14v/utils/iterable_extensions.dart';
import '../models/subscription_tier.dart';
import '../models/sar_access_level.dart';
import '../widgets/upgrade_required_dialog.dart';
import 'subscription_service.dart';
import 'usage_tracking_service.dart';
import '../config/env.dart';

/// Service for controlling feature access based on subscription tiers
class FeatureAccessService {
  FeatureAccessService._();

  static final FeatureAccessService _instance = FeatureAccessService._();
  static FeatureAccessService get instance => _instance;

  // Global switch: disable all subscription gating and dialogs when false.
  // Set to false to remove all subscription prompts app-wide.
  static const bool enforceSubscriptions = false;

  SubscriptionService? _subscriptionService;
  bool _isInitialized = false;

  /// Initialize the service
  void initialize() {
    try {
      _subscriptionService = SubscriptionService.instance;
      _isInitialized = true;
      debugPrint('FeatureAccessService: Initialized');
    } catch (e) {
      debugPrint('FeatureAccessService: Initialization error - $e');
      _isInitialized = false;
    }
  }

  /// Check if user has access to a specific feature
  bool hasFeatureAccess(String feature) {
    if (!enforceSubscriptions) return true;
    // If service is not initialized, only allow basic features
    if (!_isInitialized || _subscriptionService == null) {
      return _getFreeFeatures().contains(feature);
    }

    // Special handling for SAR features based on access levels
    // This should be checked FIRST, regardless of subscription status
    if (_isSARFeature(feature)) {
      return _checkSARFeatureAccess(feature);
    }

    final subscription = _subscriptionService!.currentSubscription;

    // If no subscription, only basic features are available
    if (subscription == null || !subscription.isActive) {
      return _getFreeFeatures().contains(feature);
    }

    return _subscriptionService!.hasFeatureAccess(feature);
  }

  /// Get feature limit for current subscription
  int getFeatureLimit(String feature) {
    if (!enforceSubscriptions) return -1; // Unlimited
    if (!_isInitialized || _subscriptionService == null) {
      return _getFreeFeatureLimits()[feature] ?? 0;
    }

    final subscription = _subscriptionService!.currentSubscription;

    if (subscription == null || !subscription.isActive) {
      return _getFreeFeatureLimits()[feature] ?? 0;
    }

    return _subscriptionService!.getFeatureLimit(feature);
  }

  /// Check if user can use satellite communication
  bool canUseSatelliteComm() {
    return hasFeatureAccess('satelliteComm');
  }

  /// Check if user can participate in SAR operations
  bool canJoinSAROperations() {
    return hasFeatureAccess('sarParticipation');
  }

  /// Check if user can manage SAR organizations
  bool canManageOrganizations() {
    return hasFeatureAccess('organizationManagement');
  }

  /// Check if user can register as a SAR volunteer
  bool canRegisterAsSARVolunteer() {
    return hasFeatureAccess('sarVolunteerRegistration');
  }

  /// Check if user can create SAR teams
  bool canCreateSARTeams() {
    return hasFeatureAccess('sarTeamManagement');
  }

  /// Check if user can coordinate SAR missions
  bool canCoordinateSARMissions() {
    return hasFeatureAccess('sarMissionCoordination');
  }

  /// Check if user can access SAR analytics
  bool canAccessSARAnalytics() {
    return hasFeatureAccess('sarAnalytics');
  }

  /// Check if user can access multi-team coordination
  bool canAccessMultiTeamCoordination() {
    return hasFeatureAccess('multiTeamCoordination');
  }

  /// Get SAR access level based on subscription
  Future<SARAccessLevel> getSARAccessLevel() async {
    if (!enforceSubscriptions) return SARAccessLevel.coordinator;
    if (!_isInitialized || _subscriptionService == null) {
      return SARAccessLevel.none;
    }

    final subscription = _subscriptionService!.currentSubscription;

    if (subscription == null || !subscription.isActive) {
      return SARAccessLevel.none;
    }

    switch (subscription.plan.tier) {
      case SubscriptionTier.free:
      case SubscriptionTier.essentialPlus:
        return SARAccessLevel.observer;
      case SubscriptionTier.pro:
      case SubscriptionTier.family:
        return SARAccessLevel.participant;
      case SubscriptionTier.ultra:
        return SARAccessLevel.coordinator;
    }
  }

  /// Check if user has unlimited SOS alerts
  bool hasUnlimitedSOS() {
    return hasFeatureAccess('unlimitedSOS');
  }

  /// Get maximum SOS alerts per month
  int getMaxSOSAlerts() {
    return getFeatureLimit('sosAlertsPerMonth');
  }

  /// Get maximum emergency contacts
  int getMaxEmergencyContacts() {
    return getFeatureLimit('emergencyContacts');
  }

  /// Get maximum satellite messages per month
  int getMaxSatelliteMessages() {
    return getFeatureLimit('satelliteMessages');
  }

  /// Check if user can manage family members (family admin only)
  bool canManageFamilyMembers() {
    if (!enforceSubscriptions) return true;
    if (!_isInitialized || _subscriptionService == null) {
      return false;
    }
    final subscription = _subscriptionService!.currentSubscription;
    return subscription?.isFamilyAdmin == true &&
        subscription?.plan.isFamilyPlan == true;
  }

  /// Check if user can access family dashboard
  bool canAccessFamilyDashboard() {
    if (!enforceSubscriptions) return true;
    if (!_isInitialized || _subscriptionService == null) {
      return false;
    }
    final subscription = _subscriptionService!.currentSubscription;
    final family = _subscriptionService!.currentFamily;
    return subscription?.familyId != null && family != null;
  }

  /// Get available features for a subscription tier
  List<String> getAvailableFeatures(SubscriptionTier tier) {
    // This is the canonical list used for upgrade prompts and feature gates.
    // Keep it aligned with keys passed to hasFeatureAccess(...) across the app.
    final tierRank = _tierRank(tier);
    return _featureRequirements.entries
        .where((e) {
          final required = e.value;
          if (_retiredInAppFeatures.contains(e.key)) return false;
          return required == null || _tierRank(required) <= tierRank;
        })
        .map((e) => e.key)
        .toList(growable: false);
  }

  static const Map<String, String> _featureAliases = {
    // Legacy keys used in older UI/gating.
    'medicalInfo': 'medicalProfile',
    'sosSms': 'sosSMS',
  };

  static const Set<String> _retiredInAppFeatures = {
    // Community chat is website-only.
    'communityChat',
    'basicCommunityChat',
    'fullCommunityChat',
    'communityFeatures',
    // Emergency messaging UI/call injection removed in this build.
    'emergencyMessaging',
    // Family chat is not supported in-app.
    'familyChat',
  };

  static const Map<String, SubscriptionTier?> _featureRequirements = {
    // Free / baseline (null => free)
    'unlimitedSOS': null,
    'quickCall': null,
    'mapAccess': null,

    // Essential+
    'medicalProfile': SubscriptionTier.essentialPlus,
    'acfd': SubscriptionTier.essentialPlus,
    'hazardAlerts': SubscriptionTier.essentialPlus,
    'sosSMS': SubscriptionTier.essentialPlus,
    'satelliteComm': SubscriptionTier.essentialPlus,
    'sosTesting': SubscriptionTier.essentialPlus,

    // Pro
    'redpingMode': SubscriptionTier.pro,
    'gadgetIntegration': SubscriptionTier.pro,
    'sarParticipation': SubscriptionTier.pro,
    'sarVolunteerRegistration': SubscriptionTier.pro,
    'sarDashboardWrite': SubscriptionTier.pro,
    'sarMissionCoordination': SubscriptionTier.pro,

    // Ultra
    'organizationManagement': SubscriptionTier.ultra,
    'sarAdminAccess': SubscriptionTier.ultra,
    'sarTeamManagement': SubscriptionTier.ultra,
    'sarAnalytics': SubscriptionTier.ultra,
    'multiTeamCoordination': SubscriptionTier.ultra,

    // Retired/website-only (kept here so the UI can show accurate messaging)
    'communityChat': null,
    'basicCommunityChat': null,
    'fullCommunityChat': null,
    'communityFeatures': null,
    'emergencyMessaging': null,
    'familyChat': null,
  };

  static int _tierRank(SubscriptionTier? tier) {
    if (tier == null) return 0;
    switch (tier) {
      case SubscriptionTier.free:
        return 0;
      case SubscriptionTier.essentialPlus:
        return 1;
      case SubscriptionTier.pro:
        return 2;
      case SubscriptionTier.ultra:
        return 3;
      case SubscriptionTier.family:
        // Treat family as comparable to Pro for most feature gating.
        return 2;
    }
  }

  String _normalizeFeatureKey(String feature) {
    return _featureAliases[feature] ?? feature;
  }

  /// Get features available without subscription (free tier)
  List<String> _getFreeFeatures() {
    return _featureRequirements.entries
        .where((e) => e.value == null)
        .map((e) => e.key)
        .where((k) => !_retiredInAppFeatures.contains(k))
        .toList(growable: false);
  }

  /// Get feature limits for free tier
  Map<String, int> _getFreeFeatureLimits() {
    return {
      // Align with the in-app free plan definition.
      'sosAlertsPerMonth': -1, // Unlimited (manual)
      'emergencyContacts': 2,
      'satelliteMessages': 0,
      'sarParticipation': 0,
      'organizationManagement': 0,
      'redpingHelp': -1,
      'sosTesting': 0, // No SOS testing for free users
      'medicalInfo': 0, // Legacy alias (maps to medicalProfile)
      'hazardAlerts': 0, // No hazard alerts for free users
      'emergencyMessaging': 0, // No emergency messaging for free users
      'communityFeatures': 0, // No community features for free users
      'satelliteComm': 0, // No satellite communication for free users
      'sarTeamManagement': 0, // No SAR team management for free users
      'sarMissionCoordination': 0, // No SAR mission coordination for free users
      'sarAnalytics': 0, // No SAR analytics for free users
      'organizationReporting': 0, // No organization reporting for free users
      'enterpriseAnalytics': 0, // No enterprise analytics for free users
      'familyDashboard': 0, // No family dashboard for free users
      'familyCoordination': 0, // No family coordination for free users
      'familyLocationSharing': 0, // No family location sharing for free users
      'familyChat': 0, // No family chat for free users
    };
  }

  /// Get subscription tier requirements for a feature
  SubscriptionTier? getRequiredTierForFeature(String feature) {
    feature = _normalizeFeatureKey(feature);

    // Retired/website-only features should not suggest an upgrade.
    if (_retiredInAppFeatures.contains(feature)) {
      return null;
    }

    if (_getFreeFeatures().contains(feature)) {
      return null; // Free feature
    }

    return _featureRequirements[feature] ?? SubscriptionTier.ultra;
  }

  /// Check if user needs to upgrade for a feature
  bool needsUpgradeForFeature(String feature) {
    return !hasFeatureAccess(feature);
  }

  /// Get upgrade message for a feature
  String getUpgradeMessage(String feature) {
    feature = _normalizeFeatureKey(feature);

    if (_retiredInAppFeatures.contains(feature)) {
      if (feature == 'communityChat' || feature == 'communityFeatures') {
        return 'Community chat is now available on the RedPing website (not in-app).';
      }
      if (feature == 'familyChat') {
        return 'Family chat is not available in this app build.';
      }
      if (feature == 'emergencyMessaging') {
        return 'Emergency messaging UI has been removed from this app build.';
      }
      return 'This feature is not available in this app build.';
    }

    final requiredTier = getRequiredTierForFeature(feature);
    if (requiredTier == null) {
      return 'This feature is available to all users';
    }

    if (!_isInitialized || _subscriptionService == null) {
      return 'Upgrade required for this feature';
    }

    final plan = _subscriptionService!.availablePlans
        .where((p) => p.tier == requiredTier)
        .firstOrNull;

    if (plan == null) {
      return 'Upgrade required for this feature';
    }

    return 'Upgrade to ${plan.name} to access this feature';
  }

  /// Check if user can access a feature with upgrade prompt
  Future<bool> checkFeatureAccessWithUpgrade(
    BuildContext context,
    String feature, {
    String? customMessage,
  }) async {
    if (!enforceSubscriptions) return true; // Always allow; no dialogs
    // First check basic access
    if (!hasFeatureAccess(feature)) {
      return await _showUpgradeDialog(context, feature, customMessage);
    }

    // Check usage limits
    final usageService = UsageTrackingService.instance;
    if (!usageService.canUseFeature(feature)) {
      return await _showLimitReachedDialog(context, feature);
    }

    return true;
  }

  /// Show upgrade dialog for restricted features
  Future<bool> _showUpgradeDialog(
    BuildContext context,
    String feature,
    String? customMessage,
  ) async {
    bool? shouldUpgrade;

    switch (feature) {
      case 'redpingHelp':
      case 'unlimitedRedpingHelp':
        shouldUpgrade = await UpgradeRequiredDialog.showForRedpingHelp(context);
        break;
      case 'sarParticipation':
        shouldUpgrade = await UpgradeRequiredDialog.showForSARParticipation(
          context,
        );
        break;
      case 'sarVolunteerRegistration':
        shouldUpgrade =
            await UpgradeRequiredDialog.showForSARVolunteerRegistration(
              context,
            );
        break;
      case 'sarTeamManagement':
        shouldUpgrade = await UpgradeRequiredDialog.showForSARTeamManagement(
          context,
        );
        break;
      case 'satelliteComm':
        shouldUpgrade = await UpgradeRequiredDialog.showForSatelliteComm(
          context,
        );
        break;
      case 'organizationManagement':
        shouldUpgrade =
            await UpgradeRequiredDialog.showForOrganizationManagement(context);
        break;
      default:
        shouldUpgrade = await UpgradeRequiredDialog.show(
          context,
          featureName: feature,
          featureDescription:
              customMessage ??
              'This feature requires a subscription to access.',
          benefits: _getFeatureBenefits(feature),
        );
    }

    return shouldUpgrade ?? false;
  }

  /// Show limit reached dialog
  Future<bool> _showLimitReachedDialog(
    BuildContext context,
    String feature,
  ) async {
    final usageService = UsageTrackingService.instance;
    final currentUsage = usageService.getCurrentUsage(feature);
    final limit = _subscriptionService?.getFeatureLimit(feature) ?? 0;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('📊 Usage Limit Reached'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You have reached your monthly limit for $feature.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Current usage: $currentUsage'),
                Text('Monthly limit: ${limit == -1 ? 'Unlimited' : limit}'),
                const SizedBox(height: 12),
                const Text(
                  'Your usage will reset next month, or you can upgrade for higher limits.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('OK'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                  // Navigate to subscription page
                },
                child: const Text('Upgrade'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Get benefits list for a feature
  List<String> _getFeatureBenefits(String feature) {
    switch (feature) {
      case 'satelliteComm':
        return [
          'Emergency messaging in remote areas',
          'No cellular coverage required',
          'Critical for wilderness safety',
        ];
      case 'sarParticipation':
        return [
          'Join official rescue missions',
          'Professional training access',
          'Emergency response coordination',
        ];
      case 'organizationManagement':
        return [
          'Full team coordination',
          'Advanced analytics',
          'Multi-organization dashboard',
        ];
      case 'aiAssistant':
        return [
          'Personal safety guidance',
          'Smart app navigation',
          'Proactive safety alerts',
        ];
      default:
        return [
          'Enhanced safety features',
          'Priority support',
          'Advanced functionality',
        ];
    }
  }

  /// Track feature usage attempts for analytics
  void trackFeatureAttempt(String feature, bool hasAccess) {
    debugPrint(
      'FeatureAccessService: Feature attempt - $feature (access: $hasAccess)',
    );
    // In a real app, you'd send this to analytics service
  }

  /// Check if user has reached usage limit for a feature
  bool hasReachedUsageLimit(String feature) {
    if (!enforceSubscriptions) return false;
    if (!_isInitialized || _subscriptionService == null) {
      // For demo purposes, assume free users have limited usage
      switch (feature) {
        case 'redpingHelp':
          return _getFreeFeatureLimits()['redpingHelp'] == 0;
        case 'sosAlerts':
          return _getFreeFeatureLimits()['sosAlertsPerMonth'] == 0;
        default:
          return true;
      }
    }

    final subscription = _subscriptionService!.currentSubscription;

    if (subscription == null || !subscription.isActive) {
      // For demo purposes, assume free users have limited usage
      switch (feature) {
        case 'redpingHelp':
          return _getFreeFeatureLimits()['redpingHelp'] == 0;
        case 'sosAlerts':
          return _getFreeFeatureLimits()['sosAlertsPerMonth'] == 0;
        default:
          return true;
      }
    }

    // Check subscription limits
    final limits = subscription.plan.limits;
    final limit = limits[feature];

    if (limit == null || limit == -1) {
      return false; // Unlimited
    }

    // For demo, we'll assume users haven't reached their limits yet
    // In a real app, you'd track actual usage
    return false;
  }

  /// Check if a feature is SAR-related
  bool _isSARFeature(String feature) {
    const sarFeatures = {
      'sarObserver',
      'sarParticipation',
      'sarVolunteerRegistration',
      'sarTeamManagement',
      'sarMissionCoordination',
      'sarAnalytics',
      'multiTeamCoordination',
      'organizationManagement',
    };
    return sarFeatures.contains(feature);
  }

  /// Check SAR feature access based on current SAR access level
  bool _checkSARFeatureAccess(String feature) {
    if (!_isInitialized || _subscriptionService == null) {
      return false;
    }

    final subscription = _subscriptionService!.currentSubscription;

    if (subscription == null || !subscription.isActive) {
      return false;
    }

    final accessLevel = _getSARAccessLevelSync();

    switch (feature) {
      // Observer level features (Essential, Essential+)
      case 'sarObserver':
        return accessLevel != SARAccessLevel.none;

      // Participant level features (Pro, Family)
      case 'sarParticipation':
      case 'sarVolunteerRegistration':
        return accessLevel == SARAccessLevel.participant ||
            accessLevel == SARAccessLevel.coordinator;

      // Coordinator level features (Ultra)
      case 'sarTeamManagement':
      case 'sarMissionCoordination':
      case 'sarAnalytics':
      case 'multiTeamCoordination':
      case 'organizationManagement':
        return accessLevel == SARAccessLevel.coordinator;

      default:
        return false;
    }
  }

  /// Get SAR access level synchronously (for internal use)
  SARAccessLevel _getSARAccessLevelSync() {
    if (!enforceSubscriptions) return SARAccessLevel.coordinator;
    if (!_isInitialized || _subscriptionService == null) {
      return SARAccessLevel.none;
    }

    final subscription = _subscriptionService!.currentSubscription;

    if (subscription == null || !subscription.isActive) {
      return SARAccessLevel.none;
    }

    switch (subscription.plan.tier) {
      case SubscriptionTier.free:
        return SARAccessLevel.none;
      case SubscriptionTier.essentialPlus:
        return SARAccessLevel.observer;
      case SubscriptionTier.pro:
      case SubscriptionTier.family:
        return SARAccessLevel.participant;
      case SubscriptionTier.ultra:
        return SARAccessLevel.coordinator;
    }
  }
}
