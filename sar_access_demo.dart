// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'lib/services/feature_access_service.dart';
import 'lib/services/subscription_service.dart';
import 'lib/models/sar_access_level.dart';
import 'lib/models/subscription_tier.dart';
import 'lib/widgets/sar_dashboard.dart';

/// Demo script showing SAR access control integration
/// Run this to see how subscription plans control SAR access levels
void main() {
  runApp(SARAccessDemo());
}

class SARAccessDemo extends StatelessWidget {
  const SARAccessDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAR Access Control Demo',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SARAccessHomePage(),
    );
  }
}

class SARAccessHomePage extends StatefulWidget {
  const SARAccessHomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SARAccessHomePageState createState() => _SARAccessHomePageState();
}

// ignore: library_private_types_in_public_api
class _SARAccessHomePageState extends State<SARAccessHomePage> {
  final _subscriptionService = SubscriptionService.instance;
  final _featureAccessService = FeatureAccessService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SAR Access Control Demo'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentSubscriptionCard(),
            const SizedBox(height: 16),
            _buildSubscriptionTestButtons(),
            const SizedBox(height: 24),
            _buildSARAccessLevelCard(),
            const SizedBox(height: 24),
            _buildFeatureTestSection(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SARDashboard()),
              ),
              icon: const Icon(Icons.dashboard),
              label: const Text('Open SAR Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSubscriptionCard() {
    final subscription = _subscriptionService.currentSubscription;
    final plan = subscription?.plan;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.card_membership, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  'Current Subscription',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (plan != null) ...[
              Text('Plan: ${plan.name}', style: const TextStyle(fontSize: 16)),
              Text(
                'Tier: ${plan.tier.name}',
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                'Price: \${plan.pricePerMonth}/month',
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                'Active: ${subscription?.isActive ?? false}',
                style: const TextStyle(fontSize: 14),
              ),
            ] else
              const Text(
                'No active subscription',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionTestButtons() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Different Subscription Plans',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSubscriptionButton('Free', SubscriptionTier.free),
                _buildSubscriptionButton(
                  'Essential',
                  SubscriptionTier.essentialPlus,
                ),
                _buildSubscriptionButton(
                  'Essential+',
                  SubscriptionTier.essentialPlus,
                ),
                _buildSubscriptionButton('Pro', SubscriptionTier.pro),
                _buildSubscriptionButton('Ultra', SubscriptionTier.ultra),
                _buildSubscriptionButton('Family', SubscriptionTier.family),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionButton(String name, SubscriptionTier tier) {
    return ElevatedButton(
      onPressed: () => _simulateSubscription(tier),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade100,
        foregroundColor: Colors.blue.shade800,
      ),
      child: Text(name),
    );
  }

  Widget _buildSARAccessLevelCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Colors.orange.shade600),
                const SizedBox(width: 8),
                Text(
                  'SAR Access Level',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<SARAccessLevel>(
              future: _featureAccessService.getSARAccessLevel(),
              builder: (context, snapshot) {
                final level = snapshot.data ?? SARAccessLevel.none;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level: ${level.displayName}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      level.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Available Features:',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ...level.availableFeatures.map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Text(
                          '• $feature',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTestSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test SAR Feature Access',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildFeatureTestButton('SAR Observer', 'sarObserver'),
            _buildFeatureTestButton('SAR Participation', 'sarParticipation'),
            _buildFeatureTestButton(
              'SAR Volunteer Registration',
              'sarVolunteerRegistration',
            ),
            _buildFeatureTestButton('SAR Team Management', 'sarTeamManagement'),
            _buildFeatureTestButton(
              'Organization Management',
              'organizationManagement',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTestButton(String name, String featureKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _testFeatureAccess(name, featureKey),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green.shade100,
            foregroundColor: Colors.green.shade800,
          ),
          child: Text('Test $name'),
        ),
      ),
    );
  }

  void _simulateSubscription(SubscriptionTier tier) {
    // This would normally involve actual subscription logic
    // For demo purposes, we'll just show the effect
    setState(() {
      // Force a rebuild to show updated access levels
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Simulated subscription change to ${tier.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _testFeatureAccess(String featureName, String featureKey) async {
    final hasAccess = _featureAccessService.hasFeatureAccess(featureKey);

    final message = hasAccess
        ? '$featureName: ✅ Access Granted'
        : '$featureName: ❌ Access Denied - Upgrade Required';

    if (!hasAccess) {
      // Show upgrade dialog
      final shouldUpgrade = await _featureAccessService
          .checkFeatureAccessWithUpgrade(context, featureKey);

      if (shouldUpgrade) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User chose to upgrade subscription')),
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
