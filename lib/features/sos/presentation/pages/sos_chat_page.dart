import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/sos_session.dart';
import '../../../../services/auth_service.dart';

/// Real-time chat page for SOS sessions between victims and SAR team
class SOSChatPage extends StatefulWidget {
  final SOSSession session;
  final bool isSARUser; // Whether current user is SAR team member

  const SOSChatPage({super.key, required this.session, this.isSARUser = false});

  @override
  State<SOSChatPage> createState() => _SOSChatPageState();
}

class _SOSChatPageState extends State<SOSChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AuthService _authService = AuthService.instance;

  StreamSubscription? _messagesSubscription;
  List<ChatMessage> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messagesSubscription?.cancel();
    super.dispose();
  }

  /// Load messages from Firestore in real-time
  void _loadMessages() {
    final messagesRef = FirebaseFirestore.instance
        .collection('sos_sessions')
        .doc(widget.session.id)
        .collection('chat_messages')
        .orderBy('timestamp', descending: false);

    _messagesSubscription = messagesRef.snapshots().listen((snapshot) {
      setState(() {
        _messages = snapshot.docs.map((doc) {
          final data = doc.data();
          return ChatMessage(
            id: doc.id,
            senderId: data['senderId'] ?? '',
            senderName: data['senderName'] ?? 'Unknown',
            message: data['message'] ?? '',
            timestamp:
                (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            isSARMember: data['isSARMember'] ?? false,
          );
        }).toList();
        _isLoading = false;
      });

      // Auto-scroll to bottom when new message arrives
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  /// Send a message to Firestore
  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    try {
      final currentUser = _authService.currentUser;
      final currentUserId = currentUser.id;
      final currentUserName = currentUser.displayName;

      final messagesRef = FirebaseFirestore.instance
          .collection('sos_sessions')
          .doc(widget.session.id)
          .collection('chat_messages');

      await messagesRef.add({
        'senderId': currentUserId,
        'senderName': currentUserName,
        'message': messageText,
        'timestamp': FieldValue.serverTimestamp(),
        'isSARMember': widget.isSARUser,
      });

      // Clear input
      _messageController.clear();

      // Update last message in session
      await FirebaseFirestore.instance
          .collection('sos_sessions')
          .doc(widget.session.id)
          .update({
            'lastMessage': messageText,
            'lastMessageTime': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('Error sending message: $e');
      ScaffoldMessenger.of(
      // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send message: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D), // Dark background
      appBar: AppBar(
        backgroundColor: AppTheme.cardBackground,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isSARUser ? 'SOS Victim Chat' : 'SAR Team Chat',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Session: ${widget.session.id.substring(0, 8)}...',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.secondaryText,
              ),
            ),
          ],
        ),
        actions: [
          // Video call button
          IconButton(
            icon: const Icon(Icons.video_call, color: AppTheme.primaryRed),
            tooltip: 'Video Call',
            onPressed: () {
              // TODO: Integrate with WebRTC service
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('WebRTC video call coming soon')),
              );
            },
          ),
          // Voice call button
          IconButton(
            icon: const Icon(Icons.phone, color: AppTheme.safeGreen),
            tooltip: 'Voice Call',
            onPressed: () {
              // TODO: Integrate with WebRTC service
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('WebRTC voice call coming soon')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Session info banner
          _buildSessionInfoBanner(),

          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isCurrentUser =
                          message.senderId == _authService.currentUser.id;
                      return _buildMessageBubble(message, isCurrentUser);
                    },
                  ),
          ),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildSessionInfoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryRed.withValues(alpha: 0.1),
            AppTheme.criticalRed.withValues(alpha: 0.1),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppTheme.primaryRed.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.sos, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.session.status
                      .toString()
                      .split('.')
                      .last
                      .toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryRed,
                  ),
                ),
                Text(
                  'Emergency session active',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryText,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.safeGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: Colors.white, size: 8),
                SizedBox(width: 6),
                Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: AppTheme.secondaryText.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            widget.isSARUser
                ? 'Start conversation with victim'
                : 'SAR team will respond soon',
            style: const TextStyle(fontSize: 16, color: AppTheme.secondaryText),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a message to begin',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.secondaryText.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isCurrentUser) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: message.isSARMember
                  ? AppTheme.safeGreen
                  : AppTheme.primaryRed,
              child: Icon(
                message.isSARMember ? Icons.local_hospital : Icons.person,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      message.senderName,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.secondaryText.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrentUser
                        ? AppTheme.primaryRed
                        : AppTheme.cardBackground,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isCurrentUser ? 16 : 4),
                      bottomRight: Radius.circular(isCurrentUser ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      fontSize: 15,
                      color: isCurrentUser
                          ? Colors.white
                          : AppTheme.primaryText,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Text(
                    _formatTimestamp(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.secondaryText.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryRed,
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: Border(
          top: BorderSide(
            color: AppTheme.primaryRed.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Attachment button
            IconButton(
              icon: const Icon(Icons.attach_file),
              color: AppTheme.primaryRed,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('File attachment coming soon')),
                );
              },
            ),
            const SizedBox(width: 8),
            // Message input field
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: AppTheme.secondaryText.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A), // Dark input background
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            // Send button
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryRed,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send),
                color: Colors.white,
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inDays < 1) {
      return '${diff.inHours}h ago';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// Chat message model
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isSARMember;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.isSARMember,
  });
}
