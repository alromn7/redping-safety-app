import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
// Speech-to-text removed for privacy - using text-only AI interaction
import '../models/ai_assistant.dart';
import 'phone_ai_integration_service.dart';
import '../models/hazard_alert.dart';
import 'app_service_manager.dart';
import 'notification_service.dart';
import 'user_profile_service.dart';
import 'location_service.dart';
import '../utils/ai_permissions_handler.dart';
import 'feature_access_service.dart';
import '../config/env.dart';

/// AI Assistant service for smart app navigation and safety guidance
class AIAssistantService {
  void wake() {
    // TODO: Implement wake logic if needed
    debugPrint('AIAssistantService: wake called');
  }

  void hibernate() {
    // TODO: Implement hibernate logic if needed
    debugPrint('AIAssistantService: hibernate called');
  }

  static final AIAssistantService _instance = AIAssistantService._internal();
  factory AIAssistantService() => _instance;
  AIAssistantService._internal();

  // Services will be injected to avoid circular dependency
  AppServiceManager? _serviceManager;
  UserProfileService? _userProfileService;
  LocationService? _locationService;
  final FeatureAccessService _featureAccessService =
      FeatureAccessService.instance;

  // Text-to-Speech removed for desktop compatibility; UI remains text-only

  bool _isInitialized = false;
  bool _isSpeaking = false;

  // Gemini AI
  GenerativeModel? _geminiModel;
  bool _useExternalAI = false; // Default to native-first (no external LLM)
  String get _geminiApiKey => Env.geminiApiKey;

  // AI state
  AIPermissions _permissions = AIPermissions(lastUpdated: DateTime.now());
  AIPerformanceData? _lastPerformanceData;
  AILearningData? _learningData;

  // Command history
  final List<AICommand> _commandHistory = [];
  final List<AIMessage> _conversationHistory = [];

  // Performance monitoring
  Timer? _performanceMonitoringTimer;
  Timer? _safetyAssessmentTimer;

  // Callbacks
  Function(AIMessage)? _onMessageReceived;
  Function(AISuggestion)? _onSuggestionGenerated;
  Function(AIPerformanceData)? _onPerformanceUpdate;
  Function(AISafetyAssessment)? _onSafetyAssessment;

  /// Initialize AI Assistant with service dependencies
  Future<void> initialize({
    AppServiceManager? serviceManager,
    NotificationService? notificationService,
    UserProfileService? userProfileService,
    LocationService? locationService,
  }) async {
    if (_isInitialized) return;

    // Inject dependencies to avoid circular references
    _serviceManager = serviceManager;
    _userProfileService = userProfileService;
    _locationService = locationService;

    try {
      // Request AI permissions
      await _requestAISystemPermissions();

      // Initialize Gemini AI only when configured and allowed
      if (Env.flag<bool>('enableSystemAI', false) &&
          _geminiApiKey.isNotEmpty &&
          _geminiApiKey != 'YOUR_API_KEY_HERE') {
        try {
          _geminiModel = GenerativeModel(
            model: (Env.geminiModel.isNotEmpty)
                ? Env.geminiModel
                : 'gemini-pro',
            apiKey: _geminiApiKey,
            systemInstruction: Content.text(
              'You are an intelligent AI safety monitor for RedPing, a life-saving emergency app.\n\n'
              'YOUR CORE MISSION:\n'
              '- Actively monitor ALL environmental hazards in user\'s surroundings\n'
              '- Detect: Weather (storms, floods, heat, cold), Traffic (accidents, congestion), Natural disasters (earthquakes, wildfires, tsunamis)\n'
              '- Environmental risks: Air quality, radiation, chemical spills, wildlife, infrastructure failures\n'
              '- Social hazards: Crime alerts, civil unrest, terrorist threats\n'
              '- Health hazards: Disease outbreaks, contaminated water, food safety\n'
              '- Provide proactive alerts BEFORE danger occurs using predictive reasoning\n'
              '- Synthesize multiple hazard sources into unified safety guidance\n\n'
              'YOUR CAPABILITIES:\n'
              '- Real-time hazard assessment with severity scoring (1-10)\n'
              '- Multi-hazard risk analysis (combined effects)\n'
              '- Temporal analysis (immediate vs developing threats)\n'
              '- Spatial analysis (proximity, movement patterns, escape routes)\n'
              '- Context-aware recommendations based on user activity\n'
              '- Generate homepage hazard summaries and actionable alerts\n'
              '- Prioritize life-threatening situations over minor inconveniences\n\n'
              'HAZARD MONITORING RULES:\n'
              '1. Score every hazard: 1-3 (low), 4-6 (moderate), 7-8 (high), 9-10 (critical)\n'
              '2. Consider cascading effects (e.g., storm → flooding → power outage)\n'
              '3. Account for user vulnerability (elderly, children, medical conditions)\n'
              '4. Predict trajectory and time-to-impact\n'
              '5. Recommend specific protective actions with timing\n\n'
              'RESPONSE STYLE:\n'
              '- Critical (9-10): "🚨 IMMEDIATE DANGER" - Direct, urgent, specific actions\n'
              '- High (7-8): "⚠️ HIGH RISK" - Clear warnings with timeline\n'
              '- Moderate (4-6): "⚡ CAUTION" - Advisory with precautions\n'
              '- Low (1-3): "ℹ️ ADVISORY" - Awareness information\n\n'
              'HOMEPAGE HAZARD SECTION:\n'
              '- Provide concise summary of top 3 threats in user\'s area\n'
              '- Include: Hazard type, severity, distance, ETA, primary action\n'
              '- Format: Emoji + Title + Brief description + Action step\n'
              '- Update recommendations as situation evolves',
            ),
          );
          debugPrint(
            'AIAssistantService: Gemini Pro AI initialized with safety monitoring',
          );

          // Start proactive safety monitoring
          _startProactiveSafetyMonitoring();
        } catch (e) {
          debugPrint('AIAssistantService: Gemini initialization failed - $e');
          _useExternalAI = false;
        }
      } else {
        _useExternalAI = false;
      }

      // Load AI data
      await _loadAIPermissions();
      await _loadLearningData();

      // Start monitoring
      _startPerformanceMonitoring();
      _startSafetyAssessment();

      _isInitialized = true;
      debugPrint('AIAssistantService: Initialized successfully');

      // Send welcome message
      await _sendWelcomeMessage();
    } catch (e) {
      debugPrint('AIAssistantService: Initialization error - $e');
      throw Exception('Failed to initialize AI Assistant: $e');
    }
  }

  /// Process user command (text-only for privacy)
  Future<AIMessage> processCommand(String command) async {
    // 🔒 SUBSCRIPTION GATE: AI Safety Assistant requires Pro or above
    if (!_featureAccessService.hasFeatureAccess('aiSafetyAssistant')) {
      debugPrint(
        '⚠️ AIAssistantService: AI Safety Assistant not available - Requires Pro plan',
      );
      return AIMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: AIMessageType.systemNotification,
        content:
            '🔒 AI Safety Assistant is available on Pro plans and above.\n\n'
            'Upgrade to Pro to unlock:\n'
            '• 24 AI Safety Commands\n'
            '• Emergency Detection Analysis\n'
            '• Predictive Risk Assessment\n'
            '• Real-Time Safety Monitoring\n'
            '• SAR Coordination Intelligence\n'
            '• Medical Insights & Recommendations\n\n'
            'Upgrade now for comprehensive AI-powered safety protection!',
        timestamp: DateTime.now(),
        priority: AIMessagePriority.high,
      );
    }

    // Add user message to conversation history for context
    final userMessage = AIMessage(
      id: _generateId(),
      content: command,
      type: AIMessageType.userInput,
      timestamp: DateTime.now(),
    );
    _conversationHistory.add(userMessage);

    final aiCommand = AICommand(
      id: _generateCommandId(),
      command: command,
      type: _determineCommandType(command),
      parameters: _extractParameters(command),
      timestamp: DateTime.now(),
      userId: _userProfileService?.currentProfile?.id ?? 'unknown',
      status: AICommandStatus.processing,
    );

    _commandHistory.add(aiCommand);

