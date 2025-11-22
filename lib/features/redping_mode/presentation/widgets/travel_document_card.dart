import 'package:flutter/material.dart';
import '../../../../models/travel_trip.dart';

/// Card widget for displaying travel documents
class TravelDocumentCard extends StatelessWidget {
  final TravelDocument document;
  final VoidCallback? onTap;

  const TravelDocumentCard({super.key, required this.document, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine status
    Color? statusColor;
    String? statusText;
    IconData? statusIcon;

    if (document.isExpired) {
      statusColor = Colors.red;
      statusText = 'EXPIRED';
      statusIcon = Icons.error;
    } else if (document.isExpiringSoon) {
      statusColor = Colors.orange;
      statusText = 'Expires Soon';
      statusIcon = Icons.warning;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Document type icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getDocumentIcon(document.type),
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),

              // Document details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (document.documentNumber != null)
                      Text(
                        document.documentNumber!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (document.expiryDate != null)
                      Text(
                        'Expires: ${_formatDate(document.expiryDate!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: statusColor ?? colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),

              // Status badge
              if (statusText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor!.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDocumentIcon(DocumentType type) {
    switch (type) {
      case DocumentType.passport:
        return Icons.badge;
      case DocumentType.visa:
        return Icons.card_membership;
      case DocumentType.ticket:
        return Icons.confirmation_number;
      case DocumentType.boardingPass:
        return Icons.flight_takeoff;
      case DocumentType.hotel:
        return Icons.hotel;
      case DocumentType.rental:
        return Icons.directions_car;
      case DocumentType.insurance:
        return Icons.health_and_safety;
      case DocumentType.vaccination:
        return Icons.vaccines;
      case DocumentType.driverLicense:
        return Icons.credit_card;
      case DocumentType.other:
        return Icons.description;
    }
  }

  String _formatDate(DateTime date) {
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
    return '${months[date.month]} ${date.day}, ${date.year}';
  }
}
