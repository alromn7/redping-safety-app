import 'package:flutter/material.dart';
import '../../../../models/group_activity.dart';

/// Card widget for displaying rally point information
class RallyPointCard extends StatelessWidget {
  const RallyPointCard({
    super.key,
    required this.rallyPoint,
    required this.session,
    this.onCheckIn,
  });

  final RallyPoint rallyPoint;
  final GroupActivitySession session;
  final Function(String rallyPointId, String memberId)? onCheckIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checkInPercentage = rallyPoint.getCheckInPercentage(
      session.currentMembers.length,
    );
    final isOverdue = rallyPoint.isOverdue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getTypeColor(rallyPoint.type).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getTypeIcon(rallyPoint.type),
                  color: _getTypeColor(rallyPoint.type),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rallyPoint.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatType(rallyPoint.type),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _getTypeColor(rallyPoint.type),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!rallyPoint.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Inactive',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, size: 12, color: Colors.red),
                        SizedBox(width: 4),
                        Text(
                          'Overdue',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                if (rallyPoint.description != null) ...[
                  Text(
                    rallyPoint.description!,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                ],

                // Location info
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${rallyPoint.latitude.toStringAsFixed(6)}, ${rallyPoint.longitude.toStringAsFixed(6)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Radius
                Row(
                  children: [
                    Icon(
                      Icons.radio_button_unchecked,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Radius: ${rallyPoint.radiusFormatted}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),

                // Scheduled time
                if (rallyPoint.scheduledTime != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: isOverdue ? Colors.red : Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Scheduled: ${_formatDateTime(rallyPoint.scheduledTime!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isOverdue ? Colors.red : null,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Check-in progress
                if (rallyPoint.checkInRequired) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Check-in Progress',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${rallyPoint.checkedInMembers.length}/${session.currentMembers.length}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: checkInPercentage,
                                minHeight: 8,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getProgressColor(checkInPercentage),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Checked-in members
                  if (rallyPoint.checkedInMembers.isNotEmpty) ...[
                    Text(
                      'Checked In:',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: rallyPoint.checkedInMembers.map((memberId) {
                        final member = session.currentMembers.firstWhere(
                          (m) => m.memberId == memberId,
                          orElse: () => GroupMember(
                            memberId: '',
                            memberName: 'Unknown',
                            role: GroupMemberRole.member,
                            joinedAt: DateTime.now(),
                          ),
                        );
                        return Chip(
                          avatar: CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Text(
                              member.memberName.isNotEmpty
                                  ? member.memberName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          label: Text(member.memberName),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ],
                ] else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Check-in not required for this rally point',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(RallyPointType? type) {
    switch (type) {
      case RallyPointType.start:
        return Colors.green;
      case RallyPointType.checkpoint:
        return Colors.blue;
      case RallyPointType.rest:
        return Colors.orange;
      case RallyPointType.lunch:
        return Colors.purple;
      case RallyPointType.emergency:
        return Colors.red;
      case RallyPointType.finish:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(RallyPointType? type) {
    switch (type) {
      case RallyPointType.start:
        return Icons.flag;
      case RallyPointType.checkpoint:
        return Icons.location_on;
      case RallyPointType.rest:
        return Icons.chair;
      case RallyPointType.lunch:
        return Icons.restaurant;
      case RallyPointType.emergency:
        return Icons.emergency;
      case RallyPointType.finish:
        return Icons.emoji_events;
      default:
        return Icons.place;
    }
  }

  String _formatType(RallyPointType? type) {
    if (type == null) return 'Rally Point';
    switch (type) {
      case RallyPointType.start:
        return 'Start Point';
      case RallyPointType.checkpoint:
        return 'Checkpoint';
      case RallyPointType.rest:
        return 'Rest Stop';
      case RallyPointType.lunch:
        return 'Lunch Break';
      case RallyPointType.emergency:
        return 'Emergency Point';
      case RallyPointType.finish:
        return 'Finish Line';
    }
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 0.8) return Colors.green;
    if (percentage >= 0.5) return Colors.orange;
    return Colors.red;
  }

  String _formatDateTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} $hour:$minute';
  }
}
