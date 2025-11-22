import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_user.dart'
    show
        UserSubscription,
        FamilySubscription,
        FamilySettings,
        FamilyMember,
        SubscriptionStatus,
        PaymentMethod;
import '../models/subscription_tier.dart' as sub;
import '../models/subscription_plan.dart' as sub;

/// Subscription service for managing REDP!NG subscription plans and family packages
class SubscriptionService {
  SubscriptionService._();

  static final SubscriptionService _instance = SubscriptionService._();
  static SubscriptionService get instance => _instance;

  // Stream controllers
  final StreamController<UserSubscription?> _subscriptionController =
      StreamController<UserSubscription?>.broadcast();
  final StreamController<FamilySubscription?> _familyController =
      StreamController<FamilySubscription?>.broadcast();

  // Current subscription state
  UserSubscription? _currentSubscription;
  FamilySubscription? _currentFamily;
  List<sub.SubscriptionPlan> _availablePlans = [];

  // Callbacks
  void Function(UserSubscription subscription)? _onSubscriptionChanged;
  void Function(FamilySubscription family)? _onFamilyChanged;

  // Storage keys
  static const String _subscriptionKey = 'user_subscription';
  static const String _familyKey = 'family_subscription';

  // Trial period configuration (for public trial period)
  static const int defaultTrialDays = 14; // 2 weeks free trial
  static const bool enableTrialForAllPlans =
      true; // Set to false after trial period ends

  // Getters
  UserSubscription? get currentSubscription => _currentSubscription;
  FamilySubscription? get currentFamily => _currentFamily;
  List<sub.SubscriptionPlan> get availablePlans => _availablePlans;
  Stream<UserSubscription?> get subscriptionStream =>
      _subscriptionController.stream;
  Stream<FamilySubscription?> get familyStream => _familyController.stream;

  /// Initialize the subscription service
  Future<void> initialize() async {
    try {
      debugPrint('SubscriptionService: Initializing...');

      // Load subscription data
      await _loadSubscriptionData();

      // Initialize default plans
      await _initializeDefaultPlans();

      // Ensure user has at least a free subscription for testing
      if (_currentSubscription == null) {
        await _createDefaultFreeSubscription();
      }

      // Initialize usage tracking service
      await _initializeUsageTracking();

      debugPrint('SubscriptionService: Initialized successfully');
    } catch (e) {
      debugPrint('SubscriptionService: Initialization error - $e');
    }
  }

  /// Initialize usage tracking service
  Future<void> _initializeUsageTracking() async {
    try {
      // Usage tracking will be initialized separately in app service manager
      debugPrint(
        'SubscriptionService: Usage tracking will be initialized by app service manager',
      );
    } catch (e) {
      debugPrint(
        'SubscriptionService: Usage tracking initialization error - $e',
      );
    }
  }

  /// Load subscription data from storage
  Future<void> _loadSubscriptionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load current subscription
      final subscriptionJson = prefs.getString(_subscriptionKey);
      if (subscriptionJson != null) {
        final data = jsonDecode(subscriptionJson);
        _currentSubscription = _parseUserSubscription(data);
        _subscriptionController.add(_currentSubscription);
      }

      // Load family subscription
      final familyJson = prefs.getString(_familyKey);
      if (familyJson != null) {
        final data = jsonDecode(familyJson);
        _currentFamily = _parseFamilySubscription(data);
        _familyController.add(_currentFamily);
      }

