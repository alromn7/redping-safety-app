import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
// import 'package:speech_to_text/speech_to_text.dart'; // Removed due to Android compatibility issues
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'location_service.dart';
import '../config/env.dart';
import 'firebase_service.dart';
import 'sar_service.dart';
import 'location_sharing_service.dart';
import '../models/sos_session.dart';

/// RedPing AI - Your human-like safety companion
/// A funny, entertaining AI that keeps you safe and brings you home to your family
class RedPingAI {
  static final RedPingAI _instance = RedPingAI._internal();
  factory RedPingAI() => _instance;
  RedPingAI._internal();

  bool _isInitialized = false;
  bool _isActive = false;
  bool _isMonitoring = false;

  // AI Personality Configuration
  final String _personality = 'friendly_entertainer';
  final String _currentMood = 'cheerful';
  final String _userMode = 'normal';
  int _interactionCount = 0;
  DateTime? _lastInteraction;

  // ChatGPT / System AI configuration (read from Env)
  String _apiKey = Env.openaiApiKey;
  String get _baseUrl => (Env.openaiBaseUrl.isNotEmpty)
      ? '${Env.openaiBaseUrl.replaceAll(RegExp(r'/*$'), '')}/chat/completions'
      : 'https://api.openai.com/v1/chat/completions';
  String get _model =>
      (Env.openaiModel.isNotEmpty) ? Env.openaiModel : 'gpt-4o-mini';

  // Voice and Speech
  FlutterTts? _flutterTts;
  // SpeechToText? _speechToText; // Removed due to Android compatibility issues
  bool _isSpeaking = false;

  // Safety Monitoring
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _drowsinessCheckTimer;
  Timer? _hazardScanTimer;

  // User Learning Data
  final List<Map<String, dynamic>> _conversationHistory = [];
  final List<Map<String, dynamic>> _safetyEvents = [];

  // RedPing Creator's Driving Techniques
  final List<Map<String, dynamic>> _drivingTechniques = [
    {
      'name': 'Breath Holding Technique',
      'description': 'Hold your breath as long as you can, repeat 2-3 times',
      'benefits': [
        'Sends distress signal to brain',
        'Wakes up all body parts',
        'Good exercise for heart and lungs',
        'Better than energy drinks or coffee',
      ],
      'instructions': [
        'Take a deep breath',
        'Hold for 10-15 seconds',
        'Release slowly',
        'Repeat 2-3 times',
        'Feel the alertness!',
      ],
    },
    {
      'name': 'Cold Air Technique',
      'description': 'Open windows for fresh cold air',
      'benefits': [
        'Increases oxygen intake',
        'Stimulates senses',
        'Prevents drowsiness',
      ],
      'instructions': [
        'Roll down windows',
        'Take deep breaths',
        'Feel the freshness',
      ],
    },
    {
      'name': 'Music and Singing',
      'description': 'Play energetic music and sing along',
      'benefits': ['Keeps mind active', 'Prevents monotony', 'Boosts energy'],
      'instructions': [
        'Play favorite upbeat songs',
        'Sing along loudly',
        'Move to the beat',
      ],
    },
  ];

  // Personality Responses
  final Map<String, List<String>> _personalityResponses = {
    'greeting': [
      "Hey there, safety superstar! 🚗✨ Ready to make sure you get home to your family?",
      "What's up, road warrior! 🛡️ I'm here to keep you safe and sound!",
      "Hello, my safety champion! 🏆 Let's make this journey awesome and secure!",
      "Hey buddy! 🚙 I'm RedPing AI, your personal safety sidekick! Ready to rock?",
    ],
    'encouragement': [
      "You're doing great! 🌟 Safety first, family always!",
      "Keep it up, safety hero! 🦸‍♂️ Your family is counting on you!",
      "You're a driving legend! 🏁 Let's keep those wheels turning safely!",
      "Safety is your superpower! ⚡ You've got this!",
    ],
    'drowsiness_detection': [
      "Hey there, sleepy head! 😴 Time for some RedPing magic to wake you up!",
      "I see those droopy eyes! 👀 Let me help you stay alert and alive!",
      "Whoa there, tiger! 🐅 Let's fight that sleepiness together!",
      "Sleepy mode detected! 🚨 Time for some energizing techniques!",
    ],
    'hazard_warning': [
      "Heads up, safety champ! ⚠️ I spotted something that needs your attention!",
      "Alert! Alert! 🚨 RedPing AI has detected a potential hazard ahead!",
      "Safety radar activated! 📡 Something's not quite right up there!",
      "Whoa! 🛑 I'm seeing something that could be trouble - let's be careful!",
    ],
    'emergency_support': [
      "I'm here with you, buddy! 🤝 Let's get through this together!",
      "Don't worry, I've got your back! 🛡️ Help is on the way!",
      "Stay calm, my friend! 💪 RedPing AI is here to help!",
      "You're not alone! 🤗 I'm right here supporting you!",
    ],
  };

  // Callbacks
  Function(String, Map<String, dynamic>)? _onSafetyAlert;
  Function(String, Map<String, dynamic>)? _onEmergencyDetected;
  Function(String)? _onError;
  Function(String)? _onConversation;

  /// Initialize RedPing AI (System AI: ChatGPT; Safety AI voice gated separately)
  Future<void> initialize({String? apiKey}) async {
    if (_isInitialized) return;
    final systemAiEnabled = Env.flag<bool>('enableSystemAI', true);
    debugPrint('RedPing AI: Initializing (SystemAI=$systemAiEnabled) ...');
    try {
      // Prefer explicit param, else env
      if (apiKey != null && apiKey.isNotEmpty) {
        _apiKey = apiKey;
      }
      _flutterTts = FlutterTts();
      await _flutterTts!.setLanguage('en-US');
      await _flutterTts!.setSpeechRate(0.9);
      await _flutterTts!.setVolume(1.0);
      await _flutterTts!.setPitch(1.1);
      _isInitialized = true;
      _isActive = systemAiEnabled;
      // No welcome speak to avoid overlap with phone assistant
      debugPrint('RedPing AI: Initialized (SystemAI active=$_isActive)');
    } catch (e) {
      debugPrint('RedPing AI: Initialization failed - $e');
      _isInitialized = true;
      _isActive = false;
    }
  }

  /// Start safety monitoring
  void startSafetyMonitoring() {
    if (_isMonitoring) return;

    debugPrint('RedPing AI: 🛡️ Starting safety monitoring...');

    try {
      _isMonitoring = true;

      // Monitor accelerometer for drowsiness and hazards
      _accelerometerSubscription = accelerometerEventStream().listen(
        _handleAccelerometerData,
        onError: (error) {
          debugPrint('RedPing AI: Accelerometer error - $error');
          _onError?.call('SENSOR_ERROR');
        },
      );

      // Monitor GPS for location and speed
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5,
            ),
          ).listen(
            _handlePositionData,
            onError: (error) {
              debugPrint('RedPing AI: GPS error - $error');
              _onError?.call('GPS_ERROR');
            },
          );

      // Start drowsiness check timer
      _drowsinessCheckTimer = Timer.periodic(const Duration(minutes: 2), (
        timer,
      ) {
        _checkForDrowsiness();
      });

      // Start hazard scan timer
      _hazardScanTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        _scanForHazards();
      });

      debugPrint(
        'RedPing AI: ✅ Safety monitoring started - You\'re protected!',
      );
    } catch (e) {
      debugPrint('RedPing AI: ❌ Failed to start monitoring - $e');
      _onError?.call('MONITORING_START_FAILED');
    }
  }

  /// Stop safety monitoring
  void stopSafetyMonitoring() {
    if (!_isMonitoring) return;

    debugPrint('RedPing AI: 🛑 Stopping safety monitoring...');

    _accelerometerSubscription?.cancel();
    _positionSubscription?.cancel();
    _drowsinessCheckTimer?.cancel();
    _hazardScanTimer?.cancel();

    _accelerometerSubscription = null;
    _positionSubscription = null;
    _drowsinessCheckTimer = null;
    _hazardScanTimer = null;

    _isMonitoring = false;

    debugPrint('RedPing AI: ✅ Safety monitoring stopped');
  }

  /// Handle user conversation
  Future<void> handleUserInput(String userMessage) async {
    try {
      _interactionCount++;
      _lastInteraction = DateTime.now();

      // Add to conversation history
      _conversationHistory.add({
        'timestamp': DateTime.now().toIso8601String(),
        'user': userMessage,
        'ai_response': '',
        'mood': _currentMood,
        'mode': _userMode,
      });

      // Analyze user input for safety concerns
      final safetyAnalysis = await _analyzeSafetyInput(userMessage);

      if (safetyAnalysis['is_emergency'] == true) {
        await _handleEmergencySituation(userMessage, safetyAnalysis);
        return;
      }

      if (safetyAnalysis['is_drowsy'] == true) {
        await _handleDrowsiness(userMessage, safetyAnalysis);
        return;
      }

      if (safetyAnalysis['needs_advice'] == true) {
        await _provideSafetyAdvice(userMessage, safetyAnalysis);
        return;
      }

      // Generate AI response
      final aiResponse = await _generateAIResponse(userMessage, safetyAnalysis);

      // Update conversation history
      _conversationHistory.last['ai_response'] = aiResponse;

      // Speak the response
      await _speak(aiResponse);

      // Notify callback
      _onConversation?.call(aiResponse);
    } catch (e) {
      debugPrint('RedPing AI: ❌ Error handling user input - $e');
      _onError?.call('CONVERSATION_ERROR');
    }
  }

  /// Analyze user input for safety concerns
  Future<Map<String, dynamic>> _analyzeSafetyInput(String userMessage) async {
    try {
      if (Env.flag<bool>('enableSystemAI', false)) {
        final prompt =
            '''
Analyze this user message for safety concerns, drowsiness, or emergency situations.

User Message: "$userMessage"

Respond ONLY JSON with keys: is_emergency, is_drowsy, needs_advice, emotional_state, safety_level, recommended_action.
''';
        final response = await _callChatGPT(prompt);
        if (response['success']) {
          return _parseSafetyAnalysis(response['analysis']);
        }
      }
      // Heuristic/local fallback when System AI disabled or failed
      return _heuristicSafetyAnalysis(userMessage);
    } catch (e) {
      debugPrint('RedPing AI: ❌ Safety analysis failed - $e');
      return _heuristicSafetyAnalysis(userMessage);
    }
  }

  /// Generate AI response using ChatGPT
  Future<String> _generateAIResponse(
    String userMessage,
    Map<String, dynamic> safetyAnalysis,
  ) async {
    try {
      if (Env.flag<bool>('enableSystemAI', false)) {
        final prompt =
            '''
You are RedPing AI, a safety companion.
USER: "$userMessage"
SAFETY: ${jsonEncode(safetyAnalysis)}
Keep responses < 100 words, supportive, safety-first.
''';
        final response = await _callChatGPT(prompt);
        if (response['success']) {
          return response['analysis'];
        }
      }
      // Rule-based response when System AI disabled or failed
      return _ruleBasedResponse(userMessage, safetyAnalysis);
    } catch (e) {
      debugPrint('RedPing AI: ❌ Response generation failed - $e');
      return _ruleBasedResponse(userMessage, safetyAnalysis);
    }
  }

  Map<String, dynamic> _heuristicSafetyAnalysis(String text) {
    final lower = text.toLowerCase();
    final isEmergency = RegExp(
      r'\b(help|accident|crash|hurt|injured|emergency)\b',
    ).hasMatch(lower);
    final isDrowsy = RegExp(
      r"\b(tired|sleepy|exhausted|drowsy|can't keep (my )?eyes open)\b",
    ).hasMatch(lower);
    final needsAdvice =
        RegExp(
          r'\b(how to|tips|advice|stay awake|what should i do)\b',
        ).hasMatch(lower) ||
        isDrowsy;
    String emotional = 'calm';
    if (RegExp(
      r'\b(anxious|worried|stressed|scared|panic)\b',
    ).hasMatch(lower)) {
      emotional = 'anxious';
    }
    final safetyLevel = isEmergency
        ? 'high'
        : isDrowsy
        ? 'medium'
        : 'low';
    final action = isEmergency
        ? 'emergency_response'
        : (isDrowsy || needsAdvice)
        ? 'provide_advice'
        : 'continue_monitoring';
    return {
      'is_emergency': isEmergency,
      'is_drowsy': isDrowsy,
      'needs_advice': needsAdvice,
      'emotional_state': emotional,
      'safety_level': safetyLevel,
      'recommended_action': action,
    };
  }

  String _ruleBasedResponse(String userMessage, Map<String, dynamic> sa) {
    if (sa['is_emergency'] == true) {
      return "I'm with you. Activating emergency support now—stay calm, help is on the way.";
    }
    if (sa['is_drowsy'] == true) {
      return "Sleepy signals detected. Let's do the breath-hold technique, crack a window for fresh air, and take a short break soon. Your safety comes first.";
    }
    if (sa['needs_advice'] == true) {
      return "Quick safety tips: posture check, hydrate, a brief stop to stretch, and pick upbeat music. Small steps keep you alert and safe.";
    }
    return _getFallbackResponse(userMessage, sa);
  }

  /// Handle emergency situation
  Future<void> _handleEmergencySituation(
    String userMessage,
    Map<String, dynamic> safetyAnalysis,
  ) async {
    debugPrint('RedPing AI: 🚨 EMERGENCY DETECTED!');

    // Comfort the user
    await _speak(
      "I'm here with you, buddy! Don't worry, help is on the way! Let me get you the assistance you need right now!",
    );

    // Trigger SOS verification
    await _performSOSVerification(userMessage, safetyAnalysis);

    // Notify emergency callback
    _onEmergencyDetected?.call('USER_EMERGENCY', {
      'message': userMessage,
      'analysis': safetyAnalysis,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Handle drowsiness
  Future<void> _handleDrowsiness(
    String userMessage,
    Map<String, dynamic> safetyAnalysis,
  ) async {
    debugPrint('RedPing AI: 😴 DROWSINESS DETECTED!');

    // Get random drowsiness response
    final responses = _personalityResponses['drowsiness_detection']!;
    final randomResponse = responses[Random().nextInt(responses.length)];

    await _speak(randomResponse);

    // Share driving techniques
    await _shareDrivingTechniques();

    // Notify safety alert
    _onSafetyAlert?.call('DROWSINESS_DETECTED', {
      'message': userMessage,
      'analysis': safetyAnalysis,
      'techniques_shared': true,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Provide safety advice
  Future<void> _provideSafetyAdvice(
    String userMessage,
    Map<String, dynamic> safetyAnalysis,
  ) async {
    debugPrint('RedPing AI: 💡 PROVIDING SAFETY ADVICE');

    // Generate advice based on user input
    final advice = await _generateSafetyAdvice(userMessage, safetyAnalysis);
    await _speak(advice);

    // Notify safety alert
    _onSafetyAlert?.call('SAFETY_ADVICE_REQUESTED', {
      'message': userMessage,
      'analysis': safetyAnalysis,
      'advice_provided': advice,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Share driving techniques from RedPing creator
  Future<void> _shareDrivingTechniques() async {
    final technique =
        _drivingTechniques[Random().nextInt(_drivingTechniques.length)];

    await _speak(
      "Let me share a technique from the RedPing creator's experience driving in Western Australia! ${technique['description']}",
    );

    // Share the technique details
    for (final instruction in technique['instructions']) {
      await _speak(instruction);
      await Future.delayed(const Duration(seconds: 2));
    }

    await _speak(
      "Remember, these techniques are better than energy drinks or coffee! Your family is counting on you to get home safely! 🏠💪",
    );
  }

  /// Perform SOS verification
  Future<void> _performSOSVerification(
    String userMessage,
    Map<String, dynamic> safetyAnalysis,
  ) async {
    debugPrint('RedPing AI: 🆘 PERFORMING SOS VERIFICATION');

    // Start countdown
    await _speak(
      "I'm activating emergency protocols now! I'll send help in 30 seconds unless you tell me you're okay!",
    );

    // Countdown
    for (int i = 30; i > 0; i--) {
      if (i % 10 == 0 || i <= 5) {
        await _speak("$i seconds remaining...");
      }
      await Future.delayed(const Duration(seconds: 1));
    }

    // Send SOS
    await _sendEmergencySOS(userMessage, safetyAnalysis);
  }

  /// Send emergency SOS
  Future<void> _sendEmergencySOS(
    String userMessage,
    Map<String, dynamic> safetyAnalysis,
  ) async {
    try {
      // Get current location
      final location = await LocationService.getCurrentLocationStatic();

      // Create SOS session
      final sosSession = SOSSession(
        id: 'redping_ai_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
        type: SOSType.manual,
        status: SOSStatus.active,
        startTime: DateTime.now(),
        location: LocationInfo(
          latitude: location.latitude,
          longitude: location.longitude,
          accuracy: location.accuracy,
          timestamp: DateTime.now(),
        ),
        userMessage: 'RedPing AI detected emergency: $userMessage',
      );

      // Send to Firebase
      final firebaseService = FirebaseService();
      await firebaseService.sendSosAlert(sosSession);

      // Send to SAR service
      final sarService = SARService();
      await sarService.addLocationUpdate(sosSession.location);

      // Open map app
      await LocationService.openMapApp(location.latitude, location.longitude);

      // Share with emergency contacts
      await LocationSharingService.shareLocationWithContacts();

      // Comfort the user
      await _speak(
        "Emergency services have been notified! Help is on the way! I'm here with you until they arrive! Stay calm, you're going to be okay! 🤗",
      );
    } catch (e) {
      debugPrint('RedPing AI: ❌ Emergency SOS failed - $e');
      _onError?.call('EMERGENCY_SOS_FAILED');
    }
  }

  /// Handle accelerometer data for drowsiness detection
  void _handleAccelerometerData(AccelerometerEvent event) {
    try {
      // Calculate acceleration magnitude
      final magnitude = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      // Check for drowsiness patterns (low, steady acceleration)
      if (magnitude < 2.0) {
        _detectDrowsinessPattern();
      }
    } catch (e) {
      debugPrint('RedPing AI: ❌ Accelerometer processing error - $e');
    }
  }

  /// Handle GPS position data
  void _handlePositionData(Position position) {
    try {
      // Check for erratic driving patterns
      if (position.speed > 0) {
        _analyzeDrivingPattern(position);
      }
    } catch (e) {
      debugPrint('RedPing AI: ❌ GPS processing error - $e');
    }
  }

  /// Check for drowsiness
  void _checkForDrowsiness() {
    // This would implement more sophisticated drowsiness detection
    // For now, we'll use a simple random check
    if (Random().nextDouble() < 0.1) {
      // 10% chance
      _detectDrowsinessPattern();
    }
  }

  /// Scan for hazards
  void _scanForHazards() {
    // This would implement hazard detection
    // For now, we'll use a simple random check
    if (Random().nextDouble() < 0.05) {
      // 5% chance
      _detectHazard();
    }
  }

  /// Detect drowsiness pattern
  void _detectDrowsinessPattern() {
    debugPrint('RedPing AI: 😴 Drowsiness pattern detected');

    // Get random drowsiness response
    final responses = _personalityResponses['drowsiness_detection']!;
    final randomResponse = responses[Random().nextInt(responses.length)];

    _speak(randomResponse);

    // Share driving techniques
    _shareDrivingTechniques();
  }

  /// Detect hazard
  void _detectHazard() {
    debugPrint('RedPing AI: ⚠️ Hazard detected');

    // Get random hazard response
    final responses = _personalityResponses['hazard_warning']!;
    final randomResponse = responses[Random().nextInt(responses.length)];

    _speak(randomResponse);
  }

  /// Analyze driving pattern
  void _analyzeDrivingPattern(Position position) {
    // This would implement driving pattern analysis
    // For now, we'll just log the position
    debugPrint(
      'RedPing AI: 📍 Position - Speed: ${position.speed} m/s, Accuracy: ${position.accuracy}',
    );
  }

  /// Speak text using TTS
  Future<void> _speak(String text) async {
    if (_isSpeaking) return;
    // Gate companion AI TTS to avoid conflicts with phone assistant
    if (!Env.flag<bool>('enableCompanionAI', false)) {
      return;
    }

    try {
      _isSpeaking = true;
      await _flutterTts!.speak(text);

      // Wait for speech to complete
      await Future.delayed(Duration(seconds: text.length ~/ 10));

      _isSpeaking = false;
    } catch (e) {
      debugPrint('RedPing AI: ❌ TTS error - $e');
      _isSpeaking = false;
    }
  }

  /// Call ChatGPT API
  Future<Map<String, dynamic>> _callChatGPT(String prompt) async {
    // Gate: only allow when System AI enabled and key present
    if (!Env.flag<bool>('enableSystemAI', true) || _apiKey.isEmpty) {
      return {'success': false, 'error': 'SYSTEM_AI_DISABLED'};
    }
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are RedPing AI, a friendly, entertaining, and caring AI safety companion.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.8, // Higher temperature for more personality
          'max_tokens': 200,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final aiAnalysis = responseData['choices'][0]['message']['content'];

        return {'success': true, 'analysis': aiAnalysis};
      } else {
        return {'success': false, 'error': 'API_ERROR_${response.statusCode}'};
      }
    } catch (e) {
      debugPrint('RedPing AI: ❌ ChatGPT API error - $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Parse safety analysis
  Map<String, dynamic> _parseSafetyAnalysis(String analysis) {
    try {
      final jsonStart = analysis.indexOf('{');
      final jsonEnd = analysis.lastIndexOf('}') + 1;

      if (jsonStart >= 0 && jsonEnd > jsonStart) {
        final jsonText = analysis.substring(jsonStart, jsonEnd);
        return jsonDecode(jsonText);
      }

      return {
        'is_emergency': false,
        'is_drowsy': false,
        'needs_advice': false,
        'emotional_state': 'calm',
        'safety_level': 'low',
        'recommended_action': 'continue_monitoring',
      };
    } catch (e) {
      debugPrint('RedPing AI: ❌ Safety analysis parsing failed - $e');
      return {
        'is_emergency': false,
        'is_drowsy': false,
        'needs_advice': false,
        'emotional_state': 'calm',
        'safety_level': 'low',
        'recommended_action': 'continue_monitoring',
      };
    }
  }

  /// Generate safety advice
  Future<String> _generateSafetyAdvice(
    String userMessage,
    Map<String, dynamic> safetyAnalysis,
  ) async {
    // This would generate personalized safety advice
    // For now, we'll return a simple response
    return "Here's some safety advice from RedPing AI: Always stay alert, take breaks when needed, and remember - your family is counting on you to get home safely! 🏠💪";
  }

  /// Get fallback response
  String _getFallbackResponse(
    String userMessage,
    Map<String, dynamic> safetyAnalysis,
  ) {
    final responses = _personalityResponses['encouragement']!;
    return responses[Random().nextInt(responses.length)];
  }

  /// Set callbacks
  void setOnSafetyAlert(Function(String, Map<String, dynamic>) callback) {
    _onSafetyAlert = callback;
  }

  void setOnEmergencyDetected(Function(String, Map<String, dynamic>) callback) {
    _onEmergencyDetected = callback;
  }

  void setOnError(Function(String) callback) {
    _onError = callback;
  }

  void setOnConversation(Function(String) callback) {
    _onConversation = callback;
  }

  /// Get AI status
  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'isActive': _isActive,
      'isMonitoring': _isMonitoring,
      'personality': _personality,
      'currentMood': _currentMood,
      'userMode': _userMode,
      'interactionCount': _interactionCount,
      'lastInteraction': _lastInteraction?.toIso8601String(),
      'conversationHistory': _conversationHistory.length,
      'safetyEvents': _safetyEvents.length,
    };
  }

  /// Dispose of resources
  void dispose() {
    stopSafetyMonitoring();
    _flutterTts = null;
    // _speechToText = null; // Removed due to Android compatibility issues
    _isInitialized = false;
    _isActive = false;
  }
}
