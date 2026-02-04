/// Phone AI Integration Service
/// Upgraded to provide real speech-to-text (STT) & text-to-speech (TTS) integration
/// while keeping a minimal, privacy-conscious command mapping. WebRTC remains disabled.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/env.dart';
import 'app_service_manager.dart';
import 'ai_assistant_service.dart';
import '../models/sos_session.dart';
import '../platform/phone_ai_channel.dart';
import 'voice_session_controller.dart';

class PhoneAIIntegrationService {
  static final PhoneAIIntegrationService _instance =
      PhoneAIIntegrationService._internal();
  factory PhoneAIIntegrationService() => _instance;
  PhoneAIIntegrationService._internal();

  // State
  bool _isInitialized = false;
  bool _isListening = false;
  bool _voiceCommandsEnabled = false;
  bool _isAISpeaking = false;

  // STT / TTS
  late stt.SpeechToText _speechToText;
  late FlutterTts _flutterTts;
  bool _speechEnabled = false;
  bool _ttsEnabled = false;
  bool _micGranted = false;
  String _lastRecognizedWords = '';

  // Callbacks
  void Function(bool)? _onListeningStateChanged;
  void Function(String)? _onVoiceRecognized;
  void Function(String)? _onVoiceCommand;

  // Services (injected to avoid circular singleton initialization)
  AppServiceManager? _serviceManager;
  final AIAssistantService _aiAssistantService = AIAssistantService();
  final VoiceSessionController _voiceController = VoiceSessionController();
  final PhoneAIChannel _phoneAIChannel = PhoneAIChannel();

  // WebRTC stub
  final _WebRTCServiceStub _webrtcStub = _WebRTCServiceStub();
  dynamic get webrtcService => _webrtcStub;

  bool get isInitialized => _isInitialized;
  bool get isWebRTCInCall => _webrtcStub.isInCall;
  bool get isListening => _isListening;
  bool get voiceCommandsEnabled => _voiceCommandsEnabled;
  bool get speechEnabled => _speechEnabled;
  bool get ttsEnabled => _ttsEnabled;
  String get lastRecognizedWords => _lastRecognizedWords;

  Future<void> initialize({AppServiceManager? serviceManager}) async {
    if (_isInitialized) return;
    try {
      // Inject service manager lazily to break circular init between
      // AppServiceManager and PhoneAIIntegrationService
      _serviceManager ??= serviceManager;

      await _ensureMicPermission();
      _speechToText = stt.SpeechToText();
      _speechEnabled = await _speechToText.initialize(
        debugLogging: kDebugMode,
        onError: (error) {
          debugPrint('PhoneAIIntegrationService STT error: ${error.errorMsg}');
          _isListening = false;
          _notifyListeningState();
        },
        onStatus: (status) {
          debugPrint('PhoneAIIntegrationService STT status: $status');
          if ((status == 'done' || status == 'notListening') &&
              _voiceCommandsEnabled &&
              !_isAISpeaking) {
            // Auto-restart if still enabled and user hasn't issued a definitive command
            Future.delayed(const Duration(milliseconds: 350), () {
              if (_voiceCommandsEnabled && !_isAISpeaking && _micGranted) {
                startVoiceListening();
              }
            });
          }
        },
      );

      _flutterTts = FlutterTts();
      try {
        await _flutterTts.setLanguage('en-US');
        await _flutterTts.setSpeechRate(0.5);
        await _flutterTts.setVolume(1.0);
        await _flutterTts.setPitch(1.0);
        _flutterTts.setStartHandler(() {
          _isAISpeaking = true;
        });
        _flutterTts.setCompletionHandler(() {
          _isAISpeaking = false;
          if (_voiceCommandsEnabled) {
            startVoiceListening();
          }
        });
        _ttsEnabled = true;
      } catch (e) {
        debugPrint('PhoneAIIntegrationService TTS init error: $e');
        _ttsEnabled = false;
      }

      // Initialize AI Assistant (non-blocking; ignore errors)
      if (_serviceManager != null) {
        unawaited(
          _aiAssistantService.initialize(serviceManager: _serviceManager),
        );
      }

      // Initialize Phone AI native channel to receive OS assistant intents (lazy)
      // Defer initialization until first actual use to save startup time
      unawaited(_initializePhoneAIChannelLazy());

      _isInitialized = true;
      debugPrint(
        'PhoneAIIntegrationService initialized: speechEnabled=$_speechEnabled ttsEnabled=$_ttsEnabled micGranted=$_micGranted',
      );
    } catch (e) {
      debugPrint('PhoneAIIntegrationService initialization failed: $e');
      _isInitialized =
          true; // Mark initialized to prevent loops, though degraded
    }
  }

