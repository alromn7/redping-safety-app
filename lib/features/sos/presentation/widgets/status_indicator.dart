import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Status indicator showing system health and safety features
class StatusIndicator extends StatelessWidget {
  final bool crashDetectionEnabled;
  final bool fallDetectionEnabled;
  final bool locationServicesEnabled;
  final String batteryLevel;
  final String networkStatus;

  const StatusIndicator({
    super.key,
    required this.crashDetectionEnabled,
    required this.fallDetectionEnabled,
    required this.locationServicesEnabled,
    required this.batteryLevel,
    required this.networkStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getOverallStatusColor().withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _getOverallStatusIcon(),
                color: _getOverallStatusColor(),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Safety Status',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getOverallStatusColor().withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getOverallStatusText(),
                  style: TextStyle(
                    color: _getOverallStatusColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatusItem(
                  icon: Icons.car_crash,
                  label: 'Crash Detection',
                  isEnabled: crashDetectionEnabled,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatusItem(
                  icon: Icons.accessibility_new,
                  label: 'Fall Detection',
                  isEnabled: fallDetectionEnabled,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatusItem(
                  icon: Icons.location_on,
                  label: 'Location Services',
                  isEnabled: locationServicesEnabled,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.battery_std,
                  label: 'Battery',
                  value: batteryLevel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.signal_cellular_alt,
                  label: 'Network',
                  value: networkStatus,
                ),
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String label,
    required bool isEnabled,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isEnabled ? AppTheme.safeGreen : AppTheme.neutralGray,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.secondaryText,
                  fontSize: 12,
                ),
              ),
              Text(
                isEnabled ? 'Enabled' : 'Disabled',
                style: TextStyle(
                  color: isEnabled ? AppTheme.safeGreen : AppTheme.neutralGray,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.infoBlue),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.secondaryText,
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.infoBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getOverallStatusColor() {
    if (crashDetectionEnabled &&
        fallDetectionEnabled &&
        locationServicesEnabled) {
      return AppTheme.safeGreen;
    } else if (locationServicesEnabled) {
      return AppTheme.warningOrange;
    } else {
      return AppTheme.criticalRed;
    }
  }

  IconData _getOverallStatusIcon() {
    if (crashDetectionEnabled &&
        fallDetectionEnabled &&
        locationServicesEnabled) {
      return Icons.check_circle;
    } else if (locationServicesEnabled) {
      return Icons.warning;
    } else {
      return Icons.error;
    }
  }

  String _getOverallStatusText() {
    if (crashDetectionEnabled &&
        fallDetectionEnabled &&
        locationServicesEnabled) {
      return 'All Systems Active';
    } else if (locationServicesEnabled) {
      return 'Partial Coverage';
    } else {
      return 'Issues Detected';
    }
  }
}
