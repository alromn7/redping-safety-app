import 'package:flutter/material.dart';
import '../../../../services/feature_access_service.dart';
import '../../../../services/usage_tracking_service.dart';
import '../../../../core/theme/app_theme.dart';

/// Access control widget for SOS features
class SOSAccessControl extends StatefulWidget {
  final Widget child;
  final String feature;
  final bool trackUsage;
  final VoidCallback? onAccessDenied;

  const SOSAccessControl({
    super.key,
    required this.child,
    required this.feature,
    this.trackUsage = true,
    this.onAccessDenied,
  });

  @override
  State<SOSAccessControl> createState() => _SOSAccessControlState();
}

class _SOSAccessControlState extends State<SOSAccessControl> {
  late final FeatureAccessService _accessService;
  late final UsageTrackingService _usageService;

  bool _hasAccess = false;
  bool _canUse = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _accessService = FeatureAccessService.instance;
    _usageService = UsageTrackingService.instance;
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    try {
      final hasFeatureAccess = _accessService.hasFeatureAccess(widget.feature);
      final canUseFeature = _usageService.canUseFeature(widget.feature);

      setState(() {
        _hasAccess = hasFeatureAccess;
        _canUse = canUseFeature;
        _isLoading = false;
      });

      // Track usage if enabled
      if (widget.trackUsage && _hasAccess && _canUse) {
        await _usageService.trackFeatureUsage(widget.feature);
      }
    } catch (e) {
      setState(() {
        _hasAccess = false;
        _canUse = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (!_hasAccess) {
      return _buildAccessDeniedWidget();
    }

    if (!_canUse) {
      return _buildLimitReachedWidget();
    }

    return widget.child;
  }

  Widget _buildAccessDeniedWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.warningOrange.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, color: AppTheme.warningOrange, size: 48),
          const SizedBox(height: 16),
          Text(
            'Feature Not Available',
            style: TextStyle(
              color: AppTheme.primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getFeatureDescription(widget.feature),
            style: TextStyle(color: AppTheme.secondaryText, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showUpgradeDialog(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Upgrade to Access'),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitReachedWidget() {
    final currentUsage = _usageService.getCurrentUsage(widget.feature);
    final limit = _accessService.getFeatureLimit(widget.feature);
    final percentage = _usageService.getUsagePercentage(widget.feature);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.criticalRed.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed, color: AppTheme.criticalRed, size: 48),
          const SizedBox(height: 16),
          Text(
            'Usage Limit Reached',
            style: TextStyle(
              color: AppTheme.primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have used $currentUsage of ${limit == -1 ? 'unlimited' : limit} this month.',
            style: TextStyle(color: AppTheme.secondaryText, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: AppTheme.neutralGray.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.criticalRed),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showUpgradeDialog(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Upgrade'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFeatureDescription(String feature) {
    switch (feature) {
      case 'sosAlertsPerMonth':
        return 'SOS alerts are limited on your current plan. Upgrade for unlimited emergency alerts.';
      case 'redpingHelp':
        return 'REDP!NG Help requests are limited on your current plan. Upgrade for unlimited help requests.';
      case 'satelliteComm':
        return 'Satellite communication requires a Pro or higher subscription for emergency situations.';
      case 'sarParticipation':
        return 'SAR participation requires Pro or higher subscription to join rescue operations.';
      default:
        return 'This feature requires a subscription upgrade to access.';
    }
  }

  Future<void> _showUpgradeDialog() async {
    final shouldUpgrade = await _accessService.checkFeatureAccessWithUpgrade(
      context,
      widget.feature,
    );

    if (shouldUpgrade && mounted) {
      // Navigate to subscription page
      // Navigator.of(context).pushNamed('/subscription');
    }
  }
}

/// Extension to easily add access control to SOS widgets
extension SOSAccessControlExtension on Widget {
  Widget requireSOSFeature(
    String feature, {
    bool trackUsage = true,
    VoidCallback? onAccessDenied,
  }) {
    return SOSAccessControl(
      feature: feature,
      trackUsage: trackUsage,
      onAccessDenied: onAccessDenied,
      child: this,
    );
  }
}
