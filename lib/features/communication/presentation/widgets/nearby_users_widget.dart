// ignore_for_file: unused_element
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/chat_message.dart';
import '../../../../models/sos_session.dart';

/// Widget for displaying nearby users
class NearbyUsersWidget extends StatelessWidget {
  final List<ChatUser> users;
  final Function(ChatUser) onUserTap;
  final VoidCallback? onRefresh;

  const NearbyUsersWidget({
    super.key,
    required this.users,
    required this.onUserTap,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Nearby Users',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...users.map((user) => _buildUserCard(user)),
      ],
    );
  }

  Widget _buildUserCard(ChatUser user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onUserTap(user),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar with status indicator
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _getAvatarColor(user),
                    backgroundImage: user.avatar != null
                        ? NetworkImage(user.avatar!)
                        : null,
                    child: user.avatar == null
                        ? Text(
                            user.initials,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: _getStatusColor(user.status),
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 12),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryText,
                            ),
                          ),
                        ),
                        _buildUserBadges(user),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          _getStatusDisplayName(user.status),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusColor(user.status),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (user.location != null) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: AppTheme.criticalRed,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _getDistanceText(user.location!),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.secondaryText,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (!user.isOnline) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Last seen ${_formatLastSeen(user.lastSeen)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.disabledText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Action button
              IconButton(
                onPressed: () => onUserTap(user),
                icon: const Icon(Icons.chat_bubble_outline),
                tooltip: 'Start Chat',
                color: AppTheme.primaryRed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserBadges(ChatUser user) {
    final badges = <Widget>[];

    if (user.isEmergencyContact) {
      badges.add(_buildBadge('EC', AppTheme.criticalRed, 'Emergency Contact'));
    }

    if (user.isSARTeamMember) {
      badges.add(_buildBadge('SAR', AppTheme.warningOrange, 'SAR Team Member'));
    }

    if (user.roles.isNotEmpty) {
      badges.add(
        _buildBadge(
          user.roles.first.substring(0, 1).toUpperCase(),
          AppTheme.infoBlue,
          user.roles.first,
        ),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: badges);
  }

  Widget _buildBadge(String text, Color color, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: AppTheme.neutralGray.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Nearby Users',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.neutralGray,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Turn on location services to discover nearby REDP!NG users',
              style: TextStyle(color: AppTheme.secondaryText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAvatarColor(ChatUser user) {
    // Generate consistent color based on user ID
    final hash = user.id.hashCode;
    final colors = [
      AppTheme.primaryRed,
      AppTheme.warningOrange,
      AppTheme.infoBlue,
      AppTheme.safeGreen,
      Colors.purple,
      Colors.teal,
    ];
    return colors[hash.abs() % colors.length];
  }

  Color _getStatusColor(UserStatus status) {
    return switch (status) {
      UserStatus.available => AppTheme.safeGreen,
      UserStatus.busy => AppTheme.warningOrange,
      UserStatus.away => AppTheme.neutralGray,
      UserStatus.emergency => AppTheme.criticalRed,
      UserStatus.offline => AppTheme.disabledText,
    };
  }

  String _getStatusDisplayName(UserStatus status) {
    return switch (status) {
      UserStatus.available => 'Available',
      UserStatus.busy => 'Busy',
      UserStatus.away => 'Away',
      UserStatus.emergency => 'Emergency',
      UserStatus.offline => 'Offline',
    };
  }

  Color _getChatTypeColor(ChatType type) {
    return switch (type) {
      ChatType.direct => AppTheme.infoBlue,
      ChatType.group => AppTheme.primaryRed,
      ChatType.community => AppTheme.warningOrange,
      ChatType.emergency => AppTheme.criticalRed,
      ChatType.sarTeam => AppTheme.primaryRed,
      ChatType.locationBased => AppTheme.safeGreen,
      ChatType.broadcast => AppTheme.neutralGray,
    };
  }

  IconData _getChatTypeIcon(ChatType type) {
    return switch (type) {
      ChatType.direct => Icons.person,
      ChatType.group => Icons.group,
      ChatType.community => Icons.people,
      ChatType.emergency => Icons.emergency,
      ChatType.sarTeam => Icons.search,
      ChatType.locationBased => Icons.location_on,
      ChatType.broadcast => Icons.campaign,
    };
  }

  String _getChatTypeDisplayName(ChatType type) {
    return switch (type) {
      ChatType.direct => 'Direct Message',
      ChatType.group => 'Group Chat',
      ChatType.community => 'Community Chat',
      ChatType.emergency => 'Emergency Chat',
      ChatType.sarTeam => 'SAR Team',
      ChatType.locationBased => 'Location-Based',
      ChatType.broadcast => 'Broadcast',
    };
  }

  String _getPriorityEmoji(MessagePriority priority) {
    return switch (priority) {
      MessagePriority.low => 'ℹ️',
      MessagePriority.normal => '💬',
      MessagePriority.high => '⚠️',
      MessagePriority.urgent => '🔥',
      MessagePriority.emergency => '🚨',
    };
  }

  String _getDistanceText(LocationInfo location) {
    // In production, calculate actual distance
    return '~0.5km';
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${lastSeen.day}/${lastSeen.month}';
    }
  }
}
