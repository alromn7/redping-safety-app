// ignore_for_file: unused_element
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/chat_message.dart';

/// Widget for chat input with message composition
class ChatInputWidget extends StatefulWidget {
  final Function(String, {MessagePriority priority}) onSendMessage;
  final VoidCallback? onSendLocation;
  final VoidCallback? onSendImage;
  final bool isSending;
  final bool isEmergencyChat;

  const ChatInputWidget({
    super.key,
    required this.onSendMessage,
    this.onSendLocation,
    this.onSendImage,
    this.isSending = false,
    this.isEmergencyChat = false,
  });

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  MessagePriority _selectedPriority = MessagePriority.normal;
  bool _showAttachmentOptions = false;

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.darkSurface,
        border: Border(
          top: BorderSide(color: AppTheme.neutralGray, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Priority selector for emergency chats
          if (widget.isEmergencyChat) _buildPrioritySelector(),

          // Attachment options
          if (_showAttachmentOptions) _buildAttachmentOptions(),

          // Main input row
          Row(
            children: [
              // Attachment button
              IconButton(
                onPressed: () => setState(
                  () => _showAttachmentOptions = !_showAttachmentOptions,
                ),
                icon: Icon(
                  _showAttachmentOptions ? Icons.close : Icons.attach_file,
                  color: AppTheme.primaryText,
                ),
                tooltip: 'Attachments',
              ),

              // Message input field
              Expanded(
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: widget.isEmergencyChat
                        ? 'Emergency message...'
                        : 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppTheme.neutralGray.withValues(alpha: 0.1),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),

              const SizedBox(width: 8),

              // Send button
              Container(
                decoration: BoxDecoration(
                  color: _getSendButtonColor(),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: IconButton(
                  onPressed:
                      widget.isSending || _messageController.text.trim().isEmpty
                      ? null
                      : _sendMessage,
                  icon: widget.isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                  tooltip: 'Send Message',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Text(
            'Priority:',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.secondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: MessagePriority.values.map((priority) {
                  final isSelected = _selectedPriority == priority;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_getPriorityEmoji(priority)),
                          const SizedBox(width: 4),
                          Text(
                            priority.name.toUpperCase(),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedPriority = priority);
                      },
                      backgroundColor: _getPriorityColor(
                        priority,
                      ).withValues(alpha: 0.1),
                      selectedColor: _getPriorityColor(
                        priority,
                      ).withValues(alpha: 0.3),
                      checkmarkColor: _getPriorityColor(priority),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOptions() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.neutralGray.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAttachmentOption(
            icon: Icons.camera_alt,
            label: 'Camera',
            onTap: widget.onSendImage,
          ),
          _buildAttachmentOption(
            icon: Icons.location_on,
            label: 'Location',
            onTap: widget.onSendLocation,
          ),
          _buildAttachmentOption(
            icon: Icons.photo_library,
            label: 'Gallery',
            onTap: _selectFromGallery,
          ),
          _buildAttachmentOption(
            icon: Icons.mic,
            label: 'Voice',
            onTap: _recordVoiceMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppTheme.primaryText),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    widget.onSendMessage(content, priority: _selectedPriority);
    _messageController.clear();

    // Reset priority to normal after sending
    if (_selectedPriority != MessagePriority.normal) {
      setState(() => _selectedPriority = MessagePriority.normal);
    }

    // Hide attachment options
    if (_showAttachmentOptions) {
      setState(() => _showAttachmentOptions = false);
    }
  }

  void _selectFromGallery() {
    // TODO: Implement gallery selection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gallery selection coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _recordVoiceMessage() {
    // TODO: Implement voice message recording
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voice messages coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getSendButtonColor() {
    if (widget.isEmergencyChat) {
      return switch (_selectedPriority) {
        MessagePriority.emergency => AppTheme.criticalRed,
        MessagePriority.urgent => AppTheme.primaryRed,
        MessagePriority.high => AppTheme.warningOrange,
        _ => AppTheme.primaryRed,
      };
    }
    return AppTheme.primaryRed;
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
    return '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}
