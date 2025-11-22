import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/sos_session.dart';
import 'sos_ticket_card.dart';

/// Widget to display rescue team responses and emergency contact responses
class RescueResponseWidget extends StatelessWidget {
  final SOSSession session;
  final bool isSARView; // true if viewed by SAR responder
  final VoidCallback? onStatusUpdated;

  const RescueResponseWidget({
    super.key,
    required this.session,
    this.isSARView = false,
    this.onStatusUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final hasResponses =
        session.rescueTeamResponses.isNotEmpty ||
        session.emergencyContactResponses.isNotEmpty;

    if (!hasResponses) {
      return const SizedBox.shrink();
    }

    return Card(
      color: AppTheme.safeGreen.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.emergency_share,
                  color: AppTheme.safeGreen,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Help is Coming',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Rescue Team Responses
            if (session.rescueTeamResponses.isNotEmpty) ...[
              const Text(
                'Emergency Responders:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              ...session.rescueTeamResponses.map(
                (response) => SOSTicketCard(
                  response: response,
                  sessionId: session.id,
                  isSARView: isSARView,
                  onStatusUpdated: onStatusUpdated,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Emergency Contact Responses
            if (session.emergencyContactResponses.isNotEmpty) ...[
              const Text(
                'Your Emergency Contacts:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              ...session.emergencyContactResponses.map(
                (response) => _buildEmergencyContactResponse(response),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactResponse(EmergencyContactResponse response) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.infoBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.infoBlue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contact header
          Row(
            children: [
              const Icon(Icons.person, color: AppTheme.infoBlue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  response.contactName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
              ),
              if (response.isOnWay)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.warningOrange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ON WAY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),

          // Response time
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.schedule,
                size: 16,
                color: AppTheme.secondaryText,
              ),
              const SizedBox(width: 6),
              Text(
                'Responded ${_formatResponseTime(response.responseTime)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.secondaryText,
                ),
              ),
            ],
          ),

          // ETA if on way
          if (response.isOnWay && response.estimatedArrival != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.directions_run,
                  size: 16,
                  color: AppTheme.warningOrange,
                ),
                const SizedBox(width: 6),
                Text(
                  'ETA: ${_formatETA(response.estimatedArrival!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.warningOrange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],

          // Message
          if (response.message != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '"${response.message!}"',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryText,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatETA(DateTime eta) {
    final now = DateTime.now();
    final difference = eta.difference(now);

    if (difference.inMinutes < 1) {
      return 'less than 1 min';
    } else if (difference.inMinutes == 1) {
      return '1 min';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins';
    } else {
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      return '${hours}h ${minutes}m';
    }
  }

  String _formatResponseTime(DateTime responseTime) {
    final now = DateTime.now();
    final difference = now.difference(responseTime);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes == 1) {
      return '1 min ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else {
      final hours = difference.inHours;
      return '${hours}h ago';
    }
  }
}
