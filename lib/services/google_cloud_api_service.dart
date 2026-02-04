import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/security_config.dart';
import '../security/request_signing.dart';
import '../security/pinned_http_client.dart';
import '../config/google_cloud_config.dart';
import '../config/env.dart';
import '../models/sos_session.dart';
import '../security/play_integrity_service.dart';
import '../security/ios_runtime_integrity_service.dart';

/// Service for communicating with Google Cloud APIs
/// Connects REDP!NG app with the website's backend
class GoogleCloudApiService {
  static final GoogleCloudApiService _instance =
      GoogleCloudApiService._internal();
  factory GoogleCloudApiService() => _instance;
  GoogleCloudApiService._internal();

  bool _isInitialized = false;
  http.Client? _httpClient;
  PinnedHttpClient? _pinnedClient;
  Timer? _heartbeatTimer;
  bool _hbTlsWarningShown = false;

  // Connection status
  bool _isConnected = false;
  DateTime? _lastSuccessfulRequest;

  // Security probe status
  bool? _lastProtectedPingOk;
  DateTime? _lastProtectedPingAt;

  // Callbacks
  Function(String, dynamic)? _onApiError;

  /// Initialize the API service
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('GoogleCloudApiService: Initializing...');

    // Validate configuration
    if (!GoogleCloudConfig.isConfigured()) {
      throw Exception('Google Cloud configuration is incomplete');
    }

    if (SecurityConfig.enableTlsPinning) {
      _pinnedClient = await PinnedHttpClient.create();
      debugPrint('GoogleCloudApiService: TLS pinning enabled');
    } else {
      _httpClient = http.Client();
    }
    _isInitialized = true;

    // Start heartbeat to maintain connection (gated)
    if (GoogleCloudConfig.enableHeartbeat) {
      _startHeartbeat();
    } else {
      debugPrint(
        'GoogleCloudApiService: Heartbeat disabled (appEnv=${Env.appEnv}, baseUrl=${GoogleCloudConfig.baseUrl})',
      );
    }

    // Run initial health check to populate connection status
    _runInitialHealthCheck();

