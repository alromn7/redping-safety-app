import 'package:flutter/material.dart';
import 'package:redping_14v/utils/iterable_extensions.dart';
import '../models/subscription_tier.dart';
import '../models/sar_access_level.dart';
import '../widgets/upgrade_required_dialog.dart';
import 'subscription_service.dart';
import 'usage_tracking_service.dart';

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

  /// Check if user can use AI Assistant
  bool canUseAIAssistant() {
    return hasFeatureAccess('aiAssistant');
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
    if (!_isInitialized || _subscriptionService == null) {
      return false;
    }
    final subscription = _subscriptionService!.currentSubscription;
    return subscription?.isFamilyAdmin == true &&
        subscription?.plan.isFamilyPlan == true;
  }

  /// Check if user can access family dashboard
  bool canAccessFamilyDashboard() {
    if (!_isInitialized || _subscriptionService == null) {
      return false;
    }
    final subscription = _subscriptionService!.currentSubscription;
    final family = _subscriptionService!.currentFamily;
    return subscription?.familyId != null && family != null;
  }

  /// Get available features for a subscription tier
  List<String> getAvailableFeatures(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return [
          'basicCrashDetection',
          'basicFallDetection',
          'gpsLocationSharing',
          'limitedRedpingHelp', // NEW: Limited safety access
        ];
      case SubscriptionTier.essentialPlus:
        return [
          'aiVerification',
          'basicCrashDetection',
          'basicFallDetection',
          'gpsLocationSharing',
          'basicHazardAlerts',
          'communityChat',
          'basicActivityTracking',
          'sarNetworkConnection', // Observer level SAR access
          'viewSARActivities', // Can view but not participate
          'emergencyNotifications',
          'enhancedRedpingHelp', // Enhanced access
          'basicAiAssistant',
          'enhancedActivityTracking',
          'limitedCommunityParticipation',
          'prioritySarConnection', // Better SAR network access
          'satelliteStatus',
          'sarInformation', // Access to SAR educational content
          'unlimitedRedpingHelp',
        ];

      case SubscriptionTier.pro:
        return [
          ...getAvailableFeatures(SubscriptionTier.essentialPlus),
          'fullAiAssistant', // Moved from Ultra
          'advancedAnalytics', // Moved from Ultra
          'satelliteComm',
          'sarParticipation', // Full SAR participation
          'sarVolunteerRegistration', // Can register as volunteer
          'missionParticipation', // Join SAR missions
          'sarCommunication', // SAR communication channels
          'sarTeamBasics', // Basic team coordination
          'advancedAIVerification',
          'missionCoordination',
          'hazardReporting',
          'helpAssistant',
          'advancedActivityTracking',
          'fullCommunityChat',
          'gadgetIntegration', // Basic gadget integration
          'deviceManagement', // Manage connected devices
        ];

      case SubscriptionTier.ultra:
        return [
          ...getAvailableFeatures(SubscriptionTier.pro),
          'organizationManagement', // Full SAR organization management
          'sarTeamManagement', // Create and manage SAR teams
          'sarMissionCoordination', // Coordinate SAR missions
          'multiTeamCoordination', // Coordinate multiple teams
          'sarAnalytics', // Advanced SAR analytics
          'sarTraining', // Access to SAR training materials
          'teamManagement',
          'enterpriseAiAssistant',
          'enterpriseAnalytics',
          'customActivityTemplates',
          'organizationReporting',
          'emergencyBroadcast',
          'integrationApis',
          'prioritySupport',
          'gadgetIntegration', // Basic gadget integration
          'deviceManagement', // Manage connected devices
          'crossDeviceSync', // Sync across devices
        ];

      case SubscriptionTier.family:
        return [
          ...getAvailableFeatures(SubscriptionTier.pro),
          'familyDashboard',
          'familyCoordination',
          'sharedEmergencyContacts',
          'familyLocationSharing',
          'crossAccountNotifications',
          'familyChat',
          'familyActivityOverview',
          'familySARCoordination', // Family members can coordinate SAR
          'gadgetIntegration', // Basic gadget integration
          'deviceManagement', // Manage connected devices
          'familyDeviceSharing', // Share devices with family members
        ];
    }
  }

  /// Get features available without subscription (free tier)
  List<String> _getFreeFeatures() {
    return [
      'basicSOS', // Limited SOS alerts
      'basicLocationSharing',
      'emergencyContacts', // Limited count
      'basicCrashDetection',
      'basicFallDetection',
      'limitedRedpingHelp', // NEW: Limited REDP!NG Help access
      'basicCommunityChat', // Read-only community access
    ];
  }

  /// Get feature limits for free tier
  Map<String, int> _getFreeFeatureLimits() {
    return {
      'sosAlertsPerMonth': 5, // Increased for safety
      'emergencyContacts': 2,
      'satelliteMessages': 0,
      'sarParticipation': 0,
      'organizationManagement': 0,
      'aiAssistant': 0,
      'redpingHelp': 5, // 5 requests per month on free plan
      'sosTesting': 0, // No SOS testing for free users
      'medicalInfo': 0, // No medical info management for free users
      'hazardAlerts': 0, // No hazard alerts for free users
      'emergencyMessaging': 0, // No emergency messaging for free users
      'communityFeatures': 0, // No community features for free users
      'satelliteComm': 0, // No satellite communication for free users
      'sarTeamManagement': 0, // No SAR team management for free users
      'sarMissionCoordination': 0, // No SAR mission coordination for free users
      'sarAnalytics': 0, // No SAR analytics for free users
      'organizationReporting': 0, // No organization reporting for free users
      'enterpriseAiAssistant': 0, // No enterprise AI for free users
      'enterpriseAnalytics': 0, // No enterprise analytics for free users
      'familyDashboard': 0, // No family dashboard for free users
      'familyCoordination': 0, // No family coordination for free users
      'familyLocationSharing': 0, // No family location sharing for free users
      'familyChat': 0, // No family chat for free users
    };
  }

  /// Get subscription tier requirements for a feature
  SubscriptionTier? getRequiredTierForFeature(String feature) {
    if (_getFreeFeatures().contains(feature)) {
      return null; // Free feature
    }

    for (final tier in SubscriptionTier.values) {
      if (getAvailableFeatures(tier).contains(feature)) {
        return tier;
      }
    }

    return SubscriptionTier.ultra; // Default to highest tier if not found
  }

  /// Check if user needs to upgrade for a feature
  bool needsUpgradeForFeature(String feature) {
    return !hasFeatureAccess(feature);
  }

  /// Get upgrade message for a feature
  String getUpgradeMessage(String feature) {
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
      case 'aiAssistant':
      case 'basicAiAssistant':
      case 'fullAiAssistant':
        shouldUpgrade = await UpgradeRequiredDialog.showForAIAssistant(context);
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