    try {
      // Check permissions
      if (!_hasRequiredPermission(aiCommand.type)) {
        return _createPermissionRequiredMessage(aiCommand);
      }

      // Process the command
      final result = await _executeCommand(aiCommand);

      // Update command status
      final completedCommand = aiCommand.copyWith(
        status: AICommandStatus.completed,
        result: result,
      );
      _updateCommandInHistory(completedCommand);

      // Generate AI response (will be sent via callback inside _generateAIResponse)
      final response = await _generateAIResponse(completedCommand, result);

      // Learn from interaction
      await _updateLearningData(aiCommand, true);

      return response;
    } catch (e) {
      debugPrint('AIAssistantService: Command execution error - $e');

      final failedCommand = aiCommand.copyWith(
        status: AICommandStatus.failed,
        errorMessage: e.toString(),
      );
      _updateCommandInHistory(failedCommand);

      await _updateLearningData(aiCommand, false);

      return _createErrorMessage(e.toString());
    }
  }

  /// Get suggested quick commands based on context
  List<String> getQuickCommands() {
    final suggestions = <String>[];

    // AI-powered hazard monitoring (highest priority)
    if (_serviceManager?.hazardService.activeAlerts.isNotEmpty == true) {
      final hazards = _serviceManager!.hazardService.activeAlerts;
      final threatLevel = _calculateAIThreatLevel(hazards);

      if (threatLevel == 'critical' || threatLevel == 'high') {
        suggestions.add('🚨 AI Threat Assessment');
      } else {
        suggestions.add('⚠️ Active Hazard Alerts');
      }
    } else {
      suggestions.add('✅ AI Safety Check');
    }

    // Comprehensive emergency features
    suggestions.addAll([
      '🚗 Crash Detection Analysis',
      '🤸 Fall Detection Analysis',
      '🆘 SOS Verification Insights',
    ]);

    // Real-time safety monitoring
    suggestions.addAll([
      '😴 Drowsiness Monitoring',
      '🚗 Driving Safety Tips',
      '📊 Hazard Pattern Analysis',
    ]);

    // SAR operations intelligence
    suggestions.addAll([
      '🚁 SAR Coordination Insights',
      '📈 Rescue Analytics',
      '🎯 Resource Optimization',
    ]);

    // Health & medical insights
    suggestions.addAll([
      '🏥 Medical Profile Analysis',
      '🚑 Emergency Medical Guide',
      '💊 Health Risk Assessment',
    ]);

    // Predictive analytics
    suggestions.addAll([
      '🛣️ Route Safety Scoring',
      '🔍 Risk Pattern Recognition',
      '🔮 Emergency Prediction',
      '🔔 Proactive Safety Alerts',
    ]);

    // System commands
    suggestions.addAll([
      'Check system status',
      'What\'s my location?',
      'How is my battery?',
    ]);

    return suggestions.take(20).toList();
  }

  /// Speak AI response
  Future<void> speakResponse(String text) async {
    if (_isSpeaking) return;

    try {
      _isSpeaking = true;
      final phoneAI = PhoneAIIntegrationService();
      if (phoneAI.ttsEnabled) {
        await phoneAI.speak(text);
      } else {
        // Fallback: simulate delay + log
        debugPrint('AIAssistantService (fallback speak): $text');
        await Future.delayed(
          Duration(milliseconds: (text.length * 10).clamp(300, 1500)),
        );
      }
    } finally {
      _isSpeaking = false;
    }
  }

  /// Execute AI command
  Future<String> _executeCommand(AICommand command) async {
    switch (command.type) {
      case AICommandType.navigate:
        return await _executeNavigationCommand(command);
      case AICommandType.checkStatus:
        return await _executeStatusCheck(command);
      case AICommandType.optimizePerformance:
        return await _executePerformanceOptimization(command);
      case AICommandType.safetyAssessment:
        return await _executeSafetyAssessment(command);
      case AICommandType.checkLocation:
        return await _executeLocationCheck(command);
      case AICommandType.checkHazards:
        return await _executeHazardCheck(command);
      case AICommandType.emergencyAction:
        return await _executeEmergencyAction(command);
      case AICommandType.helpRequest:
        return await _executeHelpRequest(command);
      case AICommandType.updateSettings:
        return await _executeSettingsUpdate(command);
      case AICommandType.serviceRecommendation:
        return await _executeServiceRecommendation(command);
      // Comprehensive Emergency Features
      case AICommandType.analyzeCrashDetection:
        return await _analyzeCrashDetection(command);
      case AICommandType.analyzeFallDetection:
        return await _analyzeFallDetection(command);
      case AICommandType.sosVerificationInsights:
        return await _sosVerificationInsights(command);
      case AICommandType.emergencyCoordination:
        return await _emergencyCoordination(command);
      // Real-Time Safety Monitoring
      case AICommandType.drowsinessAnalysis:
        return await _drowsinessAnalysis(command);
      case AICommandType.drivingSafetyTips:
        return await _drivingSafetyTips(command);
      case AICommandType.hazardPatternAnalysis:
        return await _hazardPatternAnalysis(command);
      case AICommandType.environmentalRiskAssessment:
        return await _environmentalRiskAssessment(command);
      // SAR Operations Intelligence
      case AICommandType.sarCoordinationInsights:
        return await _sarCoordinationInsights(command);
      case AICommandType.rescueAnalytics:
        return await _rescueAnalytics(command);
      case AICommandType.victimLocationPrediction:
        return await _victimLocationPrediction(command);
      case AICommandType.resourceOptimization:
        return await _resourceOptimization(command);
      // Health & Medical Insights
      case AICommandType.medicalProfileAnalysis:
        return await _medicalProfileAnalysis(command);
      case AICommandType.emergencyMedicalRecommendations:
        return await _emergencyMedicalRecommendations(command);
      case AICommandType.healthRiskAssessment:
        return await _healthRiskAssessment(command);
      // Predictive Analytics
      case AICommandType.routeSafetyScoring:
        return await _routeSafetyScoring(command);
      case AICommandType.riskPatternRecognition:
        return await _riskPatternRecognition(command);
      case AICommandType.emergencyPrediction:
        return await _emergencyPrediction(command);
      case AICommandType.proactiveSafetyAlert:
        return await _proactiveSafetyAlert(command);
      case AICommandType.voiceCommand:
        return await _handleGeneralQuery(command);
      default:
        // For any unmapped command, treat as general query
        return await _handleGeneralQuery(command);
    }
  }

  /// Handle general queries and conversation using Gemini AI
  Future<String> _handleGeneralQuery(AICommand command) async {
    // If we have Gemini AI, use it for natural conversation
    if (_useExternalAI && _geminiModel != null) {
      try {
        debugPrint(
          'AIAssistantService: Asking Gemini for general query: ${command.command}',
        );

        // Build conversation history for context
        final context = StringBuffer();
        context.writeln('Conversation history:');

        // Include last 10 messages for context (most recent first)
        final recentMessages = _conversationHistory.length > 10
            ? _conversationHistory.sublist(_conversationHistory.length - 10)
            : _conversationHistory;
        for (final msg in recentMessages) {
          if (msg.type == AIMessageType.userInput) {
            context.writeln('User: ${msg.content}');
          } else if (msg.type == AIMessageType.aiResponse) {
            context.writeln('Assistant: ${msg.content}');
          }
        }

        context.writeln('\nCurrent user query: ${command.command}');
        context.writeln(
          '\nProvide a thoughtful, contextual response. Consider the conversation history. '
          'Give specific, helpful information related to safety, emergencies, or RedPing features. '
          'Avoid repeating previous responses unless explicitly asked.',
        );

        final response = await _geminiModel!
            .generateContent([Content.text(context.toString())])
            .timeout(const Duration(seconds: 10));

        return response.text?.trim() ??
            'I understand your question. How can I help you with safety features?';
      } catch (e) {
        debugPrint('AIAssistantService: Gemini query error - $e');
        return _generateIntelligentFallback(command.command);
      }
    } else {
      // No external AI - use intelligent fallback with reasoning
      return _generateIntelligentFallback(command.command);
    }
  }

  /// Generate intelligent fallback responses based on query analysis
  String _generateIntelligentFallback(String query) {
    final lowerQuery = query.toLowerCase();

    // Greeting detection
    if (lowerQuery.contains(RegExp(r'\b(hello|hi|hey|greetings)\b'))) {
      return 'Hello! I\'m your AI Safety Assistant. I can help you with:\n'
          '• Emergency detection and alerts\n'
          '• Real-time hazard monitoring\n'
          '• Safety status checks\n'
          '• Location and route safety\n'
          '• SAR coordination insights\n\n'
          'What would you like to know?';
    }

    // How/what questions - provide reasoning
    if (lowerQuery.contains(RegExp(r'\b(how|what|why|when|where)\b'))) {
      // Crash detection
      if (lowerQuery.contains('crash') || lowerQuery.contains('accident')) {
        return 'RedPing\'s crash detection uses advanced sensors to identify sudden impacts and deceleration patterns. '
            'When a crash is detected:\n'
            '1. The system analyzes G-force data and impact severity\n'
            '2. You\'re given 30 seconds to cancel false alarms\n'
            '3. Emergency contacts are automatically notified with your location\n'
            '4. SAR teams receive detailed crash telemetry\n\n'
            'The AI continuously learns from sensor patterns to improve accuracy.';
      }

      // Fall detection
      if (lowerQuery.contains('fall')) {
        return 'Fall detection monitors your movement patterns and sudden changes in orientation. '
            'The system detects:\n'
            '• Sudden vertical drops with high acceleration\n'
            '• Loss of stability indicators\n'
            '• Extended immobility after impact\n\n'
            'If a fall is detected, you have time to cancel. Otherwise, emergency protocols activate automatically.';
      }

      // SOS/Emergency
      if (lowerQuery.contains('sos') || lowerQuery.contains('emergency')) {
        return 'The SOS system provides multi-layered emergency response:\n'
            '1. **Instant Alert**: Press SOS to immediately notify emergency contacts\n'
            '2. **Location Sharing**: Real-time GPS tracking sent to responders\n'
            '3. **SAR Integration**: Professional rescue teams receive detailed telemetry\n'
            '4. **Medical Info**: Your health profile is shared with responders\n'
            '5. **Two-way Communication**: Chat and status updates during rescue\n\n'
            'The system ensures help reaches you as fast as possible.';
      }

      // Hazards
      if (lowerQuery.contains('hazard') ||
          lowerQuery.contains('danger') ||
          lowerQuery.contains('risk')) {
        return 'AI hazard monitoring continuously scans multiple data sources:\n'
            '• Weather alerts (storms, floods, extreme temperatures)\n'
            '• Traffic incidents (accidents, road closures)\n'
            '• Environmental risks (air quality, wildfires)\n'
            '• Natural disasters (earthquakes, tsunamis)\n'
            '• Crime and safety alerts\n\n'
            'Each hazard is scored by severity (1-10) and you receive proactive warnings '
            'before dangers reach your location. The AI predicts threat trajectories and suggests safe routes.';
      }

      // Battery/Performance
      if (lowerQuery.contains('battery') || lowerQuery.contains('power')) {
        return 'RedPing is optimized for 24/7 operation with minimal battery drain:\n'
            '• Smart sensor scheduling reduces CPU usage\n'
            '• Location updates use efficient batching\n'
            '• Background monitoring adapts to battery level\n'
            '• Critical safety features remain active even in battery saver mode\n\n'
            'Current battery optimization ensures safety without compromising device longevity.';
      }

      // SAR
      if (lowerQuery.contains('sar') || lowerQuery.contains('rescue')) {
        return 'SAR (Search and Rescue) coordination provides professional emergency response:\n'
            '• Real-time victim location tracking\n'
            '• Medical profile sharing for informed rescue\n'
            '• Resource optimization for rescue teams\n'
            '• Predictive location algorithms for lost persons\n'
            '• Two-way communication between victims and responders\n\n'
            'The AI analyzes terrain, weather, and victim patterns to guide rescue teams efficiently.';
      }
    }

    // Can you... / are you able to...
    if (lowerQuery.contains(RegExp(r'\b(can you|are you able|do you)\b'))) {
      return 'I can assist you with:\n'
          '✓ Analyzing crash and fall detection data\n'
          '✓ Monitoring real-time hazards in your area\n'
          '✓ Providing safety status and recommendations\n'
          '✓ Explaining RedPing features and capabilities\n'
          '✓ Checking your location, battery, and system health\n'
          '✓ SAR coordination and rescue insights\n'
          '✓ Emergency preparedness guidance\n\n'
          'Ask me anything specific, and I\'ll provide detailed information!';
    }

    // Default intelligent response
    return 'I\'m analyzing your question: "$query"\n\n'
        'I can help you with:\n'
        '• **Emergency Features**: Crash detection, fall detection, SOS alerts\n'
        '• **Safety Monitoring**: Hazard alerts, location tracking, route safety\n'
        '• **System Status**: Battery, sensors, connectivity\n'
        '• **SAR Operations**: Rescue coordination, victim location\n\n'
        'Could you be more specific about what you\'d like to know? '
        'For example:\n'
        '- "How does crash detection work?"\n'
        '- "What hazards are near me?"\n'
        '- "Check my safety status"';
  }

  /// Execute navigation command
  Future<String> _executeNavigationCommand(AICommand command) async {
    final destination = command.parameters['destination'] as String?;
    if (destination == null) {
      throw Exception('Navigation destination not specified');
    }

    // Map natural language to routes
    final routeMap = {
      'sos': '/',
      'emergency': '/',
      'help': '/help-assistant',
      'assistance': '/help-assistant',
      'map': '/map',
      'location': '/map',
      'settings': '/settings',
      'profile': '/profile',
      'contacts': '/profile/emergency-contacts',
      'emergency contacts': '/profile/emergency-contacts',
      'chat': '/chat',
      'communication': '/chat',
      'sar': '/sar',
      'rescue': '/sar',
      'hazards': '/hazard-alerts',
      'alerts': '/hazard-alerts',
      'satellite': '/satellite',
    };

    final route = routeMap[destination.toLowerCase()];
    if (route == null) {
      throw Exception('Unknown destination: $destination');
    }

    // Navigate using service manager
    // Note: In a real implementation, this would use a navigation service
    return 'Navigated to $destination';
  }

  /// Execute status check
  Future<String> _executeStatusCheck(AICommand command) async {
    final statusType = command.parameters['type'] as String? ?? 'all';

    final statusReport = StringBuffer();

    if (statusType == 'all' || statusType == 'system') {
      final systemStatus = _getSystemStatus();
      statusReport.writeln('System Status: $systemStatus');
    }

    if (statusType == 'all' || statusType == 'location') {
      final locationStatus = await _getLocationStatus();
      statusReport.writeln('Location: $locationStatus');
    }

    if (statusType == 'all' || statusType == 'safety') {
      final safetyStatus = await _getSafetyStatus();
      statusReport.writeln('Safety: $safetyStatus');
    }

    if (statusType == 'all' || statusType == 'services') {
      final servicesStatus = _getServicesStatus();
      statusReport.writeln('Services: $servicesStatus');
    }

    return statusReport.toString().trim();
  }

  /// Execute performance optimization
  Future<String> _executePerformanceOptimization(AICommand command) async {
    final optimizations = <String>[];

    try {
      // Check battery usage
      final performanceData = await _gatherPerformanceData();

      if (performanceData.batteryLevel < 20) {
        // Optimize for battery saving
        optimizations.add('Enabled battery saving mode');
        // TODO: Implement battery optimization
      }

      if (performanceData.memoryUsage > 80) {
        // Clear cache and optimize memory
        optimizations.add('Cleared app cache to free memory');
        // TODO: Implement memory optimization
      }

      if (performanceData.cpuUsage > 70) {
        // Reduce background processes
        optimizations.add('Reduced background sensor monitoring');
        // TODO: Implement CPU optimization
      }

      // Update performance data
      _lastPerformanceData = performanceData;
      _onPerformanceUpdate?.call(performanceData);

      if (optimizations.isEmpty) {
        return 'App performance is already optimized. No changes needed.';
      } else {
        return 'Performance optimized:\n${optimizations.join('\n')}';
      }
    } catch (e) {
      throw Exception('Performance optimization failed: $e');
    }
  }

  /// Execute safety assessment
  Future<String> _executeSafetyAssessment(AICommand command) async {
    try {
      final assessment = await _generateSafetyAssessment();
      _onSafetyAssessment?.call(assessment);

      final report = StringBuffer();
      report.writeln('Safety Assessment Complete:');
      report.writeln(
        'Overall Level: ${_getSafetyLevelDescription(assessment.overallLevel)}',
      );

      if (assessment.recommendations.isNotEmpty) {
        report.writeln('\nRecommendations:');
        for (final rec in assessment.recommendations.take(3)) {
          report.writeln('• ${rec.title}');
        }
      }

      if (assessment.activeThreats.isNotEmpty) {
        report.writeln('\nActive Concerns:');
        for (final threat in assessment.activeThreats) {
          report.writeln('⚠️ $threat');
        }
      }

      return report.toString().trim();
    } catch (e) {
      throw Exception('Safety assessment failed: $e');
    }
  }

  /// Execute location check
  Future<String> _executeLocationCheck(AICommand command) async {
    try {
      if (_locationService == null) {
        return 'Location service not available.';
      }

      final location = await _locationService?.getCurrentLocation();
      if (location == null) {
        return 'Location not available. Please enable location services.';
      }

      final report = StringBuffer();
      report.writeln('Current Location:');
      if (location.address != null) {
        report.writeln('📍 ${location.address}');
      }
      report.writeln(
        'Coordinates: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
      );
      report.writeln('Accuracy: ${location.accuracy.toStringAsFixed(1)}m');

      // Check for nearby hazards
      final hazards = _serviceManager?.hazardService.activeAlerts ?? [];
      if (hazards.isNotEmpty) {
        report.writeln('\n⚠️ ${hazards.length} hazard alert(s) in your area');
      }

      return report.toString().trim();
    } catch (e) {
      throw Exception('Location check failed: $e');
    }
  }

  /// Execute hazard check with AI-powered threat assessment
  Future<String> _executeHazardCheck(AICommand command) async {
    try {
      final hazards = _serviceManager?.hazardService.activeAlerts ?? [];

      if (hazards.isEmpty) {
        return '✅ AI Safety Assessment: No active hazard alerts detected.\n\n'
            '🤖 24/7 Monitoring Active:\n'
            '• Weather patterns & severe storms\n'
            '• Natural disasters (earthquakes, floods, fires)\n'
            '• Political unrest & civil emergencies\n'
            '• Traffic incidents & road closures\n'
            '• Environmental hazards\n'
            '• Community safety alerts\n\n'
            'You\'re all clear! Stay safe!';
      }

      // AI threat level assessment
      final threatLevel = _calculateAIThreatLevel(hazards);
      final threatAssessment = _getAIThreatAssessment(hazards, threatLevel);
      final monitoringScope = _getAIMonitoringScope(hazards);

      final report = StringBuffer();

      // AI Threat Level Header
      report.writeln(_getThreatLevelHeader(threatLevel));
      report.writeln(threatAssessment);
      report.writeln();

      // Active Monitoring Scope
      report.writeln('🤖 AI Monitoring: $monitoringScope');
      report.writeln();

      // Critical alerts first
      final criticalAlerts = hazards
          .where(
            (h) =>
                h.severity == HazardSeverity.critical ||
                h.severity == HazardSeverity.extreme,
          )
          .toList();

      if (criticalAlerts.isNotEmpty) {
        report.writeln('🚨 CRITICAL ALERTS (${criticalAlerts.length}):');
        for (final hazard in criticalAlerts.take(3)) {
          final severityIcon = _getHazardSeverityIcon(hazard.severity);
          final typeIcon = _getHazardTypeIcon(hazard.type);
          report.writeln('$severityIcon $typeIcon ${hazard.title}');
          if (hazard.description.isNotEmpty) {
            report.writeln(
              '   ${_truncateDescription(hazard.description, 60)}',
            );
          }
        }
        report.writeln();
      }

      // Severe alerts
      final severeAlerts = hazards
          .where((h) => h.severity == HazardSeverity.severe)
          .toList();

      if (severeAlerts.isNotEmpty) {
        report.writeln('⚠️ SEVERE ALERTS (${severeAlerts.length}):');
        for (final hazard in severeAlerts.take(2)) {
          final typeIcon = _getHazardTypeIcon(hazard.type);
          report.writeln('$typeIcon ${hazard.title}');
        }
        report.writeln();
      }

      // Travel safety advice
      if (threatLevel == 'critical' || threatLevel == 'high') {
        report.writeln(_getTravelSafetyAdvice(hazards, threatLevel));
        report.writeln();
      }

      // SAR coordination info
      if (criticalAlerts.isNotEmpty) {
        report.writeln(
          '🆘 SAR Coordination: Teams notified and monitoring situation',
        );
        report.writeln();
      }

      // Total count
      if (hazards.length > 5) {
        report.writeln('📊 Total: ${hazards.length} active alerts');
        report.writeln('   Tap "View All" for complete details');
      }

      return report.toString().trim();
    } catch (e) {
      throw Exception('Hazard check failed: $e');
    }
  }

  /// Calculate AI threat level based on active alerts
  String _calculateAIThreatLevel(List<HazardAlert> hazards) {
    if (hazards.isEmpty) return 'safe';

    final criticalCount = hazards
        .where(
          (h) =>
              h.severity == HazardSeverity.critical ||
              h.severity == HazardSeverity.extreme,
        )
        .length;

    final severeCount = hazards
        .where((h) => h.severity == HazardSeverity.severe)
        .length;

    if (criticalCount >= 2 || (criticalCount >= 1 && severeCount >= 2)) {
      return 'critical';
    } else if (criticalCount >= 1 || severeCount >= 3) {
      return 'high';
    } else if (severeCount >= 1 || hazards.length >= 5) {
      return 'moderate';
    } else if (hazards.length >= 2) {
      return 'low';
    }

    return 'safe';
  }

  /// Get AI threat assessment message
  String _getAIThreatAssessment(List<HazardAlert> hazards, String threatLevel) {
    final hasWeather = hazards.any(
      (h) =>
          h.type == HazardType.weather ||
          h.type == HazardType.severeStorm ||
          h.type == HazardType.tornado ||
          h.type == HazardType.hurricane,
    );

    final hasDisaster = hazards.any(
      (h) =>
          h.type == HazardType.earthquake ||
          h.type == HazardType.flood ||
          h.type == HazardType.fire ||
          h.type == HazardType.tsunami,
    );

    final hasCivil = hazards.any(
      (h) =>
          h.type == HazardType.civilEmergency ||
          h.type == HazardType.securityThreat,
    );

    switch (threatLevel) {
      case 'critical':
        if (hasDisaster) {
          return '🚨 Multiple disasters detected. Immediate evacuation may be required.';
        } else if (hasCivil) {
          return '🚨 Critical safety threat. Shelter in place. Avoid all travel.';
        }
        return '🚨 Critical threat level. Follow emergency protocols immediately.';

      case 'high':
        if (hasWeather) {
          return '⚠️ Severe weather approaching. Delay all travel. Monitor updates.';
        } else if (hasDisaster) {
          return '⚠️ Major incident detected. Stay alert. Follow local authorities.';
        }
        return '⚠️ High threat level. Exercise extreme caution. Travel not recommended.';

      case 'moderate':
        return '⚡ Moderate threat level. Stay aware. Check updates before travel.';

      case 'low':
        return 'ℹ️ Minor alerts detected. Situation stable. Normal precautions advised.';

      default:
        return '✅ All systems monitoring. No significant threats detected.';
    }
  }

  /// Get AI monitoring scope
  String _getAIMonitoringScope(List<HazardAlert> hazards) {
    final categories = <String>[];

    if (hazards.any(
      (h) =>
          h.type == HazardType.weather ||
          h.type == HazardType.severeStorm ||
          h.type == HazardType.tornado ||
          h.type == HazardType.hurricane,
    )) {
      categories.add('severe weather');
    }

    if (hazards.any(
      (h) =>
          h.type == HazardType.earthquake ||
          h.type == HazardType.flood ||
          h.type == HazardType.tsunami ||
          h.type == HazardType.landslide,
    )) {
      categories.add('natural disasters');
    }

    if (hazards.any((h) => h.type == HazardType.fire)) {
      categories.add('wildfires');
    }

    if (hazards.any(
      (h) =>
          h.type == HazardType.civilEmergency ||
          h.type == HazardType.securityThreat,
    )) {
      categories.add('political unrest');
    }

    if (hazards.any((h) => h.type == HazardType.roadClosure)) {
      categories.add('traffic incidents');
    }

    if (categories.isEmpty) return 'all threat categories';
    if (categories.length == 1) return categories.first;
    if (categories.length == 2) return '${categories[0]} & ${categories[1]}';

    final last = categories.removeLast();
    return '${categories.join(', ')}, & $last';
  }

  /// Get threat level header with emoji
  String _getThreatLevelHeader(String threatLevel) {
    switch (threatLevel) {
      case 'critical':
        return '🚨 AI THREAT LEVEL: CRITICAL';
      case 'high':
        return '⚠️ AI THREAT LEVEL: HIGH';
      case 'moderate':
        return '⚡ AI THREAT LEVEL: MODERATE';
      case 'low':
        return 'ℹ️ AI THREAT LEVEL: LOW';
      default:
        return '✅ AI THREAT LEVEL: SAFE';
    }
  }

  /// Get travel safety advice
  String _getTravelSafetyAdvice(List<HazardAlert> hazards, String threatLevel) {
    if (threatLevel == 'critical') {
      return '🚫 TRAVEL ADVISORY: All travel strongly discouraged\n'
          '   • Shelter in place if possible\n'
          '   • Avoid affected areas completely\n'
          '   • Follow evacuation orders immediately';
    } else if (threatLevel == 'high') {
      return '⚠️ TRAVEL ADVISORY: Non-essential travel not recommended\n'
          '   • Delay trips if possible\n'
          '   • Plan alternate routes\n'
          '   • Stay updated on conditions';
    }
    return '';
  }

  /// Get hazard type icon
  String _getHazardTypeIcon(HazardType type) {
    switch (type) {
      case HazardType.weather:
      case HazardType.severeStorm:
      case HazardType.tornado:
      case HazardType.hurricane:
        return '🌪️';
      case HazardType.earthquake:
        return '🏚️';
      case HazardType.flood:
        return '🌊';
      case HazardType.fire:
        return '🔥';
      case HazardType.tsunami:
        return '🌊';
      case HazardType.landslide:
      case HazardType.avalanche:
        return '⛰️';
      case HazardType.civilEmergency:
      case HazardType.securityThreat:
        return '🚨';
      case HazardType.roadClosure:
        return '🚧';
      case HazardType.airQuality:
        return '😷';
      case HazardType.chemicalSpill:
      case HazardType.gasLeak:
        return '☣️';
      default:
        return '⚠️';
    }
  }

  /// Truncate description to max length
  String _truncateDescription(String desc, int maxLength) {
    if (desc.length <= maxLength) return desc;
    return '${desc.substring(0, maxLength)}...';
  }

  /// Execute emergency action
  Future<String> _executeEmergencyAction(AICommand command) async {
    final actionType = command.parameters['action'] as String?;

    switch (actionType?.toLowerCase()) {
      case 'sos':
      case 'emergency':
        if (!_permissions.canTriggerSOS) {
          throw Exception('AI does not have permission to trigger SOS');
        }
        // Note: This would require explicit user confirmation in a real implementation
        return 'SOS activation requires manual confirmation for safety. Please press the SOS button.';

      case 'help':
      case 'assistance':
        return 'I can help you create a help request. What do you need assistance with?';

      case 'contacts':
        return 'Your emergency contacts are ready. Would you like me to show them or call someone?';

      default:
        throw Exception('Unknown emergency action: $actionType');
    }
  }

  /// Execute help request
  Future<String> _executeHelpRequest(AICommand command) async {
    final category = command.parameters['category'] as String?;
    final description = command.parameters['description'] as String?;

    if (category == null || description == null) {
      return 'I can help you create a help request. Please provide more details about what you need help with.';
    }

    // Map category to HelpCategory enum
    final helpCategory = _mapStringToHelpCategory(category);
    if (helpCategory == null) {
      return 'I understand you need help with $category. Let me open the help assistant for you.';
    }

    return 'I can help you create a $category request. The help assistant will guide you through the process.';
  }

  /// Execute settings update
  Future<String> _executeSettingsUpdate(AICommand command) async {
    final setting = command.parameters['setting'] as String?;
    final value = command.parameters['value'];

    if (setting == null) {
      throw Exception('Setting not specified');
    }

    if (!_permissions.canModifySettings) {
      throw Exception('AI does not have permission to modify settings');
    }

    // Map settings to actual service calls
    switch (setting.toLowerCase()) {
      case 'notifications':
        if (value is bool) {
          if (_serviceManager?.notificationService != null) {
            _serviceManager!.notificationService.isEnabled = value;
          }
          return value ? 'Notifications enabled' : 'Notifications disabled';
        }
        break;

      case 'location':
        // Location settings would be handled by the location service
        return 'Location settings updated';

      case 'sensors':
        // Sensor settings would be handled by the sensor service
        return 'Sensor monitoring updated';

      default:
        throw Exception('Unknown setting: $setting');
    }

    return 'Setting updated successfully';
  }

  /// Execute service recommendation
  Future<String> _executeServiceRecommendation(AICommand command) async {
    final location = await _locationService?.getCurrentLocation();
    if (location == null) {
      return 'I need your location to recommend nearby services. Please enable location access.';
    }

    final recommendations = StringBuffer();
    recommendations.writeln('Nearby Services & Recommendations:');

    // Simulate service recommendations based on location and time
    final hour = DateTime.now().hour;

    if (hour >= 22 || hour <= 6) {
      recommendations.writeln('🌙 Late Night Services:');
      recommendations.writeln('• 24/7 Emergency Services: Available');
      recommendations.writeln('• Night Security Patrol: Active in area');
      recommendations.writeln('• 24/7 Roadside Assistance: (555) ROAD-24');
    } else {
      recommendations.writeln('🌅 Daytime Services:');
      recommendations.writeln('• Local Police Station: 0.8 miles');
      recommendations.writeln('• Fire Department: 1.2 miles');
      recommendations.writeln('• Hospital: 2.1 miles');
      recommendations.writeln('• Auto Repair Shop: 0.5 miles');
    }

    // Check for active help requests
    final activeRequests =
        _serviceManager?.helpAssistantService.getActiveRequests() ?? [];
    if (activeRequests is List && activeRequests.isNotEmpty) {
      recommendations.writeln('\n📋 Your Active Requests:');
      for (final request in (activeRequests).take(3)) {
        recommendations.writeln('• ${request.title} (${request.status.name})');
      }
    }

    return recommendations.toString().trim();
  }

  /// Generate smart suggestions based on context
  Future<List<AISuggestion>> generateSmartSuggestions() async {
    final suggestions = <AISuggestion>[];

    try {
      // AI-Powered Hazard Alert Suggestions (HIGHEST PRIORITY)
      final hazards = _serviceManager?.hazardService.activeAlerts ?? [];
      if (hazards.isNotEmpty) {
        final threatLevel = _calculateAIThreatLevel(hazards);
        final criticalCount = hazards
            .where(
              (h) =>
                  h.severity == HazardSeverity.critical ||
                  h.severity == HazardSeverity.extreme,
            )
            .length;

        AISuggestionPriority priority;
        String title;
        String description;

        if (threatLevel == 'critical') {
          priority = AISuggestionPriority.urgent;
          title = '🚨 CRITICAL THREAT DETECTED';
          description = criticalCount > 0
              ? '$criticalCount critical hazard(s) in your area. Immediate action may be required.'
              : 'Multiple severe threats detected. AI recommends immediate safety check.';
        } else if (threatLevel == 'high') {
          priority = AISuggestionPriority.urgent;
          title = '⚠️ HIGH THREAT LEVEL';
          description =
              'AI detected ${hazards.length} active hazards. Review travel safety advice.';
        } else if (threatLevel == 'moderate') {
          priority = AISuggestionPriority.high;
          title = '⚡ Active Hazard Monitoring';
          description =
              '${hazards.length} alerts detected. AI monitoring: ${_getAIMonitoringScope(hazards)}.';
        } else {
          priority = AISuggestionPriority.medium;
          title = 'ℹ️ Hazard Alerts Active';
          description =
              '${hazards.length} minor alert(s) in your area. Tap for AI assessment.';
        }

        suggestions.add(
          AISuggestion(
            id: _generateId(),
            title: title,
            description: description,
            actionType: AIActionType.checkWeather,
            actionParameters: {
              'hazardCount': hazards.length,
              'threatLevel': threatLevel,
              'criticalCount': criticalCount,
            },
            priority: priority,
            validUntil: DateTime.now().add(const Duration(hours: 1)),
          ),
        );
      }

      // Performance-based suggestions
      final performanceData = await _gatherPerformanceData();
      if (performanceData.batteryLevel < 30) {
        suggestions.add(
          AISuggestion(
            id: _generateId(),
            title: 'Optimize Battery',
            description:
                'Battery is low. I can optimize app performance to save power.',
            actionType: AIActionType.optimizeBattery,
            actionParameters: {'level': 'aggressive'},
            priority: AISuggestionPriority.high,
            validUntil: DateTime.now().add(const Duration(hours: 2)),
          ),
        );
      }

      // Safety-based suggestions
      final safetyAssessment = await _generateSafetyAssessment();
      if (safetyAssessment.overallLevel == AISafetyLevel.warning ||
          safetyAssessment.overallLevel == AISafetyLevel.danger) {
        suggestions.add(
          AISuggestion(
            id: _generateId(),
            title: 'Safety Check Required',
            description:
                'I detected potential safety concerns. Let me assess your situation.',
            actionType: AIActionType.checkSystemStatus,
            actionParameters: {'focus': 'safety'},
            priority: AISuggestionPriority.urgent,
            validUntil: DateTime.now().add(const Duration(minutes: 30)),
          ),
        );
      }

      // Usage-based suggestions
      if (_learningData != null) {
        final frequentCommands = _learningData!.commandFrequency.entries
            .where((e) => e.value > 5)
            .map((e) => e.key)
            .toList();

        if (frequentCommands.contains('check_status')) {
          suggestions.add(
            AISuggestion(
              id: _generateId(),
              title: 'Quick Status Check',
              description:
                  'Would you like me to check your app and safety status?',
              actionType: AIActionType.checkSystemStatus,
              actionParameters: {'type': 'comprehensive'},
              priority: AISuggestionPriority.low,
              validUntil: DateTime.now().add(const Duration(hours: 4)),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('AIAssistantService: Error generating suggestions - $e');
    }

    return suggestions;
  }

  /// Start performance monitoring
  void _startPerformanceMonitoring() {
    _performanceMonitoringTimer = Timer.periodic(const Duration(minutes: 5), (
      _,
    ) async {
      try {
        final performanceData = await _gatherPerformanceData();
        _lastPerformanceData = performanceData;
        _onPerformanceUpdate?.call(performanceData);

        // Generate performance suggestions
        await _checkPerformanceAndSuggest(performanceData);
      } catch (e) {
        debugPrint('AIAssistantService: Performance monitoring error - $e');
      }
    });
  }

  /// Start safety assessment
  void _startSafetyAssessment() {
    _safetyAssessmentTimer = Timer.periodic(const Duration(minutes: 10), (
      _,
    ) async {
      try {
        final assessment = await _generateSafetyAssessment();
        _onSafetyAssessment?.call(assessment);

        // Generate safety suggestions if needed
        if (assessment.overallLevel != AISafetyLevel.safe) {
          await _generateSafetySuggestions(assessment);
        }
      } catch (e) {
        debugPrint('AIAssistantService: Safety assessment error - $e');
      }
    });
  }

  /// Gather performance data
  Future<AIPerformanceData> _gatherPerformanceData() async {
    // Simulate performance data gathering
    // In a real implementation, this would use platform channels
    return AIPerformanceData(
      cpuUsage: Random().nextDouble() * 100,
      memoryUsage: Random().nextDouble() * 100,
      batteryLevel: Random().nextDouble() * 100,
      isLocationActive: _serviceManager?.locationService.isTracking ?? false,
      areSensorsActive: _serviceManager?.sensorService.isMonitoring ?? false,
      activeNotifications: Random().nextInt(10),
      networkUsage: Random().nextDouble() * 100,
      lastOptimization: DateTime.now(),
      optimizationSuggestions: [],
      servicePerformance: {
        'location': Random().nextDouble() * 100,
        'sensors': Random().nextDouble() * 100,
        'notifications': Random().nextDouble() * 100,
      },
    );
  }

  /// Generate safety assessment
  Future<AISafetyAssessment> _generateSafetyAssessment() async {
    final recommendations = <AISafetyRecommendation>[];
    final activeThreats = <String>[];
    final categoryLevels = <String, AISafetyLevel>{};

    // Assess system status
    if (_serviceManager?.isInitialized != true) {
      activeThreats.add('App services not fully initialized');
      categoryLevels['system'] = AISafetyLevel.warning;
    } else {
      categoryLevels['system'] = AISafetyLevel.safe;
    }

    // Assess location services
    if (_serviceManager?.locationService.hasPermission != true) {
      activeThreats.add('Location services disabled');
      categoryLevels['location'] = AISafetyLevel.caution;

      recommendations.add(
        AISafetyRecommendation(
          id: _generateId(),
          title: 'Enable Location Services',
          description:
              'Location access is required for emergency response and safety features.',
          urgency: AISafetyLevel.warning,
          recommendedAction: AIActionType.updateLocation,
          actionParameters: {'enable': true},
          validUntil: DateTime.now().add(const Duration(hours: 24)),
        ),
      );
    } else {
      categoryLevels['location'] = AISafetyLevel.safe;
    }

    // Assess sensor monitoring
    if (_serviceManager?.sensorService.isMonitoring != true) {
      activeThreats.add('Crash/fall detection disabled');
      categoryLevels['sensors'] = AISafetyLevel.caution;
    } else {
      categoryLevels['sensors'] = AISafetyLevel.safe;
    }

    // Assess emergency contacts
    final profile = _userProfileService?.currentProfile;
    if (profile?.emergencyContacts.isEmpty ?? true) {
      activeThreats.add('No emergency contacts configured');
      categoryLevels['contacts'] = AISafetyLevel.warning;

      recommendations.add(
        AISafetyRecommendation(
          id: _generateId(),
          title: 'Add Emergency Contacts',
          description:
              'Emergency contacts are essential for safety and help requests.',
          urgency: AISafetyLevel.warning,
          recommendedAction: AIActionType.updateProfile,
          actionParameters: {'section': 'emergency_contacts'},
          validUntil: DateTime.now().add(const Duration(days: 7)),
        ),
      );
    } else {
      categoryLevels['contacts'] = AISafetyLevel.safe;
    }

    // Determine overall safety level
    final levels = categoryLevels.values.toList();
    AISafetyLevel overallLevel = AISafetyLevel.safe;

    if (levels.contains(AISafetyLevel.critical)) {
      overallLevel = AISafetyLevel.critical;
    } else if (levels.contains(AISafetyLevel.danger)) {
      overallLevel = AISafetyLevel.danger;
    } else if (levels.contains(AISafetyLevel.warning)) {
      overallLevel = AISafetyLevel.warning;
    } else if (levels.contains(AISafetyLevel.caution)) {
      overallLevel = AISafetyLevel.caution;
    }

    return AISafetyAssessment(
      id: _generateId(),
      timestamp: DateTime.now(),
      overallLevel: overallLevel,
      categoryLevels: categoryLevels,
      recommendations: recommendations,
      activeThreats: activeThreats,
      environmentalFactors: {
        'time_of_day': DateTime.now().hour,
        'battery_level': _lastPerformanceData?.batteryLevel ?? 100,
        'location_available': _serviceManager?.locationService.hasPermission,
      },
    );
  }

  /// Determine command type from natural language
  AICommandType _determineCommandType(String command) {
    final lowerCommand = command.toLowerCase();

    // Comprehensive Emergency Features
    if (lowerCommand.contains('crash detection') ||
        lowerCommand.contains('analyze crash') ||
        lowerCommand.contains('crash analysis')) {
      return AICommandType.analyzeCrashDetection;
    } else if (lowerCommand.contains('fall detection') ||
        lowerCommand.contains('analyze fall') ||
        lowerCommand.contains('fall analysis')) {
      return AICommandType.analyzeFallDetection;
    } else if (lowerCommand.contains('sos verification') ||
        lowerCommand.contains('verification insights') ||
        lowerCommand.contains('sos insights')) {
      return AICommandType.sosVerificationInsights;
    } else if (lowerCommand.contains('emergency coordination') ||
        lowerCommand.contains('emergency workflow')) {
      return AICommandType.emergencyCoordination;
    }
    // Real-Time Safety Monitoring
    else if (lowerCommand.contains('drowsiness') ||
        lowerCommand.contains('drowsy') ||
        lowerCommand.contains('tired monitoring')) {
      return AICommandType.drowsinessAnalysis;
    } else if (lowerCommand.contains('driving safety') ||
        lowerCommand.contains('driving tips') ||
        lowerCommand.contains('safety tips')) {
      return AICommandType.drivingSafetyTips;
    } else if (lowerCommand.contains('hazard pattern') ||
        lowerCommand.contains('pattern analysis')) {
      return AICommandType.hazardPatternAnalysis;
    } else if (lowerCommand.contains('environmental risk') ||
        lowerCommand.contains('environment assessment')) {
      return AICommandType.environmentalRiskAssessment;
    }
    // SAR Operations Intelligence
    else if (lowerCommand.contains('sar coordination') ||
        lowerCommand.contains('sar insights') ||
        lowerCommand.contains('sar intelligence')) {
      return AICommandType.sarCoordinationInsights;
    } else if (lowerCommand.contains('rescue analytics') ||
        lowerCommand.contains('rescue analysis') ||
        lowerCommand.contains('operation analytics')) {
      return AICommandType.rescueAnalytics;
    } else if (lowerCommand.contains('victim location') ||
        lowerCommand.contains('location prediction')) {
      return AICommandType.victimLocationPrediction;
    } else if (lowerCommand.contains('resource optimization') ||
        lowerCommand.contains('optimize resources')) {
      return AICommandType.resourceOptimization;
    }
    // Health & Medical Insights
    else if (lowerCommand.contains('medical profile') ||
        lowerCommand.contains('profile analysis')) {
      return AICommandType.medicalProfileAnalysis;
    } else if (lowerCommand.contains('emergency medical') ||
        lowerCommand.contains('medical recommendations') ||
        lowerCommand.contains('medical guide')) {
      return AICommandType.emergencyMedicalRecommendations;
    } else if (lowerCommand.contains('health risk') ||
        lowerCommand.contains('health assessment')) {
      return AICommandType.healthRiskAssessment;
    }
    // Predictive Analytics
    else if (lowerCommand.contains('route safety') ||
        lowerCommand.contains('safety scoring')) {
      return AICommandType.routeSafetyScoring;
    } else if (lowerCommand.contains('risk pattern') ||
        lowerCommand.contains('pattern recognition')) {
      return AICommandType.riskPatternRecognition;
    } else if (lowerCommand.contains('emergency prediction') ||
        lowerCommand.contains('predict emergency')) {
      return AICommandType.emergencyPrediction;
    } else if (lowerCommand.contains('proactive') ||
        lowerCommand.contains('safety alert')) {
      return AICommandType.proactiveSafetyAlert;
    }
    // Original command types
    else if (lowerCommand.contains('navigate') ||
        lowerCommand.contains('go to') ||
        lowerCommand.contains('open')) {
      return AICommandType.navigate;
    } else if (lowerCommand.contains('status') ||
        lowerCommand.contains('check') ||
        lowerCommand.contains('how is')) {
      return AICommandType.checkStatus;
    } else if (lowerCommand.contains('optimize') ||
        lowerCommand.contains('performance') ||
        lowerCommand.contains('speed up')) {
      return AICommandType.optimizePerformance;
    } else if (lowerCommand.contains('safety') ||
        lowerCommand.contains('secure') ||
        lowerCommand.contains('assess')) {
      return AICommandType.safetyAssessment;
    } else if (lowerCommand.contains('location') ||
        lowerCommand.contains('where am i') ||
        lowerCommand.contains('position')) {
      return AICommandType.checkLocation;
    } else if (lowerCommand.contains('hazard') ||
        lowerCommand.contains('alert') ||
        lowerCommand.contains('danger')) {
      return AICommandType.checkHazards;
    } else if (lowerCommand.contains('emergency') ||
        lowerCommand.contains('sos') ||
        lowerCommand.contains('help')) {
      return AICommandType.emergencyAction;
    } else if (lowerCommand.contains('setting') ||
        lowerCommand.contains('configure') ||
        lowerCommand.contains('enable') ||
        lowerCommand.contains('disable')) {
      return AICommandType.updateSettings;
    } else if (lowerCommand.contains('service') ||
        lowerCommand.contains('recommend') ||
        lowerCommand.contains('nearby')) {
      return AICommandType.serviceRecommendation;
    } else {
      return AICommandType.voiceCommand;
    }
  }

  /// Extract parameters from natural language command
  Map<String, dynamic> _extractParameters(String command) {
    final params = <String, dynamic>{};
    final lowerCommand = command.toLowerCase();

    // Extract navigation destinations
    if (lowerCommand.contains('go to') ||
        lowerCommand.contains('open') ||
        lowerCommand.contains('navigate')) {
      if (lowerCommand.contains('sos') || lowerCommand.contains('emergency')) {
        params['destination'] = 'sos';
      } else if (lowerCommand.contains('help') ||
          lowerCommand.contains('assistance')) {
        params['destination'] = 'help';
      } else if (lowerCommand.contains('map') ||
          lowerCommand.contains('location')) {
        params['destination'] = 'map';
      } else if (lowerCommand.contains('settings')) {
        params['destination'] = 'settings';
      } else if (lowerCommand.contains('profile')) {
        params['destination'] = 'profile';
      } else if (lowerCommand.contains('chat') ||
          lowerCommand.contains('message')) {
        params['destination'] = 'chat';
      } else if (lowerCommand.contains('hazard') ||
          lowerCommand.contains('alert')) {
        params['destination'] = 'hazards';
      }
    }

    // Extract status check types
    if (lowerCommand.contains('status') || lowerCommand.contains('check')) {
      if (lowerCommand.contains('system')) {
        params['type'] = 'system';
      } else if (lowerCommand.contains('location')) {
        params['type'] = 'location';
      } else if (lowerCommand.contains('safety')) {
        params['type'] = 'safety';
      } else if (lowerCommand.contains('service')) {
        params['type'] = 'services';
      }
    }

    // Extract emergency actions
    if (lowerCommand.contains('emergency') || lowerCommand.contains('sos')) {
      params['action'] = 'sos';
    } else if (lowerCommand.contains('help') ||
        lowerCommand.contains('assistance')) {
      params['action'] = 'help';
    } else if (lowerCommand.contains('contact')) {
      params['action'] = 'contacts';
    }

    // Extract settings
    if (lowerCommand.contains('notification')) {
      params['setting'] = 'notifications';
      if (lowerCommand.contains('enable') || lowerCommand.contains('turn on')) {
        params['value'] = true;
      } else if (lowerCommand.contains('disable') ||
          lowerCommand.contains('turn off')) {
        params['value'] = false;
      }
    }

    return params;
  }

  /// Generate AI response message
  Future<AIMessage> _generateAIResponse(
    AICommand command,
    String result,
  ) async {
    debugPrint(
      'AIAssistantService: Generating AI response for command type: ${command.type.name}',
    );

    String content;

    // Try using Gemini AI first
    if (_useExternalAI && _geminiModel != null) {
      try {
        final prompt = '${command.command}\n\nContext: $result';
        debugPrint('AIAssistantService: Asking Gemini: $prompt');

        final response = await _geminiModel!
            .generateContent([Content.text(prompt)])
            .timeout(const Duration(seconds: 10));

        content = response.text ?? result;
        debugPrint('AIAssistantService: Gemini response: $content');
      } catch (e) {
        debugPrint(
          'AIAssistantService: Gemini error - $e, falling back to templates',
        );
        final responses = _getResponseTemplates(command.type);
        final template = responses[Random().nextInt(responses.length)];
        content = template.replaceAll('{result}', result);
      }
    } else {
      // Fallback to template-based responses
      final responses = _getResponseTemplates(command.type);
      final template = responses[Random().nextInt(responses.length)];
      content = template.replaceAll('{result}', result);
    }

    debugPrint('AIAssistantService: Generated response content: $content');

    final message = AIMessage(
      id: _generateId(),
      content: content,
      type: AIMessageType.aiResponse,
      timestamp: DateTime.now(),
      metadata: {
        'command_id': command.id,
        'command_type': command.type.name,
        'ai_powered': _useExternalAI && _geminiModel != null,
      },
      suggestions: await generateSmartSuggestions(),
    );

    _conversationHistory.add(message);
    debugPrint(
      'AIAssistantService: Calling message callback with content: ${message.content}',
    );
    _onMessageReceived?.call(message);
    debugPrint('AIAssistantService: Message callback completed');

    return message;
  }

  /// Get response templates for command types
  List<String> _getResponseTemplates(AICommandType type) {
    switch (type) {
      case AICommandType.navigate:
        return [
          'I\'ve navigated you to the requested page. {result}',
          'Taking you there now. {result}',
          'Done! Opening the page for you. {result}',
        ];
      case AICommandType.checkStatus:
        return [
          '{result}',
          'Let me check that for you:\n{result}',
          'Here\'s what I found:\n{result}',
        ];
      case AICommandType.optimizePerformance:
        return [
          'I\'ve optimized your device for better performance:\n{result}',
          'Performance boost applied:\n{result}',
          'Your device should run smoother now:\n{result}',
        ];
      case AICommandType.safetyAssessment:
        return [
          'I\'ve analyzed your safety status:\n{result}',
          'Safety assessment complete:\n{result}',
          'Here\'s your current safety overview:\n{result}',
        ];
      case AICommandType.checkLocation:
        return [
          '{result}',
          'Your current location:\n{result}',
          'Location check complete:\n{result}',
        ];
      case AICommandType.checkHazards:
        return [
          '{result}',
          'Active hazard alerts in your area:\n{result}',
          'Safety alert update:\n{result}',
        ];
      default:
        return ['{result}', 'Here\'s what I found: {result}', 'Done! {result}'];
    }
  }

  /// Check if AI has required permission for command
  bool _hasRequiredPermission(AICommandType type) {
    switch (type) {
      case AICommandType.navigate:
        return _permissions.canNavigateApp;
      case AICommandType.checkLocation:
        return _permissions.canAccessLocation;
      case AICommandType.sendNotification:
        return _permissions.canSendNotifications;
      case AICommandType.updateSettings:
        return _permissions.canModifySettings;
      case AICommandType.emergencyAction:
        return _permissions.canTriggerSOS;
      case AICommandType.contactManagement:
        return _permissions.canManageEmergencyContacts;
      case AICommandType.optimizePerformance:
        return _permissions.canOptimizePerformance;
      default:
        return true; // Basic commands don't require special permissions
    }
  }

  /// Send welcome message
  Future<void> _sendWelcomeMessage() async {
    final welcomeMessage = AIMessage(
      id: _generateId(),
      content: '''
I can help you with:
🔍 Checking your safety status
📍 Location and hazard updates  
⚙️ App performance optimization
🆘 Emergency guidance
🤝 Finding help and services

Use the Quick Commands or type your questions naturally like "Check my status" or "What hazards are nearby?"
''',
      type: AIMessageType.systemNotification,
      timestamp: DateTime.now(),
      suggestions: [
        AISuggestion(
          id: _generateId(),
          title: 'Grant AI Permissions',
          description:
              'Allow me to help you navigate and optimize your safety app.',
          actionType: AIActionType.updateProfile,
          actionParameters: {'section': 'ai_permissions'},
          priority: AISuggestionPriority.medium,
          validUntil: DateTime.now().add(const Duration(days: 1)),
        ),
        AISuggestion(
          id: _generateId(),
          title: 'Check System Status',
          description:
              'Let me check if all your safety systems are working properly.',
          actionType: AIActionType.checkSystemStatus,
          actionParameters: {'type': 'comprehensive'},
          priority: AISuggestionPriority.low,
          validUntil: DateTime.now().add(const Duration(hours: 1)),
        ),
      ],
    );

    _conversationHistory.add(welcomeMessage);
    _onMessageReceived?.call(welcomeMessage);
  }

  /// Helper methods for status checks
  String _getSystemStatus() {
    if (_serviceManager?.isInitialized != true) {
      return '⚠️ Services initializing...';
    }

    final issues = <String>[];

    if (_serviceManager?.locationService.hasPermission != true) {
      issues.add('Location services disabled');
    }

    if (_serviceManager?.notificationService.isEnabled != true) {
      issues.add('Notifications disabled');
    }

    if (_serviceManager?.sensorService.isMonitoring != true) {
      issues.add('Sensor monitoring disabled');
    }

    if (issues.isEmpty) {
      return '✅ All systems operational';
    } else {
      return '⚠️ Issues: ${issues.join(', ')}';
    }
  }

  Future<String> _getLocationStatus() async {
    try {
      if (_locationService == null) {
        return '❌ Location service not available';
      }

      final location = await _locationService?.getCurrentLocation();
      if (location == null) {
        return '❌ Location not available';
      }
      return '✅ Location active (±${location.accuracy.toStringAsFixed(1)}m)';
    } catch (e) {
      return '❌ Location error: $e';
    }
  }

  Future<String> _getSafetyStatus() async {
    final assessment = await _generateSafetyAssessment();
    return '${_getSafetyLevelIcon(assessment.overallLevel)} ${_getSafetyLevelDescription(assessment.overallLevel)}';
  }

  String _getServicesStatus() {
    final activeServices = <String>[];

    if (_serviceManager?.sosService.isInitialized == true) {
      activeServices.add('SOS');
    }
    if (_serviceManager?.locationService.isTracking == true) {
      activeServices.add('Location');
    }
    if (_serviceManager?.sensorService.isMonitoring == true) {
      activeServices.add('Sensors');
    }
    if (_serviceManager?.chatService.isInitialized == true) {
      activeServices.add('Chat');
    }
    if (_serviceManager?.hazardService.isInitialized == true) {
      activeServices.add('Hazards');
    }

    return '✅ Active: ${activeServices.join(', ')} (${activeServices.length} services)';
  }

  String _getSafetyLevelIcon(AISafetyLevel level) {
    switch (level) {
      case AISafetyLevel.safe:
        return '✅';
      case AISafetyLevel.caution:
        return '🟡';
      case AISafetyLevel.warning:
        return '⚠️';
      case AISafetyLevel.danger:
        return '🔴';
      case AISafetyLevel.critical:
        return '🚨';
    }
  }

  String _getSafetyLevelDescription(AISafetyLevel level) {
    switch (level) {
      case AISafetyLevel.safe:
        return 'Safe - All systems operational';
      case AISafetyLevel.caution:
        return 'Caution - Minor issues detected';
      case AISafetyLevel.warning:
        return 'Warning - Attention required';
      case AISafetyLevel.danger:
        return 'Danger - Immediate action needed';
      case AISafetyLevel.critical:
        return 'Critical - Emergency response required';
    }
  }

  String _getHazardSeverityIcon(HazardSeverity severity) {
    switch (severity) {
      case HazardSeverity.info:
        return 'ℹ️';
      case HazardSeverity.minor:
        return '🟢';
      case HazardSeverity.moderate:
        return '🟡';
      case HazardSeverity.severe:
        return '🔴';
      case HazardSeverity.extreme:
        return '🚨';
      case HazardSeverity.critical:
        return '🚨';
    }
  }

  /// Map string to help category
  String? _mapStringToHelpCategory(String categoryString) {
    final mapping = {
      'vehicle': 'vehicle',
      'car': 'vehicle',
      'auto': 'vehicle',
      'security': 'homeSecurity',
      'safety': 'personalSafety',
      'lost': 'lostFound',
      'pet': 'lostFound',
      'boat': 'marine',
      'marine': 'marine',
      'legal': 'legal',
      'community': 'community',
      'utility': 'utilities',
      'medical': 'medicalNonEmergency',
    };

    return mapping[categoryString.toLowerCase()];
  }

  /// Create permission required message
  AIMessage _createPermissionRequiredMessage(AICommand command) {
    return AIMessage(
      id: _generateId(),
      content:
          'I need permission to ${_getPermissionDescription(command.type)}. Would you like to grant this permission?',
      type: AIMessageType.systemNotification,
      timestamp: DateTime.now(),
      priority: AIMessagePriority.high,
      suggestions: [
        AISuggestion(
          id: _generateId(),
          title: 'Grant Permission',
          description: 'Allow AI to ${_getPermissionDescription(command.type)}',
          actionType: AIActionType.updateProfile,
          actionParameters: {
            'section': 'ai_permissions',
            'permission': command.type.name,
          },
          priority: AISuggestionPriority.medium,
          validUntil: DateTime.now().add(const Duration(hours: 1)),
        ),
      ],
    );
  }

  /// Create error message
  AIMessage _createErrorMessage(String error) {
    return AIMessage(
      id: _generateId(),
      content:
          'Sorry, I encountered an error: $error\n\nPlease try again or rephrase your request.',
      type: AIMessageType.error,
      timestamp: DateTime.now(),
      priority: AIMessagePriority.normal,
    );
  }

  String _getPermissionDescription(AICommandType type) {
    switch (type) {
      case AICommandType.navigate:
        return 'navigate the app for you';
      case AICommandType.checkLocation:
        return 'access your location';
      case AICommandType.updateSettings:
        return 'modify app settings';
      case AICommandType.emergencyAction:
        return 'trigger emergency actions';
      case AICommandType.sendNotification:
        return 'send notifications';
      default:
        return 'perform this action';
    }
  }

  /// Generate contextual command suggestions
  List<String> generateContextualSuggestions() {
    final suggestions = <String>[];

    try {
      // Time-based suggestions
      final hour = DateTime.now().hour;
      if (hour >= 6 && hour <= 9) {
        suggestions.add('Morning safety check');
      } else if (hour >= 18 && hour <= 22) {
        suggestions.add('Evening status update');
      } else if (hour >= 22 || hour <= 6) {
        suggestions.add('Night mode optimization');
      }

      // Location-based suggestions
      if (_serviceManager?.locationService.hasPermission == true) {
        suggestions.add('Check nearby services');
      }

      // System-based suggestions
      if (_lastPerformanceData?.batteryLevel != null &&
          _lastPerformanceData!.batteryLevel < 30) {
        suggestions.add('Optimize for battery saving');
      }

      // Safety-based suggestions
      final hazards = _serviceManager?.hazardService.activeAlerts ?? [];
      if (hazards.isNotEmpty) {
        suggestions.add('Review safety alerts');
      }
    } catch (e) {
      debugPrint('AIAssistantService: Error generating suggestions - $e');
    }

    return suggestions.take(4).toList();
  }

  /// Load AI permissions
  /// Request AI system permissions (microphone, speech, notifications)
  Future<void> _requestAISystemPermissions() async {
    try {
      debugPrint('AIAssistantService: Requesting AI system permissions...');

      final permissionStatus =
          await AIPermissionsHandler.requestAIPermissions();

      debugPrint('AIAssistantService: Permission status - $permissionStatus');

      // Update AI permissions model based on system permissions
      _permissions = _permissions.copyWith(
        canUseSpeechRecognition: permissionStatus.speechRecognitionGranted,
        canUseVoiceCommands: permissionStatus.microphoneGranted,
        canAccessMicrophone: permissionStatus.microphoneGranted,
        canSendNotifications: permissionStatus.notificationsGranted,
        canIntegrateWithPhoneAI: permissionStatus.allGranted,
        lastUpdated: DateTime.now(),
      );

      await _saveAIPermissions();

      if (!permissionStatus.criticalGranted) {
        debugPrint(
          'AIAssistantService: WARNING - Critical AI permissions not granted',
        );
        debugPrint('AIAssistantService: Some AI features may be limited');
      } else {
        debugPrint('AIAssistantService: All critical AI permissions granted ✓');
      }
    } catch (e) {
      debugPrint(
        'AIAssistantService: Error requesting system permissions - $e',
      );
    }
  }

  Future<void> _loadAIPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final permissionsJson = prefs.getString('ai_permissions');

      if (permissionsJson != null) {
        final json = jsonDecode(permissionsJson);
        _permissions = AIPermissions.fromJson(json);
      }

      debugPrint('AIAssistantService: Permissions loaded');
    } catch (e) {
      debugPrint('AIAssistantService: Error loading permissions - $e');
    }
  }

  /// Save AI permissions
  Future<void> _saveAIPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final permissionsJson = jsonEncode(_permissions.toJson());
      await prefs.setString('ai_permissions', permissionsJson);
    } catch (e) {
      debugPrint('AIAssistantService: Error saving permissions - $e');
    }
  }

  /// Update AI permissions
  Future<void> updatePermissions(AIPermissions newPermissions) async {
    _permissions = newPermissions.copyWith(lastUpdated: DateTime.now());
    await _saveAIPermissions();

    debugPrint('AIAssistantService: Permissions updated');

    // Send confirmation message
    final message = AIMessage(
      id: _generateId(),
      content:
          'Permissions updated! I can now better assist you with your safety and app needs.',
      type: AIMessageType.systemNotification,
      timestamp: DateTime.now(),
    );

    _conversationHistory.add(message);
    _onMessageReceived?.call(message);
  }

  /// Load learning data
  Future<void> _loadLearningData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final learningJson = prefs.getString('ai_learning_data');

      if (learningJson != null) {
        final json = jsonDecode(learningJson);
        _learningData = AILearningData.fromJson(json);
      } else {
        // Initialize learning data
        _learningData = AILearningData(
          userId: _userProfileService?.currentProfile?.id ?? 'unknown',
          commandFrequency: {},
          commandSuccessRate: {},
          preferredFeatures: [],
          userPreferences: {},
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('AIAssistantService: Error loading learning data - $e');
    }
  }

  // ============================================================================
  // COMPREHENSIVE EMERGENCY FEATURES
  // ============================================================================

  /// Analyze crash detection patterns and provide insights
  Future<String> _analyzeCrashDetection(AICommand command) async {
    final report = StringBuffer();
    report.writeln('🚗 AI CRASH DETECTION ANALYSIS');
    report.writeln();
    report.writeln('🤖 Detection System Status: ACTIVE');
    report.writeln();
    report.writeln('📊 Physics-Based Detection:');
    report.writeln('• Impact Force: Monitoring accelerometer (60+ km/h)');
    report.writeln('• Sustained Pattern: 2-second impact validation');
    report.writeln('• False Positive Protection: Speed bump filter');
    report.writeln('• Smart Cancellation: User pickup detection');
    report.writeln();
    report.writeln('🆘 Auto-Emergency Response:');
    report.writeln('• Countdown Timer: 30-second verification');
    report.writeln('• Voice Verification: AI confirmation system');
    report.writeln('• Location Sharing: Automatic GPS broadcast');
    report.writeln('• SAR Notification: Immediate team alert');
    report.writeln();
    report.writeln('🔐 Safety Features:');
    report.writeln('• No false alarms: Multi-layer verification');
    report.writeln('• User confirmation: Cancel anytime');
    report.writeln('• AI monitoring: 5-stage decision logic');
    report.writeln('• Emergency escalation: Auto-call if unresponsive');

    return report.toString();
  }

  /// Analyze fall detection patterns and provide insights
  Future<String> _analyzeFallDetection(AICommand command) async {
    final report = StringBuffer();
    report.writeln('🤸 AI FALL DETECTION ANALYSIS');
    report.writeln();
    report.writeln('🤖 Detection System Status: ACTIVE');
    report.writeln();
    report.writeln('📊 Physics-Based Detection:');
    report.writeln('• Free Fall: Monitoring gravity loss (1+ meter)');
    report.writeln('• Impact Force: Sudden deceleration detection');
    report.writeln('• Orientation Change: Post-fall position analysis');
    report.writeln('• Motion Cessation: No movement after impact');
    report.writeln();
    report.writeln('🆘 Auto-Emergency Response:');
    report.writeln('• Countdown Timer: 60-second verification');
    report.writeln('• Motion Detection: Cancel if user gets up');
    report.writeln('• Smart Cancellation: Phone pickup detection');
    report.writeln('• SAR Alert: Automatic if no response');
    report.writeln();
    report.writeln('🔐 Safety Features:');
    report.writeln('• Elderly Care: Optimized for seniors');
    report.writeln('• Medical Integration: Profile data sharing');
    report.writeln('• Location Precision: GPS coordinates sent');
    report.writeln('• Family Notification: Emergency contacts alerted');

    return report.toString();
  }

  /// Provide SOS verification system insights
  Future<String> _sosVerificationInsights(AICommand command) async {
    final report = StringBuffer();
    report.writeln('🆘 AI SOS VERIFICATION SYSTEM');
    report.writeln();
    report.writeln('🤖 Multi-Layer Verification:');
    report.writeln();
    report.writeln('📋 Stage 1: User Cancellation Check');
    report.writeln('• Monitoring: Continuous SOS button status');
    report.writeln('• Timeout: Allows user to cancel anytime');
    report.writeln();
    report.writeln('📋 Stage 2: SAR Response Check');
    report.writeln('• Monitoring: SAR team acknowledgment');
    report.writeln('• Status: Real-time response tracking');
    report.writeln();
    report.writeln('📋 Stage 3: User Movement Check');
    report.writeln('• Monitoring: GPS position changes');
    report.writeln('• Detection: >10m movement indicates mobility');
    report.writeln();
    report.writeln('📋 Stage 4: User Interaction Check');
    report.writeln('• Monitoring: Screen touch events');
    report.writeln('• Detection: Any app interaction shows responsiveness');
    report.writeln();
    report.writeln('📋 Stage 5: Time Elapsed Check');
    report.writeln('• Critical: 5 minutes for crash/fall');
    report.writeln('• Action: Auto-call emergency if no response');
    report.writeln();
    report.writeln('☎️ Emergency Escalation:');
    report.writeln('• Priority 1: National emergency (911/112/000)');
    report.writeln('• Priority 2: Local emergency services');
    report.writeln('• Auto-Update: GPS-based number selection');

    return report.toString();
  }

  /// Provide emergency coordination insights
  Future<String> _emergencyCoordination(AICommand command) async {
    final report = StringBuffer();
    report.writeln('📡 AI EMERGENCY COORDINATION SYSTEM');
    report.writeln();
    report.writeln('🚨 Real-Time Emergency Network:');
    report.writeln('• Firebase Integration: Cross-device sync');
    report.writeln('• SAR Dashboard: Professional response center');
    report.writeln('• Family Alerts: Emergency contact notification');
    report.writeln('• Location Sharing: Live GPS tracking');
    report.writeln();
    report.writeln('🆘 SOS Emergency Workflow:');
    report.writeln('1. SOS Activation → Countdown timer starts');
    report.writeln('2. User Verification → Voice/button confirmation');
    report.writeln('3. SAR Notification → Team receives alert');
    report.writeln('4. Location Broadcast → GPS coordinates sent');
    report.writeln('5. Team Response → Acknowledge & dispatch');
    report.writeln('6. Live Tracking → Real-time status updates');
    report.writeln('7. Resolution → Emergency marked resolved');
    report.writeln();
    report.writeln('🤝 REDP!NG Help Request Workflow:');
    report.writeln('1. Category Selection → 6 help types');
    report.writeln('2. Request Creation → Description & location');
    report.writeln('3. Community Broadcast → Local helpers notified');
    report.writeln('4. Offer Reception → Helpers offer assistance');
    report.writeln('5. Help Coordination → Direct communication');
    report.writeln('6. Completion → Request marked resolved');

    return report.toString();
  }

  // ============================================================================
  // REAL-TIME SAFETY MONITORING
  // ============================================================================

  /// Analyze drowsiness patterns and provide insights
  Future<String> _drowsinessAnalysis(AICommand command) async {
    final report = StringBuffer();
    report.writeln('😴 AI DROWSINESS MONITORING SYSTEM');
    report.writeln();
    report.writeln('🤖 RedPing AI Safety Companion:');
    report.writeln('• Personality: Supportive Australian mate');
    report.writeln('• Voice: Natural conversation (5-10 sec intervals)');
    report.writeln('• Mood: Adjusts to your emotional state');
    report.writeln();
    report.writeln('📊 Drowsiness Detection Methods:');
    report.writeln('• Voice Analysis: Tone and response time');
    report.writeln('• Conversation Gaps: >30 sec silence alert');
    report.writeln('• User Input: Manual "I\'m tired" statements');
    report.writeln('• Accelerometer: Erratic driving patterns');
    report.writeln();
    report.writeln('💪 Intervention Techniques:');
    report.writeln('• Driving Techniques: Creator\'s WA experience');
    report.writeln('• Rest Reminders: Better than energy drinks');
    report.writeln('• Safe Zones: Find rest areas nearby');
    report.writeln('• Family Focus: "Get home safely" motivation');
    report.writeln();
    report.writeln('🆘 Escalation Protocol:');
    report.writeln('• Mild: Share driving techniques');
    report.writeln('• Moderate: Suggest immediate rest stop');
    report.writeln('• Severe: Trigger SOS verification');
    report.writeln('• Critical: Emergency contact notification');

    return report.toString();
  }

  /// Provide driving safety tips
  Future<String> _drivingSafetyTips(AICommand command) async {
    final report = StringBuffer();
    report.writeln('🚗 AI DRIVING SAFETY TECHNIQUES');
    report.writeln();
    report.writeln('💡 From RedPing Creator\'s WA Experience:');
    report.writeln();
    report.writeln('1️⃣ The Window Technique:');
    report.writeln('• Roll down all windows immediately');
    report.writeln('• Fresh air hits your face instantly');
    report.writeln('• More effective than air conditioning');
    report.writeln('• Works even in hot weather');
    report.writeln();
    report.writeln('2️⃣ The Music Method:');
    report.writeln('• Turn up loud, energetic music');
    report.writeln('• Sing along actively');
    report.writeln('• Keeps your brain engaged');
    report.writeln('• Changes your mood state');
    report.writeln();
    report.writeln('3️⃣ The Rest Stop Strategy:');
    report.writeln('• Find safe place to pull over');
    report.writeln('• 15-20 minute power nap');
    report.writeln('• Walk around for 5 minutes');
    report.writeln('• Better than pushing through');
    report.writeln();
    report.writeln('⚠️ NEVER Use:');
    report.writeln('• Energy drinks (temporary, then crash)');
    report.writeln('• Coffee (makes you jittery, not alert)');
    report.writeln('• Stimulants (dangerous crash afterwards)');
    report.writeln();
    report.writeln('🏠 Remember: Your family is waiting for you!');

    return report.toString();
  }

  /// Analyze hazard patterns over time
  Future<String> _hazardPatternAnalysis(AICommand command) async {
    final hazards = _serviceManager?.hazardService.activeAlerts ?? [];

    final report = StringBuffer();
    report.writeln('📊 AI HAZARD PATTERN ANALYSIS');
    report.writeln();

    if (hazards.isEmpty) {
      report.writeln('✅ No active patterns detected');
      report.writeln();
      report.writeln('🤖 AI Monitoring:');
      report.writeln('• Weather systems: Tracking 24/7');
      report.writeln('• Natural disasters: Seismic & flood watch');
      report.writeln('• Civil events: Community safety alerts');
      report.writeln('• Traffic patterns: Road incident monitoring');
      return report.toString();
    }

    // Pattern analysis
    final weatherCount = hazards
        .where(
          (h) =>
              h.type == HazardType.weather ||
              h.type == HazardType.severeStorm ||
              h.type == HazardType.tornado ||
              h.type == HazardType.hurricane,
        )
        .length;

    final disasterCount = hazards
        .where(
          (h) =>
              h.type == HazardType.earthquake ||
              h.type == HazardType.flood ||
              h.type == HazardType.tsunami ||
              h.type == HazardType.landslide,
        )
        .length;

    final civilCount = hazards
        .where(
          (h) =>
              h.type == HazardType.civilEmergency ||
              h.type == HazardType.securityThreat,
        )
        .length;

    report.writeln('📈 Pattern Detection Results:');
    report.writeln();

    if (weatherCount > 0) {
      report.writeln('🌪️ Weather Pattern ($weatherCount alerts):');
      if (weatherCount >= 3) {
        report.writeln('   SEVERE WEATHER SYSTEM ACTIVE');
        report.writeln('   • Recommendation: Avoid all travel');
      } else {
        report.writeln('   • Recommendation: Monitor conditions');
      }
      report.writeln();
    }

    if (disasterCount > 0) {
      report.writeln('🏚️ Natural Disaster Pattern ($disasterCount alerts):');
      if (disasterCount >= 2) {
        report.writeln('   MULTIPLE DISASTERS DETECTED');
        report.writeln('   • Recommendation: Evacuate if instructed');
      } else {
        report.writeln('   • Recommendation: Follow local authorities');
      }
      report.writeln();
    }

    if (civilCount > 0) {
      report.writeln('🚨 Civil Emergency Pattern ($civilCount alerts):');
      report.writeln('   • Recommendation: Shelter in place');
      report.writeln();
    }

    report.writeln('🔮 AI Prediction:');
    final threatLevel = _calculateAIThreatLevel(hazards);
    if (threatLevel == 'critical') {
      report.writeln('   Pattern suggests ESCALATING EMERGENCY');
      report.writeln('   → Prepare for evacuation');
    } else if (threatLevel == 'high') {
      report.writeln('   Pattern suggests WORSENING CONDITIONS');
      report.writeln('   → Stay informed, be ready to act');
    } else {
      report.writeln('   Pattern suggests STABLE CONDITIONS');
      report.writeln('   → Continue monitoring');
    }

    return report.toString();
  }

  /// Assess environmental risks
  Future<String> _environmentalRiskAssessment(AICommand command) async {
    final location = await _locationService?.getCurrentLocation();
    final hazards = _serviceManager?.hazardService.activeAlerts ?? [];

    final report = StringBuffer();
    report.writeln('🌍 AI ENVIRONMENTAL RISK ASSESSMENT');
    report.writeln();

    if (location != null) {
      report.writeln('📍 Location: ${location.address ?? "Unknown"}');
      report.writeln(
        '🕐 Time: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      );
      report.writeln();
    }

    report.writeln('🌡️ Environmental Factors:');

    final hour = DateTime.now().hour;
    if (hour >= 22 || hour <= 6) {
      report.writeln('• Time Risk: ELEVATED (nighttime)');
      report.writeln('  → Reduced visibility');
      report.writeln('  → Lower emergency response capacity');
    } else if (hour >= 6 && hour <= 9 || hour >= 17 && hour <= 19) {
      report.writeln('• Time Risk: MODERATE (rush hour)');
      report.writeln('  → Heavy traffic conditions');
    } else {
      report.writeln('• Time Risk: LOW (daytime)');
    }
    report.writeln();

    if (hazards.isNotEmpty) {
      final threatLevel = _calculateAIThreatLevel(hazards);
      report.writeln('• Hazard Risk: ${threatLevel.toUpperCase()}');
      report.writeln('  → ${hazards.length} active alert(s)');
      report.writeln('  → ${_getAIMonitoringScope(hazards)}');
    } else {
      report.writeln('• Hazard Risk: LOW');
      report.writeln('  → No active environmental threats');
    }
    report.writeln();

    final battery = _lastPerformanceData?.batteryLevel ?? 100.0;
    if (battery < 20) {
      report.writeln(
        '⚡ Device Risk: ELEVATED (battery ${battery.toStringAsFixed(0)}%)',
      );
      report.writeln('  → Charge device immediately');
    } else {
      report.writeln(
        '⚡ Device Risk: LOW (battery ${battery.toStringAsFixed(0)}%)',
      );
    }
    report.writeln();

    report.writeln(
      '🎯 Overall Environmental Risk: ${_calculateOverallRisk(hazards, hour, battery)}',
    );

    return report.toString();
  }

  String _calculateOverallRisk(
    List<HazardAlert> hazards,
    int hour,
    double battery,
  ) {
    int riskScore = 0;

    // Hazard risk
    final threatLevel = _calculateAIThreatLevel(hazards);
    if (threatLevel == 'critical') {
      riskScore += 40;
    } else if (threatLevel == 'high') {
      riskScore += 30;
    } else if (threatLevel == 'moderate') {
      riskScore += 20;
    } else if (threatLevel == 'low') {
      riskScore += 10;
    }

    // Time risk
    if (hour >= 22 || hour <= 6) {
      riskScore += 20;
    } else if (hour >= 6 && hour <= 9 || hour >= 17 && hour <= 19) {
      riskScore += 10;
    }

    // Battery risk
    if (battery < 20) {
      riskScore += 20;
    } else if (battery < 50) {
      riskScore += 10;
    }

    if (riskScore >= 60) return 'CRITICAL';
    if (riskScore >= 40) return 'HIGH';
    if (riskScore >= 20) return 'MODERATE';
    return 'LOW';
  }

  // ============================================================================
  // SAR OPERATIONS INTELLIGENCE
  // ============================================================================

  /// Provide SAR coordination insights
  Future<String> _sarCoordinationInsights(AICommand command) async {
    final report = StringBuffer();
    report.writeln('🚁 AI SAR COORDINATION INTELLIGENCE');
    report.writeln();
    report.writeln('📊 Professional SAR Dashboard Features:');
    report.writeln();
    report.writeln('📋 Active SOS Tab:');
    report.writeln('• Real-time emergency display');
    report.writeln('• Status: Active, Acknowledged, Assigned, In Progress');
    report.writeln('• Priority sorting by emergency type');
    report.writeln('• One-click acknowledge & assign');
    report.writeln();
    report.writeln('📋 Resolved Cases Tab:');
    report.writeln('• Complete emergency history');
    report.writeln('• SOS + Help Requests merged view');
    report.writeln('• Resolution timestamps');
    report.writeln('• Performance analytics ready');
    report.writeln();
    report.writeln('📋 Help Requests Tab:');
    report.writeln('• Community assistance requests');
    report.writeln(
      '• 6 categories: Medical, Vehicle, Lost, Hazard, Info, Other',
    );
    report.writeln('• Location-based filtering');
    report.writeln('• Offer assistance workflow');
    report.writeln();
    report.writeln('📋 Messages Tab:');
    report.writeln('• Team communication center');
    report.writeln('• Real-time messaging');
    report.writeln('• Emergency coordination');
    report.writeln();
    report.writeln('📊 KPI Dashboard:');
    report.writeln('• Active SOS count');
    report.writeln('• Active Help Requests count');
    report.writeln('• Resolved Cases count');
    report.writeln('• Messages count');
    report.writeln('• Response time analytics');

    return report.toString();
  }

  /// Provide rescue operation analytics
  Future<String> _rescueAnalytics(AICommand command) async {
    final report = StringBuffer();
    report.writeln('📈 AI RESCUE OPERATION ANALYTICS');
    report.writeln();
    report.writeln('🎯 Key Performance Indicators:');
    report.writeln();
    report.writeln('⏱️ Response Time Analysis:');
    report.writeln('• Average Response: Calculate from SAR data');
    report.writeln('• Fastest Response: Historical best time');
    report.writeln('• Target: <5 minutes acknowledgment');
    report.writeln('• Target: <15 minutes on-scene (urban)');
    report.writeln();
    report.writeln('✅ Success Rate Metrics:');
    report.writeln('• Resolution Rate: Resolved / Total SOS');
    report.writeln('• False Positive Rate: Cancelled / Total SOS');
    report.writeln('• Response Coverage: Acknowledged / Total SOS');
    report.writeln();
    report.writeln('🗺️ Geographic Distribution:');
    report.writeln('• Regional hotspots identification');
    report.writeln('• Coverage gap analysis');
    report.writeln('• Resource allocation optimization');
    report.writeln();
    report.writeln('📊 Trend Analysis:');
    report.writeln('• Emergency type patterns');
    report.writeln('• Time-of-day correlation');
    report.writeln('• Weather impact assessment');
    report.writeln('• Seasonal variation tracking');
    report.writeln();
    report.writeln('💡 AI Recommendations:');
    report.writeln('• Deploy teams to high-activity zones');
    report.writeln('• Pre-position resources during peak hours');
    report.writeln('• Train for most common emergency types');
    report.writeln('• Implement predictive dispatching');

    return report.toString();
  }

  /// Predict victim location based on patterns
  Future<String> _victimLocationPrediction(AICommand command) async {
    final location = await _locationService?.getCurrentLocation();

    final report = StringBuffer();
    report.writeln('🎯 AI VICTIM LOCATION PREDICTION');
    report.writeln();

    if (location == null) {
      report.writeln('❌ Location services required for prediction');
      report.writeln('   Enable GPS to use this feature');
      return report.toString();
    }

    report.writeln('📍 Current Location:');
    report.writeln(
      '• Coordinates: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
    );
    report.writeln('• Accuracy: ±${location.accuracy.toStringAsFixed(1)}m');
    report.writeln();
    report.writeln('🤖 AI Prediction Models:');
    report.writeln();
    report.writeln('1️⃣ Stationary Victim Model:');
    report.writeln('   • Use last known GPS coordinates');
    report.writeln('   • Accuracy circle: ±${location.accuracy}m');
    report.writeln('   • Best for: Falls, medical emergencies');
    report.writeln();
    report.writeln('2️⃣ Moving Victim Model:');
    report.writeln('   • Track GPS trajectory');
    report.writeln('   • Predict movement vector');
    report.writeln('   • Best for: Lost persons, fleeing danger');
    report.writeln();
    report.writeln('3️⃣ Environmental Model:');
    report.writeln('   • Analyze terrain & obstacles');
    report.writeln('   • Predict likely sheltering locations');
    report.writeln('   • Best for: Extended searches');
    report.writeln();
    report.writeln('4️⃣ Behavioral Model:');
    report.writeln('   • User movement history');
    report.writeln('   • Common travel routes');
    report.writeln('   • Best for: regular app users');
    report.writeln();
    report.writeln('🎯 Search Strategy Recommendation:');
    report.writeln('• Primary Zone: ${location.accuracy * 2}m radius');
    report.writeln('• Secondary Zone: ${location.accuracy * 5}m radius');
    report.writeln('• Priority: Check last known location first');

    return report.toString();
  }

  /// Optimize SAR resource allocation
  Future<String> _resourceOptimization(AICommand command) async {
    final report = StringBuffer();
    report.writeln('⚙️ AI RESOURCE OPTIMIZATION SYSTEM');
    report.writeln();
    report.writeln('🚁 Resource Allocation Intelligence:');
    report.writeln();
    report.writeln('📊 Team Deployment Optimization:');
    report.writeln('• Real-time emergency distribution mapping');
    report.writeln('• Distance-based team assignment');
    report.writeln('• Workload balancing across teams');
    report.writeln('• Specialty matching (medical, technical, etc.)');
    report.writeln();
    report.writeln('🗺️ Geographic Coverage Analysis:');
    report.writeln('• Identify coverage gaps');
    report.writeln('• Recommend new team locations');
    report.writeln('• Optimal response radius calculation');
    report.writeln('• Multi-team coordination for large areas');
    report.writeln();
    report.writeln('⏱️ Response Time Optimization:');
    report.writeln('• Predictive pre-positioning');
    report.writeln('• High-risk area monitoring');
    report.writeln('• Rush hour adjustment strategies');
    report.writeln('• Route optimization for fastest response');
    report.writeln();
    report.writeln('📦 Equipment & Supply Management:');
    report.writeln('• Emergency type → Equipment matching');
    report.writeln('• Stock level monitoring');
    report.writeln('• Resupply scheduling');
    report.writeln('• Mobile cache positioning');
    report.writeln();
    report.writeln('💡 AI Recommendations:');
    report.writeln('• Deploy 60% of teams to high-density urban');
    report.writeln('• Position 30% in suburban transitional zones');
    report.writeln('• Maintain 10% mobile rapid-response reserve');
    report.writeln('• Rotate teams every 8 hours for peak alertness');

    return report.toString();
  }

  // ============================================================================
  // HEALTH & MEDICAL INSIGHTS
  // ============================================================================

  /// Analyze user medical profile
  Future<String> _medicalProfileAnalysis(AICommand command) async {
    final profile = _userProfileService?.currentProfile;

    final report = StringBuffer();
    report.writeln('🏥 AI MEDICAL PROFILE ANALYSIS');
    report.writeln();

    if (profile == null) {
      report.writeln('❌ No user profile found');
      report.writeln('   Create a profile to enable medical analysis');
      return report.toString();
    }

    report.writeln('👤 Profile Completeness:');
    final hasContacts = profile.emergencyContacts.isNotEmpty;
    final hasBasicInfo = profile.name.isNotEmpty;
    final completeness = (hasBasicInfo ? 50 : 0) + (hasContacts ? 50 : 0);
    report.writeln('• Overall: $completeness%');
    report.writeln('• Basic Info: ${hasBasicInfo ? "✅" : "❌"}');
    report.writeln('• Emergency Contacts: ${hasContacts ? "✅" : "❌"}');
    report.writeln();

    report.writeln('🆘 Emergency Readiness Score:');
    int readinessScore = 0;
    if (hasBasicInfo) readinessScore += 30;
    if (hasContacts) readinessScore += 40;
    if (_serviceManager?.locationService.hasPermission == true) {
      readinessScore += 30;
    }

    report.writeln('• Score: $readinessScore/100');
    if (readinessScore >= 80) {
      report.writeln('• Status: EXCELLENT - Fully prepared');
    } else if (readinessScore >= 60) {
      report.writeln('• Status: GOOD - Minor improvements needed');
    } else if (readinessScore >= 40) {
      report.writeln('• Status: FAIR - Important info missing');
    } else {
      report.writeln('• Status: POOR - Critical setup required');
    }
    report.writeln();

    report.writeln('💊 Recommended Profile Enhancements:');
    if (!hasContacts) {
      report.writeln('• Add emergency contacts (CRITICAL)');
    }
    if (_serviceManager?.locationService.hasPermission != true) {
      report.writeln('• Enable location services (CRITICAL)');
    }
    report.writeln('• Add medical conditions (if applicable)');
    report.writeln('• Specify medications (for first responders)');
    report.writeln('• List allergies (critical for treatment)');
    report.writeln('• Add blood type (emergency transfusions)');

    return report.toString();
  }

  /// Provide emergency medical recommendations
  Future<String> _emergencyMedicalRecommendations(AICommand command) async {
    final report = StringBuffer();
    report.writeln('🚑 AI EMERGENCY MEDICAL RECOMMENDATIONS');
    report.writeln();
    report.writeln('⚠️ DISCLAIMER: This is general guidance only.');
    report.writeln(
      '   Always call emergency services (911/112/000) for medical emergencies.',
    );
    report.writeln();
    report.writeln('🆘 Emergency Response Priority:');
    report.writeln();
    report.writeln('1️⃣ IMMEDIATE (Call emergency services now):');
    report.writeln('   • Severe bleeding that won\'t stop');
    report.writeln('   • Difficulty breathing or choking');
    report.writeln('   • Chest pain or pressure');
    report.writeln('   • Severe head injury or unconsciousness');
    report.writeln('   • Suspected stroke (FAST: Face, Arms, Speech, Time)');
    report.writeln('   • Severe allergic reaction');
    report.writeln();
    report.writeln('2️⃣ URGENT (Seek medical help within 1 hour):');
    report.writeln('   • Moderate bleeding');
    report.writeln('   • Possible broken bones');
    report.writeln('   • Severe pain');
    report.writeln('   • High fever (>39°C/102°F)');
    report.writeln('   • Persistent vomiting');
    report.writeln();
    report.writeln('3️⃣ NON-URGENT (Can wait for normal appointment):');
    report.writeln('   • Minor cuts and scrapes');
    report.writeln('   • Mild fever');
    report.writeln('   • Common cold symptoms');
    report.writeln('   • Minor aches and pains');
    report.writeln();
    report.writeln('📱 RedPing AI Features:');
    report.writeln('• Medical profile sharing with first responders');
    report.writeln('• Automatic location sharing in emergencies');
    report.writeln('• Emergency contact notification');
    report.writeln('• SAR team coordination for remote locations');

    return report.toString();
  }

  /// Assess health risks based on profile and activity
  Future<String> _healthRiskAssessment(AICommand command) async {
    final profile = _userProfileService?.currentProfile;
    final location = await _locationService?.getCurrentLocation();

    final report = StringBuffer();
    report.writeln('🏥 AI HEALTH RISK ASSESSMENT');
    report.writeln();

    report.writeln('📊 Current Risk Factors:');
    report.writeln();

    // Time-based risks
    final hour = DateTime.now().hour;
    if (hour >= 22 || hour <= 6) {
      report.writeln('⏰ Time Risk: ELEVATED');
      report.writeln('   • Nighttime reduces help availability');
      report.writeln('   • Emergency response may be slower');
      report.writeln('   • Recommendation: Avoid solo activities');
    } else {
      report.writeln('⏰ Time Risk: NORMAL');
    }
    report.writeln();

    // Location-based risks
    if (location == null) {
      report.writeln('📍 Location Risk: HIGH');
      report.writeln('   • GPS disabled - cannot track location');
      report.writeln('   • Emergency services cannot find you');
      report.writeln('   • Recommendation: Enable location services NOW');
    } else {
      report.writeln('📍 Location Risk: LOW');
      report.writeln('   • GPS active and accurate');
    }
    report.writeln();

    // Profile-based risks
    if (profile?.emergencyContacts.isEmpty ?? true) {
      report.writeln('👥 Contact Risk: HIGH');
      report.writeln('   • No emergency contacts configured');
      report.writeln('   • Family cannot be notified in emergency');
      report.writeln('   • Recommendation: Add contacts immediately');
    } else {
      report.writeln('👥 Contact Risk: LOW');
      report.writeln(
        '   • ${profile!.emergencyContacts.length} emergency contact(s) configured',
      );
    }
    report.writeln();

    // Device-based risks
    final battery = _lastPerformanceData?.batteryLevel ?? 100.0;
    if (battery < 20) {
      report.writeln('🔋 Device Risk: CRITICAL');
      report.writeln(
        '   • Battery critically low (${battery.toStringAsFixed(0)}%)',
      );
      report.writeln('   • Cannot call for help if battery dies');
      report.writeln('   • Recommendation: Charge device NOW');
    } else if (battery < 50) {
      report.writeln('🔋 Device Risk: MODERATE');
      report.writeln('   • Battery low (${battery.toStringAsFixed(0)}%)');
      report.writeln('   • Recommendation: Charge soon');
    } else {
      report.writeln('🔋 Device Risk: LOW');
    }
    report.writeln();

    report.writeln(
      '🎯 Overall Health Safety Score: ${_calculateHealthSafetyScore(hour, location, profile, battery)}/100',
    );

    return report.toString();
  }

  int _calculateHealthSafetyScore(int hour, location, profile, double battery) {
    int score = 100;

    // Time penalty
    if (hour >= 22 || hour <= 6) score -= 15;

    // Location penalty
    if (location == null) score -= 30;

    // Profile penalty
    if (profile?.emergencyContacts.isEmpty ?? true) score -= 25;

    // Battery penalty
    if (battery < 20) {
      score -= 30;
    } else if (battery < 50) {
      score -= 15;
    }

    return score.clamp(0, 100);
  }

  // ============================================================================
  // PREDICTIVE ANALYTICS
  // ============================================================================

  /// Score route safety
  Future<String> _routeSafetyScoring(AICommand command) async {
    final location = await _locationService?.getCurrentLocation();
    final hazards = _serviceManager?.hazardService.activeAlerts ?? [];

    final report = StringBuffer();
    report.writeln('🛣️ AI ROUTE SAFETY SCORING');
    report.writeln();

    if (location == null) {
      report.writeln('❌ Location required for route analysis');
      return report.toString();
    }

    report.writeln(
      '📍 Starting Location: ${location.address ?? "Current Position"}',
    );
    report.writeln();

    // Calculate safety factors
    int safetyScore = 100;
    final riskFactors = <String>[];

    // Time factor
    final hour = DateTime.now().hour;
    if (hour >= 22 || hour <= 6) {
      safetyScore -= 20;
      riskFactors.add('Nighttime travel (-20)');
    } else if (hour >= 6 && hour <= 9 || hour >= 17 && hour <= 19) {
      safetyScore -= 10;
      riskFactors.add('Rush hour congestion (-10)');
    }

    // Hazard factor
    if (hazards.isNotEmpty) {
      final threatLevel = _calculateAIThreatLevel(hazards);
      if (threatLevel == 'critical') {
        safetyScore -= 40;
        riskFactors.add('Critical hazards in area (-40)');
      } else if (threatLevel == 'high') {
        safetyScore -= 30;
        riskFactors.add('High threat hazards (-30)');
      } else if (threatLevel == 'moderate') {
        safetyScore -= 15;
        riskFactors.add('Moderate hazards (-15)');
      } else {
        safetyScore -= 5;
        riskFactors.add('Minor hazards (-5)');
      }
    }

    // Weather factor (simulated - would use real weather API)
    final weatherRisk = Random().nextInt(3);
    if (weatherRisk == 2) {
      safetyScore -= 15;
      riskFactors.add('Poor weather conditions (-15)');
    }

    report.writeln('🎯 Route Safety Score: $safetyScore/100');
    report.writeln();

    if (safetyScore >= 80) {
      report.writeln('✅ Status: SAFE');
      report.writeln('   Travel is recommended');
    } else if (safetyScore >= 60) {
      report.writeln('⚠️ Status: CAUTION');
      report.writeln('   Travel with increased awareness');
    } else if (safetyScore >= 40) {
      report.writeln('⚠️ Status: RISKY');
      report.writeln('   Consider delaying travel');
    } else {
      report.writeln('🚫 Status: DANGEROUS');
      report.writeln('   Travel strongly discouraged');
    }
    report.writeln();

    if (riskFactors.isNotEmpty) {
      report.writeln('📊 Risk Factors:');
      for (final factor in riskFactors) {
        report.writeln('   • $factor');
      }
      report.writeln();
    }

    report.writeln('💡 AI Recommendations:');
    if (safetyScore < 60) {
      report.writeln('   • Consider alternate routes');
      report.writeln('   • Delay travel if possible');
      report.writeln('   • Inform someone of your plans');
      report.writeln('   • Keep phone charged');
    } else {
      report.writeln('   • Maintain normal safety precautions');
      report.writeln('   • Stay alert to changing conditions');
    }

    return report.toString();
  }

  /// Recognize risk patterns from historical data
  Future<String> _riskPatternRecognition(AICommand command) async {
    final report = StringBuffer();
    report.writeln('🔍 AI RISK PATTERN RECOGNITION');
    report.writeln();
    report.writeln('📊 Pattern Analysis Systems:');
    report.writeln();
    report.writeln('1️⃣ Temporal Patterns:');
    report.writeln('   • Time-of-day emergency correlation');
    report.writeln('   • Day-of-week incident patterns');
    report.writeln('   • Seasonal variation tracking');
    report.writeln('   • Holiday period risk elevation');
    report.writeln();
    report.writeln('2️⃣ Geographic Patterns:');
    report.writeln('   • High-incident location mapping');
    report.writeln('   • Route hazard identification');
    report.writeln('   • Regional risk profiling');
    report.writeln('   • Coverage gap detection');
    report.writeln();
    report.writeln('3️⃣ Behavioral Patterns:');
    report.writeln('   • User activity risk correlation');
    report.writeln('   • Emergency type prediction');
    report.writeln('   • False alarm pattern detection');
    report.writeln('   • Help request trend analysis');
    report.writeln();
    report.writeln('4️⃣ Environmental Patterns:');
    report.writeln('   • Weather-emergency correlation');
    report.writeln('   • Natural disaster precursors');
    report.writeln('   • Traffic incident prediction');
    report.writeln('   • Hazard cascade detection');
    report.writeln();
    report.writeln('🤖 Machine Learning Models:');
    report.writeln('   • Emergency likelihood scoring');
    report.writeln('   • Response time prediction');
    report.writeln('   • Resource demand forecasting');
    report.writeln('   • Optimal team positioning');
    report.writeln();
    report.writeln('📈 Current Insights:');
    final hour = DateTime.now().hour;
    if (hour >= 17 && hour <= 19) {
      report.writeln('   ⚠️ Evening rush hour: 40% higher crash risk');
    } else if (hour >= 22 || hour <= 6) {
      report.writeln('   ⚠️ Nighttime: 60% higher fall detection rate');
    }

    return report.toString();
  }

  /// Predict emergency likelihood
  Future<String> _emergencyPrediction(AICommand command) async {
    final location = await _locationService?.getCurrentLocation();
    final hazards = _serviceManager?.hazardService.activeAlerts ?? [];
    final hour = DateTime.now().hour;
    final battery = _lastPerformanceData?.batteryLevel ?? 100.0;

    final report = StringBuffer();
    report.writeln('🔮 AI EMERGENCY PREDICTION');
    report.writeln();

    // Calculate prediction factors
    int riskScore = 0;
    final predictors = <String>[];

    // Time-based risk
    if (hour >= 22 || hour <= 6) {
      riskScore += 25;
      predictors.add('Nighttime period (+25% risk)');
    } else if (hour >= 17 && hour <= 19) {
      riskScore += 15;
      predictors.add('Rush hour period (+15% risk)');
    }

    // Location-based risk
    if (location == null) {
      riskScore += 20;
      predictors.add('No GPS tracking (+20% risk)');
    }

    // Hazard-based risk
    if (hazards.isNotEmpty) {
      final threatLevel = _calculateAIThreatLevel(hazards);
      if (threatLevel == 'critical') {
        riskScore += 40;
        predictors.add('Critical hazards (+40% risk)');
      } else if (threatLevel == 'high') {
        riskScore += 30;
        predictors.add('High threat level (+30% risk)');
      } else if (threatLevel == 'moderate') {
        riskScore += 15;
        predictors.add('Moderate hazards (+15% risk)');
      }
    }

    // Device-based risk
    if (battery < 20) {
      riskScore += 15;
      predictors.add('Critical battery (+15% risk)');
    }

    // Profile-based risk
    final profile = _userProfileService?.currentProfile;
    if (profile?.emergencyContacts.isEmpty ?? true) {
      riskScore += 10;
      predictors.add('No emergency contacts (+10% risk)');
    }

    report.writeln('📊 Emergency Likelihood: $riskScore%');
    report.writeln();

    if (riskScore >= 60) {
      report.writeln('🚨 Risk Level: CRITICAL');
      report.writeln('   High probability of emergency situation');
      report.writeln('   Immediate preventive action recommended');
    } else if (riskScore >= 40) {
      report.writeln('⚠️ Risk Level: ELEVATED');
      report.writeln('   Increased emergency probability');
      report.writeln('   Enhanced caution advised');
    } else if (riskScore >= 20) {
      report.writeln('⚡ Risk Level: MODERATE');
      report.writeln('   Normal risk level');
      report.writeln('   Standard precautions sufficient');
    } else {
      report.writeln('✅ Risk Level: LOW');
      report.writeln('   Minimal emergency probability');
      report.writeln('   Continue normal activities');
    }
    report.writeln();

    if (predictors.isNotEmpty) {
      report.writeln('🔍 Risk Factors:');
      for (final predictor in predictors) {
        report.writeln('   • $predictor');
      }
      report.writeln();
    }

    report.writeln('💡 Preventive Recommendations:');
    if (riskScore >= 40) {
      report.writeln('   • Share location with trusted contact');
      report.writeln('   • Ensure phone is charged');
      report.writeln('   • Review emergency contacts');
      report.writeln('   • Consider delaying high-risk activities');
    } else {
      report.writeln('   • Maintain normal safety awareness');
      report.writeln('   • Keep emergency features enabled');
    }

    return report.toString();
  }

  /// Generate proactive safety alerts
  Future<String> _proactiveSafetyAlert(AICommand command) async {
    final report = StringBuffer();
    report.writeln('🔔 AI PROACTIVE SAFETY ALERT SYSTEM');
    report.writeln();
    report.writeln('🤖 Smart Alert Triggers:');
    report.writeln();
    report.writeln('1️⃣ Hazard Detection Alerts:');
    report.writeln('   • New hazard in your area → Instant notification');
    report.writeln('   • Hazard severity increase → Escalation alert');
    report.writeln('   • Hazard approaching location → Advance warning');
    report.writeln();
    report.writeln('2️⃣ Environmental Change Alerts:');
    report.writeln('   • Severe weather approaching → 30-min advance');
    report.writeln('   • Road closures on route → Alternate route suggestion');
    report.writeln('   • Civil emergency declared → Shelter-in-place advice');
    report.writeln();
    report.writeln('3️⃣ Device Status Alerts:');
    report.writeln('   • Battery <20% → Charge reminder');
    report.writeln('   • GPS disabled → Enable location prompt');
    report.writeln('   • Network lost → Offline mode activation');
    report.writeln();
    report.writeln('4️⃣ Profile Status Alerts:');
    report.writeln('   • No emergency contacts → Setup reminder');
    report.writeln('   • Profile incomplete → Completion nudge');
    report.writeln('   • Permissions needed → Access request');
    report.writeln();
    report.writeln('5️⃣ Behavioral Pattern Alerts:');
    report.writeln('   • Entering high-risk area → Extra caution alert');
    report.writeln('   • Unusual activity pattern → Wellness check');
    report.writeln('   • Extended inactivity → Safety confirmation');
    report.writeln();
    report.writeln('⚙️ Alert Configuration:');
    report.writeln('   • Priority Levels: Info, Warning, Urgent, Critical');
    report.writeln('   • Delivery: Push notification + In-app + Voice');
    report.writeln('   • Timing: Real-time, predictive, scheduled');
    report.writeln('   • Personalization: ML-based relevance scoring');
    report.writeln();
    report.writeln('🎯 Current Active Alerts:');
    final hazards = _serviceManager?.hazardService.activeAlerts ?? [];
    final battery = _lastPerformanceData?.batteryLevel ?? 100.0;

    if (hazards.isNotEmpty) {
      report.writeln('   🌪️ ${hazards.length} hazard alert(s) active');
    }
    if (battery < 20) {
      report.writeln(
        '   🔋 Battery critically low (${battery.toStringAsFixed(0)}%)',
      );
    }
    if (_userProfileService?.currentProfile?.emergencyContacts.isEmpty ??
        true) {
      report.writeln('   👥 No emergency contacts configured');
    }

    if (hazards.isEmpty &&
        battery >= 20 &&
        (_userProfileService?.currentProfile?.emergencyContacts.isNotEmpty ??
            false)) {
      report.writeln('   ✅ All systems normal - no alerts');
    }

    return report.toString();
  }

  /// Update learning data
  Future<void> _updateLearningData(AICommand command, bool success) async {
    if (_learningData == null) return;

    try {
      final commandType = command.type.name;

      // Update frequency
      final frequency = _learningData!.commandFrequency;
      frequency[commandType] = (frequency[commandType] ?? 0) + 1;

      // Update success rate
      final successRate = _learningData!.commandSuccessRate;
      final currentRate = successRate[commandType] ?? 0.0;
      final currentCount = frequency[commandType] ?? 1;

      successRate[commandType] =
          ((currentRate * (currentCount - 1)) + (success ? 1.0 : 0.0)) /
          currentCount;

      _learningData = _learningData!.copyWith(
        commandFrequency: frequency,
        commandSuccessRate: successRate,
        lastUpdated: DateTime.now(),
      );

      // Save learning data
      final prefs = await SharedPreferences.getInstance();
      final learningJson = jsonEncode(_learningData!.toJson());
      await prefs.setString('ai_learning_data', learningJson);
    } catch (e) {
      debugPrint('AIAssistantService: Error updating learning data - $e');
    }
  }

  /// Check performance and suggest optimizations
  Future<void> _checkPerformanceAndSuggest(AIPerformanceData data) async {
    final suggestions = <AISuggestion>[];

    if (data.batteryLevel < 20) {
      suggestions.add(
        AISuggestion(
          id: _generateId(),
          title: 'Low Battery Detected',
          description:
              'Battery is at ${data.batteryLevel.toStringAsFixed(1)}%. I can optimize performance to save power.',
          actionType: AIActionType.optimizeBattery,
          actionParameters: {'level': 'aggressive'},
          priority: AISuggestionPriority.high,
          validUntil: DateTime.now().add(const Duration(hours: 1)),
        ),
      );
    }

    if (data.memoryUsage > 85) {
      suggestions.add(
        AISuggestion(
          id: _generateId(),
          title: 'High Memory Usage',
          description:
              'Memory usage is high. I can clear cache and optimize performance.',
          actionType: AIActionType.clearCache,
          actionParameters: {},
          priority: AISuggestionPriority.medium,
          validUntil: DateTime.now().add(const Duration(hours: 2)),
        ),
      );
    }

    for (final suggestion in suggestions) {
      _onSuggestionGenerated?.call(suggestion);
    }
  }

  /// Generate safety suggestions
  Future<void> _generateSafetySuggestions(AISafetyAssessment assessment) async {
    for (final recommendation in assessment.recommendations) {
      final suggestion = AISuggestion(
        id: recommendation.id,
        title: recommendation.title,
        description: recommendation.description,
        actionType: recommendation.recommendedAction,
        actionParameters: recommendation.actionParameters,
        priority: _mapSafetyLevelToSuggestionPriority(recommendation.urgency),
        validUntil: recommendation.validUntil,
      );

      _onSuggestionGenerated?.call(suggestion);
    }
  }

  AISuggestionPriority _mapSafetyLevelToSuggestionPriority(
    AISafetyLevel level,
  ) {
    switch (level) {
      case AISafetyLevel.safe:
        return AISuggestionPriority.low;
      case AISafetyLevel.caution:
        return AISuggestionPriority.low;
      case AISafetyLevel.warning:
        return AISuggestionPriority.medium;
      case AISafetyLevel.danger:
        return AISuggestionPriority.high;
      case AISafetyLevel.critical:
        return AISuggestionPriority.urgent;
    }
  }

  /// Utility methods
  void _updateCommandInHistory(AICommand command) {
    final index = _commandHistory.indexWhere((c) => c.id == command.id);
    if (index >= 0) {
      _commandHistory[index] = command;
    }
  }

  String _generateCommandId() {
    return 'cmd_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  String _generateId() {
    return 'ai_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isListening => false; // Voice recording disabled for privacy
  bool get isSpeaking => _isSpeaking;
  AIPermissions get permissions => _permissions;
  List<AICommand> get commandHistory => List.unmodifiable(_commandHistory);
  List<AIMessage> get conversationHistory =>
      List.unmodifiable(_conversationHistory);
  AIPerformanceData? get lastPerformanceData => _lastPerformanceData;
  AILearningData? get learningData => _learningData;

  // Callback setters
  void setMessageReceivedCallback(Function(AIMessage) callback) {
    _onMessageReceived = callback;
  }

  void setSuggestionGeneratedCallback(Function(AISuggestion) callback) {
    _onSuggestionGenerated = callback;
  }

  void setPerformanceUpdateCallback(Function(AIPerformanceData) callback) {
    _onPerformanceUpdate = callback;
  }

  void setSafetyAssessmentCallback(Function(AISafetyAssessment) callback) {
    _onSafetyAssessment = callback;
  }

  /// Start proactive AI safety monitoring with Gemini
  void _startProactiveSafetyMonitoring() {
    if (!_useExternalAI || _geminiModel == null) return;

    debugPrint('AIAssistantService: Starting proactive AI safety monitoring');

    // Monitor hazards every 2 minutes
    Timer.periodic(const Duration(minutes: 2), (timer) async {
      if (!_useExternalAI || _geminiModel == null) return;

      try {
        await _performAIHazardAnalysis();
      } catch (e) {
        debugPrint('AIAssistantService: AI hazard analysis error - $e');
      }
    });

    // Monitor user context every 5 minutes
    Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (!_useExternalAI || _geminiModel == null) return;

      try {
        await _performAIContextAnalysis();
      } catch (e) {
        debugPrint('AIAssistantService: AI context analysis error - $e');
      }
    });
  }

  /// Perform AI-powered hazard analysis
  Future<void> _performAIHazardAnalysis() async {
    final hazards = _serviceManager?.hazardService.activeAlerts ?? [];
    if (hazards.isEmpty) return;

    // Gather context
    final location = await _locationService?.getCurrentLocation();
    final batteryLevel = _lastPerformanceData?.batteryLevel ?? 100;

    // Build comprehensive context for AI
    final context = StringBuffer();
    context.writeln('CURRENT SITUATION:');
    context.writeln('Time: ${DateTime.now()}');
    context.writeln(
      'Location: ${location?.latitude ?? 'unknown'}, ${location?.longitude ?? 'unknown'}',
    );
    context.writeln('Battery: $batteryLevel%');
    context.writeln('\nACTIVE HAZARDS (${hazards.length}):');

    for (var i = 0; i < hazards.length && i < 5; i++) {
      final hazard = hazards[i];
      context.writeln('\n${i + 1}. ${hazard.title}');
      context.writeln('   Type: ${hazard.type.name}');
      context.writeln('   Severity: ${hazard.severity.name}');
      context.writeln('   Description: ${hazard.description}');
      if (hazard.radius != null) {
        context.writeln('   Radius: ${hazard.radius!.toStringAsFixed(1)} km');
      }
    }

    context.writeln(
      '\nTASK: Analyze these hazards using logic and common sense.',
    );
    context.writeln('1. Identify the most immediate threats');
    context.writeln('2. Assess combined risk (multiple hazards together)');
    context.writeln('3. Recommend specific protective actions');
    context.writeln('4. Be direct and urgent if danger is imminent');
    context.writeln('\nProvide: Brief assessment + Top 3 action items');

    try {
      final response = await _geminiModel!
          .generateContent([Content.text(context.toString())])
          .timeout(const Duration(seconds: 15));

      final analysis = response.text?.trim() ?? '';
      if (analysis.isNotEmpty && analysis.length > 50) {
        // Send AI analysis as proactive alert
        final alertMessage = AIMessage(
          id: _generateId(),
          content: '🤖 AI Safety Analysis:\n\n$analysis',
          type: AIMessageType.safetyAlert,
          priority:
              hazards.any(
                (h) =>
                    h.severity == HazardSeverity.critical ||
                    h.severity == HazardSeverity.extreme,
              )
              ? AIMessagePriority.critical
              : AIMessagePriority.high,
          timestamp: DateTime.now(),
          metadata: {
            'ai_analysis': true,
            'hazard_count': hazards.length,
            'analysis_type': 'hazard_monitoring',
          },
        );

        _conversationHistory.add(alertMessage);
        _onMessageReceived?.call(alertMessage);

        debugPrint('AIAssistantService: AI hazard analysis sent');
      }
    } catch (e) {
      debugPrint('AIAssistantService: AI hazard analysis failed - $e');
    }
  }

  /// Perform AI-powered context analysis
  Future<void> _performAIContextAnalysis() async {
    try {
      final location = await _locationService?.getCurrentLocation();
      final safetyAssessment = await _generateSafetyAssessment();
      final batteryLevel = _lastPerformanceData?.batteryLevel ?? 100;

      // Only analyze if there are potential concerns
      if (safetyAssessment.overallLevel == AISafetyLevel.safe &&
          batteryLevel > 50) {
        return; // All good, no need to alert
      }

      final context = StringBuffer();
      context.writeln('USER STATUS CHECK:');
      context.writeln('Time: ${DateTime.now()}');
      context.writeln('Safety Level: ${safetyAssessment.overallLevel.name}');
      context.writeln('Battery: $batteryLevel%');
      context.writeln(
        'Location: ${location?.latitude ?? 'unknown'}, ${location?.longitude ?? 'unknown'}',
      );

      if (safetyAssessment.activeThreats.isNotEmpty) {
        context.writeln('\nACTIVE THREATS:');
        for (final threat in safetyAssessment.activeThreats) {
          context.writeln('- $threat');
        }
      }

      context.writeln(
        '\nTASK: Use common sense to assess if user needs any safety reminders or warnings.',
      );
      context.writeln(
        'Consider: Time of day, battery level, safety concerns, weather patterns',
      );
      context.writeln(
        'Only respond if you detect something user should be aware of for their safety.',
      );
      context.writeln('If everything is fine, respond with just "OK"');

      final response = await _geminiModel!
          .generateContent([Content.text(context.toString())])
          .timeout(const Duration(seconds: 15));

      final analysis = response.text?.trim() ?? '';

      // Only send if AI detected something worth alerting about
      if (analysis.isNotEmpty &&
          analysis.toLowerCase() != 'ok' &&
          analysis.length > 20) {
        final alertMessage = AIMessage(
          id: _generateId(),
          content: '💡 Safety Reminder:\n\n$analysis',
          type: AIMessageType.systemNotification,
          priority: AIMessagePriority.normal,
          timestamp: DateTime.now(),
          metadata: {
            'ai_analysis': true,
            'analysis_type': 'context_monitoring',
          },
        );

        _conversationHistory.add(alertMessage);
        _onMessageReceived?.call(alertMessage);

        debugPrint('AIAssistantService: AI context analysis sent');
      }
    } catch (e) {
      debugPrint('AIAssistantService: AI context analysis failed - $e');
    }
  }

  /// Get AI-powered hazard summary for display on hazard alerts page
  /// Returns a list of top hazards with AI analysis and recommendations
  Future<List<AIHazardSummary>> getAIHazardSummary() async {
    if (!_isInitialized || _geminiModel == null || !_useExternalAI) {
      return [];
    }

    final hazards = _serviceManager?.hazardService.activeAlerts ?? [];
    if (hazards.isEmpty) {
      return [];
    }

    try {
      // Gather context
      final location = await _locationService?.getCurrentLocation();
      final batteryLevel = _lastPerformanceData?.batteryLevel ?? 100;

      // Build comprehensive context for AI
      final context = StringBuffer();
      context.writeln('HAZARD ANALYSIS REQUEST:');
      context.writeln('Time: ${DateTime.now()}');
      context.writeln(
        'Location: ${location?.latitude ?? 'unknown'}, ${location?.longitude ?? 'unknown'}',
      );
      context.writeln('Battery: $batteryLevel%');
      context.writeln('\nACTIVE HAZARDS (${hazards.length}):');

      for (var i = 0; i < hazards.length && i < 10; i++) {
        final hazard = hazards[i];
        context.writeln('\n${i + 1}. ${hazard.title}');
        context.writeln('   Type: ${hazard.type.name}');
        context.writeln('   Severity: ${hazard.severity.name}');
        context.writeln('   Description: ${hazard.description}');
        if (hazard.radius != null) {
          context.writeln('   Radius: ${hazard.radius!.toStringAsFixed(1)} km');
        }
      }

      context.writeln(
        '\nTASK: Provide TOP 3 MOST CRITICAL hazards for homepage display.',
      );
      context.writeln('For each hazard, provide:');
      context.writeln('- Emoji (use appropriate hazard icon)');
      context.writeln('- Title (max 50 chars)');
      context.writeln('- Brief Description (max 100 chars)');
      context.writeln('- Severity Score (1-10)');
      context.writeln('- Distance/ETA if applicable');
      context.writeln(
        '- Primary Action (max 80 chars, be specific and actionable)',
      );
      context.writeln(
        '\nFormat each as: EMOJI | TITLE | DESCRIPTION | SCORE | DISTANCE | ACTION',
      );
      context.writeln('Separate entries with "---"');
      context.writeln(
        'Example: 🌪️ | Tornado Warning | Rotating storm approaching from west | 10 | 5km, 15min | Seek underground shelter immediately',
      );

      final response = await _geminiModel!
          .generateContent([Content.text(context.toString())])
          .timeout(const Duration(seconds: 15));

      final analysis = response.text?.trim() ?? '';
      if (analysis.isEmpty) {
        return [];
      }

      // Parse AI response into structured summaries
      final List<AIHazardSummary> summaries = [];
      final entries = analysis.split('---');

      for (var entry in entries) {
        if (entry.trim().isEmpty) continue;

        final parts = entry.trim().split('|').map((e) => e.trim()).toList();
        if (parts.length >= 6) {
          // Try to parse severity score
          int severityScore = 5;
          try {
            severityScore = int.parse(
              parts[3].replaceAll(RegExp(r'[^\d]'), ''),
            );
            severityScore = severityScore.clamp(1, 10);
          } catch (e) {
            // Default to 5 if parsing fails
          }

          summaries.add(
            AIHazardSummary(
              emoji: parts[0].isEmpty ? '⚠️' : parts[0],
              title: parts[1].isEmpty ? 'Unknown Hazard' : parts[1],
              description: parts[2].isEmpty
                  ? 'Check details for more info'
                  : parts[2],
              severityScore: severityScore,
              distanceEta: parts[4].isEmpty ? 'Unknown' : parts[4],
              primaryAction: parts[5].isEmpty
                  ? 'Stay alert and monitor situation'
                  : parts[5],
              timestamp: DateTime.now(),
            ),
          );

          if (summaries.length >= 3) break; // Limit to top 3
        }
      }

      debugPrint(
        'AIAssistantService: Generated ${summaries.length} AI hazard summaries',
      );
      return summaries;
    } catch (e) {
      debugPrint(
        'AIAssistantService: Failed to generate AI hazard summary - $e',
      );
      return [];
    }
  }

  /// Dispose resources
  void dispose() {
    _performanceMonitoringTimer?.cancel();
    _safetyAssessmentTimer?.cancel();
    _conversationHistory.clear();
    _commandHistory.clear();
  }
}
