import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/hazard_alert.dart';

/// Widget displaying a hazard alert card
class HazardAlertCard extends StatelessWidget {
  final HazardAlert alert;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  const HazardAlertCard({
    super.key,
    required this.alert,
    this.onDismiss,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getSeverityColor(alert.severity).withValues(alpha: 0.3),
              width: 2,
            ),
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
                      color: _getSeverityColor(
                        alert.severity,
                      ).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getTypeEmoji(alert.type),
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryText,
                          ),
                        ),
                        Text(
                          _getTypeDisplayName(alert.type),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getSeverityColor(alert.severity),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          alert.severity.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (onDismiss != null) ...[
                        const SizedBox(height: 4),
                        IconButton(
                          onPressed: onDismiss,
                          icon: const Icon(Icons.close, size: 18),
                          color: AppTheme.neutralGray,
                          tooltip: 'Dismiss',
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                alert.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryText,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // Time information
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppTheme.secondaryText,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Issued ${_formatTimestamp(alert.issuedAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                  if (alert.expiresAt != null && !alert.isExpired) ...[
                    const Spacer(),
                    Icon(Icons.timer, size: 14, color: AppTheme.warningOrange),
                    const SizedBox(width: 4),
                    Text(
                      'Expires ${_formatTimestamp(alert.expiresAt!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.warningOrange,
                      ),
                    ),
                  ],
                ],
              ),

              // Source and location
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.source, size: 14, color: AppTheme.secondaryText),
                  const SizedBox(width: 4),
                  Text(
                    _getSourceDisplayName(alert.source),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                  if (alert.affectedArea != null) ...[
                    const Spacer(),
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: AppTheme.criticalRed,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Near you',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.criticalRed,
                      ),
                    ),
                  ],
                ],
              ),

              // Tags
              if (alert.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: alert.tags
                      .take(4)
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.infoBlue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: AppTheme.infoBlue,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],

              // Action buttons
              if (alert.instructions.isNotEmpty ||
                  alert.safetyTips.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onTap,
                        icon: const Icon(Icons.info_outline, size: 16),
                        label: const Text(
                          'View Details',
                          style: TextStyle(fontSize: 13),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _getSeverityColor(alert.severity),
                          side: BorderSide(
                            color: _getSeverityColor(alert.severity),
                          ),
                        ),
                      ),
                    ),
                    if (alert.severity == HazardSeverity.extreme ||
                        alert.severity == HazardSeverity.critical) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _shareAlert(context),
                          icon: const Icon(Icons.share, size: 16),
                          label: const Text(
                            'Share Alert',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _getSeverityColor(alert.severity),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _shareAlert(BuildContext context) {
    // TODO: Implement alert sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alert sharing functionality coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
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

  String _getSourceDisplayName(HazardSource source) {
    return switch (source) {
      HazardSource.nationalWeatherService => 'Weather Service',
      HazardSource.emergencyManagement => 'Emergency Mgmt',
      HazardSource.localAuthorities => 'Local Authorities',
      HazardSource.communityReport => 'Community',
      HazardSource.automatedSystem => 'Automated',
      HazardSource.userReport => 'User Report',
      HazardSource.sensorNetwork => 'Sensors',
      HazardSource.satelliteData => 'Satellite',
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
