import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/app/app_launch_config.dart';
import '../../../../models/auth_user.dart';
import '../../../../models/subscription_tier.dart';
import '../../../../models/subscription_plan.dart';
import '../../../../services/subscription_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/subscription_plan_card.dart';
import '../widgets/family_value_card.dart';
import '../widgets/feature_comparison_table.dart';
import '../widgets/tier_benefits_quick_ref.dart';

class SubscriptionPlansPage extends StatefulWidget {
  const SubscriptionPlansPage({super.key});

  @override
  State<SubscriptionPlansPage> createState() => _SubscriptionPlansPageState();
}

class _SubscriptionPlansPageState extends State<SubscriptionPlansPage>
    with TickerProviderStateMixin {
  late final SubscriptionService _subscriptionService;
  late final TabController _tabController;

  List<SubscriptionPlan> _plans = [];
  UserSubscription? _currentSubscription;
  bool _isLoading = true;
  bool _isYearlyBilling = false;

  @override
  void initState() {
    super.initState();
    _subscriptionService = SubscriptionService.instance;
    _tabController = TabController(length: 2, vsync: this);
    _initializeSubscriptionData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeSubscriptionData() async {
    try {
      await _subscriptionService.initialize();

      setState(() {
        _plans = _subscriptionService.availablePlans;
        _currentSubscription = _subscriptionService.currentSubscription;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('SubscriptionPlansPage: Error initializing - $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _subscribeToPlan(SubscriptionTier tier) async {
    // Navigate to payment page
    context.push(
      '/subscription/payment',
      extra: {'tier': tier, 'isYearlyBilling': _isYearlyBilling},
    );
  }

  Future<void> _createFamilySubscription() async {
    // Navigate to payment page for family plan
    context.push(
      '/subscription/payment',
      extra: {
        'tier': SubscriptionTier.family,
        'isYearlyBilling': _isYearlyBilling,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('REDP!NG Subscription Plans'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go(AppLaunchConfig.homeRoute);
            }
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Individual Plans'),
            Tab(icon: Icon(Icons.family_restroom), text: 'Family Package'),
          ],
        ),
        actions: [
          // Billing toggle
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Monthly',
                  style: TextStyle(
                    fontSize: 12,
                    color: !_isYearlyBilling ? AppTheme.infoBlue : Colors.grey,
                    fontWeight: !_isYearlyBilling
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                Switch(
                  value: _isYearlyBilling,
                  onChanged: (value) {
                    setState(() => _isYearlyBilling = value);
                  },
                  activeThumbColor: AppTheme.safeGreen,
                ),
                Text(
                  'Yearly',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isYearlyBilling ? AppTheme.infoBlue : Colors.grey,
                    fontWeight: _isYearlyBilling
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildIndividualPlansTab(), _buildFamilyPackageTab()],
            ),
    );
  }

  Widget _buildIndividualPlansTab() {
    final individualPlans = _plans
        .where((plan) => plan.tier != SubscriptionTier.family)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current subscription status
          if (_currentSubscription != null) ...[
            Card(
              color: AppTheme.safeGreen.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.safeGreen),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Plan: ${_currentSubscription!.plan.name}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Connected to SAR Network',
                            style: TextStyle(
                              color: AppTheme.secondaryText,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // SAR Network Notice
          Card(
            color: AppTheme.infoBlue.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.infoBlue),
                      SizedBox(width: 8),
                      Text(
                        'SAR Network Connection',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All REDP!NG users connect to the same SAR (Search & Rescue) network. '
                    'Subscription tiers unlock app features, not rescue priority. '
                    'Emergency response comes from existing volunteer SAR teams and professional rescue services.',
                    style: TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Individual plans
          ...individualPlans.map(
            (plan) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: SubscriptionPlanCard(
                    plan: plan,
                    isYearlyBilling: _isYearlyBilling,
                    isCurrentPlan: _currentSubscription?.plan.id == plan.id,
                    onSubscribe: () => _subscribeToPlan(plan.tier),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Quick reference guide
          const TierBenefitsQuickRef(),

          const SizedBox(height: 32),

          // Feature comparison table
          const FeatureComparisonTable(),
        ],
      ),
    );
  }

  Widget _buildFamilyPackageTab() {
    final familyPlan = _plans.firstWhere(
      (plan) => plan.tier == SubscriptionTier.family,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Family value proposition
          FamilyValueCard(plan: familyPlan, isYearlyBilling: _isYearlyBilling),
          const SizedBox(height: 24),

          // Family plan details
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: SubscriptionPlanCard(
                plan: familyPlan,
                isYearlyBilling: _isYearlyBilling,
                isCurrentPlan: _currentSubscription?.plan.id == familyPlan.id,
                onSubscribe: _createFamilySubscription,
                isFamilyPlan: true,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Family features breakdown
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Family Package Includes:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),

                  // Account breakdown
                  _buildAccountBreakdown(
                    '3× Essential+ Accounts',
                    'Perfect for children, teenagers, elderly parents',
                    Icons.shield_outlined,
                    AppTheme.successGreen,
                  ),
                  const SizedBox(height: 12),
                  _buildAccountBreakdown(
                    '1× Pro Account',
                    'Family coordinator with advanced features',
                    Icons.star,
                    AppTheme.infoBlue,
                  ),
                  const SizedBox(height: 16),

                  const Divider(),
                  const SizedBox(height: 16),

                  // Family features
                  const Text(
                    'Exclusive Family Features:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),

                  _buildFeatureItem(
                    'Family Dashboard',
                    'Central management for all accounts',
                  ),
                  _buildFeatureItem(
                    'Shared Emergency Contacts',
                    'One contact list for the whole family',
                  ),
                  _buildFeatureItem(
                    'Family Location Sharing',
                    'See where family members are',
                  ),
                  _buildFeatureItem(
                    'Cross-Account Notifications',
                    'Get alerts from family emergencies',
                  ),
                  _buildFeatureItem(
                    'Family Portal Messaging',
                    'Not available in-app in this build',
                  ),
                  _buildFeatureItem(
                    'Coordinated SAR Response',
                    'Family-aware rescue coordination',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountBreakdown(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                description,
                style: TextStyle(color: AppTheme.secondaryText, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: AppTheme.safeGreen, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(color: AppTheme.secondaryText, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
