import 'package:flutter/material.dart';
import '../services/feature_access_service.dart';

/// Widget that wraps content and handles feature access control
class FeatureProtectedWidget extends StatelessWidget {
  final String feature;
  final Widget child;
  final Widget? fallbackWidget;
  final String? customUpgradeMessage;
  final bool showUpgradePrompt;
  final VoidCallback? onAccessDenied;

  const FeatureProtectedWidget({
    super.key,
    required this.feature,
    required this.child,
    this.fallbackWidget,
    this.customUpgradeMessage,
    this.showUpgradePrompt = true,
    this.onAccessDenied,
  });

  @override
  Widget build(BuildContext context) {
    final accessService = FeatureAccessService.instance;

    if (accessService.hasFeatureAccess(feature)) {
      return child;
    }

    // Show fallback or upgrade prompt
    if (fallbackWidget != null) {
      return fallbackWidget!;
    }

    if (showUpgradePrompt) {
      return _buildUpgradePrompt(context);
    }

    return const SizedBox.shrink();
  }

  Widget _buildUpgradePrompt(BuildContext context) {
    final accessService = FeatureAccessService.instance;
    final upgradeMessage =
        customUpgradeMessage ?? accessService.getUpgradeMessage(feature);

    return InkWell(
      onTap: () async {
        final shouldUpgrade = await accessService.checkFeatureAccessWithUpgrade(
          context,
          feature,
          customMessage: customUpgradeMessage,
        );

        if (!shouldUpgrade && onAccessDenied != null) {
          onAccessDenied!();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, color: Colors.orange, size: 32),
            const SizedBox(height: 8),
            Text(
              'Premium Feature',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              upgradeMessage,
              style: TextStyle(fontSize: 14, color: Colors.grey[300]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                await accessService.checkFeatureAccessWithUpgrade(
                  context,
                  feature,
                  customMessage: customUpgradeMessage,
                );
              },
              icon: const Icon(Icons.upgrade, size: 16),
              label: const Text('Upgrade Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Button that checks feature access before executing action
class FeatureProtectedButton extends StatelessWidget {
  final String feature;
  final VoidCallback onPressed;
  final Widget child;
  final String? customUpgradeMessage;
  final ButtonStyle? style;

  const FeatureProtectedButton({
    super.key,
    required this.feature,
    required this.onPressed,
    required this.child,
    this.customUpgradeMessage,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final accessService = FeatureAccessService.instance;

        if (accessService.hasFeatureAccess(feature)) {
          onPressed();
        } else {
          final hasAccess = await accessService.checkFeatureAccessWithUpgrade(
            context,
            feature,
            customMessage: customUpgradeMessage,
          );

          if (hasAccess) {
            onPressed();
          }
        }
      },
      style: style,
      child: child,
    );
  }
}

/// ListTile that shows upgrade prompt when tapped if feature not accessible
class FeatureProtectedListTile extends StatelessWidget {
  final String feature;
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? customUpgradeMessage;

  const FeatureProtectedListTile({
    super.key,
    required this.feature,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.customUpgradeMessage,
  });

  @override
  Widget build(BuildContext context) {
    final accessService = FeatureAccessService.instance;
    final hasAccess = accessService.hasFeatureAccess(feature);

    return ListTile(
      leading: hasAccess
          ? leading
          : Icon(Icons.lock_outline, color: Colors.orange),
      title: title,
      subtitle: hasAccess
          ? subtitle
          : Text(
              'Premium Feature - Tap to upgrade',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
      trailing: hasAccess
          ? trailing
          : Icon(Icons.chevron_right, color: Colors.orange),
      onTap: () async {
        if (hasAccess) {
          onTap?.call();
        } else {
          final shouldUpgrade = await accessService
              .checkFeatureAccessWithUpgrade(
                context,
                feature,
                customMessage: customUpgradeMessage,
              );

          if (shouldUpgrade && onTap != null) {
            onTap!();
          }
        }
      },
    );
  }
}
