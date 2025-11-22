import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/auth_user.dart';
import '../models/subscription_tier.dart' as sub;
import '../services/subscription_service.dart';
import '../core/theme/app_theme.dart';

class SubscriptionStatusCard extends StatefulWidget {
  const SubscriptionStatusCard({super.key});

  @override
  State<SubscriptionStatusCard> createState() => _SubscriptionStatusCardState();
}

class _SubscriptionStatusCardState extends State<SubscriptionStatusCard> {
  late final SubscriptionService _subscriptionService;
  UserSubscription? _currentSubscription;
  FamilySubscription? _currentFamily;

  @override
  void initState() {
    super.initState();
    _subscriptionService = SubscriptionService.instance;
    _currentSubscription = _subscriptionService.currentSubscription;
    _currentFamily = _subscriptionService.currentFamily;

    // Listen for subscription changes
    _subscriptionService.subscriptionStream.listen((subscription) {
      if (mounted) {
        setState(() => _currentSubscription = subscription);
      }
    });

    _subscriptionService.familyStream.listen((family) {
      if (mounted) {
        setState(() => _currentFamily = family);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          if (_currentSubscription?.plan.isFamilyPlan == true) {
            context.push('/subscription/family-dashboard');
          } else {
            context.push('/subscription/plans');
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getSubscriptionColor().withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getSubscriptionIcon(),
                      color: _getSubscriptionColor(),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getSubscriptionTitle(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _getSubscriptionSubtitle(),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status and features
              if (_currentSubscription != null) ...[
                // Subscription status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _currentSubscription!.isActive
                            ? AppTheme.safeGreen
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _currentSubscription!.isActive ? 'ACTIVE' : 'INACTIVE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_currentSubscription!.plan.isFamilyPlan &&
                        _currentFamily != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.warningOrange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_currentFamily!.totalMembers} Members',
                          style: const TextStyle(
                            color: AppTheme.warningOrange,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Key features
                Row(
                  children: [
                    Expanded(
                      child: _buildFeatureChip(
                        'AI Verification',
                        Icons.psychology,
                        AppTheme.infoBlue,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildFeatureChip(
                        'SAR Network',
                        Icons.search,
                        AppTheme.safeGreen,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // No subscription
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warningOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.warningOrange),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Choose a plan to unlock full safety features',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSubscriptionColor() {
    if (_currentSubscription == null) return Colors.grey;

    switch (_currentSubscription!.plan.tier) {
      case sub.SubscriptionTier.free:
        return Colors.grey;
      case sub.SubscriptionTier.essentialPlus:
        return AppTheme.successGreen;
      case sub.SubscriptionTier.pro:
        return AppTheme.infoBlue;
      case sub.SubscriptionTier.ultra:
        return AppTheme.primaryRed;
      case sub.SubscriptionTier.family:
        return AppTheme.warningOrange;
    }
  }

  IconData _getSubscriptionIcon() {
    if (_currentSubscription == null) return Icons.card_membership_outlined;

    switch (_currentSubscription!.plan.tier) {
      case sub.SubscriptionTier.free:
        return Icons.lock_outline;
      case sub.SubscriptionTier.essentialPlus:
        return Icons.shield_outlined;
      case sub.SubscriptionTier.pro:
        return Icons.star;
      case sub.SubscriptionTier.ultra:
        return Icons.diamond;
      case sub.SubscriptionTier.family:
        return Icons.family_restroom;
    }
  }

  String _getSubscriptionTitle() {
    if (_currentSubscription == null) {
      return 'Choose Your Plan';
    }

    return '${_currentSubscription!.plan.name} Plan';
  }

  String _getSubscriptionSubtitle() {
    if (_currentSubscription == null) {
      return 'Unlock full safety features';
    }

    if (_currentSubscription!.plan.isFamilyPlan) {
      return 'Family safety protection active';
    }

    return 'Connected to SAR Network';
  }
}
