// WebRTC Emergency Call Service - DISABLED STUB
// All WebRTC functionality (Agora, voice injection) has been removed for this build.
// This stub preserves API surface so existing UI flows compile but perform no action.

class WebRTCEmergencyCallService {
  static final WebRTCEmergencyCallService _instance =
      WebRTCEmergencyCallService._internal();

  factory WebRTCEmergencyCallService() => _instance;

  WebRTCEmergencyCallService._internal();

  bool _isInitialized = false;
  bool _isInCall = false;

  bool get isInitialized => _isInitialized;
  bool get isInCall => _isInCall;

  Future<void> initialize() async {
    // No-op: WebRTC disabled
    _isInitialized = true;
  }

  Future<String> makeEmergencyCall({
    String? contactId,
    String? emergencyMessage,
  }) async {
    // No-op: return a mock channel name for UI messaging
    _isInCall = true;
    return 'webrtc-disabled-${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> joinEmergencyCall(String channelName) async {
    // No-op
    _isInCall = true;
  }

  Future<void> endCall() async {
    _isInCall = false;
  }

  Future<void> dispose() async {
    _isInCall = false;
    _isInitialized = false;
  }
}
