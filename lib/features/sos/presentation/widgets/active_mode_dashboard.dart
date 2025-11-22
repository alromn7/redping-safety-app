import 'package:flutter/material.dart';
import '../../../../models/redping_mode.dart';
import '../../../../services/redping_mode_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/app_service_manager.dart';

/// Active Mode Dashboard - Shows real-time stats when a mode is active
class ActiveModeDashboard extends StatefulWidget {
  const ActiveModeDashboard({super.key});

  @override
  State<ActiveModeDashboard> createState() => _ActiveModeDashboardState();
}

class _ActiveModeDashboardState extends State<ActiveModeDashboard> {
  final RedPingModeService _modeService = RedPingModeService();
  final AppServiceManager _serviceManager = AppServiceManager();

  @override
  Widget build(BuildContext context) {
    if (!_modeService.hasActiveMode) {
      return const SizedBox.shrink();
    }

    final mode = _modeService.activeMode!;
    final session = _modeService.activeSession!;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mode.themeColor, width: 2),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: mode.themeColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Icon(mode.icon, color: mode.themeColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.name,
                        style: TextStyle(
                          color: mode.themeColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Active for ${_formatDuration(session.duration)}',
                        style: const TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: mode.themeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Metrics Grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Configuration metrics
                Row(
                  children: [
                    _buildMetricCard(
                      'Crash Threshold',
                      '${mode.sensorConfig.crashThreshold.toInt()} m/s²',
                      Icons.warning,
                      AppTheme.criticalRed,
                    ),
                    const SizedBox(width: 12),
                    _buildMetricCard(
                      'Fall Threshold',
                      '${mode.sensorConfig.fallThreshold.toInt()} m/s²',
                      Icons.arrow_downward,
                      AppTheme.warningOrange,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildMetricCard(
                      'SOS Countdown',
                      '${mode.emergencyConfig.sosCountdown.inSeconds}s',
                      Icons.timer,
                      AppTheme.infoBlue,
                    ),
                    const SizedBox(width: 12),
                    _buildMetricCard(
                      'Power Mode',
                      _formatPowerMode(mode.sensorConfig.powerMode),
                      Icons.battery_charging_full,
                      AppTheme.safeGreen,
                    ),
                  ],
                ),

                // Real-time stats
                const SizedBox(height: 16),
                _buildRealTimeStats(),

                // Active hazard types
                if (mode.activeHazardTypes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildHazardChips(mode.activeHazardTypes),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealTimeStats() {
    final sensor = _serviceManager.sensorService;
    final location = _serviceManager.locationService;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sensors, color: AppTheme.safeGreen, size: 16),
              SizedBox(width: 6),
              Text(
                'Real-Time Monitoring',
                style: TextStyle(
                  color: AppTheme.primaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Status',
                sensor.isMonitoring ? 'Active' : 'Idle',
                sensor.isMonitoring
                    ? AppTheme.safeGreen
                    : AppTheme.secondaryText,
              ),
              _buildStatItem(
                'Location',
                location.isTracking ? 'Tracking' : 'Off',
                location.isTracking
                    ? AppTheme.safeGreen
                    : AppTheme.secondaryText,
              ),
              _buildStatItem(
                'Sensors',
                sensor.isMonitoring ? 'On' : 'Off',
                sensor.isMonitoring
                    ? AppTheme.safeGreen
                    : AppTheme.secondaryText,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppTheme.secondaryText, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildHazardChips(List<String> hazards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.warning_amber, color: AppTheme.warningOrange, size: 16),
            SizedBox(width: 6),
            Text(
              'Active Hazard Monitoring',
              style: TextStyle(
                color: AppTheme.primaryText,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: hazards.map((hazard) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.warningOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.warningOrange.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _formatHazardName(hazard),
                style: const TextStyle(
                  color: AppTheme.warningOrange,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  String _formatPowerMode(PowerMode mode) {
    switch (mode) {
      case PowerMode.low:
        return 'Low';
      case PowerMode.balanced:
        return 'Balanced';
      case PowerMode.high:
        return 'High';
    }
  }

  String _formatHazardName(String hazard) {
    return hazard
        .split('_')
        .map((word) {
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }
}
