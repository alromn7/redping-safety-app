import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/chat_message.dart';

/// Widget for displaying chat messages
class ChatMessageWidget extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showSenderName;

  const ChatMessageWidget({
    super.key,
    required this.message,
    required this.isMe,
    this.showSenderName = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[_buildAvatar(), const SizedBox(width: 8)],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (showSenderName && !isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 12),
                    child: Text(
                      message.senderName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.secondaryText,
                      ),
                    ),
                  ),
                _buildMessageBubble(context),
                _buildMessageInfo(),
              ],
            ),
          ),
          if (isMe) ...[const SizedBox(width: 8), _buildAvatar()],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 16,
      backgroundColor: _getAvatarColor(),
      backgroundImage: message.senderAvatar != null
          ? NetworkImage(message.senderAvatar!)
          : null,
      child: message.senderAvatar == null
          ? Text(
              _getInitials(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            )
          : null,
    );
  }

  Widget _buildMessageBubble(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getBubbleColor(),
        borderRadius: BorderRadius.circular(16).copyWith(
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        border: message.priority == MessagePriority.emergency
            ? Border.all(color: AppTheme.criticalRed, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority indicator for high priority messages
          if (message.priority == MessagePriority.high ||
              message.priority == MessagePriority.urgent ||
              message.priority == MessagePriority.emergency) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_getPriorityEmoji(message.priority)),
                const SizedBox(width: 4),
                Text(
                  message.priority.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getPriorityColor(message.priority),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
          ],

          // Message content
          _buildMessageContent(),

          // Attachments
          if (message.hasAttachments) ...[
            const SizedBox(height: 8),
            ...message.attachments.map(
              (attachment) => _buildAttachment(attachment),
            ),
          ],

          // Location
          if (message.location != null) ...[
            const SizedBox(height: 8),
            _buildLocationInfo(),
          ],

          // Reply indicator
          if (message.replyToMessageId != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.reply, size: 12),
                  SizedBox(width: 4),
                  Text('Reply', style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent() {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            fontSize: 15,
            color: isMe ? Colors.white : AppTheme.primaryText,
          ),
        );

      case MessageType.system:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: isMe ? Colors.white70 : AppTheme.secondaryText,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                message.content,
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: isMe ? Colors.white70 : AppTheme.secondaryText,
                ),
              ),
            ),
          ],
        );

      case MessageType.emergency:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emergency, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  'EMERGENCY',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isMe ? Colors.white : AppTheme.criticalRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              message.content,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isMe ? Colors.white : AppTheme.primaryText,
              ),
            ),
          ],
        );

      case MessageType.location:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_on,
              size: 16,
              color: isMe ? Colors.white : AppTheme.criticalRed,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                message.content,
                style: TextStyle(
                  fontSize: 15,
                  color: isMe ? Colors.white : AppTheme.primaryText,
                ),
              ),
            ),
          ],
        );

      default:
        return Text(
          message.content,
          style: TextStyle(
            fontSize: 15,
            color: isMe ? Colors.white : AppTheme.primaryText,
          ),
        );
    }
  }

  Widget _buildAttachment(MessageAttachment attachment) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getAttachmentIcon(attachment.type),
            size: 16,
            color: isMe ? Colors.white70 : AppTheme.secondaryText,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isMe ? Colors.white : AppTheme.primaryText,
                  ),
                ),
                Text(
                  attachment.fileSizeFormatted,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe ? Colors.white70 : AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo() {
    final location = message.location!;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: isMe ? Colors.white : AppTheme.criticalRed,
              ),
              const SizedBox(width: 6),
              Text(
                'Location Shared',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isMe ? Colors.white : AppTheme.primaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: isMe ? Colors.white70 : AppTheme.secondaryText,
            ),
          ),
          if (location.address != null)
            Text(
              location.address!,
              style: TextStyle(
                fontSize: 11,
                color: isMe ? Colors.white70 : AppTheme.secondaryText,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageInfo() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatTime(message.timestamp),
            style: const TextStyle(fontSize: 11, color: AppTheme.disabledText),
          ),
          if (isMe) ...[
            const SizedBox(width: 4),
            Icon(
              message.isDelivered ? Icons.done_all : Icons.done,
              size: 12,
              color: message.isRead
                  ? AppTheme.safeGreen
                  : AppTheme.disabledText,
            ),
          ],
          if (message.isEdited) ...[
            const SizedBox(width: 4),
            const Text(
              'edited',
              style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: AppTheme.disabledText,
              ),
            ),
          ],
          if (message.isEncrypted) ...[
            const SizedBox(width: 4),
            const Icon(Icons.lock, size: 10, color: AppTheme.disabledText),
          ],
        ],
      ),
    );
  }

  Color _getBubbleColor() {
    if (message.priority == MessagePriority.emergency) {
      return AppTheme.criticalRed;
    }

    if (message.type == MessageType.system) {
      return AppTheme.neutralGray.withValues(alpha: 0.3);
    }

    return isMe ? AppTheme.primaryRed : AppTheme.darkSurface;
  }

  Color _getAvatarColor() {
    // Generate consistent color based on sender ID
    final hash = message.senderId.hashCode;
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

  String _getInitials() {
    return message.senderName
        .split(' ')
        .map((name) => name.isNotEmpty ? name[0] : '')
        .take(2)
        .join()
        .toUpperCase();
  }

  IconData _getAttachmentIcon(AttachmentType type) {
    return switch (type) {
      AttachmentType.image => Icons.image,
      AttachmentType.video => Icons.videocam,
      AttachmentType.audio => Icons.audiotrack,
      AttachmentType.document => Icons.description,
      AttachmentType.location => Icons.location_on,
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

  Color _getPriorityColor(MessagePriority priority) {
    return switch (priority) {
      MessagePriority.low => AppTheme.infoBlue,
      MessagePriority.normal => AppTheme.neutralGray,
      MessagePriority.high => AppTheme.warningOrange,
      MessagePriority.urgent => AppTheme.primaryRed,
      MessagePriority.emergency => AppTheme.criticalRed,
    };
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}