  DateTime _lastIntentDelivery = DateTime.now();
  static const _intentDebounceMs = 500;

  Future<void> _initializePhoneAIChannelLazy() async {
    try {
      await _phoneAIChannel.initialize();
      _phoneAIChannel.onTranscriptFinal.listen((text) {
        // Debounce rapid transcript updates
        final now = DateTime.now();
        if (now.difference(_lastIntentDelivery).inMilliseconds <
            _intentDebounceMs) {
          return;
        }
        _lastIntentDelivery = now;
        unawaited(_voiceController.onUtterance(text, speak));
      });
      _phoneAIChannel.onIntent.listen((payload) {
        final text = (payload['text'] ?? '') as String;
        if (text.isNotEmpty) {
          // Debounce rapid intent delivery
          final now = DateTime.now();
          if (now.difference(_lastIntentDelivery).inMilliseconds <
              _intentDebounceMs) {
            return;
          }
          _lastIntentDelivery = now;
          unawaited(_voiceController.onUtterance(text, speak));
        }
      });
    } catch (e) {
      debugPrint('PhoneAIIntegrationService: Channel init error - $e');
    }
  }

  Future<void> _ensureMicPermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      _micGranted = true;
      return;
    }
    final req = await Permission.microphone.request();
    _micGranted = req.isGranted;
  }

  void dispose() {
    try {
      _speechToText.stop();
    } catch (_) {}
    try {
      _flutterTts.stop();
    } catch (_) {}
    _voiceController.dispose();
  }

  // WebRTC wrappers (disabled)
  Future<void> hangUpWebRTCCall() async => _webrtcStub.endCall();
  Future<void> endWebRTCCall() async => _webrtcStub.endCall();

  Future<void> makeAIVoiceCall({
    String? phoneNumber,
    String? contactName,
    String? contactId,
    String? emergencyMessage,
    String? sessionId,
    String? userId,
    String? emergencyType,
  }) async {
    // Disabled - placeholder only
  }

  // Callback registration
  void setOnListeningStateChanged(void Function(bool) cb) =>
      _onListeningStateChanged = cb;
  void setOnVoiceRecognized(void Function(String) cb) =>
      _onVoiceRecognized = cb;
  void setOnVoiceCommand(void Function(String) cb) => _onVoiceCommand = cb;

  Future<void> setVoiceCommandsEnabled(bool enabled) async {
    final allowed = Env.flag<bool>('enableInAppVoiceAI', false);
    _voiceCommandsEnabled = enabled && allowed;
    if (!allowed && enabled) {
      debugPrint(
        'PhoneAIIntegrationService: In-app voice AI disabled by feature flag',
      );
    }
    if (!_voiceCommandsEnabled) {
      await stopVoiceListening();
    } else {
      if (!_isInitialized) await initialize();
      if (!_isListening) await startVoiceListening();
    }
  }

  Future<void> startVoiceListening() async {
    if (!Env.flag<bool>('enableInAppVoiceAI', false)) return;
    if (!_voiceCommandsEnabled || !_micGranted || !_speechEnabled) return;
    // Battery-aware restriction: if aggressive optimization active, avoid continuous listening
    final sm = _serviceManager ?? AppServiceManager();
    final batteryService = sm.batteryOptimizationService;
    if (batteryService.isBatteryCritical) {
      debugPrint(
        'PhoneAIIntegrationService: Skipping startVoiceListening due to critical battery',
      );
      return;
    }
    if (_isListening) return;
    try {
      _isListening = true;
      _notifyListeningState();
      _lastRecognizedWords = '';
      await _speechToText.listen(
        onResult: (result) {
          final words = result.recognizedWords.toLowerCase();
          _lastRecognizedWords = words;
          _onVoiceRecognized?.call(words);
          final matched = _matchCommand(words);
          if (matched != null) {
            _onVoiceCommand?.call(matched);
            // Execute direct action first (fast path) then full AI processing
            unawaited(_executeDirectAction(matched));
            // Forward to AI Assistant for contextual handling
            unawaited(_handleAICommand(words));
            // After a successful command on low battery, auto-stop to save power
            if (batteryService.shouldReduceBackgroundProcessing()) {
              stopVoiceListening();
            }
          }
        },
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en-US',
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: stt.ListenMode.confirmation,
        ),
      );
    } catch (e) {
      debugPrint('PhoneAIIntegrationService startVoiceListening error: $e');
      _isListening = false;
      _notifyListeningState();
    }
  }

  Future<void> stopVoiceListening() async {
    if (!_isListening) return;
    try {
      await _speechToText.stop();
    } catch (_) {}
    _isListening = false;
    _notifyListeningState();
  }

  void _notifyListeningState() => _onListeningStateChanged?.call(_isListening);

  Future<void> speak(String text) async {
    if (!_ttsEnabled) return;
    if (!Env.flag<bool>('enableInAppVoiceAI', false)) return;
    try {
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('PhoneAIIntegrationService speak error: $e');
    }
  }

  Future<void> _handleAICommand(String raw) async {
    try {
      await _voiceController.onUtterance(raw, speak);
    } catch (e) {
      debugPrint('PhoneAIIntegrationService AI command error: $e');
    }
  }

  Future<void> _executeDirectAction(String commandKey) async {
    try {
      switch (commandKey) {
        case 'start_sos':
          // Start manual SOS countdown if possible
          try {
            final sm = _serviceManager ?? AppServiceManager();
            await sm.sosService.startSOSCountdown(type: SOSType.manual);
            await speak(
              'Starting SOS countdown. Stay calm, help is on the way.',
            );
          } catch (e) {
            debugPrint('Direct action start_sos failed: $e');
          }
          break;
        case 'cancel_sos':
          (_serviceManager ?? AppServiceManager()).sosService.cancelSOS();
          await speak('SOS cancelled. Standing down.');
          break;
        case 'hazards':
          final count = (_serviceManager ?? AppServiceManager())
              .hazardService
              .activeAlerts
              .length;
          final msg = count == 0
              ? 'No active hazard alerts detected.'
              : 'There are $count active hazard alerts.';
          await speak(msg);
          break;
        case 'battery':
          final perf = _aiAssistantService.lastPerformanceData;
          final level = perf?.batteryLevel.toStringAsFixed(0) ?? 'unknown';
          await speak('Battery level is $level percent.');
          break;
        case 'location':
          final loc = await (_serviceManager ?? AppServiceManager())
              .locationService
              .getCurrentLocation();
          if (loc != null) {
            await speak(
              'Your location is latitude ${loc.latitude.toStringAsFixed(3)}, longitude ${loc.longitude.toStringAsFixed(3)}',
            );
          } else {
            await speak('Location not available yet.');
          }
          break;
        case 'status':
          final batteryService = (_serviceManager ?? AppServiceManager())
              .batteryOptimizationService;
          final battery = batteryService.currentBatteryLevel;
          final processingReduced = batteryService
              .shouldReduceBackgroundProcessing();
          await speak(
            'System status: battery at $battery percent. Optimization ${processingReduced ? 'active for low power' : 'normal'}.',
          );
          break;
        default:
          // No direct action
          break;
      }
    } catch (e) {
      debugPrint('PhoneAIIntegrationService direct action error: $e');
    }
  }

  String? _matchCommand(String phrase) {
    final map = getAvailableCommands();
    for (final entry in map.entries) {
      if (entry.value.any((v) => phrase.contains(v))) {
        return entry.key;
      }
    }
    return null;
  }

  // Cached command map for performance
  static const _commandMap = {
    'start_sos': ['start sos', 'help me', 'emergency', 'i need help'],
    'cancel_sos': ['cancel sos', 'stand down', 'false alarm'],
    'status': ['status', 'what\'s my status', 'system status'],
    'battery': ['battery status', 'battery level', 'battery'],
    'location': ['share location', 'send location', 'where am i'],
    'hazards': ['check hazards', 'hazard status', 'alerts'],
  };

  Map<String, List<String>> getAvailableCommands() => _commandMap;
}

class _WebRTCServiceStub {
  bool _isInCall = false;
  bool get isInCall => _isInCall;
  bool get isInitialized => true;

  Future<String> makeEmergencyCall({
    String? contactId,
    String? emergencyMessage,
  }) async {
    _isInCall = true;
    return 'webrtc-disabled-${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> endCall() async {
    _isInCall = false;
  }
}
