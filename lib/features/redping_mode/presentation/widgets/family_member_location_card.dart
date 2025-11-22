import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/family_member_location.dart';

/// Card displaying family member location info
class FamilyMemberLocationCard extends StatelessWidget {
  const FamilyMemberLocationCard({
    super.key,
    required this.location,
    required this.isInSafeZone,
    this.onTap,
  });

  final FamilyMemberLocation location;
  final bool isInSafeZone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
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
                  // Avatar
                  CircleAvatar(
                    backgroundColor: _getStatusColor().withValues(alpha: 0.2),
                    child: Text(
                      location.memberName[0].toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name and status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.memberName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: location.isOnline
                                    ? AppTheme.safeGreen
                                    : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              location.isOnline ? 'Online' : 'Offline',
                              style: TextStyle(
                                fontSize: 12,
                                color: location.isOnline
                                    ? AppTheme.safeGreen
                                    : Colors.grey,
                              ),
                            ),
                            if (isInSafeZone) ...[
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.shield,
                                size: 14,
                                color: AppTheme.infoBlue,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'In Safe Zone',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.infoBlue,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Time since update
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        location.timeSinceUpdate,
                        style: TextStyle(
                          fontSize: 12,
                          color: location.isStale ? Colors.orange : Colors.grey,
                        ),
                      ),
                      if (location.batteryLevel != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getBatteryIcon(),
                              size: 14,
                              color: _getBatteryColor(),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${location.batteryLevel}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: _getBatteryColor(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              // Location details
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              Row(
                children: [
                  // Accuracy
                  Expanded(
                    child: _buildInfoChip(
                      Icons.my_location,
                      location.accuracyFormatted,
                      'Accuracy',
                    ),
                  ),

                  // Speed
                  if (location.speed != null && location.speed! > 0) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInfoChip(
                        Icons.speed,
                        location.speedKmh,
                        'Speed',
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String value, String label) {
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

  Color _getStatusColor() {
    if (!location.isOnline) return Colors.grey;
    if (location.isStale) return Colors.orange;
    return AppTheme.safeGreen;
  }

  IconData _getBatteryIcon() {
    if (location.batteryLevel == null) return Icons.battery_unknown;
    if (location.batteryLevel! <= 20) return Icons.battery_0_bar;
    if (location.batteryLevel! <= 40) return Icons.battery_2_bar;
    if (location.batteryLevel! <= 60) return Icons.battery_4_bar;
    if (location.batteryLevel! <= 80) return Icons.battery_5_bar;
    return Icons.battery_full;
  }

  Color _getBatteryColor() {
    if (location.batteryLevel == null) return Colors.grey;
    if (location.batteryLevel! <= 20) return Colors.red;
    if (location.batteryLevel! <= 40) return Colors.orange;
    return AppTheme.safeGreen;
  }
}