    debugPrint('GoogleCloudApiService: Initialized successfully');
  }

  /// Run initial health check on startup
  Future<void> _runInitialHealthCheck() async {
    // Run in background to avoid blocking initialization
    Future.microtask(() async {
      try {
        debugPrint('GoogleCloudApiService: Running initial health check...');

        // Test basic connectivity
        final healthResponse = await _makeRequest('GET', '/health');
        if (healthResponse != null) {
          _isConnected = true;
          _lastSuccessfulRequest = DateTime.now();
          debugPrint(
            'GoogleCloudApiService: Health check passed - API connected',
          );
        } else {
          _isConnected = false;
          _lastSuccessfulRequest =
              DateTime.now(); // Mark attempt time even on failure
          debugPrint(
            'GoogleCloudApiService: Health check failed - API disconnected',
          );
        }

        // Test protected endpoint (security)
        final protectedOk = await protectedPing();
        if (protectedOk) {
          debugPrint('GoogleCloudApiService: Security check passed');
        } else {
          debugPrint(
            'GoogleCloudApiService: Security check failed or not available',
          );
        }
      } catch (e) {
        _isConnected = false;
        _lastSuccessfulRequest =
            DateTime.now(); // Mark attempt time even on error
        _lastProtectedPingOk = false; // Mark security check as failed
        _lastProtectedPingAt = DateTime.now();
        debugPrint('GoogleCloudApiService: Initial health check error - $e');
      }
    });
  }

  /// Start heartbeat to maintain connection with backend
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _sendHeartbeat();
    });
  }

  /// Send heartbeat to backend
  Future<void> _sendHeartbeat() async {
    try {
      final response = await _makeRequest('GET', '/health');
      if (response != null) {
        _isConnected = true;
        _lastSuccessfulRequest = DateTime.now();
      }
    } catch (e) {
      _isConnected = false;
      final msg = e.toString();
      if (msg.contains('CERTIFICATE_VERIFY_FAILED')) {
        if (!_hbTlsWarningShown) {
          _hbTlsWarningShown = true;
          debugPrint(
            'GoogleCloudApiService: Heartbeat TLS verification failed (hostname mismatch). Check Env.baseUrl and certificate. Suppressing further repeats.',
          );
        }
        // Stop repeating heartbeats to avoid log spam
        _heartbeatTimer?.cancel();
      } else {
        debugPrint('GoogleCloudApiService: Heartbeat failed - $e');
      }
    }
  }

  /// Make HTTP request to the API
  Future<Map<String, dynamic>?> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    bool requireIntegrity = false,
  }) async {
    if (!_isInitialized) {
      throw Exception('Service not initialized');
    }
    final url = GoogleCloudConfig.getApiUrl(endpoint);
    try {
      Map<String, String> headers = GoogleCloudConfig.getApiHeaders();
      final String encodedBody = body != null ? jsonEncode(body) : '';

      bool doSigning = SecurityConfig.enableRequestSigning;
      if (endpoint == '/health' &&
          Env.flag<bool>('skipSigningOnHealth', false)) {
        doSigning = false;
      }
      if (doSigning) {
        headers = await RequestSigner.signHeaders(
          headers: headers,
          method: method,
          endpoint: endpoint,
          body: encodedBody,
        );
      }

      http.Response? response;

      // Optional enforcement: platform-specific runtime integrity for writes
      final isWrite = method.toUpperCase() != 'GET';

      // Attach Play Integrity token only when needed (writes or explicit requirement)
      String? integrityToken;
      if (SecurityConfig.enablePlayIntegrityHeader &&
          (isWrite || requireIntegrity)) {
        try {
          integrityToken = await PlayIntegrityService.instance.getToken();
          if (integrityToken != null && integrityToken.isNotEmpty) {
            headers['X-Play-Integrity'] = integrityToken;
            final nonce = PlayIntegrityService.instance.nonce;
            if (nonce != null && nonce.isNotEmpty) {
              headers['X-Play-Nonce'] = nonce;
            }
          }
        } catch (_) {}
      }
      if (isWrite || requireIntegrity) {
        // Android: require Play Integrity token when enabled
        if (Platform.isAndroid &&
            SecurityConfig.requirePlayIntegrityForWrites) {
          if (integrityToken == null || integrityToken.isEmpty) {
            throw Exception('INTEGRITY_TOKEN_MISSING');
          }
        }
        // iOS: enforce jailbreak guard when enabled
        if (Platform.isIOS &&
            SecurityConfig.requireIosRuntimeIntegrityForWrites) {
          await IosRuntimeIntegrityService.instance.assertDeviceAllowed();
        }
      }

      switch (method.toUpperCase()) {
        case 'GET':
          if (_pinnedClient != null) {
            final r = await _pinnedClient!.request(
              'GET',
              Uri.parse(url),
              headers: headers,
            );
            return _handlePinnedJson(r);
          } else {
            response = await _httpClient!
                .get(Uri.parse(url), headers: headers)
                .timeout(GoogleCloudConfig.apiTimeout);
          }
          break;
        case 'POST':
          if (_pinnedClient != null) {
            final r = await _pinnedClient!.request(
              'POST',
              Uri.parse(url),
              headers: headers,
              body: body != null ? encodedBody : null,
            );
            return _handlePinnedJson(r);
          } else {
            response = await _httpClient!
                .post(
                  Uri.parse(url),
                  headers: headers,
                  body: body != null ? encodedBody : null,
                )
                .timeout(GoogleCloudConfig.apiTimeout);
          }
          break;
        case 'PUT':
          if (_pinnedClient != null) {
            final r = await _pinnedClient!.request(
              'PUT',
              Uri.parse(url),
              headers: headers,
              body: body != null ? encodedBody : null,
            );
            return _handlePinnedJson(r);
          } else {
            response = await _httpClient!
                .put(
                  Uri.parse(url),
                  headers: headers,
                  body: body != null ? encodedBody : null,
                )
                .timeout(GoogleCloudConfig.apiTimeout);
          }
          break;
        case 'DELETE':
          if (_pinnedClient != null) {
            final r = await _pinnedClient!.request(
              'DELETE',
              Uri.parse(url),
              headers: headers,
            );
            return _handlePinnedJson(r);
          } else {
            response = await _httpClient!
                .delete(Uri.parse(url), headers: headers)
                .timeout(GoogleCloudConfig.apiTimeout);
          }
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _isConnected = true;
        _lastSuccessfulRequest = DateTime.now();
        return jsonDecode(response.body);
      } else {
        _isConnected = false;
        throw Exception(
          'API request failed: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e, st) {
      _isConnected = false;
      // Extended diagnostics for TLS / integrity / signing failures
      final msg = e.toString();
      if (msg.contains('CERTIFICATE_VERIFY_FAILED')) {
        debugPrint('[API] TLS hostname mismatch or cert issue for $url');
      } else if (msg.contains('INTEGRITY_TOKEN_MISSING')) {
        debugPrint(
          '[API] Play Integrity token missing (method=$method endpoint=$endpoint)',
        );
      } else if (msg.contains('TlsPinningException')) {
        debugPrint(
          '[API] TLS pinning rejection for host ${Uri.parse(url).host}',
        );
      }
      debugPrint('[API] $method $url failed: $e');
      debugPrint('[API] Stack: $st');
      _onApiError?.call('API_REQUEST_FAILED', e);
      rethrow;
    }
  }

  Map<String, dynamic>? _handlePinnedJson(PinnedResponse r) {
    if (r.statusCode >= 200 && r.statusCode < 300) {
      _isConnected = true;
      _lastSuccessfulRequest = DateTime.now();
      return jsonDecode(r.body);
    } else {
      _isConnected = false;
      throw Exception('API request failed: ${r.statusCode} - ${r.body}');
    }
  }

  /// Send SOS alert to backend
  Future<bool> sendSosAlert(SOSSession session) async {
    try {
      final response = await _makeRequest(
        'POST',
        '/sos-alerts',
        body: {
          'id': session.id,
          'userId': session.userId,
          'location': {
            'latitude': session.location.latitude,
            'longitude': session.location.longitude,
            'accuracy': session.location.accuracy,
          },
          'timestamp': session.startTime.toIso8601String(),
          'status': session.status.toString(),
          'message': session.userMessage ?? 'Emergency alert',
          'priority': session.type.toString(),
        },
        requireIntegrity: true,
      );

      return response != null;
    } catch (e) {
      debugPrint('GoogleCloudApiService: Failed to send SOS alert - $e');
      return false;
    }
  }

  /// Protected ping to validate HMAC + Integrity + nonce path end-to-end.
  Future<bool> protectedPing() async {
    try {
      final response = await _makeRequest(
        'POST',
        '/protected/ping',
        body: {'timestamp': DateTime.now().toIso8601String()},
        requireIntegrity: true,
      );
      final ok =
          response != null &&
          (response['ok'] == true) &&
          (response['pong'] == true);
      if (ok) {
        debugPrint(
          'GoogleCloudApiService: Protected ping success (HMAC + Integrity + nonce validated)',
        );
        _lastProtectedPingOk = true;
        _lastProtectedPingAt = DateTime.now();
      }
      return ok;
    } catch (e, st) {
      final msg = e.toString();
      if (msg.contains('INTEGRITY_TOKEN_MISSING')) {
        debugPrint(
          '[ProtectedPing] Integrity token missing – check Play Services configuration & flags',
        );
      } else if (msg.contains('CERTIFICATE_VERIFY_FAILED')) {
        debugPrint(
          '[ProtectedPing] TLS hostname mismatch – validate GoogleCloudConfig.baseUrl and certificate CN/SAN',
        );
      } else if (msg.contains('TlsPinningException')) {
        debugPrint(
          '[ProtectedPing] TLS pin mismatch – verify assets/pins/pins.json fingerprints',
        );
      }
      debugPrint('GoogleCloudApiService: Protected ping failed - $e');
      debugPrint('[ProtectedPing] Stack: $st');
      _lastProtectedPingOk = false;
      _lastProtectedPingAt = DateTime.now();
      return false;
    }
  }

  /// Get SAR teams from backend
  Future<List<Map<String, dynamic>>> getSarTeams() async {
    try {
      final response = await _makeRequest('GET', '/sar-teams');
      return List<Map<String, dynamic>>.from(response?['teams'] ?? []);
    } catch (e) {
      debugPrint('GoogleCloudApiService: Failed to get SAR teams - $e');
      return [];
    }
  }

  /// Update user location
  Future<bool> updateLocation(
    double latitude,
    double longitude,
    double accuracy,
  ) async {
    try {
      final response = await _makeRequest(
        'POST',
        '/locations',
        body: {
          'latitude': latitude,
          'longitude': longitude,
          'accuracy': accuracy,
          'timestamp': DateTime.now().toIso8601String(),
        },
        requireIntegrity: true,
      );

      return response != null;
    } catch (e) {
      debugPrint('GoogleCloudApiService: Failed to update location - $e');
      return false;
    }
  }

  /// Send notification to backend
  Future<bool> sendNotification(
    String title,
    String message,
    String type,
  ) async {
    try {
      final response = await _makeRequest(
        'POST',
        '/notifications',
        body: {
          'title': title,
          'message': message,
          'type': type,
          'timestamp': DateTime.now().toIso8601String(),
        },
        requireIntegrity: true,
      );

      return response != null;
    } catch (e) {
      debugPrint('GoogleCloudApiService: Failed to send notification - $e');
      return false;
    }
  }

  /// Get user subscription status
  Future<Map<String, dynamic>?> getSubscriptionStatus() async {
    try {
      final response = await _makeRequest('GET', '/subscriptions/status');
      return response;
    } catch (e) {
      debugPrint(
        'GoogleCloudApiService: Failed to get subscription status - $e',
      );
      return null;
    }
  }

  /// Update emergency contacts
  Future<bool> updateEmergencyContacts(
    List<Map<String, dynamic>> contacts,
  ) async {
    try {
      final response = await _makeRequest(
        'PUT',
        '/emergency-contacts',
        body: {
          'contacts': contacts,
          'timestamp': DateTime.now().toIso8601String(),
        },
        requireIntegrity: true,
      );

      return response != null;
    } catch (e) {
      debugPrint(
        'GoogleCloudApiService: Failed to update emergency contacts - $e',
      );
      return false;
    }
  }

  /// Register gadget device
  Future<bool> registerGadget(Map<String, dynamic> device) async {
    try {
      final response = await _makeRequest(
        'POST',
        '/gadgets',
        body: device,
        requireIntegrity: true,
      );
      // Above defaults to requireIntegrity=false; enforce for device registration
      // to protect provisioning endpoints.
      // Re-issue with integrity if not already guarded elsewhere.
      return response != null;
    } catch (e) {
      debugPrint('GoogleCloudApiService: Failed to register gadget - $e');
      return false;
    }
  }

  /// Set API error callback
  void setApiErrorCallback(Function(String, dynamic) callback) {
    _onApiError = callback;
  }

  /// Get connection status
  bool get isConnected => _isConnected;

  /// Get last successful request time
  DateTime? get lastSuccessfulRequest => _lastSuccessfulRequest;

  /// Get service status
  Map<String, dynamic> getStatus() {
    return {
      'isInitialized': _isInitialized,
      'isConnected': _isConnected,
      'lastSuccessfulRequest': _lastSuccessfulRequest?.toIso8601String(),
      'configurationValid': GoogleCloudConfig.isConfigured(),
      'protectedPingOk': _lastProtectedPingOk,
      'protectedPingAt': _lastProtectedPingAt?.toIso8601String(),
    };
  }

  /// Dispose of resources
  void dispose() {
    _heartbeatTimer?.cancel();
    _httpClient?.close();
    _pinnedClient?.close();
    _isInitialized = false;
    _isConnected = false;
  }
}
