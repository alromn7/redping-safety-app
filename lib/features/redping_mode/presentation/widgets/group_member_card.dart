import 'package:flutter/material.dart';
import '../../../../models/group_activity.dart';

/// Card widget for displaying group member information
class GroupMemberCard extends StatelessWidget {
  const GroupMemberCard({
    super.key,
    required this.member,
    required this.session,
    this.onRemove,
  });

  final GroupMember member;
  final GroupActivitySession session;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOnline = member.isOnline;
    final hasRecentCheckIn = member.hasRecentCheckIn;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isOnline && hasRecentCheckIn) {
      statusColor = Colors.green;
      statusText = 'Online';
      statusIcon = Icons.circle;
    } else if (isOnline && !hasRecentCheckIn) {
      statusColor = Colors.orange;
      statusText = 'Online (No recent check-in)';
      statusIcon = Icons.warning_amber;
    } else {
      statusColor = Colors.grey;
      statusText = 'Offline';
      statusIcon = Icons.circle_outlined;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showMemberDetails(context),
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
                    radius: 24,
                    backgroundColor: _getRoleColor(
                      member.role,
                    ).withValues(alpha: 0.2),
                    child: Text(
                      member.memberName.isNotEmpty
                          ? member.memberName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: _getRoleColor(member.role),
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name and role
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                member.memberName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (member.role != GroupMemberRole.member) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRoleColor(
                                    member.role,
                                  ).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getRoleColor(member.role),
                                  ),
                                ),
                                child: Text(
                                  _formatRole(member.role),
                                  style: TextStyle(
                                    color: _getRoleColor(member.role),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(statusIcon, size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  if (member.role != GroupMemberRole.leader)
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showMemberMenu(context),
                    ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Stats row
              Row(
                children: [
                  // Check-in status
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.check_circle_outline,
                      label: 'Last Check-in',
                      value: member.checkInStatus,
                      color: hasRecentCheckIn ? Colors.green : Colors.orange,
                    ),
                  ),

                  // Battery
                  if (member.batteryLevel != null)
                    Expanded(
                      child: _buildStatItem(
                        icon: _getBatteryIcon(member.batteryLevel!),
                        label: 'Battery',
                        value: '${member.batteryLevel}%',
                        color: _getBatteryColor(member.batteryLevel!),
                      ),
                    ),

                  // Buddy status
                  if (member.buddyId != null)
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.people,
                        label: 'Buddy',
                        value: _getBuddyName(member.buddyId!),
                        color: Colors.blue,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  Color _getRoleColor(GroupMemberRole role) {
    switch (role) {
      case GroupMemberRole.leader:
        return Colors.purple;
      case GroupMemberRole.coLeader:
        return Colors.blue;
      case GroupMemberRole.member:
        return Colors.green;
    }
  }

  String _formatRole(GroupMemberRole role) {
    switch (role) {
      case GroupMemberRole.leader:
        return 'LEADER';
      case GroupMemberRole.coLeader:
        return 'CO-LEADER';
      case GroupMemberRole.member:
        return 'MEMBER';
    }
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

  String _getBuddyName(String buddyId) {
    final buddy = session.currentMembers.firstWhere(
      (m) => m.memberId == buddyId,
      orElse: () => GroupMember(
        memberId: '',
        memberName: 'Unknown',
        role: GroupMemberRole.member,
        joinedAt: DateTime.now(),
      ),
    );
    return buddy.memberName;
  }

  void _showMemberDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Avatar and name
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: _getRoleColor(member.role).withValues(alpha: 0.2),
                  child: Text(
                    member.memberName.isNotEmpty
                        ? member.memberName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: _getRoleColor(member.role),
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                member.memberName,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getRoleColor(member.role).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getRoleColor(member.role)),
                  ),
                  child: Text(
                    _formatRole(member.role),
                    style: TextStyle(
                      color: _getRoleColor(member.role),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Details
              _buildDetailRow(
                Icons.email,
                'Email',
                member.email ?? 'Not provided',
              ),
              _buildDetailRow(
                Icons.phone,
                'Phone',
                member.phone ?? 'Not provided',
              ),
              _buildDetailRow(
                Icons.calendar_today,
                'Joined',
                _formatDateTime(member.joinedAt),
              ),
              if (member.lastCheckIn != null)
                _buildDetailRow(
                  Icons.check_circle,
                  'Last Check-in',
                  _formatDateTime(member.lastCheckIn!),
                ),
              if (member.latitude != null && member.longitude != null)
                _buildDetailRow(
                  Icons.location_on,
                  'Location',
                  '${member.latitude!.toStringAsFixed(6)}, ${member.longitude!.toStringAsFixed(6)}',
                ),
              if (member.speed != null)
                _buildDetailRow(
                  Icons.speed,
                  'Speed',
                  '${(member.speed! * 3.6).toStringAsFixed(1)} km/h',
                ),
              if (member.batteryLevel != null)
                _buildDetailRow(
                  Icons.battery_charging_full,
                  'Battery',
                  '${member.batteryLevel}%',
                ),
              if (member.buddyId != null)
                _buildDetailRow(
                  Icons.people,
                  'Buddy',
                  _getBuddyName(member.buddyId!),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMemberMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showMemberDetails(context);
              },
            ),
            if (member.role != GroupMemberRole.leader)
              ListTile(
                leading: const Icon(Icons.remove_circle, color: Colors.red),
                title: const Text('Remove from Group'),
                onTap: () {
                  Navigator.pop(context);
                  onRemove?.call();
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
