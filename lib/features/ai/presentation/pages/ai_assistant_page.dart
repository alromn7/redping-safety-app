import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/app_service_manager.dart';
import '../../../../services/phone_ai_integration_service.dart';
import '../../../../models/ai_assistant.dart';
import '../widgets/ai_message_widget.dart';
import '../widgets/ai_suggestions_widget.dart';
import '../widgets/ai_permissions_widget.dart';

/// AI Assistant main interface page
class AIAssistantPage extends StatefulWidget {
  const AIAssistantPage({super.key});

  @override
  State<AIAssistantPage> createState() => _AIAssistantPageState();
}

class _AIAssistantPageState extends State<AIAssistantPage>
    with TickerProviderStateMixin {
  final AppServiceManager _serviceManager = AppServiceManager();
  final PhoneAIIntegrationService _phoneAI = PhoneAIIntegrationService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<AIMessage> _messages = [];
  List<AISuggestion> _suggestions = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  // Voice integration state (removed unused _voiceEnabled flag)
  bool _isListening = false;
  // UI state
  bool _showQuickCommands =
      false; // collapsed by default to reduce vertical space
  bool _showSuggestions = false; // collapsed by default to save space

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeAI();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  Future<void> _initializeAI() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Add timeout to prevent freezing
      await _serviceManager.aiAssistantService.initialize().timeout(
        Duration(seconds: 10),
        onTimeout: () {
          debugPrint('AIAssistantPage: Initialization timeout');
          throw Exception('AI initialization timeout');
        },
      );

      // Set up callbacks only if still mounted
      if (mounted) {
        debugPrint('AIAssistantPage: Setting up message callbacks');
        _serviceManager.aiAssistantService.setMessageReceivedCallback(
          _onMessageReceived,
        );
        _serviceManager.aiAssistantService.setSuggestionGeneratedCallback(
          _onSuggestionReceived,
        );

        // Load conversation history (create modifiable copy)
        _messages = List<AIMessage>.from(
          _serviceManager.aiAssistantService.conversationHistory,
        );

        // Generate initial suggestions with timeout
        try {
          _suggestions = await _serviceManager.aiAssistantService
              .generateSmartSuggestions()
              .timeout(
                Duration(seconds: 5),
                onTimeout: () {
                  debugPrint(
                    'AIAssistantPage: Suggestions timeout, using defaults',
                  );
                  return <AISuggestion>[];
                },
              );
        } catch (e) {
          debugPrint('AIAssistantPage: Error loading suggestions - $e');
          _suggestions = <AISuggestion>[];
        }

        // Voice layer initialization & callbacks
        _phoneAI.setOnListeningStateChanged((listening) {
          if (!mounted) return;
          setState(() => _isListening = listening);
        });
        // Live recognition preview is hidden; skip setting recognition/command callbacks
        await _phoneAI.initialize();
      }
    } catch (e) {
      debugPrint('AIAssistantPage: Error initializing - $e');
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'AI Assistant initialization failed: ${e.toString()}',
            ),
            backgroundColor: AppTheme.primaryRed,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onMessageReceived(AIMessage message) {
    debugPrint(
      'AIAssistantPage: _onMessageReceived called with: ${message.content}',
    );
    if (!mounted) return;
    setState(() {
      _messages.add(message);
    });
    debugPrint(
      'AIAssistantPage: Message added, total messages: ${_messages.length}',
    );
    _scrollToBottom();

    // Speak AI responses if they're not too long
    if (message.type == AIMessageType.aiResponse &&
        message.content.length < 200) {
      _serviceManager.aiAssistantService.speakResponse(message.content);
    }
  }

  void _onSuggestionReceived(AISuggestion suggestion) {
    if (!mounted) return;
    setState(() {
      _suggestions.add(suggestion);
      // Keep only recent suggestions
      _suggestions.sort((a, b) => b.validUntil.compareTo(a.validUntil));
      if (_suggestions.length > 10) {
        _suggestions = _suggestions.take(10).toList();
      }
    });
  }

  void _scrollToBottom() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        try {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } catch (e) {
          debugPrint('AIAssistantPage: Scroll error - $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _phoneAI.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('AI Safety Assistant'),
        backgroundColor: AppTheme.infoBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.go('/main');
            }
          },
          tooltip: 'Back',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showAISettings,
            tooltip: 'AI Settings',
          ),
          IconButton(
            icon: const Icon(Icons.security),
            onPressed: _showPermissions,
            tooltip: 'AI Permissions',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // AI Status Bar (flexible height to prevent overflow)
            _buildAIStatusBar(),

            // Inline AI Safety Assistant toggle for quick access
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Card(
                child: Builder(
                  builder: (context) {
                    final enabled =
                        _serviceManager.isAISafetyAssistantUserEnabled;
                    final active = _serviceManager.isAISafetyAssistantActive;
                    return SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      title: const Text('AI Safety Assistant'),
                      subtitle: Text(
                        active
                            ? 'Active (manual or auto at >60 km/h)'
                            : 'Inactive (auto turns on above 60 km/h)',
                      ),
                      secondary: const Icon(
                        Icons.shield,
                        color: AppTheme.infoBlue,
                      ),
                      value: enabled,
                      onChanged: (v) async {
                        await _serviceManager.setAISafetyAssistantUserEnabled(
                          v,
                        );
                        if (mounted) setState(() {});
                      },
                      activeThumbColor: AppTheme.infoBlue,
                    );
                  },
                ),
              ),
            ),

            // Live recognized speech preview (hidden by default for a cleaner UI)
            // Intentionally removed to avoid clutter and reduce overflow risk.

            // Suggestions (collapsible)
            if (_suggestions.isNotEmpty && !keyboardOpen) ...[
              _buildSuggestionsToggle(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _showSuggestions
                    ? Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.2,
                        ),
                        child: AISuggestionsWidget(
                          suggestions: _suggestions,
                          onSuggestionTap: _executeSuggestion,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],

            // Messages (scrollable)
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isProcessing ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isProcessing && index == _messages.length) {
                    return _buildTypingIndicator();
                  }
                  return AIMessageWidget(
                    message: _messages[index],
                    onSuggestionTap: _executeSuggestion,
                  );
                },
              ),
            ),

            // Input area (fixed at bottom)
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          SizedBox(width: 6),
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text(
            'Assistant is typing…',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAIStatusBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.infoBlue.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: AppTheme.infoBlue.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side: Icon and status
              Expanded(
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isListening ? _pulseAnimation.value : 1.0,
                          child: Icon(
                            _isListening ? Icons.mic : Icons.psychology,
                            color: _isListening
                                ? AppTheme.primaryRed
                                : AppTheme.infoBlue,
                            size: 18,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isProcessing
                            ? 'Processing…'
                            : _isListening
                            ? 'Listening…'
                            : 'AI Ready',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryText,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Right side: Performance indicator only (text-based chat)
              if (_serviceManager.aiAssistantService.lastPerformanceData !=
                  null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _buildPerformanceIndicator(),
                ),
            ],
          ),
          if (_isProcessing)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: SizedBox(
                height: 2,
                child: LinearProgressIndicator(
                  color: AppTheme.infoBlue,
                  backgroundColor: AppTheme.infoBlue.withValues(alpha: 0.15),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicator() {
    final data = _serviceManager.aiAssistantService.lastPerformanceData!;
    final batteryColor = data.batteryLevel > 50
        ? AppTheme.safeGreen
        : data.batteryLevel > 20
        ? AppTheme.warningOrange
        : AppTheme.criticalRed;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.battery_std, color: batteryColor, size: 16),
        const SizedBox(width: 2),
        Text(
          '${data.batteryLevel.toStringAsFixed(0)}%',
          style: TextStyle(fontSize: 11, color: batteryColor),
        ),
        const SizedBox(width: 6),
        Icon(
          data.isLocationActive ? Icons.location_on : Icons.location_off,
          color: data.isLocationActive
              ? AppTheme.safeGreen
              : AppTheme.neutralGray,
          size: 16,
        ),
      ],
    );
  }

  Widget _buildInputArea() {
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.3,
        ),
        child: Container(
          // Avoid adding viewInsets again; SafeArea already accounts for keyboard
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: Colors.black87,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 6,
                offset: const Offset(0, -2),
              ),
            ],
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quick Commands (collapsed by default to reduce vertical size)
              _buildQuickCommandsToggle(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _showQuickCommands
                    ? _buildQuickCommands()
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 12),

              // Text input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Ask me anything about your safety...',
                        hintStyle: const TextStyle(color: Colors.white60),
                        filled: true,
                        fillColor: Colors.black54,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.24),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.24),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: AppTheme.infoBlue,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: _sendTextMessage,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _isProcessing
                        ? null
                        : () => _sendTextMessage(_messageController.text),
                    backgroundColor: AppTheme.infoBlue,
                    foregroundColor: Colors.white,
                    mini: true,
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsToggle() {
    return InkWell(
      onTap: () => setState(() => _showSuggestions = !_showSuggestions),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: Row(
          children: [
            Icon(
              _showSuggestions ? Icons.expand_less : Icons.expand_more,
              color: AppTheme.warningOrange,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              _showSuggestions
                  ? 'Hide suggestions'
                  : 'Smart suggestions (${_suggestions.length})',
              style: const TextStyle(
                color: AppTheme.warningOrange,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCommandsToggle() {
    return InkWell(
      onTap: () => setState(() => _showQuickCommands = !_showQuickCommands),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Icon(
            _showQuickCommands ? Icons.expand_less : Icons.expand_more,
            color: AppTheme.infoBlue,
          ),
          const SizedBox(width: 6),
          Text(
            _showQuickCommands ? 'Hide quick commands' : 'Show quick commands',
            style: const TextStyle(
              color: AppTheme.infoBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendTextMessage(String message) async {
    if (message.trim().isEmpty || _isProcessing) return;

    setState(() => _isProcessing = true);

    // Add user message
    final userMessage = AIMessage(
      id: _generateId(),
      content: message.trim(),
      type: AIMessageType.userInput,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Process command with timeout
      debugPrint('AIAssistantPage: Processing command: $message');
      await _serviceManager.aiAssistantService
          .processCommand(message)
          .timeout(
            Duration(seconds: 15),
            onTimeout: () {
              debugPrint('AIAssistantPage: Message processing timeout');
              _showError('Request timed out. Please try again.');
              throw Exception('Processing timeout');
            },
          );
      // Response is automatically added via callback (_onMessageReceived)
      debugPrint('AIAssistantPage: Command processed successfully');
    } catch (e) {
      debugPrint('AIAssistantPage: Error processing message - $e');
      _showError('Failed to process your request: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Widget _buildQuickCommands() {
    final quickCommands = _serviceManager.aiAssistantService.getQuickCommands();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.25,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: SingleChildScrollView(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: quickCommands.map((command) {
              return ActionChip(
                label: Text(
                  command,
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
                onPressed: () => _sendTextMessage(command),
                backgroundColor: Colors.white.withValues(alpha: 0.06),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _executeSuggestion(AISuggestion suggestion) {
    // Convert suggestion to command
    final command =
        'Execute ${suggestion.actionType.name} with ${suggestion.actionParameters}';
    _sendTextMessage(command);
  }

  void _showAISettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.neutralGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.psychology, color: AppTheme.infoBlue, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'AI Assistant Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryText,
                    ),
                  ),
                ],
              ),
            ),

            // Settings content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // AI Safety Assistant monitoring toggle (moved from SAR Dashboard)
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Builder(
                      builder: (context) {
                        final enabled =
                            _serviceManager.isAISafetyAssistantUserEnabled;
                        final active =
                            _serviceManager.isAISafetyAssistantActive;
                        return SwitchListTile(
                          title: const Text('AI Safety Assistant'),
                          subtitle: Text(
                            active
                                ? 'Active (manual or auto at >60 km/h)'
                                : 'Inactive (auto turns on above 60 km/h)',
                          ),
                          secondary: const Icon(
                            Icons.shield,
                            color: AppTheme.infoBlue,
                          ),
                          value: enabled,
                          onChanged: (v) async {
                            await _serviceManager
                                .setAISafetyAssistantUserEnabled(v);
                            if (mounted) setState(() {});
                          },
                          activeThumbColor: AppTheme.infoBlue,
                        );
                      },
                    ),
                  ),

                  _buildSettingCard(
                    'Voice Recognition',
                    'Enable voice commands and responses',
                    Icons.mic,
                    true,
                    (value) => _updateVoiceSetting(value),
                  ),

                  _buildSettingCard(
                    'Smart Suggestions',
                    'Get proactive safety and performance suggestions',
                    Icons.lightbulb,
                    true,
                    (value) => _updateSuggestionsSetting(value),
                  ),

                  _buildSettingCard(
                    'Performance Monitoring',
                    'Monitor and optimize app performance automatically',
                    Icons.speed,
                    true,
                    (value) => _updatePerformanceMonitoring(value),
                  ),

                  _buildSettingCard(
                    'Safety Assessments',
                    'Regular safety status checks and recommendations',
                    Icons.security,
                    true,
                    (value) => _updateSafetyAssessments(value),
                  ),

                  const SizedBox(height: 16),

                  // Learning data
                  _buildLearningDataCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        secondary: Icon(icon, color: AppTheme.infoBlue),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.infoBlue,
      ),
    );
  }

  Widget _buildLearningDataCard() {
    final learningData = _serviceManager.aiAssistantService.learningData;
    if (learningData == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.psychology, color: AppTheme.infoBlue, size: 20),
                SizedBox(width: 8),
                Text(
                  'AI Learning Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              'Commands learned: ${learningData.commandFrequency.length}',
              style: const TextStyle(color: AppTheme.secondaryText),
            ),

            Text(
              'Success rate: ${_calculateOverallSuccessRate(learningData).toStringAsFixed(1)}%',
              style: const TextStyle(color: AppTheme.secondaryText),
            ),

            if (learningData.preferredFeatures.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Preferred features:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              Wrap(
                spacing: 4,
                children: learningData.preferredFeatures
                    .take(3)
                    .map(
                      (feature) => Chip(
                        label: Text(
                          feature,
                          style: const TextStyle(fontSize: 10),
                        ),
                        backgroundColor: AppTheme.infoBlue.withValues(
                          alpha: 0.1,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPermissions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        'AI Permissions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // Permissions widget
                Expanded(
                  child: AIPermissionsWidget(
                    permissions: _serviceManager.aiAssistantService.permissions,
                    onPermissionsChanged: (permissions) {
                      _serviceManager.aiAssistantService.updatePermissions(
                        permissions,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Permissions updated'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _updateVoiceSetting(bool value) {
    // TODO: Update voice recognition setting
    debugPrint('Voice recognition: $value');
  }

  void _updateSuggestionsSetting(bool value) {
    // TODO: Update smart suggestions setting
    debugPrint('Smart suggestions: $value');
  }

  void _updatePerformanceMonitoring(bool value) {
    // TODO: Update performance monitoring setting
    debugPrint('Performance monitoring: $value');
  }

  void _updateSafetyAssessments(bool value) {
    // TODO: Update safety assessments setting
    debugPrint('Safety assessments: $value');
  }

  double _calculateOverallSuccessRate(AILearningData data) {
    if (data.commandSuccessRate.isEmpty) return 100.0;

    final rates = data.commandSuccessRate.values;
    return (rates.reduce((a, b) => a + b) / rates.length) * 100;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.criticalRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _generateId() {
    return 'ui_${DateTime.now().millisecondsSinceEpoch}';
  }
}

/// AI Permissions management page
class AIPermissionsPage extends StatefulWidget {
  const AIPermissionsPage({super.key});

  @override
  State<AIPermissionsPage> createState() => _AIPermissionsPageState();
}

class _AIPermissionsPageState extends State<AIPermissionsPage> {
  final AppServiceManager _serviceManager = AppServiceManager();
  late AIPermissions _permissions;

  @override
  void initState() {
    super.initState();
    _permissions = _serviceManager.aiAssistantService.permissions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Permissions'),
        backgroundColor: AppTheme.infoBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
      ),
      body: AIPermissionsWidget(
        permissions: _permissions,
        onPermissionsChanged: _updatePermissions,
      ),
    );
  }

  void _updatePermissions(AIPermissions newPermissions) {
    setState(() {
      _permissions = newPermissions;
    });

    _serviceManager.aiAssistantService.updatePermissions(newPermissions);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AI permissions updated'),
        backgroundColor: AppTheme.safeGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
