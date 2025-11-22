import '../../../../models/subscription_tier.dart' as sub;
import 'package:flutter/material.dart';
import '../../../../models/auth_user.dart';
import '../../../../core/theme/app_theme.dart';

class FamilyMemberCard extends StatelessWidget {
  const FamilyMemberCard({
    super.key,
    required this.member,
    required this.onRemove,
    required this.onEdit,
  });

  final FamilyMember member;
  final VoidCallback onRemove;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: _getTierColor().withValues(alpha: 0.2),
              child: Text(
                member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getTierColor(),
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Member info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildTierBadge(),
                    ],
                  ),
                  if (member.relationship != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      member.relationship!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                  if (member.email != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      member.email!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Added ${_formatDate(member.addedDate)}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            ),

            // Status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: member.isActive ? AppTheme.safeGreen : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                member.isActive ? 'ACTIVE' : 'INACTIVE',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Actions
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    onEdit();
                    break;
                  case 'remove':
                    onRemove();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'remove',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 16, color: AppTheme.criticalRed),
                      SizedBox(width: 8),
                      Text(
                        'Remove',
                        style: TextStyle(color: AppTheme.criticalRed),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getTierColor(),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _getTierIcon(),
          const SizedBox(width: 4),
          Text(
            member.assignedTier.name.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTierColor() {
    switch (member.assignedTier) {
      case sub.SubscriptionTier.essentialPlus:
        return AppTheme.successGreen;
      case sub.SubscriptionTier.pro:
        return AppTheme.infoBlue;
      case sub.SubscriptionTier.ultra:
        return AppTheme.primaryRed;
      case sub.SubscriptionTier.family:
        return AppTheme.warningOrange;
      case sub.SubscriptionTier.free:
        return Colors.grey;
    }
  }

  Widget _getTierIcon() {
    switch (member.assignedTier) {
      case sub.SubscriptionTier.essentialPlus:
        return const Icon(Icons.shield_outlined, color: Colors.white, size: 12);
      case sub.SubscriptionTier.pro:
        return const Icon(Icons.star, color: Colors.white, size: 12);
      case sub.SubscriptionTier.ultra:
        return const Icon(Icons.diamond, color: Colors.white, size: 12);
      case sub.SubscriptionTier.family:
        return const Icon(Icons.family_restroom, color: Colors.white, size: 12);
      case sub.SubscriptionTier.free:
        return const Icon(Icons.lock_outline, color: Colors.white, size: 12);
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    }
  }
}
