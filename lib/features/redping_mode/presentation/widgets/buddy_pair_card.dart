import 'package:flutter/material.dart';
import '../../../../models/group_activity.dart';

/// Card widget for displaying buddy pair information
class BuddyPairCard extends StatelessWidget {
  const BuddyPairCard({super.key, required this.pair, required this.members});

  final BuddyPair pair;
  final List<GroupMember> members;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final member1 = members.firstWhere(
      (m) => m.memberId == pair.member1Id,
      orElse: () => GroupMember(
        memberId: '',
        memberName: 'Unknown',
        role: GroupMemberRole.member,
        joinedAt: DateTime.now(),
      ),
    );

    final member2 = members.firstWhere(
      (m) => m.memberId == pair.member2Id,
      orElse: () => GroupMember(
        memberId: '',
        memberName: 'Unknown',
        role: GroupMemberRole.member,
        joinedAt: DateTime.now(),
      ),
    );

    // Calculate distance between buddies if both have locations
    double? distance;
    bool bothOnline = member1.isOnline && member2.isOnline;
    bool separationWarning = false;

    if (member1.latitude != null &&
        member1.longitude != null &&
        member2.latitude != null &&
        member2.longitude != null) {
      distance = _calculateDistance(
        member1.latitude!,
        member1.longitude!,
        member2.latitude!,
        member2.longitude!,
      );
      separationWarning = distance > pair.maxSeparationMeters;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.people,
                  color: separationWarning ? Colors.red : Colors.blue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Buddy Pair',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (!pair.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Inactive',
                      style: TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Buddies
            Row(
              children: [
                Expanded(child: _buildMemberInfo(member1, theme)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.compare_arrows, color: Colors.grey[400]),
                ),
                Expanded(child: _buildMemberInfo(member2, theme)),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Status and distance
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Online status
                Row(
                  children: [
                    Icon(
                      bothOnline ? Icons.check_circle : Icons.warning,
                      size: 16,
                      color: bothOnline ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      bothOnline
                          ? 'Both buddies online'
                          : 'One or both offline',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: bothOnline ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Distance
                if (distance != null) ...[
                  Row(
                    children: [
                      Icon(
                        separationWarning
                            ? Icons.warning_amber
                            : Icons.location_on,
                        size: 16,
                        color: separationWarning ? Colors.red : Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          separationWarning
                              ? 'Separation: ${distance.toStringAsFixed(0)}m (Max: ${pair.maxSeparationMeters.toStringAsFixed(0)}m)'
                              : 'Distance: ${distance.toStringAsFixed(0)}m',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: separationWarning ? Colors.red : Colors.blue,
                            fontWeight: separationWarning
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Distance progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (distance / pair.maxSeparationMeters).clamp(
                        0.0,
                        1.0,
                      ),
                      minHeight: 8,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        separationWarning ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                ] else
                  Row(
                    children: [
                      Icon(
                        Icons.location_off,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Location data unavailable',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 12),

                // Max separation setting
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.settings_input_composite,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Max separation: ${pair.maxSeparationMeters.toStringAsFixed(0)}m',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberInfo(GroupMember member, ThemeData theme) {
    return Column(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: member.isOnline
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.2),
          child: Text(
            member.memberName.isNotEmpty
                ? member.memberName[0].toUpperCase()
                : '?',
            style: TextStyle(
              color: member.isOnline ? Colors.green : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          member.memberName,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              member.isOnline ? Icons.circle : Icons.circle_outlined,
              size: 8,
              color: member.isOnline ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              member.isOnline ? 'Online' : 'Offline',
              style: theme.textTheme.bodySmall?.copyWith(
                color: member.isOnline ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
        if (member.batteryLevel != null) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getBatteryIcon(member.batteryLevel!),
                size: 12,
                color: _getBatteryColor(member.batteryLevel!),
              ),
              const SizedBox(width: 4),
              Text(
                '${member.batteryLevel}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _getBatteryColor(member.batteryLevel!),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  IconData _getBatteryIcon(int level) {
    if (level > 80) return Icons.battery_full;
    if (level > 50) return Icons.battery_5_bar;
    if (level > 30) return Icons.battery_3_bar;
    if (level > 15) return Icons.battery_2_bar;
    return Icons.battery_alert;
  }

  Color _getBatteryColor(int level) {
    if (level > 30) return Colors.green;
    if (level > 15) return Colors.orange;
    return Colors.red;
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000; // meters
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        (dLat / 2) * (dLat / 2) +
        (dLon / 2) *
            (dLon / 2) *
            _degreesToRadians(lat1) *
            _degreesToRadians(lat2);

    final c = 2 * (a < 0.5 ? a : 1 - a);
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180.0);
  }
}
