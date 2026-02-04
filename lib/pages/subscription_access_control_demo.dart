import 'package:flutter/material.dart';
import '../services/feature_access_service.dart';
import '../services/subscription_service.dart';
import '../models/subscription_tier.dart';
import '../widgets/feature_protected_widget.dart';
import '../widgets/upgrade_required_dialog.dart';
import '../core/theme/app_theme.dart';

/// Demo page showing how subscription access control works
class SubscriptionAccessControlDemo extends StatefulWidget {
  const SubscriptionAccessControlDemo({super.key});

  @override
  State<SubscriptionAccessControlDemo> createState() =>
      _SubscriptionAccessControlDemoState();
}

class _SubscriptionAccessControlDemoState
    extends State<SubscriptionAccessControlDemo> {
  final _accessService = FeatureAccessService.instance;
  final _subscriptionService = SubscriptionService.instance;

  @override
  Widget build(BuildContext context) {
    final currentSubscription = _subscriptionService.currentSubscription;
    final currentTier = currentSubscription?.plan.tier ?? SubscriptionTier.free;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Access Control Demo'),
        backgroundColor: AppTheme.infoBlue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current subscription info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Subscription',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Plan: ${currentSubscription?.plan.name ?? 'Free'} (${currentTier.name})',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.secondaryText,
                      ),
                    ),
                    if (currentSubscription != null) ...[
                      Text(
                        'Price: \$${currentSubscription.plan.monthlyPrice.toStringAsFixed(2)}/month',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                      Text(
                        'Status: ${currentSubscription.status.name}',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Feature access tests
            Text(
              'Feature Access Tests',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 16),

            // REDP!NG Help Test
            _buildFeatureTest(
              'REDP!NG Help',
              'redpingHelp',
              'Emergency assistance and safety guidance',
              Icons.help,
              AppTheme.infoBlue,
            ),

            const SizedBox(height: 12),

            // Hazard Alerts Test
            _buildFeatureTest(
              'Hazard Alerts',
              'hazardAlerts',
              'Official and community hazard alerts',
              Icons.warning,
              AppTheme.warningOrange,
            ),

            const SizedBox(height: 12),

            // SAR Participation Test
            _buildFeatureTest(
              'SAR Participation',
              'sarParticipation',
              'Join Search & Rescue operations',
              Icons.group_add,
              AppTheme.warningOrange,
            ),

            const SizedBox(height: 12),

            // Satellite Communication Test
            _buildFeatureTest(
              'Satellite Communication',
              'satelliteComm',
              'Emergency messaging via satellite',
              Icons.satellite,
              AppTheme.primaryRed,
            ),

            const SizedBox(height: 12),

            // Organization Management Test
            _buildFeatureTest(
              'Organization Management',
              'organizationManagement',
              'Manage SAR teams and organizations',
              Icons.corporate_fare,
              AppTheme.criticalRed,
            ),

            const SizedBox(height: 24),

            // Feature limits display
            Text(
              'Current Feature Limits',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildLimitRow('SOS Alerts/Month', 'sosAlertsPerMonth'),
                    _buildLimitRow('Emergency Contacts', 'emergencyContacts'),
                    _buildLimitRow('Satellite Messages', 'satelliteMessages'),
                    _buildLimitRow('REDP!NG Help', 'redpingHelp'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Feature protected widgets demo
            Text(
              'Feature Protected Widgets Demo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 16),

            // Example of FeatureProtectedWidget
            FeatureProtectedWidget(
              feature: 'hazardAlerts',
              customUpgradeMessage: 'Upgrade to unlock Hazard Alerts',
              child: Card(
                color: AppTheme.warningOrange.withValues(alpha: 0.1),
                child: ListTile(
                  leading: Icon(Icons.warning, color: AppTheme.warningOrange),
                  title: Text('Hazard Alerts Enabled'),
                  subtitle: Text('You have access to hazard alerts'),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Example of FeatureProtectedButton
            FeatureProtectedButton(
              feature: 'satelliteComm',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Satellite communication activated!'),
                  ),
                );
              },
              customUpgradeMessage:
                  'Satellite communication requires Pro plan or higher',
              child: const Text('Use Satellite Communication'),
            ),

            const SizedBox(height: 12),

            // Example of FeatureProtectedListTile
            FeatureProtectedListTile(
              feature: 'organizationManagement',
              leading: Icon(Icons.corporate_fare),
              title: Text('Organization Dashboard'),
              subtitle: Text('Manage your SAR organization'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening organization dashboard...'),
                  ),
                );
              },
              customUpgradeMessage:
                  'Organization management requires Ultra plan',
            ),

            const SizedBox(height: 24),

            // Manual test buttons
            Text(
              'Manual Test Controls',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        _simulateSubscription(SubscriptionTier.free),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                    child: const Text('Simulate Free'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        _simulateSubscription(SubscriptionTier.pro),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.infoBlue,
                    ),
                    child: const Text('Simulate Pro'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showUpgradeDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warningOrange,
                ),
                child: const Text('Show Upgrade Dialog'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTest(
    String name,
    String feature,
    String description,
    IconData icon,
    Color color,
  ) {
    final hasAccess = _accessService.hasFeatureAccess(feature);
    final requiredTier = _accessService.getRequiredTierForFeature(feature);

    return Card(
      child: ListTile(
        leading: Icon(
          hasAccess ? icon : Icons.lock_outline,
          color: hasAccess ? color : Colors.grey,
        ),
        title: Text(name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            const SizedBox(height: 4),
            Text(
              hasAccess
                  ? '✅ Available'
                  : requiredTier != null
                  ? '🔒 Requires ${requiredTier.name} plan'
                  : '🔒 Premium feature',
              style: TextStyle(
                color: hasAccess
                    ? AppTheme.successGreen
                    : AppTheme.warningOrange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: hasAccess
            ? Icon(Icons.check_circle, color: AppTheme.successGreen)
            : IconButton(
                icon: Icon(Icons.upgrade, color: AppTheme.warningOrange),
                onPressed: () async {
                  await _accessService.checkFeatureAccessWithUpgrade(
                    context,
                    feature,
                    customMessage: 'Test upgrade dialog for $name',
                  );
                },
              ),
        onTap: hasAccess
            ? () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$name feature accessed!')),
                );
              }
            : () async {
                await _accessService.checkFeatureAccessWithUpgrade(
                  context,
                  feature,
                  customMessage: 'Test upgrade dialog for $name',
                );
              },
      ),
    );
  }

  Widget _buildLimitRow(String label, String feature) {
    final limit = _accessService.getFeatureLimit(feature);
    final limitText = limit == -1 ? 'Unlimited' : limit.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            limitText,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: limit == -1
                  ? AppTheme.successGreen
                  : AppTheme.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  void _simulateSubscription(SubscriptionTier tier) {
    // In a real app, this would actually change the subscription
    // For demo purposes, we'll just show what would happen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Simulation: Would change subscription to ${tier.name} plan\n'
          'This is a demo - actual subscription changes require payment processing.',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showUpgradeDialog() async {
    await UpgradeRequiredDialog.show(
      context,
      featureName: 'demoFeature',
      featureDescription: 'This is a demo of the upgrade dialog system.',
      benefits: [
        'Access to premium features',
        'Priority customer support',
        'Advanced safety tools',
        'Unlimited usage limits',
        'Professional-grade capabilities',
      ],
    );
  }
}
