import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../services/feature_access_service.dart';
import '../../../../widgets/upgrade_required_dialog.dart';
import '../../../../models/subscription_tier.dart';
import '../../../../services/chat_service.dart';
import '../../../../models/chat_message.dart';
import '../../../../services/app_service_manager.dart';

/// Community page for mesh networking, chat, and nearby users
class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final AppServiceManager _serviceManager = AppServiceManager();

  // Live data
  List<ChatUser> _nearbyUsers = [];
  List<ChatMessage> _messages = [];
  String? _communityChatId; // Selected/primary community chat id
  bool _chatReady = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initChatWiring();
  }

  String _statusToLabel(UserStatus status) {
    switch (status) {
      case UserStatus.available:
        return 'Available';
      case UserStatus.busy:
        return 'Busy';
      case UserStatus.away:
        return 'Away';
      case UserStatus.emergency:
        return 'Alert';
      case UserStatus.offline:
        return 'Offline';
    }
  }

  Color _statusToColor(UserStatus status) {
    switch (status) {
      case UserStatus.available:
        return AppTheme.safeGreen;
      case UserStatus.busy:
        return AppTheme.infoBlue;
      case UserStatus.away:
        return AppTheme.neutralGray;
      case UserStatus.emergency:
        return AppTheme.warningOrange;
      case UserStatus.offline:
        return AppTheme.disabledText;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _initChatWiring() async {
    // Initialize ChatService gracefully; fall back to static UI on failure
    try {
      if (!_chatService.isInitialized) {
        await _chatService.initialize();
      }

      // Pick a community chat room if available, else default demo id
      final rooms = _chatService.chatRooms;
      final communityRoom = rooms.firstWhere(
        (r) => r.type == ChatType.community,
        orElse: () => ChatRoom(
          id: 'COMMUNITY_001',
          name: 'Local Community',
          type: ChatType.community,
          participants: [],
          moderators: [],
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        ),
      );
      _communityChatId = communityRoom.id;

      // Seed initial lists
      _nearbyUsers = _chatService.nearbyUsers;
      _messages = _chatService.getMessagesForChat(_communityChatId!);

      // Set callbacks for live updates
      _chatService.setNearbyUsersUpdatedCallback((users) {
        if (!mounted) return;
        setState(() => _nearbyUsers = users);
      });
      _chatService.setMessageReceivedCallback((msg) {
        if (!mounted) return;
        if (msg.chatId == _communityChatId) {
          setState(
            () =>
                _messages = _chatService.getMessagesForChat(_communityChatId!),
          );
        }
      });

      setState(() => _chatReady = true);
    } catch (e) {
      debugPrint('CommunityPage: Chat wiring disabled (init failed): $e');
      setState(() => _chatReady = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final featureAccessService = FeatureAccessService.instance;

    // Essential users only get access to Chat tab
    final tabs = featureAccessService.hasFeatureAccess('communityFeatures')
        ? const [
            Tab(text: 'Nearby', icon: Icon(Icons.people, size: 18)),
            Tab(text: 'Chat', icon: Icon(Icons.chat, size: 18)),
            Tab(text: 'SAR', icon: Icon(Icons.search_outlined, size: 18)),
          ]
        : const [Tab(text: 'Chat', icon: Icon(Icons.chat, size: 18))];

    final tabViews = featureAccessService.hasFeatureAccess('communityFeatures')
        ? [_buildNearbyTab(), _buildChatTab(), _buildSARTab()]
        : [_buildChatTab()];

    // Update tab controller length based on access
    if (_tabController.length != tabs.length) {
      _tabController.dispose();
      _tabController = TabController(length: tabs.length, vsync: this);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          if (featureAccessService.hasFeatureAccess('communityFeatures'))
            IconButton(
              icon: const Icon(Icons.search, size: 20),
              onPressed: () {
                // Search nearby users - only for Pro+ users
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: tabs,
          isScrollable: true,
          indicatorWeight: 2,
          labelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
        ),
      ),
      body: TabBarView(controller: _tabController, children: tabViews),
    );
  }

  Widget _buildNearbyTab() {
    final featureAccessService = FeatureAccessService.instance;

    // Check if user has access to nearby features
    if (!featureAccessService.hasFeatureAccess('communityFeatures')) {
      return _buildUpgradeRequiredTab(
        'Nearby Users',
        'Connect with nearby RedPing users and view their status',
        'communityFeatures',
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mesh Network Status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.safeGreen.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wifi,
                      color: AppTheme.safeGreen,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mesh Network Active',
                          style: TextStyle(
                            color: AppTheme.primaryText,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _nearbyUsers.isNotEmpty
                              ? '${_nearbyUsers.length} nearby RedPing users detected'
                              : 'Discovering nearby users…',
                          style: const TextStyle(
                            color: AppTheme.secondaryText,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.safeGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text(
                      'CONNECTED',
                      style: TextStyle(
                        color: AppTheme.safeGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Nearby Users',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: _nearbyUsers.isEmpty
                ? Center(
                    child: Text(
                      'No nearby users yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondaryText,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _nearbyUsers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, i) {
                      final u = _nearbyUsers[i];
                      final statusStr = _statusToLabel(u.status);
                      final statusColor = _statusToColor(u.status);
                      final distanceStr = u.location?.address ?? 'Nearby';
                      return _buildUserCard(
                        name: u.name,
                        distance: distanceStr,
                        status: statusStr,
                        statusColor: statusColor,
                        avatar: (u.name.isNotEmpty ? u.name[0] : '?')
                            .toUpperCase(),
                        userId: u.id,
                        userStatus: u.status,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    final featureAccessService = FeatureAccessService.instance;

    return Column(
      children: [
        // Show upgrade banner for Essential users
        if (!featureAccessService.hasFeatureAccess('communityFeatures'))
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.warningOrange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.warningOrange.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.warningOrange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Essential Plan: Read-only access to community chat. Upgrade to Pro for full messaging and nearby user features.',
                    style: TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _showUpgradeDialog(
                    context,
                    'Community Features',
                    'Advanced community features require Pro tier or higher.',
                  ),
                  child: const Text(
                    'Upgrade',
                    style: TextStyle(
                      color: AppTheme.warningOrange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Chat header
        Container(
          padding: const EdgeInsets.all(12),
          color: AppTheme.darkSurface,
          child: Row(
            children: [
              const Icon(Icons.group, color: AppTheme.infoBlue, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Local Community Chat',
                  style: const TextStyle(
                    color: AppTheme.primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.infoBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _chatReady
                      ? '${(_messages.length).clamp(0, 99)} msgs'
                      : 'read-only',
                  style: const TextStyle(
                    color: AppTheme.infoBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Chat messages
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            reverse: true,
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages.reversed.elementAt(index);
              final isMe = _chatService.currentUser?.id == msg.senderId;
              return _buildChatMessage(
                sender: msg.senderName,
                message: msg.content,
                time: _formatTime(msg.timestamp),
                isMe: isMe,
              );
            },
          ),
        ),

        // Message input
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.darkSurface,
            border: Border(
              top: BorderSide(
                color: AppTheme.neutralGray.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: _buildMessageInput(),
        ),
      ],
    );
  }

  Widget _buildSARTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: AppTheme.warningOrange,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Search & Rescue Mode',
                        style: TextStyle(
                          color: AppTheme.primaryText,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Connect with local emergency responders and SAR teams. '
                    'Share your location and coordinate rescue efforts.',
                    style: TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _handleSARButtonClick(context),
                    icon: const Icon(Icons.emergency),
                    label: const Text('Activate SAR Mode'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.warningOrange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'Active SAR Operations',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: AppTheme.neutralGray.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Active Operations',
                    style: TextStyle(
                      color: AppTheme.secondaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'SAR operations will appear here when active',
                    style: TextStyle(
                      color: AppTheme.disabledText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard({
    required String name,
    required String distance,
    required String status,
    required Color statusColor,
    required String avatar,
    String? userId,
    UserStatus? userStatus,
  }) {
    final isEmergency = userStatus == UserStatus.emergency;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isEmergency ? Colors.red.shade50 : null,
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: isEmergency
                  ? AppTheme.primaryRed.withValues(alpha: 0.3)
                  : AppTheme.primaryRed.withValues(alpha: 0.2),
              child: Text(
                avatar,
                style: TextStyle(
                  color: isEmergency
                      ? AppTheme.primaryRed
                      : AppTheme.primaryRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isEmergency)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryRed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          name,
          style: TextStyle(
            color: isEmergency ? AppTheme.primaryRed : AppTheme.primaryText,
            fontWeight: isEmergency ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              distance,
              style: const TextStyle(
                color: AppTheme.secondaryText,
                fontSize: 12,
              ),
            ),
            if (isEmergency) ...[
              const SizedBox(width: 8),
              const Icon(Icons.emergency, color: AppTheme.primaryRed, size: 14),
              const SizedBox(width: 4),
              const Text(
                'EMERGENCY',
                style: TextStyle(
                  color: AppTheme.primaryRed,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (userId != null && userId.isNotEmpty)
              IconButton(
                icon: Icon(
                  Icons.video_call,
                  color: isEmergency ? AppTheme.primaryRed : Colors.blue,
                  size: 24,
                ),
                tooltip: 'Start WebRTC call',
                onPressed: () =>
                    _startCommunityWebRTCCall(userId, name, isEmergency),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        onTap: userId != null && userId.isNotEmpty
            ? () => _showUserActionsSheet(userId, name, isEmergency)
            : null,
      ),
    );
  }

  /// Start WebRTC call to community member
  Future<void> _startCommunityWebRTCCall(
    String userId,
    String userName,
    bool isEmergency,
  ) async {
    try {
      final webrtcService =
          _serviceManager.phoneAIIntegrationService.webrtcService;

      if (!webrtcService.isInitialized) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WebRTC service not initialized'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          title: Text('Starting WebRTC Call...'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Connecting to community member...'),
            ],
          ),
        ),
      );

      final currentUserName =
          _serviceManager.authService.currentUser.displayName;
      final message = isEmergency
          ? '''EMERGENCY RESPONSE from $currentUserName.

I see your emergency alert status in the community network.

Are you okay? Do you need assistance?

Please respond if you can hear me.'''
          : '''Hi, this is $currentUserName from the RedPing community.

I'm reaching out via WebRTC voice call.

Can you hear me? Please let me know if everything is okay.''';

      final channelName = await webrtcService.makeEmergencyCall(
        contactId: userId,
        emergencyMessage: message,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.video_call,
                color: isEmergency ? AppTheme.primaryRed : Colors.blue,
              ),
              const SizedBox(width: 12),
              const Text('Community Call Active'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '📞 ${isEmergency ? "Emergency " : ""}Call to $userName',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isEmergency ? AppTheme.primaryRed : Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Channel: $channelName',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (isEmergency ? Colors.red : Colors.blue).shade50,
                  border: Border.all(
                    color: (isEmergency ? Colors.red : Colors.blue).shade300,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEmergency
                          ? '🚨 Emergency Call'
                          : '✅ Voice call established',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isEmergency ? AppTheme.primaryRed : Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEmergency
                          ? 'You are responding to an emergency alert. The user may be in distress.'
                          : 'You can now speak directly with the community member.',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _serviceManager.phoneAIIntegrationService.endWebRTCCall();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Call ended')));
                }
              },
              child: const Text(
                'End Call',
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep Active'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start call: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show user action sheet
  Future<void> _showUserActionsSheet(
    String userId,
    String userName,
    bool isEmergency,
  ) async {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.video_call,
                  color: isEmergency ? AppTheme.primaryRed : Colors.blue,
                ),
                title: Text(
                  isEmergency ? 'Emergency WebRTC Call' : 'Start WebRTC Call',
                ),
                subtitle: Text(
                  isEmergency
                      ? 'Respond to emergency alert'
                      : 'Voice call via internet',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _startCommunityWebRTCCall(userId, userName, isEmergency);
                },
              ),
              ListTile(
                leading: const Icon(Icons.chat),
                title: const Text('Send Message'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Open direct message chat
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('View Profile'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Show user profile
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatMessage({
    required String sender,
    required String message,
    required String time,
    required bool isMe,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.infoBlue.withValues(alpha: 0.2),
              child: Text(
                sender[0],
                style: const TextStyle(
                  color: AppTheme.infoBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.primaryRed : AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe) ...[
                    Text(
                      sender,
                      style: TextStyle(
                        color: AppTheme.infoBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.primaryRed.withValues(alpha: 0.2),
              child: const Text(
                'Y',
                style: TextStyle(
                  color: AppTheme.primaryRed,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build message input with access control
  Widget _buildMessageInput() {
    final featureAccessService = FeatureAccessService.instance;

    // Essential users have limited messaging
    if (!featureAccessService.hasFeatureAccess('communityFeatures')) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              enabled: false,
              decoration: InputDecoration(
                hintText: 'Upgrade to send messages...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.darkBackground.withValues(alpha: 0.5),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.neutralGray,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => _showUpgradeDialog(
                context,
                'Community Messaging',
                'Send messages in community chat requires Pro tier or higher. Upgrade to communicate with nearby users and participate in group discussions.',
              ),
              icon: const Icon(Icons.lock, color: Colors.white, size: 20),
            ),
          ),
        ],
      );
    }

    // Pro+ users get full messaging
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _messageController,
            decoration: InputDecoration(
              hintText: 'Type a message...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: AppTheme.darkBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          decoration: const BoxDecoration(
            color: AppTheme.primaryRed,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: !_chatReady || _communityChatId == null
                ? null
                : () async {
                    final text = _messageController.text.trim();
                    if (text.isEmpty) return;
                    try {
                      await _chatService.sendMessage(
                        chatId: _communityChatId!,
                        content: text,
                      );
                      if (!mounted) return;
                      setState(() {
                        _messages = _chatService.getMessagesForChat(
                          _communityChatId!,
                        );
                        _messageController.clear();
                      });
                    } catch (e) {
                      debugPrint('CommunityPage: failed to send message: $e');
                    }
                  },
            icon: const Icon(Icons.send, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime ts) {
    final hour = ts.hour % 12 == 0 ? 12 : ts.hour % 12;
    final minute = ts.minute.toString().padLeft(2, '0');
    final ampm = ts.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  /// Build upgrade required tab for restricted features
  Widget _buildUpgradeRequiredTab(
    String featureName,
    String description,
    String featureKey,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.warningOrange.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.warningOrange.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    color: AppTheme.warningOrange,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '$featureName - Pro Required',
                  style: const TextStyle(
                    color: AppTheme.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.secondaryText,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () =>
                      _showUpgradeDialog(context, featureName, description),
                  icon: const Icon(Icons.upgrade),
                  label: const Text('Upgrade to Pro'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warningOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Show upgrade dialog for community features
  void _showUpgradeDialog(
    BuildContext context,
    String feature,
    String description,
  ) {
    showDialog(
      context: context,
      builder: (context) => const UpgradeRequiredDialog(
        featureName: 'Community Features',
        featureDescription:
            'Advanced community features require Pro tier or higher. Upgrade to access nearby users, group messaging, and enhanced community tools.',
        requiredTier: SubscriptionTier.pro,
      ),
    );
  }

  /// Handle SAR button click with access control
  void _handleSARButtonClick(BuildContext context) {
    final featureAccessService = FeatureAccessService.instance;

    // Check if user has SAR participation access
    if (featureAccessService.hasFeatureAccess('sarParticipation')) {
      // User has access, navigate to SAR page
      context.go(AppRouter.sar);
    } else {
      // User doesn't have access, show upgrade dialog
      showDialog(
        context: context,
        builder: (context) => const UpgradeRequiredDialog(
          featureName: 'SAR Participation',
          featureDescription:
              'Access to Search & Rescue operations requires Pro tier or higher. Upgrade to participate in emergency response and volunteer rescue missions.',
          requiredTier: SubscriptionTier.pro,
        ),
      );
    }
  }
}
