import 'package:flutter/material.dart';
import '../services/feature_access_service.dart';
import '../services/usage_tracking_service.dart';
import '../core/theme/app_theme.dart';

/// Widget that controls access to features based on subscription and usage limits
class SubscriptionControlledWidget extends StatefulWidget {
  /// The feature key to check access for
  final String feature;

  /// The widget to show when user has access
  final Widget child;

  /// The widget to show when user doesn't have access
  final Widget? fallbackWidget;

  /// Custom message to show in upgrade dialog
  final String? customMessage;

  /// Whether to show upgrade prompt when access is denied
  final bool showUpgradePrompt;

  /// Whether to track usage when widget is accessed
  final bool trackUsage;

  /// Callback when access is denied
  final VoidCallback? onAccessDenied;

  /// Callback when usage limit is reached
  final VoidCallback? onLimitReached;

  const SubscriptionControlledWidget({
    super.key,
    required this.feature,
    required this.child,
    this.fallbackWidget,
    this.customMessage,
    this.showUpgradePrompt = true,
    this.trackUsage = false,
    this.onAccessDenied,
    this.onLimitReached,
  });

  @override
  State<SubscriptionControlledWidget> createState() =>
      _SubscriptionControlledWidgetState();
}

class _SubscriptionControlledWidgetState
    extends State<SubscriptionControlledWidget> {
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
      // Check basic feature access
      final hasFeatureAccess = _accessService.hasFeatureAccess(widget.feature);

      // Check usage limits
      final canUseFeature = _usageService.canUseFeature(widget.feature);

      setState(() {
        _hasAccess = hasFeatureAccess;
        _canUse = canUseFeature;
        _isLoading = false;
      });

      // Track usage if enabled and user has access
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

    // If user doesn't have feature access
    if (!_hasAccess) {
      if (widget.fallbackWidget != null) {
        return widget.fallbackWidget!;
      }

      return _buildAccessDeniedWidget();
    }

    // If user has access but reached usage limit
    if (!_canUse) {
      if (widget.fallbackWidget != null) {
        return widget.fallbackWidget!;
      }

      return _buildLimitReachedWidget();
    }

    // User has access and can use the feature
    return widget.child;
  }

  Widget _buildAccessDeniedWidget() {
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, color: AppTheme.warningOrange, size: 32),
          const SizedBox(height: 8),
          Text(
            'Feature Not Available',
            style: TextStyle(
              color: AppTheme.primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'This feature requires a subscription upgrade.',
            style: TextStyle(color: AppTheme.secondaryText, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (widget.showUpgradePrompt) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _showUpgradeDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text('Upgrade Now'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLimitReachedWidget() {
    final currentUsage = _usageService.getCurrentUsage(widget.feature);
    final limit = _accessService.getFeatureLimit(widget.feature);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.criticalRed.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed, color: AppTheme.criticalRed, size: 32),
          const SizedBox(height: 8),
          Text(
            'Usage Limit Reached',
            style: TextStyle(
              color: AppTheme.primaryText,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You have used $currentUsage of ${limit == -1 ? 'unlimited' : limit} this month.',
            style: TextStyle(color: AppTheme.secondaryText, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: limit == -1 ? 0.0 : (currentUsage / limit).clamp(0.0, 1.0),
            backgroundColor: AppTheme.neutralGray.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.criticalRed),
          ),
          if (widget.showUpgradePrompt) ...[
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _showUpgradeDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text('Upgrade for Higher Limits'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showUpgradeDialog() async {
    final shouldUpgrade = await _accessService.checkFeatureAccessWithUpgrade(
      context,
      widget.feature,
      customMessage: widget.customMessage,
    );

    if (shouldUpgrade && mounted) {
      // Navigate to subscription page
      // Navigator.of(context).pushNamed('/subscription');
    }
  }
}

/// Extension to easily wrap widgets with subscription controls
extension SubscriptionControl on Widget {
  Widget requireFeature(
    String feature, {
    Widget? fallbackWidget,
    String? customMessage,
    bool showUpgradePrompt = true,
    bool trackUsage = false,
    VoidCallback? onAccessDenied,
    VoidCallback? onLimitReached,
  }) {
    return SubscriptionControlledWidget(
      feature: feature,
      fallbackWidget: fallbackWidget,
      customMessage: customMessage,
      showUpgradePrompt: showUpgradePrompt,
      trackUsage: trackUsage,
      onAccessDenied: onAccessDenied,
      onLimitReached: onLimitReached,
      child: this,
    );
  }
}
