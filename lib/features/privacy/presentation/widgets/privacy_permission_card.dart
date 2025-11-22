import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/privacy_security.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Widget to display a privacy permission card
class PrivacyPermissionCard extends StatelessWidget {
  final PrivacyPermission permission;
  final VoidCallback onToggle;
  final VoidCallback onInfo;

  const PrivacyPermissionCard({
    super.key,
    required this.permission,
    required this.onToggle,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                    color: _getStatusColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getPermissionIcon(),
                    color: _getStatusColor(),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            permission.displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryText,
                            ),
                          ),
                          if (permission.isRequired) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.criticalRed,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'REQUIRED',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        permission.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.secondaryText,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onInfo,
                  icon: const Icon(Icons.info_outline),
                  iconSize: 20,
                  tooltip: 'More Info',
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Status and actions
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getStatusColor().withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(),
                          color: _getStatusColor(),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getStatusDisplayName(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(),
                                ),
                              ),
                              if (permission.lastUsed != null)
                                Text(
                                  'Last used: ${_formatTimeAgo(permission.lastUsed!)}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.secondaryText,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Action button
                if (permission.status == PermissionStatus.notRequested ||
                    permission.status == PermissionStatus.denied)
                  ElevatedButton(
                    onPressed: onToggle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: permission.isRequired
                          ? AppTheme.criticalRed
                          : AppTheme.infoBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      permission.isRequired ? 'Grant' : 'Allow',
                      style: const TextStyle(fontSize: 12),
                    ),
                  )
                else if (permission.status ==
                    PermissionStatus.permanentlyDenied)
                  OutlinedButton(
                    onPressed: () => ph.openAppSettings(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.warningOrange,
                      side: const BorderSide(color: AppTheme.warningOrange),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Settings',
                      style: TextStyle(fontSize: 12),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.safeGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Granted',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.safeGreen,
                      ),
                    ),
                  ),
              ],
            ),

            // Purpose tags
            if (permission.purposes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: permission.purposes.map((purpose) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.infoBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.infoBlue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      _getPurposeDisplayName(purpose),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.infoBlue,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getPermissionIcon() {
    switch (permission.type) {
      case PrivacyPermissionType.location:
        return Icons.location_on;
      case PrivacyPermissionType.camera:
        return Icons.camera_alt;
      case PrivacyPermissionType.microphone:
        return Icons.mic;
      case PrivacyPermissionType.contacts:
        return Icons.contacts;
      case PrivacyPermissionType.storage:
        return Icons.storage;
      case PrivacyPermissionType.notifications:
        return Icons.notifications;
      case PrivacyPermissionType.bluetooth:
        return Icons.bluetooth;
      case PrivacyPermissionType.sensors:
        return Icons.sensors;
      case PrivacyPermissionType.phone:
        return Icons.phone;
      case PrivacyPermissionType.sms:
        return Icons.sms;
      case PrivacyPermissionType.calendar:
        return Icons.calendar_today;
      case PrivacyPermissionType.photos:
        return Icons.photo_library;
      case PrivacyPermissionType.satellite:
        return Icons.satellite_alt;
      case PrivacyPermissionType.emergencyServices:
        return Icons.emergency;
      case PrivacyPermissionType.biometric:
        return Icons.fingerprint;
      case PrivacyPermissionType.deviceInfo:
        return Icons.info;
    }
  }

  Color _getStatusColor() {
    switch (permission.status) {
      case PermissionStatus.granted:
        return AppTheme.safeGreen;
      case PermissionStatus.denied:
        return AppTheme.warningOrange;
      case PermissionStatus.permanentlyDenied:
        return AppTheme.criticalRed;
      case PermissionStatus.restricted:
        return AppTheme.neutralGray;
      case PermissionStatus.provisional:
        return AppTheme.infoBlue;
      case PermissionStatus.notRequested:
        return AppTheme.neutralGray;
    }
  }

  IconData _getStatusIcon() {
    switch (permission.status) {
      case PermissionStatus.granted:
        return Icons.check_circle;
      case PermissionStatus.denied:
        return Icons.cancel;
      case PermissionStatus.permanentlyDenied:
        return Icons.block;
      case PermissionStatus.restricted:
        return Icons.warning;
      case PermissionStatus.provisional:
        return Icons.schedule;
      case PermissionStatus.notRequested:
        return Icons.help_outline;
    }
  }

  String _getStatusDisplayName() {
    switch (permission.status) {
      case PermissionStatus.granted:
        return 'Granted';
      case PermissionStatus.denied:
        return 'Denied';
      case PermissionStatus.permanentlyDenied:
        return 'Permanently Denied';
      case PermissionStatus.restricted:
        return 'Restricted';
      case PermissionStatus.provisional:
        return 'Provisional';
      case PermissionStatus.notRequested:
        return 'Not Requested';
    }
  }

  String _getPurposeDisplayName(DataCollectionPurpose purpose) {
    switch (purpose) {
      case DataCollectionPurpose.emergencyResponse:
        return 'Emergency';
      case DataCollectionPurpose.locationTracking:
        return 'Location';
      case DataCollectionPurpose.activityMonitoring:
        return 'Activity';
      case DataCollectionPurpose.hazardAlerts:
        return 'Hazards';
      case DataCollectionPurpose.communicationServices:
        return 'Communication';
      case DataCollectionPurpose.userProfile:
        return 'Profile';
      case DataCollectionPurpose.analytics:
        return 'Analytics';
      case DataCollectionPurpose.crashReporting:
        return 'Crashes';
      case DataCollectionPurpose.performanceMonitoring:
        return 'Performance';
      case DataCollectionPurpose.securityMonitoring:
        return 'Security';
      case DataCollectionPurpose.backupRestore:
        return 'Backup';
      case DataCollectionPurpose.serviceImprovement:
        return 'Improvement';
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
