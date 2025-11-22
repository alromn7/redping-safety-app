import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/privacy_security.dart';

/// Widget to display data collection policy information
class DataCollectionCard extends StatelessWidget {
  final DataCollectionPolicy policy;
  final bool isOptedOut;
  final VoidCallback onToggle;

  const DataCollectionCard({
    super.key,
    required this.policy,
    required this.isOptedOut,
    required this.onToggle,
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
                    color: _getPurposeColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getPurposeIcon(),
                    color: _getPurposeColor(),
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
                            _getPurposeDisplayName(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryText,
                            ),
                          ),
                          if (!policy.isOptional) ...[
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
                        policy.description,
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
                if (policy.isOptional)
                  Switch(
                    value: !isOptedOut,
                    onChanged: (_) => onToggle(),
                    activeThumbColor: AppTheme.safeGreen,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Data details
            _buildDataDetailsSection(),

            const SizedBox(height: 12),

            // Security and retention info
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    'Retention',
                    _getRetentionDisplayName(),
                    Icons.schedule,
                    AppTheme.infoBlue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    'Encryption',
                    _getEncryptionDisplayName(),
                    Icons.lock,
                    _getEncryptionColor(),
                  ),
                ),
              ],
            ),

            if (policy.isSharedWithThirdParties) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.warningOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.warningOrange.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.share,
                      color: AppTheme.warningOrange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Shared with Third Parties',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.warningOrange,
                            ),
                          ),
                          if (policy.thirdParties.isNotEmpty)
                            Text(
                              policy.thirdParties.join(', '),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.secondaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
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

  Widget _buildDataDetailsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Types Collected:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: policy.dataTypes.map((dataType) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.neutralGray.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  dataType.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.neutralGray,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.secondaryText,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPurposeColor() {
    switch (policy.purpose) {
      case DataCollectionPurpose.emergencyResponse:
        return AppTheme.criticalRed;
      case DataCollectionPurpose.locationTracking:
        return AppTheme.infoBlue;
      case DataCollectionPurpose.activityMonitoring:
        return AppTheme.safeGreen;
      case DataCollectionPurpose.hazardAlerts:
        return AppTheme.warningOrange;
      case DataCollectionPurpose.securityMonitoring:
        return AppTheme.primaryRed;
      default:
        return AppTheme.neutralGray;
    }
  }

  IconData _getPurposeIcon() {
    switch (policy.purpose) {
      case DataCollectionPurpose.emergencyResponse:
        return Icons.emergency;
      case DataCollectionPurpose.locationTracking:
        return Icons.location_on;
      case DataCollectionPurpose.activityMonitoring:
        return Icons.directions_run;
      case DataCollectionPurpose.hazardAlerts:
        return Icons.warning;
      case DataCollectionPurpose.communicationServices:
        return Icons.chat;
      case DataCollectionPurpose.userProfile:
        return Icons.person;
      case DataCollectionPurpose.analytics:
        return Icons.analytics;
      case DataCollectionPurpose.crashReporting:
        return Icons.bug_report;
      case DataCollectionPurpose.performanceMonitoring:
        return Icons.speed;
      case DataCollectionPurpose.securityMonitoring:
        return Icons.security;
      case DataCollectionPurpose.backupRestore:
        return Icons.backup;
      case DataCollectionPurpose.serviceImprovement:
        return Icons.trending_up;
    }
  }

  String _getPurposeDisplayName() {
    switch (policy.purpose) {
      case DataCollectionPurpose.emergencyResponse:
        return 'Emergency Response';
      case DataCollectionPurpose.locationTracking:
        return 'Location Tracking';
      case DataCollectionPurpose.activityMonitoring:
        return 'Activity Monitoring';
      case DataCollectionPurpose.hazardAlerts:
        return 'Hazard Alerts';
      case DataCollectionPurpose.communicationServices:
        return 'Communication';
      case DataCollectionPurpose.userProfile:
        return 'User Profile';
      case DataCollectionPurpose.analytics:
        return 'Usage Analytics';
      case DataCollectionPurpose.crashReporting:
        return 'Crash Reporting';
      case DataCollectionPurpose.performanceMonitoring:
        return 'Performance';
      case DataCollectionPurpose.securityMonitoring:
        return 'Security';
      case DataCollectionPurpose.backupRestore:
        return 'Backup & Restore';
      case DataCollectionPurpose.serviceImprovement:
        return 'Service Improvement';
    }
  }

  String _getRetentionDisplayName() {
    switch (policy.retentionPeriod) {
      case DataRetentionPeriod.session:
        return 'Session Only';
      case DataRetentionPeriod.day:
        return '24 Hours';
      case DataRetentionPeriod.week:
        return '7 Days';
      case DataRetentionPeriod.month:
        return '30 Days';
      case DataRetentionPeriod.year:
        return '1 Year';
      case DataRetentionPeriod.indefinite:
        return 'Indefinite';
      case DataRetentionPeriod.legal:
        return 'Legal Requirement';
    }
  }

  String _getEncryptionDisplayName() {
    switch (policy.encryptionLevel) {
      case EncryptionLevel.none:
        return 'None';
      case EncryptionLevel.basic:
        return 'Basic';
      case EncryptionLevel.standard:
        return 'Standard';
      case EncryptionLevel.enterprise:
        return 'Enterprise';
    }
  }

  Color _getEncryptionColor() {
    switch (policy.encryptionLevel) {
      case EncryptionLevel.none:
        return AppTheme.criticalRed;
      case EncryptionLevel.basic:
        return AppTheme.warningOrange;
      case EncryptionLevel.standard:
        return AppTheme.safeGreen;
      case EncryptionLevel.enterprise:
        return AppTheme.infoBlue;
    }
  }
}