      debugPrint(
        'SubscriptionService: Data loaded - Subscription: ${_currentSubscription?.plan.name}, Family: ${_currentFamily?.familyName}',
      );
    } catch (e) {
      debugPrint('SubscriptionService: Error loading data - $e');
    }
  }

  /// Initialize default subscription plans
  Future<void> _initializeDefaultPlans() async {
    _availablePlans = [
      // Free Plan - RedPing 1-Tap Help All Categories + Community + Quick Call + Map
      sub.SubscriptionPlan(
        id: 'free_plan',
        name: 'Free',
        tier: sub.SubscriptionTier.free,
        monthlyPrice: 0.0,
        yearlyPrice: 0.0,
        description:
            'Essential Safety Features - RedPing Help, Community, Quick Call & Maps',
        features: [
          'RedPing 1-Tap Help (All Categories)',
          'Community Chat (Full Participation)',
          'Quick Call - Emergency Services',
          'Map Access with Real-Time Location',
          'Standard Profile',
          'Manual SOS Activation',
          '2 Emergency Contacts',
          'Basic Location Sharing',
        ],
        limits: {
          'sosAlertsPerMonth': -1, // Unlimited
          'emergencyContacts': 2,
          'redpingHelp': -1, // Unlimited - all categories
          'communityChat': -1, // Full access
          'quickCall': true,
          'mapAccess': true,
          'medicalProfile': false,
          'acfd': false, // No Auto Crash/Fall Detection
          'redpingMode': false,
          'hazardAlerts': false,
          'aiSafetyAssistant': false,
          'sosSMS': false,
          'gadgetIntegration': false,
          'sarDashboardWrite': false, // Can view only
          'sarAdminAccess': false,
          'satelliteMessages': 0,
          'sarParticipation': false,
          'organizationManagement': false,
        },
        durationDays: 365,
      ),
      // Essential+ Plan - $4.99 - Adds Medical + ACFD + Hazard + SMS
      sub.SubscriptionPlan(
        id: 'essential_plus_plan',
        name: 'Essential+',
        tier: sub.SubscriptionTier.essentialPlus,
        monthlyPrice: 4.99,
        yearlyPrice: 59.88,
        description: 'Automatic Detection with Medical Profile & Hazard Alerts',
        features: [
          'Everything in Free',
          'Profile + Medical Information',
          'Auto Crash Detection (ACFD)',
          'Auto Fall Detection (ACFD)',
          'Manual SOS Override',
          'AI Verification System',
          'Hazard Alerts (Weather, Natural Disasters)',
          'SOS SMS Alerts to Contacts',
          'Emergency Contacts (up to 5)',
          'Enhanced Location Tracking',
          'SAR Dashboard (View Only)',
        ],
        limits: {
          'sosAlertsPerMonth': -1, // Unlimited
          'emergencyContacts': 5,
          'redpingHelp': -1, // Unlimited - all categories
          'communityChat': -1, // Full access
          'quickCall': true,
          'mapAccess': true,
          'medicalProfile': true,
          'acfd': true, // Auto + Manual
          'redpingMode': false,
          'hazardAlerts': true,
          'aiSafetyAssistant': false,
          'sosSMS': true,
          'gadgetIntegration': false,
          'sarDashboardWrite': false, // Can view only
          'sarAdminAccess': false,
          'satelliteMessages': 5,
          'sarParticipation': false,
          'organizationManagement': false,
        },
      ),

      // Pro Plan - $9.99 - Adds RedPing Mode + AI + Gadgets + Full SAR Dashboard
      sub.SubscriptionPlan(
        id: 'pro_plan',
        name: 'RedPing Pro',
        tier: sub.SubscriptionTier.pro,
        monthlyPrice: 9.99,
        yearlyPrice: 119.88,
        description:
            'Professional Safety with AI Assistant, Activity Modes & Full SAR Access',
        features: [
          'Everything in Essential+',
          'Profile Pro + Medical',
          'RedPing Mode (All Activity Modes)',
          'AI Safety Assistant (24 Commands)',
          'Gadget Integration (Smartwatch, Car, IoT)',
          'Full SAR Dashboard Access',
          'SAR Volunteer Registration',
          'Unlimited Emergency Contacts',
          'Advanced Analytics & Risk Assessment',
          'Satellite Communication (100/month)',
          'Priority Response Queue',
          'Mission Participation & Coordination',
          'Cross-Device Sync',
        ],
        limits: {
          'sosAlertsPerMonth': -1, // Unlimited
          'emergencyContacts': -1, // Unlimited
          'redpingHelp': -1, // Unlimited - all categories
          'communityChat': -1, // Full access
          'quickCall': true,
          'mapAccess': true,
          'medicalProfile': true,
          'acfd': true,
          'redpingMode': true, // All modes
          'hazardAlerts': true,
          'aiSafetyAssistant': true, // 24 commands
          'sosSMS': true,
          'gadgetIntegration': true, // All devices
          'sarDashboardWrite': true, // Full access
          'sarAdminAccess': false,
          'satelliteMessages': 100,
          'sarParticipation': true,
          'organizationManagement': false,
        },
      ),

      // Ultra Plan - $29.99 + $5/member - Full Admin + Organization Management
      sub.SubscriptionPlan(
        id: 'ultra_plan',
        name: 'RedPing Ultra',
        tier: sub.SubscriptionTier.ultra,
        monthlyPrice: 29.99,
        yearlyPrice: 359.88,
        description:
            'Enterprise-Grade SAR Organization Management + \$5 per additional Pro member',
        features: [
          'Everything in Pro',
          'SAR Admin Management (Full)',
          'Organization Creation & Management',
          'Unlimited Team Management',
          'Member Role Assignment & Permissions',
          'Team Performance Analytics',
          'Multi-Organization Dashboard',
          'Cross-Team Coordination',
          'Resource & Equipment Management',
          'Compliance & Regulatory Tools',
          'Training Program Management',
          'Priority Satellite (Unlimited)',
          'Emergency Broadcast System',
          'Enterprise Analytics & Reporting',
          'Custom Activity Templates',
          'Integration APIs',
          'Priority Support & Training',
          'White-Label Options (Enterprise)',
        ],
        limits: {
          'sosAlertsPerMonth': -1, // Unlimited
          'emergencyContacts': -1, // Unlimited
          'redpingHelp': -1, // Unlimited
          'communityChat': -1, // Full access
          'quickCall': true,
          'mapAccess': true,
          'medicalProfile': true,
          'acfd': true,
          'redpingMode': true,
          'hazardAlerts': true,
          'aiSafetyAssistant': true,
          'sosSMS': true,
          'gadgetIntegration': true,
          'sarDashboardWrite': true,
          'sarAdminAccess': true, // Full admin
          'satelliteMessages': -1, // Unlimited
          'sarParticipation': true,
          'organizationManagement': true,
          'additionalMemberCost': 5.00, // $5 per Pro member
        },
      ),

      // Family Plan - $19.99 - 1 Pro Account + 3 Essential+ Accounts
      sub.SubscriptionPlan(
        id: 'family_plan',
        name: 'Family Package',
        tier: sub.SubscriptionTier.family,
        monthlyPrice: 19.99,
        yearlyPrice: 239.88,
        description:
            'Best Value: 1 Pro + 3 Essential+ Accounts (\$5 per account)',
        features: [
          '1 Pro Account (Full Features)',
          '3 Essential+ Accounts',
          'Total: 4 Accounts Included',
          'Family Dashboard with Real-Time Monitoring',
          'Shared Emergency Contacts (Unlimited)',
          'Family Location Sharing (All Members)',
          'Cross-Account Notifications',
          'Family Chat Channel (Private)',
          'Coordinated SAR Response',
          'Family Activity Overview',
          'Unified Safety Status Dashboard',
          'Family AI Assistant (Pro Account)',
          'Best Value: \$5 per account vs \$9.99 individual',
        ],
        limits: {
          'sosAlertsPerMonth': -1, // Unlimited for family
          'emergencyContacts': -1, // Shared across family
          'redpingHelp': -1, // Unlimited across family
          'communityChat': -1, // Full access
          'quickCall': true,
          'mapAccess': true,
          'medicalProfile': true, // All accounts
          'acfd': true, // All accounts
          'redpingMode': true, // Pro account only
          'hazardAlerts': true, // All accounts
          'aiSafetyAssistant': true, // Pro account only
          'sosSMS': true, // All accounts
          'gadgetIntegration': true, // Pro account only
          'sarDashboardWrite': true, // Pro account, Essential+ view only
          'sarAdminAccess': false,
          'satelliteMessages': 150, // Pooled for family
          'sarParticipation': true, // Pro account
          'organizationManagement': false,
          'aiAssistant': 'family', // Family-focused AI features
        },
        maxFamilyMembers: 5,
        essentialAccounts: 0, // Upgraded
        essentialPlusAccounts: 3, // New tier
        proAccounts: 2, // Enhanced
        ultraAccounts: 0,
      ),
    ];

    debugPrint(
      'SubscriptionService: Initialized ${_availablePlans.length} plans',
    );
  }

  /// Create a default free subscription for new users
  Future<void> _createDefaultFreeSubscription() async {
    try {
      final freePlan = getPlanByTier(sub.SubscriptionTier.free);
      if (freePlan == null) {
        debugPrint('SubscriptionService: Free plan not found');
        return;
      }

      final freeSubscription = UserSubscription(
        id: 'free_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'default_user',
        plan: freePlan,
        startDate: DateTime.now(),
        status: SubscriptionStatus.active,
        paymentMethod:
            PaymentMethod.creditCard, // Default for free subscription
        isYearlyBilling: false,
        autoRenew: false,
      );

      await _saveSubscription(freeSubscription);
      _currentSubscription = freeSubscription;
      _subscriptionController.add(_currentSubscription);

      debugPrint('SubscriptionService: Created default free subscription');
    } catch (e) {
      debugPrint('SubscriptionService: Error creating free subscription - $e');
    }
  }

  /// Get subscription plan by tier
  sub.SubscriptionPlan? getPlanByTier(sub.SubscriptionTier tier) {
    try {
      return _availablePlans.firstWhere((plan) => plan.tier == tier);
    } catch (e) {
      return null;
    }
  }

  /// Get family plan
  sub.SubscriptionPlan get familyPlan {
    return _availablePlans.firstWhere(
      (plan) => plan.tier == sub.SubscriptionTier.family,
    );
  }

  /// Subscribe to a plan
  Future<UserSubscription> subscribeToPlan({
    required String userId,
    required sub.SubscriptionTier tier,
    required PaymentMethod paymentMethod,
    bool isYearlyBilling = false,
    int? trialDays, // Optional: Override default trial period
    bool skipTrial = false, // Optional: Skip trial for returning customers
  }) async {
    try {
      final plan = getPlanByTier(tier);
      if (plan == null) {
        throw Exception('Plan not found for tier: $tier');
      }

      // Determine if this subscription gets a trial period
      final shouldHaveTrial =
          !skipTrial &&
          enableTrialForAllPlans &&
          tier != sub.SubscriptionTier.free;
      final effectiveTrialDays = shouldHaveTrial
          ? (trialDays ?? defaultTrialDays)
          : 0;
      final now = DateTime.now();
      final trialEnd = shouldHaveTrial
          ? now.add(Duration(days: effectiveTrialDays))
          : null;

      // First billing happens after trial ends (or immediately if no trial)
      final firstBillingDate =
          trialEnd ??
          now.add(
            isYearlyBilling
                ? const Duration(days: 365)
                : const Duration(days: 30),
          );

      final subscription = UserSubscription(
        id: 'sub_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}',
        userId: userId,
        plan: plan,
        startDate: now,
        status: SubscriptionStatus.active,
        paymentMethod: paymentMethod,
        isYearlyBilling: isYearlyBilling,
        nextBillingDate: firstBillingDate,
        isTrialPeriod: shouldHaveTrial,
        trialEndDate: trialEnd,
        trialDays: effectiveTrialDays,
      );

      await _saveSubscription(subscription);
      _currentSubscription = subscription;
      _subscriptionController.add(_currentSubscription);
      _onSubscriptionChanged?.call(subscription);

      debugPrint('SubscriptionService: Subscribed to ${plan.name} plan');
      return subscription;
    } catch (e) {
      debugPrint('SubscriptionService: Error subscribing - $e');
      rethrow;
    }
  }

  /// Create family subscription
  Future<FamilySubscription> createFamilySubscription({
    required String adminUserId,
    required PaymentMethod paymentMethod,
    String? familyName,
    bool isYearlyBilling = false,
    int? trialDays, // Optional: Override default trial period
    bool skipTrial = false, // Optional: Skip trial for returning customers
  }) async {
    try {
      final familyPlan = this.familyPlan;

      // Determine if family subscription gets trial period
      final shouldHaveTrial = !skipTrial && enableTrialForAllPlans;
      final effectiveTrialDays = shouldHaveTrial
          ? (trialDays ?? defaultTrialDays)
          : 0;
      final now = DateTime.now();
      final trialEnd = shouldHaveTrial
          ? now.add(Duration(days: effectiveTrialDays))
          : null;

      // First billing happens after trial ends (or immediately if no trial)
      final firstBillingDate =
          trialEnd ??
          now.add(
            isYearlyBilling
                ? const Duration(days: 365)
                : const Duration(days: 30),
          );

      final family = FamilySubscription(
        id: 'family_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}',
        adminUserId: adminUserId,
        plan: familyPlan,
        members: [],
        settings: const FamilySettings(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        familyName: familyName,
      );

      // Create admin's subscription
      final adminSubscription = UserSubscription(
        id: 'sub_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}',
        userId: adminUserId,
        plan: familyPlan,
        startDate: now,
        status: SubscriptionStatus.active,
        paymentMethod: paymentMethod,
        familyId: family.id,
        isFamilyAdmin: true,
        isTrialPeriod: shouldHaveTrial,
        trialEndDate: trialEnd,
        trialDays: effectiveTrialDays,
        nextBillingDate: firstBillingDate,
        isYearlyBilling: isYearlyBilling,
      );

      await _saveSubscription(adminSubscription);
      await _saveFamilySubscription(family);

      _currentSubscription = adminSubscription;
      _currentFamily = family;

      _subscriptionController.add(_currentSubscription);
      _familyController.add(_currentFamily);

      _onSubscriptionChanged?.call(adminSubscription);
      _onFamilyChanged?.call(family);

      debugPrint('SubscriptionService: Created family subscription');
      return family;
    } catch (e) {
      debugPrint(
        'SubscriptionService: Error creating family subscription - $e',
      );
      rethrow;
    }
  }

  /// Add family member
  Future<void> addFamilyMember({
    required String familyId,
    required String userId,
    required String name,
    required sub.SubscriptionTier assignedTier,
    String? email,
    String? relationship,
  }) async {
    try {
      if (_currentFamily?.id != familyId) {
        throw Exception('Family not found or not authorized');
      }

      if (!_currentFamily!.hasAvailableSlots(assignedTier)) {
        throw Exception('No available slots for $assignedTier tier');
      }

      final member = FamilyMember(
        id: 'member_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}',
        userId: userId,
        name: name,
        email: email,
        relationship: relationship,
        assignedTier: assignedTier,
        addedDate: DateTime.now(),
      );

      final updatedFamily = FamilySubscription(
        id: _currentFamily!.id,
        adminUserId: _currentFamily!.adminUserId,
        plan: _currentFamily!.plan,
        members: [..._currentFamily!.members, member],
        settings: _currentFamily!.settings,
        createdAt: _currentFamily!.createdAt,
        updatedAt: DateTime.now(),
        sharedContacts: _currentFamily!.sharedContacts,
        familyName: _currentFamily!.familyName,
      );

      // Create member's subscription
      final memberPlan = getPlanByTier(assignedTier);
      if (memberPlan != null) {
        final memberSubscription = UserSubscription(
          id: 'sub_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}',
          userId: userId,
          plan: memberPlan,
          startDate: DateTime.now(),
          status: SubscriptionStatus.active,
          paymentMethod: _currentSubscription!.paymentMethod,
          familyId: familyId,
          isYearlyBilling: _currentSubscription!.isYearlyBilling,
        );

        await _saveSubscription(memberSubscription);
      }

      await _saveFamilySubscription(updatedFamily);
      _currentFamily = updatedFamily;
      _familyController.add(_currentFamily);
      _onFamilyChanged?.call(updatedFamily);

      debugPrint(
        'SubscriptionService: Added family member - $name ($assignedTier)',
      );
    } catch (e) {
      debugPrint('SubscriptionService: Error adding family member - $e');
      rethrow;
    }
  }

  /// Remove family member
  Future<void> removeFamilyMember(String memberId) async {
    try {
      if (_currentFamily == null) {
        throw Exception('No family subscription found');
      }

      final updatedMembers = _currentFamily!.members
          .where((member) => member.id != memberId)
          .toList();

      final updatedFamily = FamilySubscription(
        id: _currentFamily!.id,
        adminUserId: _currentFamily!.adminUserId,
        plan: _currentFamily!.plan,
        members: updatedMembers,
        settings: _currentFamily!.settings,
        createdAt: _currentFamily!.createdAt,
        updatedAt: DateTime.now(),
        sharedContacts: _currentFamily!.sharedContacts,
        familyName: _currentFamily!.familyName,
      );

      await _saveFamilySubscription(updatedFamily);
      _currentFamily = updatedFamily;
      _familyController.add(_currentFamily);
      _onFamilyChanged?.call(updatedFamily);

      debugPrint('SubscriptionService: Removed family member - $memberId');
    } catch (e) {
      debugPrint('SubscriptionService: Error removing family member - $e');
      rethrow;
    }
  }

  /// Update family settings
  Future<void> updateFamilySettings(FamilySettings settings) async {
    try {
      if (_currentFamily == null) {
        throw Exception('No family subscription found');
      }

      final updatedFamily = FamilySubscription(
        id: _currentFamily!.id,
        adminUserId: _currentFamily!.adminUserId,
        plan: _currentFamily!.plan,
        members: _currentFamily!.members,
        settings: settings,
        createdAt: _currentFamily!.createdAt,
        updatedAt: DateTime.now(),
        sharedContacts: _currentFamily!.sharedContacts,
        familyName: _currentFamily!.familyName,
      );

      await _saveFamilySubscription(updatedFamily);
      _currentFamily = updatedFamily;
      _familyController.add(_currentFamily);
      _onFamilyChanged?.call(updatedFamily);

      debugPrint('SubscriptionService: Updated family settings');
    } catch (e) {
      debugPrint('SubscriptionService: Error updating family settings - $e');
      rethrow;
    }
  }

  /// Check feature access based on subscription
  bool hasFeatureAccess(String feature) {
    if (_currentSubscription == null || !_currentSubscription!.isActive) {
      return false;
    }

    final limits = _currentSubscription!.plan.limits;

    switch (feature) {
      case 'aiVerification':
        return true; // All plans include AI verification
      case 'satelliteComm':
        return limits['satelliteMessages'] != 0;
      case 'sarParticipation':
        return limits['sarParticipation'] == true;
      case 'organizationManagement':
        return limits['organizationManagement'] == true;
      case 'aiAssistant':
        return limits['aiAssistant'] == true;
      case 'unlimitedSOS':
        return limits['sosAlertsPerMonth'] == -1;
      default:
        return false;
    }
  }

  /// Get feature limit
  int getFeatureLimit(String feature) {
    if (_currentSubscription == null || !_currentSubscription!.isActive) {
      return 0;
    }

    final limits = _currentSubscription!.plan.limits;
    return limits[feature] ?? 0;
  }

  /// Cancel subscription
  Future<void> cancelSubscription() async {
    try {
      if (_currentSubscription == null) {
        throw Exception('No active subscription found');
      }

      final cancelledSubscription = UserSubscription(
        id: _currentSubscription!.id,
        userId: _currentSubscription!.userId,
        plan: _currentSubscription!.plan,
        startDate: _currentSubscription!.startDate,
        endDate: _currentSubscription!.nextBillingDate,
        status: SubscriptionStatus.cancelled,
        paymentMethod: _currentSubscription!.paymentMethod,
        familyId: _currentSubscription!.familyId,
        isFamilyAdmin: _currentSubscription!.isFamilyAdmin,
        familyMembers: _currentSubscription!.familyMembers,
        isYearlyBilling: _currentSubscription!.isYearlyBilling,
        nextBillingDate: _currentSubscription!.nextBillingDate,
        autoRenew: false,
      );

      await _saveSubscription(cancelledSubscription);
      _currentSubscription = cancelledSubscription;
      _subscriptionController.add(_currentSubscription);
      _onSubscriptionChanged?.call(cancelledSubscription);

      debugPrint('SubscriptionService: Subscription cancelled');
    } catch (e) {
      debugPrint('SubscriptionService: Error cancelling subscription - $e');
      rethrow;
    }
  }

  /// Upgrade subscription
  Future<UserSubscription> upgradeSubscription({
    required sub.SubscriptionTier newTier,
    bool isYearlyBilling = false,
  }) async {
    try {
      if (_currentSubscription == null) {
        throw Exception('No active subscription found');
      }

      final newPlan = getPlanByTier(newTier);
      if (newPlan == null) {
        throw Exception('Plan not found for tier: $newTier');
      }

      final upgradedSubscription = UserSubscription(
        id: _currentSubscription!.id,
        userId: _currentSubscription!.userId,
        plan: newPlan,
        startDate: _currentSubscription!.startDate,
        status: SubscriptionStatus.active,
        paymentMethod: _currentSubscription!.paymentMethod,
        familyId: _currentSubscription!.familyId,
        isFamilyAdmin: _currentSubscription!.isFamilyAdmin,
        familyMembers: _currentSubscription!.familyMembers,
        isYearlyBilling: isYearlyBilling,
        nextBillingDate: DateTime.now().add(
          isYearlyBilling
              ? const Duration(days: 365)
              : const Duration(days: 30),
        ),
        autoRenew: _currentSubscription!.autoRenew,
      );

      await _saveSubscription(upgradedSubscription);
      _currentSubscription = upgradedSubscription;
      _subscriptionController.add(_currentSubscription);
      _onSubscriptionChanged?.call(upgradedSubscription);

      debugPrint('SubscriptionService: Upgraded to ${newPlan.name}');
      return upgradedSubscription;
    } catch (e) {
      debugPrint('SubscriptionService: Error upgrading subscription - $e');
      rethrow;
    }
  }

  /// Get subscription comparison data
  Map<String, dynamic> getSubscriptionComparison() {
    return {
      'plans': _availablePlans
          .map(
            (sub.SubscriptionPlan plan) => {
              'tier': plan.tier.name,
              'name': plan.name,
              'monthlyPrice': plan.monthlyPrice,
              'yearlyPrice': plan.yearlyPrice,
              'yearlySavings': plan.yearlySavingsPercent.toStringAsFixed(0),
              'features': plan.features,
              'limits': plan.limits,
              'isFamilyPlan': plan.isFamilyPlan,
              'familyAccounts': plan.isFamilyPlan
                  ? {
                      'essential': plan.essentialAccounts,
                      'pro': plan.proAccounts,
                      'ultra': plan.ultraAccounts,
                    }
                  : null,
            },
          )
          .toList(),
      'familyValue': {
        'individualCost': 4.99 * 4 + 14.99, // 4 Essential + 1 Pro
        'familyCost': 19.99,
        'monthlySavings': (4.99 * 4 + 14.99) - 19.99,
        'savingsPercent':
            (((4.99 * 4 + 14.99) - 19.99) / (4.99 * 4 + 14.99) * 100)
                .toStringAsFixed(0),
      },
    };
  }

  /// Set callbacks
  void setSubscriptionChangedCallback(
    void Function(UserSubscription) callback,
  ) {
    _onSubscriptionChanged = callback;
  }

  void setFamilyChangedCallback(void Function(FamilySubscription) callback) {
    _onFamilyChanged = callback;
  }

  /// Save subscription to storage
  Future<void> _saveSubscription(UserSubscription subscription) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _userSubscriptionToJson(subscription);
      await prefs.setString(_subscriptionKey, jsonEncode(data));
    } catch (e) {
      debugPrint('SubscriptionService: Error saving subscription - $e');
    }
  }

  /// Save family subscription to storage
  Future<void> _saveFamilySubscription(FamilySubscription family) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = _familySubscriptionToJson(family);
      await prefs.setString(_familyKey, jsonEncode(data));
    } catch (e) {
      debugPrint('SubscriptionService: Error saving family subscription - $e');
    }
  }

  /// Parse user subscription from JSON
  UserSubscription _parseUserSubscription(Map<String, dynamic> data) {
    return UserSubscription(
      id: data['id'],
      userId: data['userId'],
      plan: _parseSubscriptionPlan(data['plan']),
      startDate: DateTime.parse(data['startDate']),
      endDate: data['endDate'] != null ? DateTime.parse(data['endDate']) : null,
      status: SubscriptionStatus.values.byName(data['status']),
      paymentMethod: PaymentMethod.values.byName(data['paymentMethod']),
      familyId: data['familyId'],
      isFamilyAdmin: data['isFamilyAdmin'] ?? false,
      familyMembers:
          (data['familyMembers'] as List?)
              ?.map((m) => _parseFamilyMember(m))
              .toList() ??
          [],
      isYearlyBilling: data['isYearlyBilling'] ?? false,
      nextBillingDate: data['nextBillingDate'] != null
          ? DateTime.parse(data['nextBillingDate'])
          : null,
      autoRenew: data['autoRenew'] ?? true,
      isTrialPeriod: data['isTrialPeriod'] ?? false,
      trialEndDate: data['trialEndDate'] != null
          ? DateTime.parse(data['trialEndDate'])
          : null,
      trialDays: data['trialDays'] ?? 0,
    );
  }

  /// Parse family subscription from JSON
  FamilySubscription _parseFamilySubscription(Map<String, dynamic> data) {
    return FamilySubscription(
      id: data['id'],
      adminUserId: data['adminUserId'],
      plan: _parseSubscriptionPlan(data['plan']),
      members: (data['members'] as List)
          .map((m) => _parseFamilyMember(m))
          .toList(),
      settings: _parseFamilySettings(data['settings']),
      createdAt: DateTime.parse(data['createdAt']),
      updatedAt: DateTime.parse(data['updatedAt']),
      sharedContacts: List<String>.from(data['sharedContacts'] ?? []),
      familyName: data['familyName'],
    );
  }

  /// Parse subscription plan from JSON
  sub.SubscriptionPlan _parseSubscriptionPlan(Map<String, dynamic> data) {
    return sub.SubscriptionPlan(
      id: data['id'],
      name: data['name'],
      tier: sub.SubscriptionTier.values.byName(data['tier']),
      monthlyPrice: (data['monthlyPrice'] as num).toDouble(),
      yearlyPrice: (data['yearlyPrice'] as num).toDouble(),
      description: data['description'],
      features: List<String>.from(data['features'] ?? []),
      limits: Map<String, dynamic>.from(data['limits'] ?? {}),
      maxFamilyMembers: data['maxFamilyMembers'],
      essentialAccounts: data['essentialAccounts'],
      proAccounts: data['proAccounts'],
      ultraAccounts: data['ultraAccounts'],
      isActive: data['isActive'] ?? true,
    );
  }

  /// Parse family member from JSON
  FamilyMember _parseFamilyMember(Map<String, dynamic> data) {
    return FamilyMember(
      id: data['id'],
      userId: data['userId'],
      name: data['name'],
      email: data['email'],
      relationship: data['relationship'],
      assignedTier: sub.SubscriptionTier.values.byName(data['assignedTier']),
      addedDate: DateTime.parse(data['addedDate']),
      isActive: data['isActive'] ?? true,
    );
  }

  /// Parse family settings from JSON
  FamilySettings _parseFamilySettings(Map<String, dynamic> data) {
    return FamilySettings(
      allowLocationSharing: data['allowLocationSharing'] ?? true,
      allowCrossAccountNotifications:
          data['allowCrossAccountNotifications'] ?? true,
      allowSharedEmergencyContacts:
          data['allowSharedEmergencyContacts'] ?? true,
      allowActivitySharing: data['allowActivitySharing'] ?? true,
      familyChatEnabled: data['familyChatEnabled'] ?? true,
      parentalControls: data['parentalControls'] ?? false,
      emergencyOverride: data['emergencyOverride'] ?? true,
    );
  }

  /// Convert user subscription to JSON
  Map<String, dynamic> _userSubscriptionToJson(UserSubscription subscription) {
    return {
      'id': subscription.id,
      'userId': subscription.userId,
      'plan': _subscriptionPlanToJson(subscription.plan),
      'startDate': subscription.startDate.toIso8601String(),
      'endDate': subscription.endDate?.toIso8601String(),
      'status': subscription.status.name,
      'paymentMethod': subscription.paymentMethod.name,
      'familyId': subscription.familyId,
      'isFamilyAdmin': subscription.isFamilyAdmin,
      'familyMembers': subscription.familyMembers
          .map((m) => _familyMemberToJson(m))
          .toList(),
      'isYearlyBilling': subscription.isYearlyBilling,
      'nextBillingDate': subscription.nextBillingDate?.toIso8601String(),
      'autoRenew': subscription.autoRenew,
      'isTrialPeriod': subscription.isTrialPeriod,
      'trialEndDate': subscription.trialEndDate?.toIso8601String(),
      'trialDays': subscription.trialDays,
    };
  }

  /// Convert family subscription to JSON
  Map<String, dynamic> _familySubscriptionToJson(FamilySubscription family) {
    return {
      'id': family.id,
      'adminUserId': family.adminUserId,
      'plan': _subscriptionPlanToJson(family.plan),
      'members': family.members.map((m) => _familyMemberToJson(m)).toList(),
      'settings': _familySettingsToJson(family.settings),
      'createdAt': family.createdAt.toIso8601String(),
      'updatedAt': family.updatedAt.toIso8601String(),
      'sharedContacts': family.sharedContacts,
      'familyName': family.familyName,
    };
  }

  /// Convert subscription plan to JSON
  Map<String, dynamic> _subscriptionPlanToJson(sub.SubscriptionPlan plan) {
    return {
      'id': plan.id,
      'name': plan.name,
      'tier': plan.tier.name,
      'monthlyPrice': plan.monthlyPrice,
      'yearlyPrice': plan.yearlyPrice,
      'description': plan.description,
      'features': plan.features,
      'limits': plan.limits,
      'maxFamilyMembers': plan.maxFamilyMembers,
      'essentialAccounts': plan.essentialAccounts,
      'proAccounts': plan.proAccounts,
      'ultraAccounts': plan.ultraAccounts,
      'isActive': plan.isActive,
    };
  }

  /// Convert family member to JSON
  Map<String, dynamic> _familyMemberToJson(FamilyMember member) {
    return {
      'id': member.id,
      'userId': member.userId,
      'name': member.name,
      'email': member.email,
      'relationship': member.relationship,
      'assignedTier': member.assignedTier.name,
      'addedDate': member.addedDate.toIso8601String(),
      'isActive': member.isActive,
    };
  }

  /// Convert family settings to JSON
  Map<String, dynamic> _familySettingsToJson(FamilySettings settings) {
    return {
      'allowLocationSharing': settings.allowLocationSharing,
      'allowCrossAccountNotifications': settings.allowCrossAccountNotifications,
      'allowSharedEmergencyContacts': settings.allowSharedEmergencyContacts,
      'allowActivitySharing': settings.allowActivitySharing,
      'familyChatEnabled': settings.familyChatEnabled,
      'parentalControls': settings.parentalControls,
      'emergencyOverride': settings.emergencyOverride,
    };
  }

  /// Dispose of resources
  void dispose() {
    _subscriptionController.close();
    _familyController.close();
  }
}
