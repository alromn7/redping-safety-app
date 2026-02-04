import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/theme/app_theme.dart';
import '../core/network/starlink_carrier_utils.dart';
import '../services/app_service_manager.dart';
import '../services/connectivity_monitor_service.dart';
import '../models/user_profile.dart';
import '../services/platform_service.dart';

/// Widget showing overall app status and emergency readiness
class AppStatusWidget extends StatefulWidget {
  const AppStatusWidget({super.key});

  @override
  State<AppStatusWidget> createState() => _AppStatusWidgetState();
}

class _AppStatusWidgetState extends State<AppStatusWidget> {
  final AppServiceManager _serviceManager = AppServiceManager();
  final ConnectivityMonitorService _connectivityMonitor =
      ConnectivityMonitorService();
  double _readinessScore = 0.0;
  Timer? _timer;

  bool _hasMobileConnectivity = false;
  bool _hasWifiConnectivity = false;

  String _carrierName = 'Unknown';
  bool _carrierStarlinkCapable = false;

  @override
  void initState() {
    super.initState();
    _connectivityMonitor.initialize();
    _updateStatus();

    // Update status every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _updateStatus();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _updateStatus() async {
    if (!mounted) return;

    // Connectivity type (mobile/wifi)
    bool hasMobile = false;
    bool hasWifi = false;
    try {
      final results = await Connectivity().checkConnectivity();
      hasMobile = results.contains(ConnectivityResult.mobile);
      hasWifi =
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet) ||
          results.contains(ConnectivityResult.vpn);
    } catch (_) {
      // Non-fatal; we'll just keep previous values
    }

    String carrierName = _carrierName;
    bool carrierStarlink = _carrierStarlinkCapable;
    try {
      carrierName = await PlatformService.getCarrierName();
      carrierStarlink = StarlinkCarrierUtils.isStarlinkPartnerCarrier(carrierName);
    } catch (_) {
      // Non-fatal
    }

    if (!mounted) return;
    setState(() {
      _readinessScore = _serviceManager.getEmergencyReadinessScore();
      _hasMobileConnectivity = hasMobile;
      _hasWifiConnectivity = hasWifi;
      _carrierName = carrierName;
      _carrierStarlinkCapable = carrierStarlink;
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

            const SizedBox(height: 12),

            // Additional readiness indicators
            Row(
              children: [
                Expanded(
                  child: _buildServiceIndicator(
                    'Medical',
                    _getMedicalStatus(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildServiceIndicator(
                    'Mobile',
                    _getMobileNetworkStatus(),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _buildServiceIndicator(
                    'Starlink',
                    _getStarlinkCarrierStatus(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildServiceIndicator(
                    'Satellite',
                    _getSatelliteEnabledStatus(),
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
    final showCarrier = label == 'Starlink';
    final carrierText = _carrierName.trim().isEmpty ? 'Unknown' : _carrierName;

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

        if (showCarrier) ...[
          const SizedBox(height: 2),
          Text(
            carrierText,
            style: const TextStyle(
              color: AppTheme.secondaryText,
              fontSize: 9,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
    final hasActiveSession = _serviceManager.sosService.hasActiveSession;
    if (hasActiveSession) return ServiceStatus.active;
    return _serviceManager.sosService.isInitialized
        ? ServiceStatus.ready
        : ServiceStatus.error;
  }

  ServiceStatus _getSensorStatus() {
    final sensor = _serviceManager.sensorService;
    if (sensor.isMonitoring) return ServiceStatus.active;
    // Consider sensors "ready" when at least one detection mode is enabled.
    if (sensor.crashDetectionEnabled || sensor.fallDetectionEnabled) {
      return ServiceStatus.ready;
    }
    return ServiceStatus.error;
  }

  ServiceStatus _getLocationStatus() {
    final location = _serviceManager.locationService;
    if (location.isTracking) return ServiceStatus.active;
    return location.hasPermission ? ServiceStatus.ready : ServiceStatus.error;
  }

  ServiceStatus _getContactsStatus() {
    final enabledCount = _serviceManager.contactsService.enabledContacts.length;
    if (enabledCount >= 2) return ServiceStatus.active;
    if (enabledCount >= 1) return ServiceStatus.ready;
    return ServiceStatus.error;
  }

  ServiceStatus _getMedicalStatus() {
    final profile = _serviceManager.profileService.currentProfile;
    if (profile == null) return ServiceStatus.error;

    return _hasAnyMedicalInfo(profile) ? ServiceStatus.ready : ServiceStatus.error;
  }

  bool _hasAnyMedicalInfo(UserProfile profile) {
    final hasBlood = (profile.bloodType ?? '').trim().isNotEmpty;
    final hasAllergies = profile.allergies.isNotEmpty;
    final hasMeds = profile.medications.isNotEmpty;
    final hasConditions = profile.medicalConditions.isNotEmpty;
    final hasDob = profile.dateOfBirth != null;
    return hasBlood || hasAllergies || hasMeds || hasConditions || hasDob;
  }

  ServiceStatus _getMobileNetworkStatus() {
    // Green when we have a mobile data bearer AND internet is reachable.
    final internetOk = _connectivityMonitor.hasInternetAccess;
    if (_hasMobileConnectivity && internetOk) return ServiceStatus.active;
    // If internet is reachable but via Wi‑Fi/other, show "ready".
    if ((_hasWifiConnectivity || !_connectivityMonitor.isEffectivelyOffline) &&
        internetOk) {
      return ServiceStatus.ready;
    }
    return ServiceStatus.error;
  }

  /// Starlink readiness based on carrier partnership (e.g., Telstra/Globe).
  /// This is about wide SMS reach in remote areas, not device satellite APIs.
  ServiceStatus _getStarlinkCarrierStatus() {
    if (_carrierStarlinkCapable) {
      // "Active" when we actually have a mobile bearer right now.
      if (_hasMobileConnectivity) return ServiceStatus.active;
      // Otherwise still "ready" (capable when mobile is present).
      return ServiceStatus.ready;
    }
    return ServiceStatus.error;
  }

  /// Satellite device feature readiness (separate from carrier Starlink).
  ServiceStatus _getSatelliteEnabledStatus() {
    final sat = _serviceManager.satelliteService;
    if (sat.canSendEmergency || sat.isConnected) return ServiceStatus.active;
    if (sat.isEnabled && sat.hasPermission && sat.isAvailable) {
      return ServiceStatus.ready;
    }
    return ServiceStatus.error;
  }

  Color _getStatusColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.active:
        return AppTheme.safeGreen;
      case ServiceStatus.ready:
        // "Ready" is still good-to-go; show green in SOS readiness.
        return AppTheme.safeGreen;
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
