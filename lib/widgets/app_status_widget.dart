import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/app_service_manager.dart';

/// Widget showing overall app status and emergency readiness
class AppStatusWidget extends StatefulWidget {
  const AppStatusWidget({super.key});

  @override
  State<AppStatusWidget> createState() => _AppStatusWidgetState();
}

class _AppStatusWidgetState extends State<AppStatusWidget> {
  final AppServiceManager _serviceManager = AppServiceManager();
  double _readinessScore = 0.0;
  Map<String, dynamic> _appStatus = {};

  @override
  void initState() {
    super.initState();
    _updateStatus();

    // Update status every 30 seconds
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _updateStatus();
      } else {
        timer.cancel();
      }
    });
  }

  void _updateStatus() {
    if (!mounted) return;
    setState(() {
      _readinessScore = _serviceManager.getEmergencyReadinessScore();
      _appStatus = _serviceManager.getAppStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getReadinessIcon(),
                  color: _getReadinessColor(),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Emergency Readiness',
                    style: TextStyle(
                      color: AppTheme.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getReadinessColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(_readinessScore * 100).toInt()}%',
                    style: TextStyle(
                      color: _getReadinessColor(),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Readiness progress bar
            LinearProgressIndicator(
              value: _readinessScore,
              backgroundColor: AppTheme.neutralGray.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(_getReadinessColor()),
            ),

            const SizedBox(height: 16),

            // Service status indicators
            Row(
              children: [
                Expanded(child: _buildServiceIndicator('SOS', _getSOSStatus())),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildServiceIndicator('Sensors', _getSensorStatus()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildServiceIndicator('GPS', _getLocationStatus()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildServiceIndicator(
                    'Contacts',
                    _getContactsStatus(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceIndicator(String label, ServiceStatus status) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getStatusColor(status),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: _getStatusColor(status),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  IconData _getReadinessIcon() {
    if (_readinessScore >= 0.9) return Icons.check_circle;
    if (_readinessScore >= 0.7) return Icons.warning;
    return Icons.error;
  }

  Color _getReadinessColor() {
    if (_readinessScore >= 0.9) return AppTheme.safeGreen;
    if (_readinessScore >= 0.7) return AppTheme.warningOrange;
    return AppTheme.criticalRed;
  }

  ServiceStatus _getSOSStatus() {
    final services = _appStatus['services'] as Map<String, dynamic>? ?? {};
    final sosStatus = services['sos'] as Map<String, dynamic>? ?? {};
    final isInitialized = sosStatus['isInitialized'] ?? false;
    final hasActiveSession = sosStatus['hasActiveSession'] ?? false;

    if (hasActiveSession) return ServiceStatus.active;
    if (isInitialized) return ServiceStatus.ready;
    return ServiceStatus.error;
  }

  ServiceStatus _getSensorStatus() {
    final services = _appStatus['services'] as Map<String, dynamic>? ?? {};
    final sensorStatus = services['sensor'] as Map<String, dynamic>? ?? {};
    final isMonitoring = sensorStatus['isMonitoring'] ?? false;

    if (isMonitoring) return ServiceStatus.active;
    return ServiceStatus.error;
  }

  ServiceStatus _getLocationStatus() {
    final services = _appStatus['services'] as Map<String, dynamic>? ?? {};
    final locationStatus = services['location'] as Map<String, dynamic>? ?? {};
    final hasPermission = locationStatus['hasPermission'] ?? false;
    final isTracking = locationStatus['isTracking'] ?? false;

    if (isTracking) return ServiceStatus.active;
    if (hasPermission) return ServiceStatus.ready;
    return ServiceStatus.error;
  }

  ServiceStatus _getContactsStatus() {
    final services = _appStatus['services'] as Map<String, dynamic>? ?? {};
    final contactsStatus = services['contacts'] as Map<String, dynamic>? ?? {};
    final enabledContacts = contactsStatus['enabledContacts'] ?? 0;

    if (enabledContacts >= 2) return ServiceStatus.active;
    if (enabledContacts >= 1) return ServiceStatus.ready;
    return ServiceStatus.error;
  }

  Color _getStatusColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.active:
        return AppTheme.safeGreen;
      case ServiceStatus.ready:
        return AppTheme.infoBlue;
      case ServiceStatus.error:
        return AppTheme.criticalRed;
    }
  }
}

enum ServiceStatus {
  active, // Fully operational
  ready, // Available but not active
  error, // Not working or not configured
}
