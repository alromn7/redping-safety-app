import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/user_activity.dart';

/// Widget to display activity statistics and monitoring data
class ActivityStatsWidget extends StatelessWidget {
  final UserActivity activity;

  const ActivityStatsWidget({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activity Stats',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 16),

            // Stats grid
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Duration',
                    _getDurationText(),
                    Icons.timer,
                    AppTheme.infoBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Distance',
                    _getDistanceText(),
                    Icons.straighten,
                    AppTheme.safeGreen,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Check-ins',
                    _getCheckInsText(),
                    Icons.check_circle,
                    AppTheme.warningOrange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Safety',
                    _getSafetyScoreText(),
                    Icons.shield,
                    _getSafetyScoreColor(),
                  ),
                ),
              ],
            ),

            // Location info
            if (activity.currentLocation != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.infoBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: AppTheme.infoBlue,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Current Location',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.infoBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${activity.currentLocation!.latitude.toStringAsFixed(4)}, ${activity.currentLocation!.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.secondaryText,
                      ),
                    ),
                    if (activity.currentLocation!.address != null)
                      Text(
                        activity.currentLocation!.address!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.secondaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.secondaryText),
          ),
        ],
      ),
    );
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
    }
    return '0m';
  }

  String _getDistanceText() {
    // Calculate distance from breadcrumbs
    if (activity.breadcrumbs.length < 2) return '0.0 km';

    // Simple distance calculation (in a real app, you'd use proper geospatial calculations)
    double totalDistance = 0.0;
    for (int i = 1; i < activity.breadcrumbs.length; i++) {
      final prev = activity.breadcrumbs[i - 1];
      final curr = activity.breadcrumbs[i];

      // Simplified distance calculation (not accurate for real use)
      final latDiff = curr.latitude - prev.latitude;
      final lonDiff = curr.longitude - prev.longitude;
      final distance =
          (latDiff * latDiff + lonDiff * lonDiff) * 111; // Rough km conversion
      totalDistance += distance;
    }

    return '${totalDistance.toStringAsFixed(1)} km';
  }

  String _getCheckInsText() {
    // Count check-ins (simplified - in real app this would be tracked)
    if (activity.lastCheckIn != null) {
      return '1'; // Simplified
    }
    return '0';
  }

  String _getSafetyScoreText() {
    // Calculate safety score based on various factors
    int score = 100;

    // Deduct for high risk
    switch (activity.riskLevel) {
      case ActivityRiskLevel.moderate:
        score -= 10;
        break;
      case ActivityRiskLevel.high:
        score -= 25;
        break;
      case ActivityRiskLevel.extreme:
        score -= 40;
        break;
      default:
        break;
    }

    // Deduct for overdue check-ins
    if (activity.nextCheckInDue != null &&
        activity.nextCheckInDue!.isBefore(DateTime.now())) {
      score -= 20;
    }

    // Ensure score doesn't go below 0
    score = score.clamp(0, 100);

    return '$score%';
  }

  Color _getSafetyScoreColor() {
    final scoreText = _getSafetyScoreText();
    final score = int.tryParse(scoreText.replaceAll('%', '')) ?? 100;

    if (score >= 80) return AppTheme.safeGreen;
    if (score >= 60) return AppTheme.warningOrange;
    return AppTheme.criticalRed;
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
}
