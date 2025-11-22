import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/sos_ping.dart';

/// Professional emergency card with enhanced visual design and functionality
class ProfessionalEmergencyCard extends StatelessWidget {
  final SOSPing emergency;
  final VoidCallback onRespond;
  final VoidCallback onViewDetails;

  const ProfessionalEmergencyCard({
    super.key,
    required this.emergency,
    required this.onRespond,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(emergency.priority);
    final timeElapsed = _getTimeElapsed(emergency.timestamp);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: priorityColor.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: priorityColor.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Priority Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: priorityColor),
              child: Row(
                children: [
                  Icon(Icons.emergency, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${emergency.priority.name.toUpperCase()} PRIORITY EMERGENCY',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      timeElapsed,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: priorityColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          Icons.person,
                          color: priorityColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              emergency.userName ?? 'Unknown User',
                              style: const TextStyle(
                                color: AppTheme.primaryText,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Emergency Request',
                              style: TextStyle(
                                color: AppTheme.secondaryText,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                            emergency.status,
                          ).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          emergency.status.name.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(emergency.status),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Emergency Message
                  if (emergency.userMessage?.isNotEmpty == true) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.darkBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: priorityColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        emergency.userMessage!,
                        style: const TextStyle(
                          color: AppTheme.primaryText,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Location and Medical Info
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoChip(
                          Icons.location_on,
                          'Location',
                          '${emergency.location.latitude.toStringAsFixed(4)}, ${emergency.location.longitude.toStringAsFixed(4)}',
                          AppTheme.infoBlue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoChip(
                          Icons.timer,
                          'ETA',
                          '${emergency.estimatedRescueTime} min',
                          AppTheme.warningOrange,
                        ),
                      ),
                    ],
                  ),

                  if (emergency.medicalConditions.isNotEmpty ||
                      emergency.allergies.isNotEmpty ||
                      emergency.bloodType != null) ...[
                    const SizedBox(height: 12),
                    _buildMedicalInfo(),
                  ],

                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onRespond,
                          icon: const Icon(Icons.assignment, size: 18),
                          label: const Text('RESPOND'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: priorityColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onViewDetails,
                          icon: const Icon(Icons.info_outline, size: 18),
                          label: const Text('DETAILS'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: priorityColor,
                            side: BorderSide(color: priorityColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: AppTheme.primaryText, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.warningOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.warningOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.medical_services,
                color: AppTheme.warningOrange,
                size: 16,
              ),
              const SizedBox(width: 4),
              const Text(
                'Medical Information',
                style: TextStyle(
                  color: AppTheme.warningOrange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (emergency.bloodType != null) ...[
            Text(
              'Blood Type: ${emergency.bloodType}',
              style: const TextStyle(color: AppTheme.primaryText, fontSize: 12),
            ),
            const SizedBox(height: 4),
          ],
          if (emergency.medicalConditions.isNotEmpty) ...[
            Text(
              'Conditions: ${emergency.medicalConditions.join(', ')}',
              style: const TextStyle(color: AppTheme.primaryText, fontSize: 12),
            ),
            const SizedBox(height: 4),
          ],
          if (emergency.allergies.isNotEmpty) ...[
            Text(
              'Allergies: ${emergency.allergies.join(', ')}',
              style: const TextStyle(color: AppTheme.primaryText, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Color _getPriorityColor(SOSPriority priority) {
    switch (priority) {
      case SOSPriority.low:
        return AppTheme.safeGreen;
      case SOSPriority.medium:
        return AppTheme.warningOrange;
      case SOSPriority.high:
        return AppTheme.primaryRed;
      case SOSPriority.critical:
        return AppTheme.criticalRed;
    }
  }

  Color _getStatusColor(SOSPingStatus status) {
    switch (status) {
      case SOSPingStatus.active:
        return AppTheme.primaryRed;
      case SOSPingStatus.assigned:
        return AppTheme.infoBlue;
      case SOSPingStatus.inProgress:
        return AppTheme.warningOrange;
      // case SOSPingStatus.completed: // This enum value doesn't exist
      //   return AppTheme.safeGreen;
      case SOSPingStatus.cancelled:
        return AppTheme.neutralGray;
      case SOSPingStatus.resolved:
        return AppTheme.safeGreen;
      case SOSPingStatus.expired:
        return AppTheme.neutralGray;
    }
  }

  String _getTimeElapsed(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
