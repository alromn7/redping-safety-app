import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/help_request.dart';
import '../../../../models/help_response.dart';

/// Widget for real-time communication between user and community help network
class HelpCommunicationWidget extends StatefulWidget {
  final HelpRequest helpRequest;
  final List<HelpResponse> responses;
  final Function(String) onSendMessage;
  final Function(String) onUpdateStatus;

  const HelpCommunicationWidget({
    super.key,
    required this.helpRequest,
    required this.responses,
    required this.onSendMessage,
    required this.onUpdateStatus,
  });

  @override
  State<HelpCommunicationWidget> createState() =>
      _HelpCommunicationWidgetState();
}

class _HelpCommunicationWidgetState extends State<HelpCommunicationWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _scrollToBottom();
  }

  @override
  void didUpdateWidget(HelpCommunicationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.responses.length != oldWidget.responses.length) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.neutralGray.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),

          // Messages
          Expanded(child: _buildMessagesList()),

          // Typing indicator
          if (_isTyping) _buildTypingIndicator(),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.safeGreen.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.chat, color: AppTheme.safeGreen, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Community Help Network',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryText,
                  ),
                ),
                Text(
                  'Connected to ${widget.helpRequest.assignedHelpers.length} community helpers',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          _buildStatusButton(),
        ],
      ),
    );
  }

  Widget _buildStatusButton() {
    return PopupMenuButton<String>(
      onSelected: (status) => widget.onUpdateStatus(status),
      icon: Icon(Icons.more_vert, color: AppTheme.safeGreen),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'resolved',
          child: Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.safeGreen),
              SizedBox(width: 8),
              Text('Mark as Resolved'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'escalate',
          child: Row(
            children: [
              Icon(Icons.priority_high, color: AppTheme.criticalRed),
              SizedBox(width: 8),
              Text('Escalate Priority'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'cancel',
          child: Row(
            children: [
              Icon(Icons.cancel, color: AppTheme.warningOrange),
              SizedBox(width: 8),
              Text('Cancel Request'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    if (widget.responses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppTheme.neutralGray,
            ),
            const SizedBox(height: 16),
            const Text(
              'No messages yet',
              style: TextStyle(fontSize: 16, color: AppTheme.secondaryText),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start a conversation with the community help network',
              style: TextStyle(fontSize: 14, color: AppTheme.secondaryText),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: widget.responses.length,
      itemBuilder: (context, index) {
        final response = widget.responses[index];
        return _buildResponseBubble(response);
      },
    );
  }

  Widget _buildResponseBubble(HelpResponse response) {
    final isFromUser = response.responderId == widget.helpRequest.userId;
    final isHighPriority = response.type == HelpResponseType.emergency;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isFromUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isFromUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.safeGreen,
              child: Icon(Icons.people, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isFromUser ? AppTheme.safeGreen : AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomLeft: isFromUser
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isFromUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
                border: isHighPriority
                    ? Border.all(
                        color: AppTheme.criticalRed.withValues(alpha: 0.5),
                      )
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isHighPriority)
                    Row(
                      children: [
                        Icon(
                          Icons.priority_high,
                          color: AppTheme.criticalRed,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'HIGH PRIORITY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.criticalRed,
                          ),
                        ),
                      ],
                    ),
                  Text(
                    response.message,
                    style: TextStyle(
                      color: isFromUser ? Colors.white : AppTheme.primaryText,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(response.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: isFromUser
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppTheme.secondaryText,
                        ),
                      ),
                      if (response.isAccepted) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all,
                          size: 12,
                          color: isFromUser
                              ? Colors.white.withValues(alpha: 0.7)
                              : AppTheme.safeGreen,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isFromUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.safeGreen,
              child: Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.people, color: AppTheme.safeGreen, size: 16),
          const SizedBox(width: 8),
          const Text(
            'Community helper is typing...',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.secondaryText,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border(
          top: BorderSide(color: AppTheme.neutralGray.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: const TextStyle(color: AppTheme.secondaryText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: AppTheme.neutralGray.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: AppTheme.neutralGray.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppTheme.safeGreen),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                filled: true,
                fillColor: AppTheme.darkBackground,
              ),
              style: const TextStyle(color: AppTheme.primaryText),
              maxLines: null,
              onChanged: (value) {
                setState(() {
                  _isTyping = value.isNotEmpty;
                });
              },
              onSubmitted: (value) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.safeGreen,
              borderRadius: BorderRadius.circular(24),
            ),
            child: IconButton(
              onPressed: _messageController.text.trim().isNotEmpty
                  ? _sendMessage
                  : null,
              icon: const Icon(Icons.send, color: Colors.white),
              tooltip: 'Send Message',
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      widget.onSendMessage(message);
      _messageController.clear();
      setState(() {
        _isTyping = false;
      });
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
