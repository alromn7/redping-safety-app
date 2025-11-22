import 'package:flutter/material.dart';
import '../../../../models/travel_trip.dart';

/// Card widget for displaying itinerary items
class ItineraryItemCard extends StatelessWidget {
  final ItineraryItem item;
  final VoidCallback? onTap;

  const ItineraryItemCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Time
              Column(
                children: [
                  Text(
                    _formatTime(item.startTime),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (item.endTime != null)
                    Text(
                      _formatTime(item.endTime!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // Type icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getTypeColor(item.type).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getTypeIcon(item.type),
                  color: _getTypeColor(item.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (item.location != null)
                      Text(
                        item.location!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (item.confirmationNumber != null)
                      Text(
                        'Conf: ${item.confirmationNumber}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),

              // Cost if available
              if (item.cost != null)
                Text(
                  '\$${item.cost!.toStringAsFixed(0)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(ItineraryType type) {
    switch (type) {
      case ItineraryType.flight:
        return Icons.flight;
      case ItineraryType.train:
        return Icons.train;
      case ItineraryType.bus:
        return Icons.directions_bus;
      case ItineraryType.car:
        return Icons.directions_car;
      case ItineraryType.hotel:
        return Icons.hotel;
      case ItineraryType.restaurant:
        return Icons.restaurant;
      case ItineraryType.activity:
        return Icons.local_activity;
      case ItineraryType.tour:
        return Icons.tour;
      case ItineraryType.meeting:
        return Icons.business_center;
      case ItineraryType.other:
        return Icons.event;
    }
  }

  Color _getTypeColor(ItineraryType type) {
    switch (type) {
      case ItineraryType.flight:
        return Colors.blue;
      case ItineraryType.train:
      case ItineraryType.bus:
      case ItineraryType.car:
        return Colors.orange;
      case ItineraryType.hotel:
        return Colors.purple;
      case ItineraryType.restaurant:
        return Colors.red;
      case ItineraryType.activity:
      case ItineraryType.tour:
        return Colors.green;
      case ItineraryType.meeting:
        return Colors.indigo;
      case ItineraryType.other:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
