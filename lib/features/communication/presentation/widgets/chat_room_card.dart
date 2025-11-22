import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/chat_message.dart';

/// Widget displaying a chat room card
class ChatRoomCard extends StatelessWidget {
  final ChatRoom room;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final VoidCallback? onLeave;

  const ChatRoomCard({
    super.key,
    required this.room,
    this.onTap,
    this.onJoin,
    this.onLeave,
  });

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
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getChatTypeColor(
                        room.type,
                      ).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getChatTypeIcon(room.type),
                      color: _getChatTypeColor(room.type),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                room.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryText,
                                ),
                              ),
                            ),
                            if (room.hasUnreadMessages) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.criticalRed,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${room.unreadCount}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          _getChatTypeDisplayName(room.type),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (room.isEncrypted)
                    const Icon(Icons.lock, size: 16, color: AppTheme.safeGreen),
                ],
              ),

              // Description
              if (room.description != null && room.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  room.description!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryText,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Last message
              if (room.lastMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.neutralGray.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _getPriorityEmoji(room.lastMessage!.priority),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${room.lastMessage!.senderName}: ${room.lastMessage!.content}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Footer info
              Row(
                children: [
                  Icon(Icons.people, size: 14, color: AppTheme.secondaryText),
                  const SizedBox(width: 4),
                  Text(
                    '${room.participants.length} members',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                  const Spacer(),
                  if (room.lastActivity != null) ...[
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppTheme.secondaryText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimestamp(room.lastActivity!),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondaryText,
                      ),
                    ),
                  ],
                ],
              ),

              // Tags
              if (room.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: room.tags
                      .take(3)
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.infoBlue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: AppTheme.infoBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],

              // Action buttons for non-joined rooms
              if (!_isUserInRoom()) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onJoin,
                    icon: const Icon(Icons.login, size: 16),
                    label: const Text('Join Chat'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _getChatTypeColor(room.type),
                      side: BorderSide(color: _getChatTypeColor(room.type)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _isUserInRoom() {
    // In production, check if current user is in participants
    return room.participants.contains('current_user');
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
}
