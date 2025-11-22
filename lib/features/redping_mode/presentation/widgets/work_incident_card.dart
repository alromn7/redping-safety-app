import 'package:flutter/material.dart';
import '../../../../models/work_shift.dart';

class WorkIncidentCard extends StatelessWidget {
  final WorkIncident incident;
  final String? shiftInfo;

  const WorkIncidentCard({super.key, required this.incident, this.shiftInfo});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  _getIncidentIcon(incident.type),
                  color: _getSeverityColor(incident.severity),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        incident.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (shiftInfo != null)
                        Text(
                          shiftInfo!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                _buildSeverityBadge(context),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            Text(incident.description, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 12),

            // Details
            Row(
              children: [
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  _formatDateTime(incident.reportedAt),
                  style: const TextStyle(fontSize: 12),
                ),
                if (incident.location != null) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      incident.location!,
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),

            // Involved persons
            if (incident.involvedPersons.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.people, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Involved: ${incident.involvedPersons.join(", ")}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],

            // Action taken
            if (incident.actionTaken != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Action Taken:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            incident.actionTaken!,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Follow-up required
            if (incident.requiresFollowUp) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.assignment_late,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Follow-up Required',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    if (incident.followUpNotes != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          incident.followUpNotes!,
                          style: const TextStyle(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Type chip
            const SizedBox(height: 12),
            Chip(
              avatar: Icon(_getIncidentIcon(incident.type), size: 16),
              label: Text(_formatIncidentType(incident.type)),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(BuildContext context) {
    final color = _getSeverityColor(incident.severity);
    final text = _formatSeverity(incident.severity);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getSeverityColor(IncidentSeverity severity) {
    switch (severity) {
      case IncidentSeverity.low:
        return Colors.blue;
      case IncidentSeverity.medium:
        return Colors.orange;
      case IncidentSeverity.high:
        return Colors.deepOrange;
      case IncidentSeverity.critical:
        return Colors.red;
    }
  }

  IconData _getIncidentIcon(IncidentType type) {
    switch (type) {
      case IncidentType.safety:
        return Icons.warning;
      case IncidentType.equipment:
        return Icons.build;
      case IncidentType.customer:
        return Icons.person;
      case IncidentType.workplace:
        return Icons.business;
      case IncidentType.health:
        return Icons.medical_services;
      case IncidentType.security:
        return Icons.security;
      case IncidentType.other:
        return Icons.report_problem;
    }
  }

  String _formatSeverity(IncidentSeverity severity) {
    return severity.name[0].toUpperCase() + severity.name.substring(1);
  }

  String _formatIncidentType(IncidentType type) {
    return type.name[0].toUpperCase() + type.name.substring(1);
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays == 0) {
      final hour = dateTime.hour > 12
          ? dateTime.hour - 12
          : (dateTime.hour == 0 ? 12 : dateTime.hour);
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      return 'Today at $hour:$minute $period';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    }

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
  }
}
