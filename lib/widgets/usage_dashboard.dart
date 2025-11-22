import 'package:flutter/material.dart';
import '../services/usage_tracking_service.dart';
import '../services/subscription_service.dart';
import '../core/theme/app_theme.dart';

/// Dashboard widget showing usage statistics and limits
class UsageDashboard extends StatefulWidget {
  const UsageDashboard({super.key});

  @override
  State<UsageDashboard> createState() => _UsageDashboardState();
}

class _UsageDashboardState extends State<UsageDashboard> {
  late final UsageTrackingService _usageService;
  late final SubscriptionService _subscriptionService;

  Map<String, dynamic> _usageStatus = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _usageService = UsageTrackingService.instance;
    _subscriptionService = SubscriptionService.instance;
    _loadUsageData();
  }

  Future<void> _loadUsageData() async {
    try {
      final status = _usageService.getUsageStatus();
      setState(() {
        _usageStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final subscription = _subscriptionService.currentSubscription;
    if (subscription == null) {
      return _buildNoSubscriptionWidget();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neutralGray.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(subscription),
          const SizedBox(height: 16),
          _buildUsageOverview(),
          const SizedBox(height: 16),
          _buildFeatureUsageList(),
        ],
      ),
    );
  }

  Widget _buildNoSubscriptionWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.warningOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, color: AppTheme.warningOrange, size: 32),
          const SizedBox(height: 8),
          Text(
            'No Active Subscription',
            style: TextStyle(
              color: AppTheme.primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Subscribe to access usage tracking and limits.',
            style: TextStyle(color: AppTheme.secondaryText, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(dynamic subscription) {
    return Row(
      children: [
        Icon(Icons.analytics_outlined, color: AppTheme.primaryRed, size: 24),
        const SizedBox(width: 8),
        Text(
          'Usage Dashboard',
          style: TextStyle(
            color: AppTheme.primaryText,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getTierColor(subscription.plan.tier),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            subscription.plan.name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUsageOverview() {
    final analytics = _usageService.getUsageAnalytics();
    final nearLimitFeatures = _usageService.getFeaturesNearLimit();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Features Used',
                '${analytics['used_features'] ?? 0}',
                AppTheme.infoBlue,
              ),
              _buildStatItem(
                'Near Limit',
                '${nearLimitFeatures.length}',
                nearLimitFeatures.isNotEmpty
                    ? AppTheme.warningOrange
                    : AppTheme.safeGreen,
              ),
              _buildStatItem(
                'Usage %',
                '${((analytics['usage_percentage'] ?? 0.0) * 100).toStringAsFixed(0)}%',
                AppTheme.primaryRed,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: AppTheme.secondaryText, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildFeatureUsageList() {
    final features = _usageStatus.keys.toList();
    if (features.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feature Usage',
          style: TextStyle(
            color: AppTheme.primaryText,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...features.map((feature) => _buildFeatureUsageItem(feature)),
      ],
    );
  }

  Widget _buildFeatureUsageItem(String feature) {
    final usage = _usageStatus[feature] as Map<String, dynamic>?;
    if (usage == null) return const SizedBox.shrink();

    final current = usage['current'] as int? ?? 0;
    final limit = usage['limit'] as int? ?? 0;
    final percentage = usage['percentage'] as double? ?? 0.0;
    final canUse = usage['canUse'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getUsageColor(percentage), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _getFeatureDisplayName(feature),
                style: TextStyle(
                  color: AppTheme.primaryText,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (!canUse)
                Icon(Icons.block, color: AppTheme.criticalRed, size: 16),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '$current',
                style: TextStyle(
                  color: _getUsageColor(percentage),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                ' / ${limit == -1 ? '∞' : limit}',
                style: TextStyle(color: AppTheme.secondaryText, fontSize: 14),
              ),
              const Spacer(),
              Text(
                '${(percentage * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: _getUsageColor(percentage),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: AppTheme.neutralGray.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              _getUsageColor(percentage),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTierColor(dynamic tier) {
    switch (tier.toString()) {
      case 'free':
        return AppTheme.neutralGray;
      case 'essential':
        return AppTheme.infoBlue;
      case 'essentialPlus':
        return AppTheme.safeGreen;
      case 'pro':
        return AppTheme.primaryRed;
      case 'ultra':
        return AppTheme.warningOrange;
      case 'family':
        return AppTheme.primaryRed;
      default:
        return AppTheme.neutralGray;
    }
  }

  Color _getUsageColor(double percentage) {
    if (percentage >= 1.0) return AppTheme.criticalRed;
    if (percentage >= 0.8) return AppTheme.warningOrange;
    if (percentage >= 0.5) return AppTheme.infoBlue;
    return AppTheme.safeGreen;
  }

  String _getFeatureDisplayName(String feature) {
    switch (feature) {
      case 'sosAlertsPerMonth':
        return 'SOS Alerts';
      case 'emergencyContacts':
        return 'Emergency Contacts';
      case 'satelliteMessages':
        return 'Satellite Messages';
      case 'redpingHelp':
        return 'REDP!NG Help';
      case 'sarParticipation':
        return 'SAR Participation';
      case 'organizationManagement':
        return 'Organization Management';
      case 'aiAssistant':
        return 'AI Assistant';
      default:
        return feature.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim();
    }
  }
}
