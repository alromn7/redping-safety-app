import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/redping_ai_service.dart';
import '../config/env.dart';

/// RedPing AI Screen - Interactive interface for the AI safety companion
class RedPingAIScreen extends StatefulWidget {
  const RedPingAIScreen({super.key});

  @override
  State<RedPingAIScreen> createState() => _RedPingAIScreenState();
}

class _RedPingAIScreenState extends State<RedPingAIScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  final RedPingAI _redPingAI = RedPingAI();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _conversationHistory = [];
  bool _isListening = false;
  final bool _isSpeaking = false;
  String _currentStatus = 'Initializing...';
  Map<String, dynamic> _aiStatus = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeRedPingAI();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeRedPingAI() async {
    try {
      // Gate legacy screen to avoid duplication with Safety Assistant
      if (!Env.flag<bool>('enableLegacyRedPingAIScreen', false)) {
        setState(() {
          _currentStatus = 'RedPing AI screen is disabled by configuration';
        });
        return;
      }
      setState(() {
        _currentStatus = 'Initializing RedPing AI...';
      });

      // Initialize RedPing AI
      await _redPingAI.initialize();

      // Set up callbacks
      _redPingAI.setOnSafetyAlert((type, data) {
        _showSafetyAlert(type, data);
      });

      _redPingAI.setOnEmergencyDetected((type, data) {
        _showEmergencyAlert(type, data);
      });

      _redPingAI.setOnError((error) {
        _showErrorAlert(error);
      });

      _redPingAI.setOnConversation((response) {
        _addAIMessage(response);
      });

      // Start safety monitoring
      _redPingAI.startSafetyMonitoring();

      setState(() {
        _currentStatus = 'RedPing AI is ready! 🚗✨';
        _aiStatus = _redPingAI.getStatus();
      });

      // Suppress welcome message to avoid overlap with Safety Assistant
    } catch (e) {
      setState(() {
        _currentStatus = 'Failed to initialize: $e';
      });
      _showErrorAlert('Failed to initialize RedPing AI: $e');
    }
  }

  void _addUserMessage(String message) {
    setState(() {
      _conversationHistory.add({
        'type': 'user',
        'message': message,
        'timestamp': DateTime.now(),
      });
    });
    _scrollToBottom();
  }

  void _addAIMessage(String message) {
    setState(() {
      _conversationHistory.add({
        'type': 'ai',
        'message': message,
        'timestamp': DateTime.now(),
      });
    });
    _scrollToBottom();
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

  void _showSafetyAlert(String type, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🛡️ Safety Alert'),
        content: Text(
          'RedPing AI detected: $type\n${data['message'] ?? 'Safety concern detected'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showEmergencyAlert(String type, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚨 Emergency Alert'),
        content: Text(
          'RedPing AI detected emergency: $type\n${data['message'] ?? 'Emergency situation detected'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorAlert(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('❌ Error'),
        content: Text('RedPing AI error: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _addUserMessage(message);
    _messageController.clear();

    // Send to RedPing AI
    await _redPingAI.handleUserInput(message);
  }

  Future<void> _startListening() async {
    setState(() {
      _isListening = true;
    });

    // Simulate listening (in real implementation, this would use speech recognition)
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isListening = false;
    });

    // Simulate speech recognition result
    _addUserMessage("I'm feeling a bit tired while driving");
    await _redPingAI.handleUserInput("I'm feeling a bit tired while driving");
  }

  Future<void> _shareDrivingTechniques() async {
    _addAIMessage(
      "Let me share some driving techniques from the RedPing creator's experience in Western Australia! 🚗",
    );

    // Simulate sharing techniques
    await Future.delayed(const Duration(seconds: 2));
    _addAIMessage(
      "Here's the breath holding technique: Take a deep breath, hold for 10-15 seconds, release slowly, and repeat 2-3 times. This sends a distress signal to your brain and wakes up all your body parts! 💪",
    );

    await Future.delayed(const Duration(seconds: 2));
    _addAIMessage(
      "This technique is better than energy drinks or coffee, and it's good exercise for your heart and lungs! Your family is counting on you to get home safely! 🏠",
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _redPingAI.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('RedPing AI'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.primaryText,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAIStatus(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Icon(
                        Icons.smart_toy,
                        color: AppTheme.accentBlue,
                        size: 24,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _currentStatus,
                    style: TextStyle(
                      color: AppTheme.primaryText,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_isListening)
                  AnimatedBuilder(
                    animation: _waveAnimation,
                    builder: (context, child) {
                      return Icon(
                        Icons.mic,
                        color: AppTheme.accentYellow,
                        size: 24,
                      );
                    },
                  ),
                if (_isSpeaking)
                  AnimatedBuilder(
                    animation: _waveAnimation,
                    builder: (context, child) {
                      return Icon(
                        Icons.volume_up,
                        color: AppTheme.accentGreen,
                        size: 24,
                      );
                    },
                  ),
              ],
            ),
          ),

          // Conversation history
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _conversationHistory.length,
              itemBuilder: (context, index) {
                final message = _conversationHistory[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              border: Border(top: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Column(
              children: [
                // Quick action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickActionButton(
                      icon: Icons.mic,
                      label: 'Listen',
                      onPressed: _isListening ? null : _startListening,
                      color: AppTheme.accentBlue,
                    ),
                    _buildQuickActionButton(
                      icon: Icons.drive_eta,
                      label: 'Techniques',
                      onPressed: _shareDrivingTechniques,
                      color: AppTheme.accentGreen,
                    ),
                    _buildQuickActionButton(
                      icon: Icons.help_outline,
                      label: 'Help',
                      onPressed: () => _showHelpDialog(),
                      color: AppTheme.accentYellow,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Text input
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message to RedPing AI...',
                          hintStyle: TextStyle(color: AppTheme.secondaryText),
                          filled: true,
                          fillColor: AppTheme.inputBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: AppTheme.borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: AppTheme.borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide(color: AppTheme.accentBlue),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        style: TextStyle(color: AppTheme.primaryText),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton(
                      onPressed: _sendMessage,
                      backgroundColor: AppTheme.accentBlue,
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['type'] == 'user';
    final timestamp = message['timestamp'] as DateTime;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.accentBlue,
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.accentBlue : AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isUser ? AppTheme.accentBlue : AppTheme.borderColor,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['message'],
                    style: TextStyle(
                      color: isUser ? Colors.white : AppTheme.primaryText,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: isUser ? Colors.white70 : AppTheme.secondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.accentGreen,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          onPressed: onPressed,
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: AppTheme.primaryText, fontSize: 12),
        ),
      ],
    );
  }

  void _showAIStatus() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('RedPing AI Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Initialized: ${_aiStatus['isInitialized']}'),
            Text('Active: ${_aiStatus['isActive']}'),
            Text('Monitoring: ${_aiStatus['isMonitoring']}'),
            Text('Personality: ${_aiStatus['personality']}'),
            Text('Current Mood: ${_aiStatus['currentMood']}'),
            Text('User Mode: ${_aiStatus['userMode']}'),
            Text('Interactions: ${_aiStatus['interactionCount']}'),
            Text('Conversations: ${_aiStatus['conversationHistory']}'),
            Text('Safety Events: ${_aiStatus['safetyEvents']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('RedPing AI Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('RedPing AI is your personal safety companion! 🚗✨'),
              SizedBox(height: 16),
              Text('Features:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('• Safety monitoring and alerts'),
              Text('• Drowsiness detection and prevention'),
              Text('• Emergency response and SOS activation'),
              Text('• Driving techniques from RedPing creator'),
              Text('• Human-like conversation and support'),
              SizedBox(height: 16),
              Text(
                'Quick Actions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Listen: Voice input'),
              Text('• Techniques: Share driving tips'),
              Text('• Help: Show this help dialog'),
              SizedBox(height: 16),
              Text('Mission: Bring you home safely to your family! 🏠💪'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
