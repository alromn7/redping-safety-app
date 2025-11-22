import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/chat_message.dart';
import '../../../../services/chat_service.dart';
import '../../../../services/notification_service.dart';
import '../../../../services/location_service.dart';
import '../widgets/chat_message_widget.dart';
import '../widgets/chat_input_widget.dart';
import '../widgets/chat_room_card.dart';
import '../widgets/nearby_users_widget.dart';

/// Comprehensive chat page with messaging, community, and emergency communication
class ChatPage extends StatefulWidget {
  final String? chatId;

  const ChatPage({super.key, this.chatId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final LocationService _locationService = LocationService();

  late TabController _tabController;

  List<ChatRoom> _chatRooms = [];
  List<ChatMessage> _currentChatMessages = [];
  List<ChatUser> _nearbyUsers = [];
  ChatRoom? _currentChatRoom;

  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeChatService();
    _setupCallbacks();

    // If specific chat ID provided, open that chat
    if (widget.chatId != null) {
      _openSpecificChat(widget.chatId!);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeChatService() async {
    setState(() => _isLoading = true);

    try {
      await _chatService.initialize();
      await _locationService.initialize();
      _loadChatData();
    } catch (e) {
      _showError('Failed to initialize chat service: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _setupCallbacks() {
    _chatService.setMessageReceivedCallback(_onMessageReceived);
    _chatService.setChatRoomUpdatedCallback(_onChatRoomUpdated);
    _chatService.setNearbyUsersUpdatedCallback(_onNearbyUsersUpdated);
    _chatService.setConnectionStatusChangedCallback(_onConnectionStatusChanged);
  }

  void _loadChatData() {
    if (!mounted) return;

    setState(() {
      _chatRooms = _chatService.chatRooms;
      _nearbyUsers = _chatService.nearbyUsers;

      if (_currentChatRoom != null) {
        _currentChatMessages = _chatService.getMessagesForChat(
          _currentChatRoom!.id,
        );
      }
    });
  }

  void _openSpecificChat(String chatId) {
    final room = _chatRooms.firstWhere(
      (room) => room.id == chatId,
      orElse: () => ChatRoom(
        id: '',
        name: '',
        type: ChatType.direct,
        createdAt: DateTime.now(),
      ),
    );

    if (room.id.isNotEmpty) {
      _openChatRoom(room);
    }
  }

  void _openChatRoom(ChatRoom room) {
    setState(() {
      _currentChatRoom = room;
      _currentChatMessages = _chatService.getMessagesForChat(room.id);
    });

    // Mark messages as read
    _chatService.markMessagesAsRead(room.id);

    // Switch to chat tab
    _tabController.animateTo(1);
  }

  void _onMessageReceived(ChatMessage message) {
    if (!mounted) return;

    if (_currentChatRoom?.id == message.chatId) {
      setState(() {
        _currentChatMessages = _chatService.getMessagesForChat(message.chatId);
      });
    }

    _loadChatData();
    _showMessageNotification(message);

    // Show local notification for normal SAR-user messages (not emergency)
    if (message.priority == MessagePriority.normal &&
        message.type == MessageType.text) {
      // Only notify if not viewing the chat
      if (_currentChatRoom?.id != message.chatId) {
        // Use NotificationService for local notification
        _chatService.notificationService.showNotification(
          title: 'New SAR Message',
          body: '${message.senderName}: ${message.content}',
          importance: NotificationImportance.defaultImportance,
        );
      }
    }
  }

  void _onChatRoomUpdated(ChatRoom room) {
    if (!mounted) return;
    _loadChatData();
  }

  void _onNearbyUsersUpdated(List<ChatUser> users) {
    if (!mounted) return;
    setState(() {
      _nearbyUsers = users;
    });
  }

  void _onConnectionStatusChanged(bool isConnected) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isConnected ? Icons.wifi : Icons.wifi_off,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(isConnected ? 'Connected to chat server' : 'Connection lost'),
          ],
        ),
        backgroundColor: isConnected
            ? AppTheme.safeGreen
            : AppTheme.warningOrange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _sendMessage(
    String content, {
    MessagePriority priority = MessagePriority.normal,
  }) async {
    if (_currentChatRoom == null || content.trim().isEmpty) return;

    setState(() => _isSending = true);

    try {
      await _chatService.sendMessage(
        chatId: _currentChatRoom!.id,
        content: content.trim(),
        priority: priority,
      );

      setState(() {
        _currentChatMessages = _chatService.getMessagesForChat(
          _currentChatRoom!.id,
        );
      });
    } catch (e) {
      _showError('Failed to send message: $e');
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _sendLocationMessage() async {
    if (_currentChatRoom == null) return;

    try {
      final location = await _locationService.getCurrentLocation();
      if (location == null) {
        _showError('Location not available');
        return;
      }

      await _chatService.sendMessage(
        chatId: _currentChatRoom!.id,
        content: 'Shared location: ${location.address ?? 'Current position'}',
        type: MessageType.location,
        location: location,
      );

      setState(() {
        _currentChatMessages = _chatService.getMessagesForChat(
          _currentChatRoom!.id,
        );
      });
    } catch (e) {
      _showError('Failed to share location: $e');
    }
  }

  Future<void> _sendImageMessage() async {
    if (_currentChatRoom == null) return;

    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);

      if (image != null) {
        final attachment = MessageAttachment(
          id: _generateAttachmentId(),
          fileName: image.name,
          localPath: image.path,
          type: AttachmentType.image,
          fileSize: await image.length(),
          mimeType: 'image/jpeg',
        );

        await _chatService.sendMessage(
          chatId: _currentChatRoom!.id,
          content: 'Shared a photo',
          type: MessageType.image,
          attachments: [attachment],
        );

        setState(() {
          _currentChatMessages = _chatService.getMessagesForChat(
            _currentChatRoom!.id,
          );
        });
      }
    } catch (e) {
      _showError('Failed to send image: $e');
    }
  }

  Future<void> _createNewChatRoom() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _CreateChatRoomDialog(),
    );

    if (result != null) {
      try {
        final room = await _chatService.createChatRoom(
          name: result['name'],
          description: result['description'],
          type: result['type'],
          tags: result['tags'],
        );

        _loadChatData();
        _openChatRoom(room);
        _showSuccess('Chat room "${room.name}" created');
      } catch (e) {
        _showError('Failed to create chat room: $e');
      }
    }
  }

  void _showMessageNotification(ChatMessage message) {
    if (_currentChatRoom?.id == message.chatId) {
      return; // Don't notify if already viewing
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(_getPriorityEmoji(message.priority)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${message.senderName}: ${message.content}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: _getPriorityColor(message.priority),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            final room = _chatRooms.firstWhere((r) => r.id == message.chatId);
            _openChatRoom(room);
          },
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.criticalRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.safeGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentChatRoom != null) {
      return _buildChatRoomView();
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Community Chat'),
            if (_chatService.totalUnreadMessages > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.criticalRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_chatService.totalUnreadMessages}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _chatService.isConnected ? Icons.wifi : Icons.wifi_off,
              color: _chatService.isConnected
                  ? AppTheme.safeGreen
                  : AppTheme.warningOrange,
            ),
            onPressed: () => _showConnectionInfo(),
            tooltip: _chatService.isConnected ? 'Connected' : 'Disconnected',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewChatRoom,
            tooltip: 'Create Chat Room',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.chat_bubble),
              text: 'Chats (${_chatRooms.length})',
            ),
            Tab(
              icon: const Icon(Icons.people),
              text: 'Nearby (${_nearbyUsers.length})',
            ),
            Tab(icon: const Icon(Icons.emergency), text: 'Emergency'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildChatRoomsTab(),
                _buildNearbyUsersTab(),
                _buildEmergencyTab(),
              ],
            ),
    );
  }

  Widget _buildChatRoomView() {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_currentChatRoom!.name),
            Text(
              '${_currentChatRoom!.participants.length} participants',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.secondaryText,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _currentChatRoom = null),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: _sendLocationMessage,
            tooltip: 'Share Location',
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _sendImageMessage,
            tooltip: 'Send Photo',
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleChatMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'info', child: Text('Chat Info')),
              const PopupMenuItem(value: 'mute', child: Text('Mute')),
              const PopupMenuItem(value: 'leave', child: Text('Leave Chat')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: _currentChatMessages.length,
              itemBuilder: (context, index) {
                final message = _currentChatMessages.reversed.toList()[index];
                return ChatMessageWidget(
                  message: message,
                  isMe: message.senderId == _chatService.currentUser?.id,
                  showSenderName: _shouldShowSenderName(index),
                );
              },
            ),
          ),

          // Chat input
          ChatInputWidget(
            onSendMessage: _sendMessage,
            onSendLocation: _sendLocationMessage,
            onSendImage: _sendImageMessage,
            isSending: _isSending,
            isEmergencyChat: _currentChatRoom?.type == ChatType.emergency,
          ),
        ],
      ),
    );
  }

  Widget _buildChatRoomsTab() {
    if (_chatRooms.isEmpty) {
      return _buildEmptyState(
        icon: Icons.chat_bubble_outline,
        title: 'No Chat Rooms',
        subtitle: 'Create a chat room to start messaging',
        actionLabel: 'Create Chat Room',
        onAction: _createNewChatRoom,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _chatService.discoverNearbyUsers();
        _loadChatData();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _chatRooms.length,
        itemBuilder: (context, index) {
          final room = _chatRooms[index];
          return ChatRoomCard(
            room: room,
            onTap: () => _openChatRoom(room),
            onJoin: () => _chatService.joinChatRoom(room.id),
            onLeave: () => _chatService.leaveChatRoom(room.id),
          );
        },
      ),
    );
  }

  Widget _buildNearbyUsersTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await _chatService.discoverNearbyUsers();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection status
            _buildConnectionStatus(),

            const SizedBox(height: 16),

            // Nearby users
            NearbyUsersWidget(
              users: _nearbyUsers,
              onUserTap: _startDirectChat,
              onRefresh: () => _chatService.discoverNearbyUsers(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyTab() {
    final emergencyRooms = _chatRooms
        .where(
          (room) =>
              room.type == ChatType.emergency || room.type == ChatType.sarTeam,
        )
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Emergency communication header
          Card(
            color: AppTheme.criticalRed.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.emergency, color: AppTheme.criticalRed),
                      SizedBox(width: 8),
                      Text(
                        'Emergency Communication',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.criticalRed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Secure communication channels for emergency response and SAR coordination',
                    style: TextStyle(color: AppTheme.secondaryText),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _createEmergencyChat,
                          icon: const Icon(Icons.emergency),
                          label: const Text('Emergency Chat'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.criticalRed,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _createSARTeamChat,
                          icon: const Icon(Icons.search),
                          label: const Text('SAR Team'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.criticalRed,
                            side: const BorderSide(color: AppTheme.criticalRed),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Emergency chat rooms
          if (emergencyRooms.isNotEmpty) ...[
            const Text(
              'Active Emergency Chats',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 12),
            ...emergencyRooms.map(
              (room) => ChatRoomCard(
                room: room,
                onTap: () => _openChatRoom(room),
                onJoin: () => _chatService.joinChatRoom(room.id),
                onLeave: () => _chatService.leaveChatRoom(room.id),
              ),
            ),
          ] else
            _buildEmptyState(
              icon: Icons.security,
              title: 'No Emergency Chats',
              subtitle: 'Emergency chats will appear here when created',
              color: AppTheme.criticalRed,
            ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    (_chatService.isConnected
                            ? AppTheme.safeGreen
                            : AppTheme.warningOrange)
                        .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _chatService.isConnected ? Icons.wifi : Icons.wifi_off,
                color: _chatService.isConnected
                    ? AppTheme.safeGreen
                    : AppTheme.warningOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _chatService.isConnected ? 'Connected' : 'Disconnected',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _chatService.isConnected
                          ? AppTheme.safeGreen
                          : AppTheme.warningOrange,
                    ),
                  ),
                  Text(
                    _chatService.isConnected
                        ? 'Real-time messaging active'
                        : 'Messages will be queued for delivery',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? color,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final displayColor = color ?? AppTheme.neutralGray;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: displayColor.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: displayColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: AppTheme.secondaryText),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel),
                style: ElevatedButton.styleFrom(backgroundColor: displayColor),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _shouldShowSenderName(int index) {
    if (index == _currentChatMessages.length - 1) return true;

    final currentMessage = _currentChatMessages.reversed.toList()[index];
    final nextMessage = _currentChatMessages.reversed.toList()[index + 1];

    return currentMessage.senderId != nextMessage.senderId;
  }

  Future<void> _startDirectChat(ChatUser user) async {
    // Check if direct chat already exists
    final existingChat = _chatRooms.firstWhere(
      (room) =>
          room.type == ChatType.direct &&
          room.participants.contains(user.id) &&
          room.participants.contains(_chatService.currentUser?.id),
      orElse: () => ChatRoom(
        id: '',
        name: '',
        type: ChatType.direct,
        createdAt: DateTime.now(),
      ),
    );

    ChatRoom chatRoom;
    if (existingChat.id.isNotEmpty) {
      chatRoom = existingChat;
    } else {
      chatRoom = await _chatService.createChatRoom(
        name: user.name,
        type: ChatType.direct,
        participants: [user.id, _chatService.currentUser?.id ?? 'current_user'],
      );
      _loadChatData();
    }

    _openChatRoom(chatRoom);
  }

  Future<void> _createEmergencyChat() async {
    final room = await _chatService.createChatRoom(
      name: 'Emergency Response ${DateTime.now().millisecondsSinceEpoch}',
      description: 'Emergency coordination and communication',
      type: ChatType.emergency,
      tags: ['emergency', 'response'],
    );

    _loadChatData();
    _openChatRoom(room);
  }

  Future<void> _createSARTeamChat() async {
    final room = await _chatService.createChatRoom(
      name: 'SAR Team ${DateTime.now().millisecondsSinceEpoch}',
      description: 'Search and rescue team coordination',
      type: ChatType.sarTeam,
      tags: ['sar', 'team', 'coordination'],
    );

    _loadChatData();
    _openChatRoom(room);
  }

  void _handleChatMenuAction(String action) {
    switch (action) {
      case 'info':
        _showChatInfo();
        break;
      case 'mute':
        _toggleChatMute();
        break;
      case 'leave':
        _leaveChatRoom();
        break;
    }
  }

  void _showChatInfo() {
    showDialog(
      context: context,
      builder: (context) => _ChatInfoDialog(room: _currentChatRoom!),
    );
  }

  void _toggleChatMute() {
    // TODO: Implement chat mute functionality
    _showSuccess('Chat mute functionality coming soon');
  }

  void _leaveChatRoom() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Chat'),
        content: Text(
          'Are you sure you want to leave "${_currentChatRoom!.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _chatService.leaveChatRoom(_currentChatRoom!.id);
              setState(() => _currentChatRoom = null);
              _loadChatData();
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _showConnectionInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusRow(
              'Server',
              _chatService.isConnected ? 'Connected' : 'Disconnected',
            ),
            _buildStatusRow(
              'Chat Service',
              _chatService.isEnabled ? 'Enabled' : 'Disabled',
            ),
            _buildStatusRow('Total Chats', '${_chatRooms.length}'),
            _buildStatusRow(
              'Unread Messages',
              '${_chatService.totalUnreadMessages}',
            ),
            _buildStatusRow('Nearby Users', '${_nearbyUsers.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // Helper methods
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

  String _generateAttachmentId() {
    return 'ATT_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999).toString().padLeft(4, '0')}';
  }
}

/// Dialog for creating new chat rooms
class _CreateChatRoomDialog extends StatefulWidget {
  @override
  State<_CreateChatRoomDialog> createState() => _CreateChatRoomDialogState();
}

class _CreateChatRoomDialogState extends State<_CreateChatRoomDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  ChatType _selectedType = ChatType.group;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Chat Room'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Room Name *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ChatType>(
              initialValue: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Chat Type',
                border: OutlineInputBorder(),
              ),
              items:
                  [ChatType.group, ChatType.community, ChatType.locationBased]
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(_getChatTypeDisplayName(type)),
                        ),
                      )
                      .toList(),
              onChanged: (value) => setState(() => _selectedType = value!),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma separated)',
                hintText: 'hiking, emergency, local, etc.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _nameController.text.trim().isEmpty
              ? null
              : () {
                  final tags = _tagsController.text
                      .split(',')
                      .map((tag) => tag.trim())
                      .where((tag) => tag.isNotEmpty)
                      .toList();

                  Navigator.pop(context, {
                    'name': _nameController.text.trim(),
                    'description': _descriptionController.text.trim(),
                    'type': _selectedType,
                    'tags': tags,
                  });
                },
          child: const Text('Create'),
        ),
      ],
    );
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
}

/// Dialog showing chat room information
class _ChatInfoDialog extends StatelessWidget {
  final ChatRoom room;

  const _ChatInfoDialog({required this.room});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(room.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (room.description != null) ...[
              const Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(room.description!),
              const SizedBox(height: 12),
            ],
            const Text('Type:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(_getChatTypeDisplayName(room.type)),
            const SizedBox(height: 12),
            const Text(
              'Participants:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('${room.participants.length} members'),
            const SizedBox(height: 12),
            const Text(
              'Created:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(_formatDateTime(room.createdAt)),
            if (room.lastActivity != null) ...[
              const SizedBox(height: 12),
              const Text(
                'Last Activity:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(_formatDateTime(room.lastActivity!)),
            ],
            if (room.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Tags:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 6,
                children: room.tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        backgroundColor: AppTheme.infoBlue.withValues(
                          alpha: 0.2,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
