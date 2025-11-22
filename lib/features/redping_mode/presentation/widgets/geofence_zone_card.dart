import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/family_member_location.dart';

/// Card displaying geofence zone information
class GeofenceZoneCard extends StatelessWidget {
  const GeofenceZoneCard({
    super.key,
    required this.zone,
    required this.membersInZone,
    this.onEdit,
    this.onDelete,
  });

  final GeofenceZone zone;
  final List<FamilyMemberLocation> membersInZone;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final zoneColor = zone.color != null
        ? Color(int.parse(zone.color!.replaceFirst('#', '0xff')))
        : AppTheme.infoBlue;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Zone icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: zoneColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.location_city, color: zoneColor, size: 24),
                ),
                const SizedBox(width: 12),

                // Name and description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zone.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (zone.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          zone.description!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
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
                    color: zone.isActive
                        ? AppTheme.safeGreen.withValues(alpha: 0.2)
                        : Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    zone.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: zone.isActive ? AppTheme.safeGreen : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Zone details
            Row(
              children: [
                Expanded(
                  child: _buildDetailChip(
                    Icons.straighten,
                    zone.radiusFormatted,
                    'Radius',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildDetailChip(
                    Icons.people,
                    '${membersInZone.length}',
                    'Members Inside',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Alert settings
            Wrap(
              spacing: 8,
              children: [
                if (zone.alertOnEntry)
                  Chip(
                    label: const Text('Entry Alert'),
                    avatar: const Icon(Icons.login, size: 16),
                    labelStyle: const TextStyle(fontSize: 11),
                    visualDensity: VisualDensity.compact,
                  ),
                if (zone.alertOnExit)
                  Chip(
                    label: const Text('Exit Alert'),
                    avatar: const Icon(Icons.logout, size: 16),
                    labelStyle: const TextStyle(fontSize: 11),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),

            // Members in zone
            if (membersInZone.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.person_pin_circle,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      membersInZone.map((m) => m.memberName).join(', '),
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],

            // Action buttons
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
