// ignore_for_file: unused_element
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/hazard_alert.dart';

/// Widget displaying a community hazard report
class CommunityReportCard extends StatelessWidget {
  final CommunityHazardReport report;
  final VoidCallback? onVerify;

  const CommunityReportCard({super.key, required this.report, this.onVerify});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                    color: _getSeverityColor(
                      report.reportedSeverity,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getTypeEmoji(report.type),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      Text(
                        _getTypeDisplayName(report.type),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildVerificationBadge(),
              ],
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              report.description,
              style: const TextStyle(fontSize: 14, color: AppTheme.primaryText),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Location and time
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: AppTheme.criticalRed),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    report.location.address ??
                        '${report.location.latitude.toStringAsFixed(4)}, ${report.location.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: AppTheme.secondaryText,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTimestamp(report.reportedAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
              ],
            ),

            // Media and verification info
            if (report.mediaFiles.isNotEmpty ||
                report.verificationCount > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  if (report.mediaFiles.isNotEmpty) ...[
                    Icon(
                      Icons.photo_library,
                      size: 14,
                      color: AppTheme.infoBlue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${report.mediaFiles.length} media',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.infoBlue,
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  if (report.verificationCount > 0) ...[
                    Icon(Icons.verified, size: 14, color: AppTheme.safeGreen),
                    const SizedBox(width: 4),
                    Text(
                      '${report.verificationCount} verifications',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.safeGreen,
                      ),
                    ),
                  ],
                ],
              ),
            ],

            // Tags
            if (report.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: report.tags
                    .take(3)
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.neutralGray.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: AppTheme.secondaryText,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],

            // Action buttons
            if (!report.isVerified &&
                report.needsVerification &&
                onVerify != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onVerify,
                      icon: const Icon(Icons.thumb_up, size: 16),
                      label: const Text(
                        'Verify Report',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.safeGreen,
                        side: const BorderSide(color: AppTheme.safeGreen),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showReportDetails(context),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text(
                        'View Details',
                        style: TextStyle(fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.infoBlue,
                        side: const BorderSide(color: AppTheme.infoBlue),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationBadge() {
    if (report.isVerified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.safeGreen,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified, color: Colors.white, size: 12),
            SizedBox(width: 4),
            Text(
              'VERIFIED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (report.verificationCount > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.warningOrange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${report.verificationCount}/3',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.neutralGray.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'UNVERIFIED',
          style: TextStyle(
            color: AppTheme.neutralGray,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  void _showReportDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _CommunityReportDetailsDialog(report: report),
    );
  }

  Color _getSeverityColor(HazardSeverity severity) {
    return switch (severity) {
      HazardSeverity.info => AppTheme.infoBlue,
      HazardSeverity.minor => AppTheme.safeGreen,
      HazardSeverity.moderate => AppTheme.warningOrange,
      HazardSeverity.severe => AppTheme.primaryRed,
      HazardSeverity.extreme => AppTheme.criticalRed,
      HazardSeverity.critical => AppTheme.criticalRed,
    };
  }

  String _getTypeEmoji(HazardType type) {
    return switch (type) {
      HazardType.weather => '🌩️',
      HazardType.earthquake => '🌍',
      HazardType.fire => '🔥',
      HazardType.flood => '🌊',
      HazardType.tornado => '🌪️',
      HazardType.hurricane => '🌀',
      HazardType.tsunami => '🌊',
      HazardType.landslide => '⛰️',
      HazardType.avalanche => '❄️',
      HazardType.chemicalSpill => '☣️',
      HazardType.gasLeak => '💨',
      HazardType.roadClosure => '🚧',
      HazardType.powerOutage => '⚡',
      HazardType.airQuality => '😷',
      _ => '⚠️',
    };
  }

  String _getTypeDisplayName(HazardType type) {
    return switch (type) {
      HazardType.weather => 'Weather Alert',
      HazardType.earthquake => 'Earthquake',
      HazardType.fire => 'Fire Hazard',
      HazardType.flood => 'Flood Warning',
      HazardType.tornado => 'Tornado Warning',
      HazardType.hurricane => 'Hurricane',
      HazardType.tsunami => 'Tsunami Warning',
      HazardType.landslide => 'Landslide',
      HazardType.avalanche => 'Avalanche',
      HazardType.chemicalSpill => 'Chemical Spill',
      HazardType.gasLeak => 'Gas Leak',
      HazardType.roadClosure => 'Road Closure',
      HazardType.powerOutage => 'Power Outage',
      HazardType.airQuality => 'Air Quality',
      HazardType.civilEmergency => 'Civil Emergency',
      HazardType.amberAlert => 'Amber Alert',
      HazardType.securityThreat => 'Security Threat',
      HazardType.evacuation => 'Evacuation Order',
      HazardType.shelterInPlace => 'Shelter in Place',
      HazardType.communityHazard => 'Community Hazard',
      _ => 'Hazard Alert',
    };
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}

/// Dialog showing community report details
class _CommunityReportDetailsDialog extends StatelessWidget {
  final CommunityHazardReport report;

  const _CommunityReportDetailsDialog({required this.report});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(report.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Type: ${_getTypeDisplayName(report.type)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Severity: ${report.reportedSeverity.name.toUpperCase()}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _getSeverityColor(report.reportedSeverity),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Description:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(report.description),
            const SizedBox(height: 16),
            Text(
              'Reported: ${_formatDateTime(report.reportedAt)}',
              style: const TextStyle(color: AppTheme.secondaryText),
            ),
            if (report.mediaFiles.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Media files: ${report.mediaFiles.length}',
                style: const TextStyle(color: AppTheme.infoBlue),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Color _getSeverityColor(HazardSeverity severity) {
    return switch (severity) {
      HazardSeverity.info => AppTheme.infoBlue,
      HazardSeverity.minor => AppTheme.safeGreen,
      HazardSeverity.moderate => AppTheme.warningOrange,
      HazardSeverity.severe => AppTheme.primaryRed,
      HazardSeverity.extreme => AppTheme.criticalRed,
      HazardSeverity.critical => AppTheme.criticalRed,
    };
  }

  String _getTypeEmoji(HazardType type) {
    return switch (type) {
      HazardType.weather => '🌩️',
      HazardType.earthquake => '🌍',
      HazardType.fire => '🔥',
      HazardType.flood => '🌊',
      HazardType.tornado => '🌪️',
      HazardType.hurricane => '🌀',
      HazardType.tsunami => '🌊',
      HazardType.landslide => '⛰️',
      HazardType.avalanche => '❄️',
      HazardType.chemicalSpill => '☣️',
      HazardType.gasLeak => '💨',
      HazardType.roadClosure => '🚧',
      HazardType.powerOutage => '⚡',
      HazardType.airQuality => '😷',
      _ => '⚠️',
    };
  }

  String _getTypeDisplayName(HazardType type) {
    return switch (type) {
      HazardType.weather => 'Weather Alert',
      HazardType.earthquake => 'Earthquake',
      HazardType.fire => 'Fire Hazard',
      HazardType.flood => 'Flood Warning',
      HazardType.tornado => 'Tornado Warning',
      HazardType.hurricane => 'Hurricane',
      HazardType.tsunami => 'Tsunami Warning',
      HazardType.landslide => 'Landslide',
      HazardType.avalanche => 'Avalanche',
      HazardType.chemicalSpill => 'Chemical Spill',
      HazardType.gasLeak => 'Gas Leak',
      HazardType.roadClosure => 'Road Closure',
      HazardType.powerOutage => 'Power Outage',
      HazardType.airQuality => 'Air Quality',
      HazardType.civilEmergency => 'Civil Emergency',
      HazardType.amberAlert => 'Amber Alert',
      HazardType.securityThreat => 'Security Threat',
      HazardType.evacuation => 'Evacuation Order',
      HazardType.shelterInPlace => 'Shelter in Place',
      HazardType.communityHazard => 'Community Hazard',
      _ => 'Hazard Alert',
    };
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}
