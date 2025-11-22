import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/emergency_message.dart';

/// Professional communication panel for SAR team messaging
class ProfessionalCommunicationPanel extends StatefulWidget {
  final List<EmergencyMessage> recentMessages;
  final Function(String content, String recipientId) onSendMessage;

  const ProfessionalCommunicationPanel({
    super.key,
    required this.recentMessages,
    required this.onSendMessage,
  });

  @override
  State<ProfessionalCommunicationPanel> createState() =>
      _ProfessionalCommunicationPanelState();
}

class _ProfessionalCommunicationPanelState
    extends State<ProfessionalCommunicationPanel> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.safeGreen.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.safeGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.message,
                  color: AppTheme.safeGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Team Communication',
                  style: TextStyle(
                    color: AppTheme.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.infoBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.infoBlue),
                ),
                child: Text(
                  '${widget.recentMessages.length} messages',
                  style: const TextStyle(
                    color: AppTheme.infoBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Recent Messages
          if (widget.recentMessages.isEmpty)
            _buildEmptyState()
          else
            Expanded(child: _buildMessagesList()),

          const SizedBox(height: 16),

          // Quick Actions
          _buildQuickActions(),

          const SizedBox(height: 16),

          // Message Composer
          _buildMessageComposer(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.message_outlined,
            size: 48,
            color: AppTheme.neutralGray.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'No Recent Messages',
            style: TextStyle(
              color: AppTheme.secondaryText,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Team communication will appear here',
            style: TextStyle(color: AppTheme.secondaryText, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neutralGray.withValues(alpha: 0.3)),
      ),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(12),
        itemCount: widget.recentMessages.length,
        itemBuilder: (context, index) {
          final message = widget.recentMessages[index];
          return _buildMessageItem(message);
        },
      ),
    );
  }

  Widget _buildMessageItem(EmergencyMessage message) {
    final isFromSAR = message.type == MessageType.sarResponse;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isFromSAR
            ? AppTheme.infoBlue.withValues(alpha: 0.1)
            : AppTheme.neutralGray.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFromSAR
              ? AppTheme.infoBlue.withValues(alpha: 0.3)
              : AppTheme.neutralGray.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isFromSAR ? Icons.emergency : Icons.person,
                color: isFromSAR ? AppTheme.infoBlue : AppTheme.primaryText,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message.senderName,
                  style: TextStyle(
                    color: isFromSAR ? AppTheme.infoBlue : AppTheme.primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                _formatTime(message.timestamp),
                style: const TextStyle(
                  color: AppTheme.secondaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.content,
            style: const TextStyle(color: AppTheme.primaryText, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getPriorityColor(message.priority).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              message.priority.name.toUpperCase(),
              style: TextStyle(
                color: _getPriorityColor(message.priority),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: AppTheme.primaryText,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                'Status Update',
                Icons.update,
                AppTheme.infoBlue,
                () => _sendQuickMessage('Status update: En route to location'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionButton(
                'ETA Update',
                Icons.timer,
                AppTheme.warningOrange,
                () => _sendQuickMessage('ETA: 15 minutes'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuickActionButton(
                'On Scene',
                Icons.location_on,
                AppTheme.safeGreen,
                () =>
                    _sendQuickMessage('On scene - beginning rescue operation'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neutralGray.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Recipient Selection
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.neutralGray.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  color: AppTheme.secondaryText,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Send to: All Team Members',
                  style: TextStyle(color: AppTheme.secondaryText, fontSize: 12),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_drop_down,
                  color: AppTheme.secondaryText,
                  size: 16,
                ),
              ],
            ),
          ),

          // Message Input
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: AppTheme.primaryText),
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      hintStyle: TextStyle(color: AppTheme.secondaryText),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _sendMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.safeGreen,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: const Icon(Icons.send, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendQuickMessage(String message) {
    _messageController.text = message;
    _sendMessage();
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isNotEmpty) {
      widget.onSendMessage(content, 'team'); // Send to all team members
      _messageController.clear();

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  Color _getPriorityColor(MessagePriority priority) {
    switch (priority) {
      case MessagePriority.low:
        return AppTheme.safeGreen;
      case MessagePriority.medium:
        return AppTheme.warningOrange;
      case MessagePriority.high:
        return AppTheme.primaryRed;
      case MessagePriority.critical:
        return AppTheme.criticalRed;
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}






