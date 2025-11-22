import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/user_activity.dart';

/// Widget to display an activity card
class ActivityCard extends StatelessWidget {
  final UserActivity activity;
  final bool isExpanded;
  final VoidCallback? onTap;
  final VoidCallback? onCheckIn;
  final VoidCallback? onEnd;
  final VoidCallback? onStart;

  const ActivityCard({
    super.key,
    required this.activity,
    this.isExpanded = false,
    this.onTap,
    this.onCheckIn,
    this.onEnd,
    this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
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
                      color: _getActivityColor().withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getActivityIcon(),
                      color: _getActivityColor(),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryText,
                          ),
                        ),
                        if (activity.description != null)
                          Text(
                            activity.description!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.secondaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              if (isExpanded) ...[
                const SizedBox(height: 16),
                _buildExpandedContent(),
              ] else ...[
                const SizedBox(height: 12),
                _buildCompactContent(),
              ],

              // Action buttons
              if (activity.status == ActivityStatus.active &&
                  (onCheckIn != null || onEnd != null)) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (onCheckIn != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onCheckIn,
                          icon: const Icon(
                            Icons.check_circle_outline,
                            size: 16,
                          ),
                          label: const Text('Check In'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.safeGreen,
                            side: const BorderSide(color: AppTheme.safeGreen),
                          ),
                        ),
                      ),
                    if (onCheckIn != null && onEnd != null)
                      const SizedBox(width: 8),
                    if (onEnd != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onEnd,
                          icon: const Icon(Icons.stop, size: 16),
                          label: const Text('End'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.criticalRed,
                            side: const BorderSide(color: AppTheme.criticalRed),
                          ),
                        ),
                      ),
                  ],
                ),
              ],

              if (activity.status == ActivityStatus.planned &&
                  onStart != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onStart,
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Start Activity'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getActivityColor(),
                      foregroundColor: Colors.white,
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

  Widget _buildExpandedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Activity details
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                'Risk Level',
                _getRiskLevelText(),
                _getRiskLevelColor(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDetailItem(
                'Environment',
                _getEnvironmentText(),
                AppTheme.infoBlue,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Timing information
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                'Duration',
                _getDurationText(),
                AppTheme.neutralGray,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildDetailItem(
                'Started',
                _getStartTimeText(),
                AppTheme.neutralGray,
              ),
            ),
          ],
        ),

        // Check-in status (for active activities)
        if (activity.status == ActivityStatus.active &&
            activity.hasCheckInSchedule) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getCheckInStatusColor().withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _getCheckInStatusColor().withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getCheckInStatusIcon(),
                  color: _getCheckInStatusColor(),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Check-In Status',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getCheckInStatusColor(),
                        ),
                      ),
                      Text(
                        _getCheckInStatusText(),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // Safety notes
        if (activity.safetyNotes.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Safety Notes:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          ...activity.safetyNotes
              .take(3)
              .map(
                (note) => Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '• $note',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ),
              ),
        ],
      ],
    );
  }

  Widget _buildCompactContent() {
    return Row(
      children: [
        Icon(Icons.schedule, size: 14, color: AppTheme.secondaryText),
        const SizedBox(width: 4),
        Text(
          _getDurationText(),
          style: const TextStyle(fontSize: 12, color: AppTheme.secondaryText),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: _getRiskLevelColor().withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _getRiskLevelText(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _getRiskLevelColor(),
            ),
          ),
        ),
        if (activity.hasCheckInSchedule) ...[
          const SizedBox(width: 8),
          Icon(Icons.notifications_active, size: 14, color: AppTheme.infoBlue),
        ],
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppTheme.secondaryText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  // Helper methods
  IconData _getActivityIcon() {
    switch (activity.type) {
      case ActivityType.hiking:
        return Icons.hiking;
      case ActivityType.fishing:
        return Icons.phishing;
      case ActivityType.kayaking:
        return Icons.kayaking;
      case ActivityType.driving:
        return Icons.directions_car;
      case ActivityType.fourWD:
        return Icons.terrain;
      case ActivityType.surfing:
        return Icons.surfing;
      case ActivityType.skydiving:
        return Icons.flight;
      case ActivityType.remoteWork:
        return Icons.laptop;
      case ActivityType.exploring:
        return Icons.explore;
      case ActivityType.scubaDiving:
        return Icons.scuba_diving;
      case ActivityType.swimming:
        return Icons.pool;
      case ActivityType.cycling:
        return Icons.directions_bike;
      case ActivityType.running:
        return Icons.directions_run;
      case ActivityType.camping:
        return Icons.cabin;
      case ActivityType.climbing:
        return Icons.landscape;
      case ActivityType.skiing:
        return Icons.downhill_skiing;
      case ActivityType.snowboarding:
        return Icons.snowboarding;
      case ActivityType.sailing:
        return Icons.sailing;
      case ActivityType.hunting:
        return Icons.my_location;
      case ActivityType.photography:
        return Icons.camera_alt;
      case ActivityType.geocaching:
        return Icons.search;
      case ActivityType.backpacking:
        return Icons.backpack;
      case ActivityType.custom:
        return Icons.star;
    }
  }

  Color _getActivityColor() {
    switch (activity.type) {
      case ActivityType.hiking:
      case ActivityType.exploring:
      case ActivityType.backpacking:
        return AppTheme.safeGreen;
      case ActivityType.fishing:
      case ActivityType.swimming:
      case ActivityType.kayaking:
      case ActivityType.sailing:
      case ActivityType.scubaDiving:
        return AppTheme.infoBlue;
      case ActivityType.driving:
      case ActivityType.remoteWork:
        return AppTheme.neutralGray;
      case ActivityType.fourWD:
      case ActivityType.climbing:
        return AppTheme.warningOrange;
      case ActivityType.skydiving:
      case ActivityType.hunting:
        return AppTheme.criticalRed;
      default:
        return AppTheme.primaryText;
    }
  }

  Color _getStatusColor() {
    switch (activity.status) {
      case ActivityStatus.planned:
        return AppTheme.infoBlue;
      case ActivityStatus.active:
        return AppTheme.safeGreen;
      case ActivityStatus.paused:
        return AppTheme.warningOrange;
      case ActivityStatus.completed:
        return AppTheme.neutralGray;
      case ActivityStatus.cancelled:
        return AppTheme.criticalRed;
    }
  }

  String _getStatusText() {
    switch (activity.status) {
      case ActivityStatus.planned:
        return 'PLANNED';
      case ActivityStatus.active:
        return 'ACTIVE';
      case ActivityStatus.paused:
        return 'PAUSED';
      case ActivityStatus.completed:
        return 'COMPLETED';
      case ActivityStatus.cancelled:
        return 'CANCELLED';
    }
  }

  Color _getRiskLevelColor() {
    switch (activity.riskLevel) {
      case ActivityRiskLevel.low:
        return AppTheme.safeGreen;
      case ActivityRiskLevel.moderate:
        return AppTheme.warningOrange;
      case ActivityRiskLevel.high:
        return AppTheme.criticalRed;
      case ActivityRiskLevel.extreme:
        return AppTheme.primaryRed;
    }
  }

  String _getRiskLevelText() {
    switch (activity.riskLevel) {
      case ActivityRiskLevel.low:
        return 'Low Risk';
      case ActivityRiskLevel.moderate:
        return 'Moderate Risk';
      case ActivityRiskLevel.high:
        return 'High Risk';
      case ActivityRiskLevel.extreme:
        return 'Extreme Risk';
    }
  }

  String _getEnvironmentText() {
    switch (activity.environment) {
      case ActivityEnvironment.urban:
        return 'Urban';
      case ActivityEnvironment.suburban:
        return 'Suburban';
      case ActivityEnvironment.rural:
        return 'Rural';
      case ActivityEnvironment.wilderness:
        return 'Wilderness';
      case ActivityEnvironment.water:
        return 'Water';
      case ActivityEnvironment.mountain:
        return 'Mountain';
      case ActivityEnvironment.desert:
        return 'Desert';
      case ActivityEnvironment.forest:
        return 'Forest';
      case ActivityEnvironment.coastal:
        return 'Coastal';
      case ActivityEnvironment.indoor:
        return 'Indoor';
    }
  }

  String _getDurationText() {
    if (activity.status == ActivityStatus.active &&
        activity.startTime != null) {
      final duration = DateTime.now().difference(activity.startTime!);
      return _formatDuration(duration);
    } else if (activity.status == ActivityStatus.completed &&
        activity.startTime != null &&
        activity.endTime != null) {
      final duration = activity.endTime!.difference(activity.startTime!);
      return _formatDuration(duration);
    } else if (activity.estimatedDuration != null) {
      return '~${_formatDuration(activity.estimatedDuration!)}';
    }
    return 'Unknown';
  }

  String _getStartTimeText() {
    if (activity.startTime != null) {
      return _formatTimeAgo(activity.startTime!);
    } else if (activity.plannedStartTime != null) {
      return 'Planned: ${_formatTimeAgo(activity.plannedStartTime!)}';
    }
    return 'Not started';
  }

  Color _getCheckInStatusColor() {
    if (activity.nextCheckInDue == null) return AppTheme.neutralGray;

    final now = DateTime.now();
    final overdue = activity.nextCheckInDue!.isBefore(now);

    if (overdue) {
      return AppTheme.criticalRed;
    } else if (activity.nextCheckInDue!.difference(now).inMinutes <= 15) {
      return AppTheme.warningOrange;
    } else {
      return AppTheme.safeGreen;
    }
  }

  IconData _getCheckInStatusIcon() {
    if (activity.nextCheckInDue == null) return Icons.schedule;

    final now = DateTime.now();
    final overdue = activity.nextCheckInDue!.isBefore(now);

    if (overdue) {
      return Icons.warning;
    } else if (activity.nextCheckInDue!.difference(now).inMinutes <= 15) {
      return Icons.schedule_send;
    } else {
      return Icons.check_circle;
    }
  }

  String _getCheckInStatusText() {
    if (activity.nextCheckInDue == null) {
      return 'No check-in scheduled';
    }

    final now = DateTime.now();
    final nextCheckIn = activity.nextCheckInDue!;

    if (nextCheckIn.isBefore(now)) {
      final overdue = now.difference(nextCheckIn);
      return 'Check-in overdue by ${_formatDuration(overdue)}';
    } else {
      final remaining = nextCheckIn.difference(now);
      return 'Next check-in in ${_formatDuration(remaining)}';
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
