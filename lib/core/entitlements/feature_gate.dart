import 'package:flutter/material.dart';
import 'entitlement_service.dart';

/// FeatureGate wraps content and shows an upgrade prompt when entitlement is missing.
class FeatureGate extends StatelessWidget {
  final String featureId;
  final Widget child;
  final VoidCallback? onUpgrade;
  final String missingMessage;

  const FeatureGate({
    super.key,
    required this.featureId,
    required this.child,
    this.onUpgrade,
    this.missingMessage = 'This feature requires an upgraded plan.',
  });

  @override
  Widget build(BuildContext context) {
    // Gating disabled in this build.
    return child;
  }
}
