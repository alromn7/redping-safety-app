import 'package:flutter/material.dart';
import '../../../../models/travel_trip.dart';

/// Card widget for displaying travel trips
class TravelTripCard extends StatelessWidget {
  final TravelTrip trip;
  final VoidCallback? onTap;
  final VoidCallback? onStart;
  final VoidCallback? onEnd;

  const TravelTripCard({
    super.key,
    required this.trip,
    this.onTap,
    this.onStart,
    this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine status color
    Color statusColor = colorScheme.primary;
    if (trip.status == TripStatus.active) {
      statusColor = Colors.green;
    } else if (trip.status == TripStatus.completed) {
      statusColor = Colors.grey;
    } else if (trip.status == TripStatus.cancelled) {
      statusColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Trip type icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTripTypeIcon(trip.type),
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Trip name and destination
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          trip.destination,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      _formatStatus(trip.status),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Dates
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    _formatDateRange(trip.startDate, trip.endDate),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),

              // Trip info
              if (trip.duration != null || trip.isUpcoming) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (trip.duration != null) ...[
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${trip.duration!.inDays} days',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (trip.isUpcoming) ...[
                      Icon(Icons.upcoming, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        'In ${trip.daysRemaining} days',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ],

              // Companions, documents, itinerary count
              if (trip.companions.isNotEmpty ||
                  trip.documents.isNotEmpty ||
                  trip.itinerary.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (trip.companions.isNotEmpty)
                      _buildInfoChip(
                        '${trip.companions.length} ${trip.companions.length == 1 ? "person" : "people"}',
                        Icons.people,
                        colorScheme.tertiaryContainer,
                      ),
                    if (trip.itinerary.isNotEmpty)
                      _buildInfoChip(
                        '${trip.itinerary.length} activities',
                        Icons.list_alt,
                        colorScheme.tertiaryContainer,
                      ),
                    if (trip.documents.isNotEmpty)
                      _buildInfoChip(
                        '${trip.documents.length} docs',
                        Icons.description,
                        colorScheme.tertiaryContainer,
                      ),
                    if (trip.totalExpenses > 0)
                      _buildInfoChip(
                        '\$${trip.totalExpenses.toStringAsFixed(0)}',
                        Icons.account_balance_wallet,
                        colorScheme.tertiaryContainer,
                      ),
                  ],
                ),
              ],

              // Action buttons
              if (onStart != null || onEnd != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (onStart != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onStart,
                          icon: const Icon(Icons.play_arrow, size: 16),
                          label: const Text('Start Trip'),
                        ),
                      ),
                    if (onEnd != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onEnd,
                          icon: const Icon(Icons.stop, size: 16),
                          label: const Text('End Trip'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  IconData _getTripTypeIcon(TripType type) {
    switch (type) {
      case TripType.leisure:
        return Icons.beach_access;
      case TripType.business:
        return Icons.business_center;
      case TripType.family:
        return Icons.family_restroom;
      case TripType.adventure:
        return Icons.hiking;
      case TripType.backpacking:
        return Icons.backpack;
      case TripType.cruise:
        return Icons.directions_boat;
      case TripType.roadTrip:
        return Icons.directions_car;
      case TripType.other:
        return Icons.flight_takeoff;
    }
  }

  String _formatStatus(TripStatus status) {
    switch (status) {
      case TripStatus.planned:
        return 'PLANNED';
      case TripStatus.active:
        return 'ACTIVE';
      case TripStatus.completed:
        return 'COMPLETED';
      case TripStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String _formatDateRange(DateTime start, DateTime? end) {
    final months = [
      '',
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

    final startStr = '${months[start.month]} ${start.day}, ${start.year}';
    if (end == null) {
      return startStr;
    }

    final endStr = '${months[end.month]} ${end.day}, ${end.year}';
    return '$startStr - $endStr';
  }
}
