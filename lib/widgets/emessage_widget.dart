// ignore_for_file: unused_element
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../core/theme/app_theme.dart';
import '../services/app_service_manager.dart';
import '../models/emergency_contact.dart';
import '../models/emergency_message.dart';

/// E-message widget for emergency messaging with online/offline capability
class EmessageWidget extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool showBackground;

  const EmessageWidget({super.key, this.onPressed, this.showBackground = true});

  @override
  State<EmessageWidget> createState() => _EmessageWidgetState();
}

class _EmessageWidgetState extends State<EmessageWidget> {
  final AppServiceManager _serviceManager = AppServiceManager();
  List<QueryDocumentSnapshot>? _cachedMessages;

  @override
  void initState() {
    super.initState();
    // Pre-load messages for better performance
    _preloadMessages();
  }

  /// Pre-load messages to reduce lag when opening
  Future<void> _preloadMessages() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('sos_sessions')
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .limit(10) // Limit to recent messages for faster load
          .get();

      if (mounted) {
        setState(() {
          _cachedMessages = snapshot.docs;
        });
      }
    } catch (e) {
      debugPrint('EmessageWidget: Error preloading messages: $e');
    }
  }

  void _handleEmergencyMessage() {
    if (widget.onPressed != null) {
      widget.onPressed!();
    } else {
      _showEmergencyMessageDialog();
    }
  }

  void _showEmergencyMessageDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkSurface,
      isScrollControlled: true,
      builder: (context) => Scaffold(
        backgroundColor: AppTheme.darkSurface,
        appBar: AppBar(
          backgroundColor: AppTheme.darkSurface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.primaryText),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Emergency Messaging',
            style: TextStyle(
              color: AppTheme.primaryText,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Connection status
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.successGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.wifi,
                          color: AppTheme.successGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Live Feed from Firestore',
                          style: TextStyle(
                            color: AppTheme.successGreen,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Quick Actions
                  const Text(
                    'Quick Actions',
                    style: TextStyle(
                      color: AppTheme.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Send Emergency Message Button
                  _buildActionButton(
                    'Send Emergency Message',
                    'Send urgent message to all emergency contacts',
                    Icons.send,
                    AppTheme.primaryRed,
                    _sendEmergencyMessage,
                  ),
                  const SizedBox(height: 12),

                  // View Messages Button
                  _buildActionButton(
                    'View Messages',
                    'Check received emergency messages',
                    Icons.message,
                    AppTheme.infoBlue,
                    _viewMessages,
                  ),
                  const SizedBox(height: 12),

                  const SizedBox(height: 24),

                  // Recent Messages
                  const Text(
                    'Recent Messages',
                    style: TextStyle(
                      color: AppTheme.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Recent Messages Section
                  SizedBox(
                    height: 300, // Fixed height for the messages list
                    child: _buildRecentMessagesList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentMessagesList() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(
        child: Text(
          'Please log in to see messages.',
          style: TextStyle(color: AppTheme.secondaryText),
        ),
      );
    }

    // Show cached messages immediately if available
    if (_cachedMessages != null && _cachedMessages!.isNotEmpty) {
      return ListView.builder(
        itemCount: _cachedMessages!.length,
        physics: const BouncingScrollPhysics(), // Smoother scrolling
        itemBuilder: (context, index) {
          final doc = _cachedMessages![index];
          final message = doc.data() as Map<String, dynamic>;
          final adaptedMessage = _adaptMessage(doc.id, message);
          return _buildMessageItem(adaptedMessage);
        },
      );
    }

    // Otherwise show StreamBuilder with loading state
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sos_sessions')
          .where('userId', isEqualTo: currentUser.uid)
          .orderBy('createdAt', descending: true)
          .limit(10) // Limit for performance
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          debugPrint(
            'EmessageWidget: Firestore stream error: ${snapshot.error}',
          );
          return const Center(
            child: Text(
              'Error loading messages.',
              style: TextStyle(color: AppTheme.criticalRed),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.infoBlue),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading messages...',
                  style: TextStyle(color: AppTheme.secondaryText, fontSize: 12),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, color: AppTheme.disabledText, size: 48),
                SizedBox(height: 8),
                Text(
                  'No messages yet.',
                  style: TextStyle(color: AppTheme.secondaryText),
                ),
              ],
            ),
          );
        }

        final messages = snapshot.data!.docs;

        // Cache the messages for next time
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _cachedMessages = messages;
            });
          }
        });

        return ListView.builder(
          itemCount: messages.length,
          physics: const BouncingScrollPhysics(), // Smoother scrolling
          itemBuilder: (context, index) {
            final doc = messages[index];
            final message = doc.data() as Map<String, dynamic>;
            final adaptedMessage = _adaptMessage(doc.id, message);
            return _buildMessageItem(adaptedMessage);
          },
        );
      },
    );
  }

  /// Adapt Firestore message to widget format (extracted for reuse)
  Map<String, dynamic> _adaptMessage(
    String docId,
    Map<String, dynamic> message,
  ) {
    final ts =
        (message['updatedAt'] ??
        message['createdAt'] ??
        message['startTime'] ??
        message['timestamp']);
    final Timestamp? t = ts is Timestamp ? ts : null;
    final loc = (message['location'] ?? {}) as Map<String, dynamic>;

    double? toD(v) {
      if (v is num) return v.toDouble();
      if (v is String) {
        final p = double.tryParse(v);
        return p;
      }
      return null;
    }

    final lat = toD(loc['latitude']);
    final lon = toD(loc['longitude']);
    final latStr = lat != null ? lat.toStringAsFixed(4) : 'N/A';
    final lonStr = lon != null ? lon.toStringAsFixed(4) : 'N/A';
    final msg =
        (message['userMessage'] ??
                message['details'] ??
                message['description'] ??
                '')
            as String;

    return {
      'id': docId,
      'sender': message['userName'] ?? 'SOS User',
      'content': msg.isNotEmpty
          ? msg
          : 'Status: ${message['status']} • Location: $latStr, $lonStr',
      'time': t != null ? TimeAgo.timeAgoSinceDate(t.toDate()) : '',
      'type': (message['status'] ?? 'active') == 'active'
          ? 'emergency'
          : 'sarResponse',
      'isRead': true, // For now, all are considered read
      'priority': (message['priority'] ?? 'high').toString(),
    };
  }

  Widget _buildMessageItem(Map<String, dynamic> message) {
    // Removed debug prints for better performance
    return InkWell(
      onTap: () => _handleMessageTap(message),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.darkSurface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: message['isRead'] == false
                ? AppTheme.primaryRed.withValues(alpha: 0.5)
                : AppTheme.neutralGray.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  message['type'] == 'emergency'
                      ? Icons.emergency
                      : message['type'] == 'sarResponse'
                      ? Icons.volunteer_activism
                      : Icons.message,
                  color: message['type'] == 'emergency'
                      ? AppTheme.primaryRed
                      : message['type'] == 'sarResponse'
                      ? AppTheme.safeGreen
                      : AppTheme.infoBlue,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message['sender'],
                    style: const TextStyle(
                      color: AppTheme.primaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  message['time'],
                  style: const TextStyle(
                    color: AppTheme.disabledText,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    message['content'],
                    style: TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.touch_app,
                  size: 12,
                  color: AppTheme.disabledText.withValues(alpha: 0.7),
                ),
              ],
            ),
            // Add reply button for SAR messages
            if (message['type'] == 'sarResponse' ||
                message['sender'] == 'SAR Team') ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showReplyDialog(message),
                    icon: const Icon(Icons.reply, size: 14),
                    label: const Text('Reply', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.infoBlue,
                      side: BorderSide(
                        color: AppTheme.infoBlue.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleMessageTap(Map<String, dynamic> message) {
    // Removed debug prints for better performance

    // Mark message as read if it's unread
    if (message['isRead'] == false) {
      _markMessageAsRead(message);
    }

    // Handle different message types
    if (message['type'] == 'sarResponse' || message['sender'] == 'SAR Team') {
      // For SAR messages, show reply dialog directly
      _showReplyDialog(message);
    } else {
      // For other messages, show message details dialog
      _showMessageDetailsDialog(message);
    }
  }

  void _markMessageAsRead(Map<String, dynamic> message) {
    // This would mark the message as read in the service
    // For now, we'll just update the UI state
    setState(() {
      // The message list will be refreshed from the service
    });
  }

  void _showMessageDetailsDialog(Map<String, dynamic> message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Text(
          'Message from ${message['sender']}',
          style: const TextStyle(color: AppTheme.primaryText),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  message['type'] == 'emergency'
                      ? Icons.emergency
                      : Icons.message,
                  color: message['type'] == 'emergency'
                      ? AppTheme.primaryRed
                      : AppTheme.infoBlue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  message['time'],
                  style: const TextStyle(
                    color: AppTheme.secondaryText,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message['content'],
              style: const TextStyle(color: AppTheme.primaryText, fontSize: 14),
            ),
            if (message['priority'] != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(
                    message['priority'],
                  ).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: _getPriorityColor(
                      message['priority'],
                    ).withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  'Priority: ${message['priority'].toUpperCase()}',
                  style: TextStyle(
                    color: _getPriorityColor(message['priority']),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppTheme.secondaryText),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppTheme.primaryRed;
      case 'medium':
        return AppTheme.warningOrange;
      case 'low':
        return AppTheme.safeGreen;
      default:
        return AppTheme.infoBlue;
    }
  }

  void _sendEmergencyMessage() {
    Navigator.pop(context);
    _showEmergencyMessageComposer();
  }

  void _showEmergencyMessageComposer() {
    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: const Text(
          'Send Emergency Message',
          style: TextStyle(color: AppTheme.primaryText),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Send urgent message to all emergency contacts',
              style: TextStyle(color: AppTheme.secondaryText),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              maxLines: 3,
              style: const TextStyle(color: AppTheme.primaryText),
              decoration: InputDecoration(
                hintText: 'Enter your emergency message...',
                hintStyle: const TextStyle(color: AppTheme.disabledText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primaryRed),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.secondaryText),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (messageController.text.trim().isNotEmpty) {
                final emergencyContacts = _serviceManager
                    .contactsService
                    .contacts
                    .where((contact) => contact.isEnabled)
                    .toList();

                // Capture UI helpers before awaiting
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);

                final success = await _serviceManager.emergencyMessagingService
                    .sendEmergencyMessage(
                      content: messageController.text.trim(),
                      recipients: emergencyContacts,
                    );

                navigator.pop();

                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Emergency message sent successfully!'
                          : 'Failed to send emergency message',
                    ),
                    backgroundColor: success
                        ? AppTheme.successGreen
                        : AppTheme.primaryRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _viewMessages() {
    Navigator.pop(context);
    // This would navigate to the messages list
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency messages list would open here'),
        backgroundColor: AppTheme.infoBlue,
      ),
    );
  }

  void _viewOfflineQueue() {
    Navigator.pop(context);
    // This would show offline message queue
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Offline message queue would open here'),
        backgroundColor: AppTheme.warningOrange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget iconButton = IconButton(
      onPressed: _handleEmergencyMessage,
      icon: const Icon(Icons.emergency, color: AppTheme.successGreen),
      tooltip: 'Emergency Messaging (Live)',
    );

    if (!widget.showBackground) {
      return iconButton;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.successGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.successGreen.withValues(alpha: 0.3)),
      ),
      child: iconButton,
    );
  }

  void _showReplyDialog(Map<String, dynamic> originalMessage) {
    debugPrint(
      'EmessageWidget: _showReplyDialog called for message: ${originalMessage['id']}',
    );
    final TextEditingController replyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: const Text(
          'Reply to SAR Team',
          style: TextStyle(color: AppTheme.primaryText),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show original message
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.neutralGray.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Original message from ${originalMessage['sender']}:',
                    style: const TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    originalMessage['content'],
                    style: const TextStyle(
                      color: AppTheme.primaryText,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: replyController,
              maxLines: 3,
              style: const TextStyle(color: AppTheme.primaryText),
              decoration: InputDecoration(
                hintText: 'Type your reply...',
                hintStyle: const TextStyle(color: AppTheme.disabledText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.infoBlue),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.secondaryText),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (replyController.text.trim().isNotEmpty) {
                // Capture navigator before the await to avoid using context across async gap
                final navigator = Navigator.of(context);
                await _sendReplyToSAR(
                  originalMessage,
                  replyController.text.trim(),
                );
                navigator.pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.infoBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Send Reply'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendReplyToSAR(
    Map<String, dynamic> originalMessage,
    String replyContent,
  ) async {
    // Capture messenger early to avoid using context across async gaps
    final messenger = ScaffoldMessenger.of(context);
    try {
      debugPrint(
        'EmessageWidget: Sending reply to SAR - ${originalMessage['id']}',
      );
      debugPrint('EmessageWidget: Reply content: $replyContent');

      final serviceManager = AppServiceManager();
      if (serviceManager.isInitialized) {
        debugPrint(
          'EmessageWidget: Service manager is initialized, sending message',
        );

        // Send to SAR messaging service
        await serviceManager.sarMessagingService.receiveMessageFromSOSUser(
          sosUserId: 'current_user', // Use consistent user ID
          sosUserName: 'SOS User',
          content: replyContent,
          priority: MessagePriority.medium,
          metadata: {
            'originalMessageId': originalMessage['id'],
            'originalSender': originalMessage['sender'],
            'isReply': true,
          },
        );

        debugPrint(
          'EmessageWidget: Message sent to SAR messaging service successfully',
        );

        // Also send via emergency messaging service for backup
        final sarContact = EmergencyContact(
          id: 'sar_team',
          name: 'SAR Team',
          phoneNumber: 'N/A',
          email: null,
          type: ContactType.emergencyServices,
          priority: 1,
          isEnabled: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await serviceManager.emergencyMessagingService.sendEmergencyMessage(
          content: replyContent,
          recipients: [sarContact],
        );
      }

      debugPrint('EmessageWidget: Reply sent successfully');

      // Show success feedback
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Reply sent to SAR team successfully!'),
          backgroundColor: AppTheme.safeGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('EmessageWidget: Error sending reply to SAR: $e');

      // Show error feedback
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to send reply: $e'),
          backgroundColor: AppTheme.criticalRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class TimeAgo {
  static String timeAgoSinceDate(DateTime date, {bool numericDates = true}) {
    return timeago.format(date);
  }
}
