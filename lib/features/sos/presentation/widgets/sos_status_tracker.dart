import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/sos_session.dart';

/// Widget to show comprehensive SOS status and rescue progress to the sender
class SOSStatusTracker extends StatelessWidget {
  final SOSSession session;

  const SOSStatusTracker({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.primaryRed.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.emergency,
                  color: AppTheme.primaryRed,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Emergency Response Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'ACTIVE',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Response Summary
            _buildResponseSummary(),

            const SizedBox(height: 16),

            // Current Phase
            if (session.rescueStatus != null)
              _buildCurrentPhase(session.rescueStatus!),

            const SizedBox(height: 16),

            // Quick Stats
            _buildQuickStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseSummary() {
    final totalResponders =
        session.rescueTeamResponses.length +
        session.emergencyContactResponses.length;
    final teamsEnRoute = session.rescueTeamResponses
        .where((r) => r.status == ResponseStatus.enRoute)
        .length;
    final teamsOnScene = session.rescueTeamResponses
        .where((r) => r.status == ResponseStatus.onScene)
        .length;
    final contactsOnWay = session.emergencyContactResponses
        .where((r) => r.isOnWay)
        .length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.safeGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.safeGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          if (totalResponders > 0) ...[
            Row(
              children: [
                const Icon(Icons.groups, color: AppTheme.safeGreen, size: 20),
                const SizedBox(width: 8),
                Text(
                  '$totalResponders responder${totalResponders == 1 ? '' : 's'} notified',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
              ],
            ),
            if (teamsEnRoute > 0 || teamsOnScene > 0 || contactsOnWay > 0) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (teamsEnRoute > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.directions_run,
                          color: AppTheme.warningOrange,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        // Text is kept short; Row is wrapped to prevent overflow
                      ],
                    ),
                  if (teamsEnRoute > 0)
                    Text(
                      '$teamsEnRoute en route',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.warningOrange,
                      ),
                    ),
                  if (teamsOnScene > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.location_on,
                          color: AppTheme.safeGreen,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                      ],
                    ),
                  if (teamsOnScene > 0)
                    Text(
                      '$teamsOnScene on scene',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.safeGreen,
                      ),
                    ),
                  if (contactsOnWay > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.person_pin_circle,
                          color: AppTheme.infoBlue,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                      ],
                    ),
                  if (contactsOnWay > 0)
                    Text(
                      '$contactsOnWay contact${contactsOnWay == 1 ? '' : 's'} coming',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.infoBlue,
                      ),
                    ),
                ],
              ),
            ],
          ] else ...[
            Row(
              children: const [
                Icon(
                  Icons.access_time,
                  color: AppTheme.warningOrange,
                  size: 20,
                ),
                SizedBox(width: 8),
                // Allow the text to wrap within available width to prevent overflow
                Expanded(
                  child: Text(
                    'Dispatching emergency responders...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentPhase(RescueStatus rescueStatus) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.infoBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getPhaseIcon(rescueStatus.phase),
                color: AppTheme.infoBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getPhaseDisplayName(rescueStatus.phase),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
              ),
            ],
          ),
          if (rescueStatus.currentAction != null) ...[
            const SizedBox(height: 8),
            Text(
              rescueStatus.currentAction!,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.secondaryText,
              ),
            ),
          ],
          if (rescueStatus.estimatedCompletion != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.timer,
                  size: 16,
                  color: AppTheme.secondaryText,
                ),
                const SizedBox(width: 4),
                Text(
                  'Est. completion: ${_formatETA(rescueStatus.estimatedCompletion!)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final nextETA = _getNextETA();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Session Time',
            _formatDuration(session.duration),
            Icons.timer,
            AppTheme.infoBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Next ETA',
            nextETA ?? 'Calculating...',
            Icons.schedule,
            AppTheme.warningOrange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppTheme.secondaryText),
          ),
        ],
      ),
    );
  }

  IconData _getPhaseIcon(RescuePhase phase) {
    switch (phase) {
      case RescuePhase.alertSent:
        return Icons.send;
      case RescuePhase.responseDispatched:
        return Icons.local_shipping;
      case RescuePhase.enRoute:
        return Icons.directions_run;
      case RescuePhase.onScene:
        return Icons.location_on;
      case RescuePhase.treatmentInProgress:
        return Icons.medical_services;
      case RescuePhase.transportToHospital:
        return Icons.local_hospital;
      case RescuePhase.completed:
        return Icons.check_circle;
    }
  }

  String _getPhaseDisplayName(RescuePhase phase) {
    switch (phase) {
      case RescuePhase.alertSent:
        return 'Emergency Alert Sent';
      case RescuePhase.responseDispatched:
        return 'Response Teams Dispatched';
      case RescuePhase.enRoute:
        return 'Teams En Route';
      case RescuePhase.onScene:
        return 'Teams On Scene';
      case RescuePhase.treatmentInProgress:
        return 'Treatment in Progress';
      case RescuePhase.transportToHospital:
        return 'Transport to Hospital';
      case RescuePhase.completed:
        return 'Emergency Response Complete';
    }
  }

  String? _getNextETA() {
    // Find the earliest ETA from all responses
    DateTime? earliestETA;

    for (final response in session.rescueTeamResponses) {
      if (response.estimatedArrival != null &&
          response.status != ResponseStatus.onScene &&
          response.status != ResponseStatus.completed) {
        if (earliestETA == null ||
            response.estimatedArrival!.isBefore(earliestETA)) {
          earliestETA = response.estimatedArrival;
        }
      }
    }

    for (final response in session.emergencyContactResponses) {
      if (response.estimatedArrival != null && response.isOnWay) {
        if (earliestETA == null ||
            response.estimatedArrival!.isBefore(earliestETA)) {
          earliestETA = response.estimatedArrival;
        }
      }
    }

    return earliestETA != null ? _formatETA(earliestETA) : null;
  }

  String _formatETA(DateTime eta) {
    final now = DateTime.now();
    final difference = eta.difference(now);

    if (difference.inMinutes < 1) {
      return 'Any moment';
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    if (minutes == 0) {
      return '${seconds}s';
    } else {
      return '${minutes}m ${seconds}s';
    }
  }
}
