import 'package:flutter/material.dart';
import '../../../../services/chat_service.dart';
import '../../../../services/sar_identity_service.dart';
import '../../../../services/user_profile_service.dart';
import '../../../../models/chat_message.dart';
import '../../../../core/theme/app_theme.dart';

/// Test widget to demonstrate cross messaging policies
class CrossMessagingTestWidget extends StatefulWidget {
  const CrossMessagingTestWidget({super.key});

  @override
  State<CrossMessagingTestWidget> createState() =>
      _CrossMessagingTestWidgetState();
}

class _CrossMessagingTestWidgetState extends State<CrossMessagingTestWidget> {
  final ChatService _chatService = ChatService();
  final SARIdentityService _sarIdentityService = SARIdentityService();
  final UserProfileService _userProfileService = UserProfileService();
  final TextEditingController _messageController = TextEditingController();

  String _currentUserType = 'Loading...';
  String _testResults = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _userProfileService.initialize();
      await _sarIdentityService.initialize();
      await _chatService.initialize();

      _updateUserTypeDisplay();
    } catch (e) {
      setState(() {
        _testResults = 'Error initializing services: $e';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _updateUserTypeDisplay() {
    final currentUser = _chatService.currentUser;
    if (currentUser == null) {
      setState(() {
        _currentUserType = 'No User';
      });
      return;
    }

    final isSAR = _sarIdentityService.isVerifiedSARMember(currentUser.id);
    setState(() {
      _currentUserType = isSAR ? 'SAR Member' : 'Civilian';
    });
  }

  Future<void> _testDirectMessaging() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Testing direct messaging policies...\n';
    });

    try {
      // Create a test direct chat room with mixed user types
      final testChatRoom = await _chatService.createChatRoom(
        name: 'Test Direct Chat',
        type: ChatType.direct,
        participants: [
          _chatService.currentUser?.id ?? 'current_user',
          'test_sar_member_1',
          'test_civilian_1',
        ],
      );

      // Try to send a message
      await _chatService.sendMessage(
        chatId: testChatRoom.id,
        content: _messageController.text.isNotEmpty
            ? _messageController.text
            : 'Test cross-messaging policy',
        type: MessageType.text,
        priority: MessagePriority.normal,
      );

      setState(() {
        _testResults += 'SUCCESS: Message sent (policy allowed)\n';
      });
    } catch (e) {
      setState(() {
        _testResults += 'BLOCKED: $e\n';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testEmergencyMessaging() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Testing emergency messaging policies...\n';
    });

    try {
      // Try to send emergency message to community channel
      final communityRoom = _chatService.chatRooms
          .where((room) => room.type == ChatType.community)
          .firstOrNull;

      if (communityRoom != null) {
        await _chatService.sendMessage(
          chatId: communityRoom.id,
          content: 'EMERGENCY: Test emergency message',
          type: MessageType.emergency,
          priority: MessagePriority.emergency,
        );

        setState(() {
          _testResults += 'SUCCESS: Emergency message sent\n';
        });
      } else {
        setState(() {
          _testResults += 'ERROR: No community room found\n';
        });
      }
    } catch (e) {
      setState(() {
        _testResults += 'BLOCKED: $e\n';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testSARTeamAccess() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Testing SAR team access...\n';
    });

    try {
      // Try to create SAR team chat room
      final sarRoom = await _chatService.createChatRoom(
        name: 'Test SAR Team',
        type: ChatType.sarTeam,
        participants: [_chatService.currentUser?.id ?? 'current_user'],
      );

      await _chatService.sendMessage(
        chatId: sarRoom.id,
        content: 'SAR team coordination message',
        type: MessageType.text,
        priority: MessagePriority.normal,
      );

      setState(() {
        _testResults += 'SUCCESS: SAR team access granted\n';
      });
    } catch (e) {
      setState(() {
        _testResults += 'BLOCKED: $e\n';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _toggleUserType() async {
    setState(() {
      _isLoading = true;
      _testResults =
          'Note: User type toggling requires complex SAR registration.\n'
          'For testing, you can:\n'
          '1. Use different test users with pre-configured types\n'
          '2. Check the debug logs to see policy validation in action\n'
          '3. Test with the existing demo SAR members in the system\n';
    });

    // For demo purposes, just show the current status
    final currentUser = _chatService.currentUser;
    if (currentUser != null) {
      try {
        final isSAR = _sarIdentityService.isVerifiedSARMember(currentUser.id);
        setState(() {
          _testResults +=
              '\nCurrent user ${currentUser.id} is ${isSAR ? 'SAR member' : 'civilian'}\n';
        });
      } catch (e) {
        setState(() {
          _testResults += 'Error checking user type: $e\n';
        });
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cross Messaging Test'),
        backgroundColor: AppTheme.primaryRed,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Type Display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current User Type: $_currentUserType',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _toggleUserType,
                      child: const Text('Toggle User Type (Test)'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Message Input
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Test Message',
                hintText: 'Enter a test message...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // Test Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _testDirectMessaging,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warningOrange,
                  ),
                  child: const Text('Test Direct Messaging'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testEmergencyMessaging,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryRed,
                  ),
                  child: const Text('Test Emergency Message'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testSARTeamAccess,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successGreen,
                  ),
                  child: const Text('Test SAR Team Access'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Results Display
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Test Results:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _testResults.isEmpty
                                ? 'Click a test button to see results...'
                                : _testResults,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
