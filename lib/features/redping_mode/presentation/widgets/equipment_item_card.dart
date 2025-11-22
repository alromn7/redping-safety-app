import 'package:flutter/material.dart';
import '../../../../models/extreme_activity.dart';

/// Card widget for displaying equipment items
class EquipmentItemCard extends StatelessWidget {
  final EquipmentItem item;
  final VoidCallback? onTap;
  final VoidCallback? onInspect;

  const EquipmentItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.onInspect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine status color
    Color statusColor = colorScheme.primary;
    IconData statusIcon = Icons.check_circle;
    String? statusText;

    if (item.isExpired) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
      statusText = 'EXPIRED';
    } else if (item.needsInspection) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
      statusText = 'Needs Inspection';
    } else if (item.condition == EquipmentCondition.poor) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
      statusText = 'Poor Condition';
    } else if (item.condition == EquipmentCondition.retired) {
      statusColor = Colors.grey;
      statusIcon = Icons.block;
      statusText = 'Retired';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: item.isExpired || item.needsInspection ? 4 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Category icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(item.category),
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name and category
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatCategory(item.category),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status indicator
                  if (statusText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: statusColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Details
              Row(
                children: [
                  // Condition indicator
                  _buildInfoChip(
                    _formatCondition(item.condition),
                    _getConditionColor(item.condition),
                    Icons.fitness_center,
                  ),
                  const SizedBox(width: 8),

                  // Last inspection
                  if (item.lastInspection != null)
                    _buildInfoChip(
                      'Inspected ${_formatDate(item.lastInspection!)}',
                      colorScheme.tertiaryContainer,
                      Icons.calendar_today,
                    ),
                ],
              ),

              // Activity types
              if (item.activityTypes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: item.activityTypes.map((type) {
                    return Chip(
                      label: Text(
                        _formatActivityType(type),
                        style: const TextStyle(fontSize: 10),
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],

              // Action buttons
              if (onInspect != null && !item.isExpired) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onInspect,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Mark Inspected'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(EquipmentCategory category) {
    switch (category) {
      case EquipmentCategory.helmet:
        return Icons.sports_motorsports;
      case EquipmentCategory.harness:
        return Icons.health_and_safety;
      case EquipmentCategory.rope:
        return Icons.cable;
      case EquipmentCategory.carabiner:
        return Icons.link;
      case EquipmentCategory.wetsuit:
      case EquipmentCategory.drysuit:
        return Icons.dry_cleaning;
      case EquipmentCategory.lifeJacket:
        return Icons.water;
      case EquipmentCategory.avalancheBeacon:
      case EquipmentCategory.emergencyBeacon:
        return Icons.sensors;
      case EquipmentCategory.parachute:
      case EquipmentCategory.reserve:
        return Icons.paragliding;
      case EquipmentCategory.gps:
        return Icons.gps_fixed;
      case EquipmentCategory.radio:
        return Icons.radio;
      case EquipmentCategory.firstAid:
        return Icons.medical_services;
      default:
        return Icons.category;
    }
  }

  Color _getConditionColor(EquipmentCondition condition) {
    switch (condition) {
      case EquipmentCondition.excellent:
        return Colors.green.shade100;
      case EquipmentCondition.good:
        return Colors.blue.shade100;
      case EquipmentCondition.fair:
        return Colors.orange.shade100;
      case EquipmentCondition.poor:
        return Colors.red.shade100;
      case EquipmentCondition.retired:
        return Colors.grey.shade300;
    }
  }

  String _formatCategory(EquipmentCategory category) {
    return category
        .toString()
        .split('.')
        .last
        .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[1]}')
        .trim()
        .split(' ')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  String _formatCondition(EquipmentCondition condition) {
    return condition.toString().split('.').last[0].toUpperCase() +
        condition.toString().split('.').last.substring(1);
  }

  String _formatActivityType(String type) {
    return type
        .split('_')
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) return 'today';
    if (diff == 1) return 'yesterday';
    if (diff < 7) return '$diff days ago';
    if (diff < 30) return '${(diff / 7).round()} weeks ago';
    if (diff < 365) return '${(diff / 30).round()} months ago';
    return '${(diff / 365).round()} years ago';
  }
}
