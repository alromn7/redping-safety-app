import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Professional SAR statistics card with comprehensive metrics
class ProfessionalSARStatsCard extends StatelessWidget {
  final int activeEmergencies;
  final int assignedMissions;
  final double responseTime;
  final double successRate;

  const ProfessionalSARStatsCard({
    super.key,
    required this.activeEmergencies,
    required this.assignedMissions,
    required this.responseTime,
    required this.successRate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.safeGreen.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.safeGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: AppTheme.safeGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'SAR Performance Metrics',
                  style: TextStyle(
                    color: AppTheme.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Metrics Grid
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Active Emergencies',
                  activeEmergencies.toString(),
                  Icons.emergency,
                  activeEmergencies > 0
                      ? AppTheme.primaryRed
                      : AppTheme.safeGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricItem(
                  'Assigned Missions',
                  assignedMissions.toString(),
                  Icons.assignment,
                  AppTheme.infoBlue,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  'Avg Response Time',
                  '${responseTime.toStringAsFixed(1)} min',
                  Icons.timer,
                  responseTime <= 15
                      ? AppTheme.safeGreen
                      : AppTheme.warningOrange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricItem(
                  'Success Rate',
                  '${successRate.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  successRate >= 90
                      ? AppTheme.safeGreen
                      : AppTheme.warningOrange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Performance Indicator
          _buildPerformanceIndicator(),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppTheme.secondaryText, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicator() {
    final overallScore = _calculateOverallScore();
    final scoreColor = overallScore >= 80
        ? AppTheme.safeGreen
        : overallScore >= 60
        ? AppTheme.warningOrange
        : AppTheme.criticalRed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Overall Performance',
              style: TextStyle(
                color: AppTheme.primaryText,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${overallScore.toStringAsFixed(0)}/100',
              style: TextStyle(
                color: scoreColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: AppTheme.neutralGray.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: overallScore / 100,
            child: Container(
              decoration: BoxDecoration(
                color: scoreColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }

  double _calculateOverallScore() {
    // Calculate overall performance score based on metrics
    double score = 100.0;

    // Deduct points for active emergencies
    score -= (activeEmergencies * 10).clamp(0, 30);

    // Deduct points for slow response time
    if (responseTime > 15) {
      score -= ((responseTime - 15) * 2).clamp(0, 20);
    }

    // Deduct points for low success rate
    if (successRate < 90) {
      score -= ((90 - successRate) * 1.5).clamp(0, 25);
    }

    return score.clamp(0, 100);
  }
}






