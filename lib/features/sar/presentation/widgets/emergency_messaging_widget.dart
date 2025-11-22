import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/sos_ping.dart';
import '../../../../models/emergency_message.dart';
import '../../../../services/sos_ping_service.dart';

/// Widget for emergency messaging between SAR members and civilians
class EmergencyMessagingWidget extends StatefulWidget {
  final SOSPing ping;
  final bool isSARMember;
  final String currentUserId;

  const EmergencyMessagingWidget({
    super.key,
    required this.ping,
    required this.isSARMember,
    required this.currentUserId,
  });

  @override
  State<EmergencyMessagingWidget> createState() =>
      _EmergencyMessagingWidgetState();
}

class _EmergencyMessagingWidgetState extends State<EmergencyMessagingWidget> {
  final SOSPingService _pingService = SOSPingService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<EmergencyMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    setState(() {
      _messages = _pingService.getMessagesForPing(widget.ping.id);
    });

    // Mark messages as read
    _pingService.markMessagesAsRead(widget.ping.id, widget.currentUserId);

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.isSARMember) {
        await _pingService.sendMessageToCivilian(
          pingId: widget.ping.id,
          content: content,
          type: MessageType.status,
        );
      } else {
        await _pingService.sendMessageToSAR(
          pingId: widget.ping.id,
          content: content,
          type: MessageType.emergency,
        );
      }

      _messageController.clear();
      _loadMessages(); // Refresh messages

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Message sent'),
            backgroundColor: AppTheme.safeGreen,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: AppTheme.criticalRed,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Messages header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            border: Border(
              bottom: BorderSide(
                color: AppTheme.neutralGray.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.isSARMember ? Icons.volunteer_activism : Icons.person,
                color: AppTheme.infoBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.isSARMember
                      ? 'Communication with ${widget.ping.userName ?? 'SOS User'}'
                      : 'Communication with SAR Team',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryText,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.infoBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_messages.length} message${_messages.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: AppTheme.infoBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Messages list
        Expanded(
          child: _messages.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.message_outlined,
                        size: 48,
                        color: AppTheme.neutralGray,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No messages yet',
                        style: TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Start a conversation to coordinate the rescue',
                        style: TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isFromCurrentUser =
                        message.senderId == widget.currentUserId;

                    return _buildMessageBubble(message, isFromCurrentUser);
                  },
                ),
        ),

        // Message input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            border: Border(
              top: BorderSide(
                color: AppTheme.neutralGray.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: InputDecoration(
                    hintText: widget.isSARMember
                        ? 'Message to victim...'
                        : 'Message to SAR team...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppTheme.darkBackground,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: _isLoading
                      ? AppTheme.neutralGray
                      : AppTheme.primaryRed,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(EmergencyMessage message, bool isFromCurrentUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isFromCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isFromCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: _getMessageTypeColor(message.type),
              child: Icon(
                widget.isSARMember ? Icons.person : Icons.volunteer_activism,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isFromCurrentUser
                    ? AppTheme.primaryRed
                    : AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: isFromCurrentUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                  bottomLeft: !isFromCurrentUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
                border: !isFromCurrentUser
                    ? Border.all(
                        color: AppTheme.neutralGray.withValues(alpha: 0.3),
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isFromCurrentUser) ...[
                    Row(
                      children: [
                        Text(
                          message.senderName,
                          style: TextStyle(
                            color: isFromCurrentUser
                                ? Colors.white70
                                : AppTheme.infoBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getMessageTypeColor(
                              message.type,
                            ).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _getMessageTypeDisplayName(message.type),
                            style: TextStyle(
                              color: _getMessageTypeColor(message.type),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isFromCurrentUser
                          ? Colors.white
                          : AppTheme.primaryText,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(message.timestamp),
                    style: TextStyle(
                      color: isFromCurrentUser
                          ? Colors.white70
                          : AppTheme.secondaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isFromCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryRed,
              child: Icon(
                widget.isSARMember ? Icons.volunteer_activism : Icons.person,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getMessageTypeColor(MessageType type) {
    switch (type) {
      case MessageType.status:
        return AppTheme.infoBlue;
      case MessageType.emergency:
        return AppTheme.criticalRed;
      case MessageType.alert:
        return AppTheme.warningOrange;
      case MessageType.response:
        return AppTheme.safeGreen;
      case MessageType.sarResponse:
        return AppTheme.infoBlue;
      case MessageType.userResponse:
        return AppTheme.warningOrange;
      case MessageType.general:
        return AppTheme.neutralGray;
    }
  }

  String _getMessageTypeDisplayName(MessageType type) {
    switch (type) {
      case MessageType.status:
        return 'Status';
      case MessageType.emergency:
        return 'Emergency';
      case MessageType.alert:
        return 'Alert';
      case MessageType.response:
        return 'Response';
      case MessageType.sarResponse:
        return 'SAR Response';
      case MessageType.userResponse:
        return 'User Response';
      case MessageType.general:
        return 'General';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
