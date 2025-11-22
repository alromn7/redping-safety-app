import 'env.dart';

/// Google Cloud configuration for REDP!NG app
/// This connects to the same APIs as the REDP!NG website
class GoogleCloudConfig {
  // Google Cloud Project Configuration
  static String get projectId =>
      (Env.projectId.isNotEmpty) ? Env.projectId : 'redping-production-2024';
  static String get apiKey => (Env.apiKey.isNotEmpty) ? Env.apiKey : '';
  static String get clientId => (Env.clientId.isNotEmpty)
      ? Env.clientId
      : '123456789012-abcdefghijklmnopqrstuvwxyz123456.apps.googleusercontent.com';

  // API endpoints - Same as website
  static String get baseUrl => (Env.baseUrl.isNotEmpty)
      ? Env.baseUrl
      : 'https://redping-api-2024.run.app/api';
  static const String firebaseUrl =
      'https://redping-api-2024-default-rtdb.firebaseio.com/';

  // REDP!NG specific endpoints
  static String get sosAlertsEndpoint => '$baseUrl/sos-alerts';
  static String get sarTeamsEndpoint => '$baseUrl/sar-teams';
  static String get locationsEndpoint => '$baseUrl/locations';
  static String get notificationsEndpoint => '$baseUrl/notifications';
  static String get subscriptionsEndpoint => '$baseUrl/subscriptions';
  static String get emergencyContactsEndpoint => '$baseUrl/emergency-contacts';
  static String get gadgetsEndpoint => '$baseUrl/gadgets';

  // WebSocket endpoints for real-time communication
  static String get sosAlertsWebSocket {
    if (Env.websocketBaseUrl.isNotEmpty) {
      return '${Env.websocketBaseUrl}/sos-alerts';
    }
    // Derive from baseUrl host by default
    try {
      final u = Uri.parse(baseUrl);
      final host = u.host;
      if (host.isNotEmpty) return 'wss://$host/ws/sos-alerts';
    } catch (_) {}
    return 'wss://redping-api-2024.run.app/ws/sos-alerts';
  }

  static String get sarCoordinationWebSocket {
    if (Env.websocketBaseUrl.isNotEmpty) {
      return '${Env.websocketBaseUrl}/sar-coordination';
    }
    try {
      final u = Uri.parse(baseUrl);
      final host = u.host;
      if (host.isNotEmpty) return 'wss://$host/ws/sar-coordination';
    } catch (_) {}
    return 'wss://redping-api-2024.run.app/ws/sar-coordination';
  }

  // Firebase configuration
  // Unified blueprint: use a single Firestore collection for SOS data
  // Renamed logical target from 'sos_alerts' -> 'sos_sessions'
  static const String firestoreCollectionSosAlerts = 'sos_sessions';
  static const String firestoreCollectionSarTeams = 'sar_teams';
  static const String firestoreCollectionUsers = 'users';
  static const String firestoreCollectionGadgets = 'gadgets';

  // Feature flag: when false, avoid client-side writes to 'sos_pings'.
  static bool get allowClientSOSPingWrites => Env.allowClientSosPingWrites;

  // Authentication scopes
  static const List<String> authScopes = [
    'https://www.googleapis.com/auth/cloud-platform',
    'https://www.googleapis.com/auth/firebase',
    'https://www.googleapis.com/auth/userinfo.email',
    'https://www.googleapis.com/auth/userinfo.profile',
  ];

  // API rate limiting
  static const int maxRequestsPerMinute = 100;
  static const int maxRequestsPerHour = 1000;

  // Timeout configurations
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration websocketTimeout = Duration(seconds: 60);

  /// Get the complete API URL for a specific endpoint
  static String getApiUrl(String endpoint) => '$baseUrl$endpoint';

  /// Get WebSocket URL for real-time communication
  static String getWebSocketUrl(String endpoint) {
    if (Env.websocketBaseUrl.isNotEmpty) {
      return '${Env.websocketBaseUrl}$endpoint';
    }
    try {
      final u = Uri.parse(baseUrl);
      final host = u.host;
      if (host.isNotEmpty) return 'wss://$host$endpoint';
    } catch (_) {}
    return 'wss://redping-api-2024.run.app$endpoint';
  }

  /// Validate API configuration
  static bool isConfigured() =>
      // Minimal requirement to operate against our Functions API
      baseUrl.isNotEmpty;

  /// Get headers for API requests
  static Map<String, String> getApiHeaders() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (clientId.isNotEmpty) headers['X-Client-ID'] = clientId;
    if (projectId.isNotEmpty) headers['X-Project-ID'] = projectId;
    if (apiKey.isNotEmpty) headers['Authorization'] = 'Bearer $apiKey';
    return headers;
  }

  /// Feature gate for background heartbeat pings.
  ///
  /// Rules:
  /// - Disabled automatically in test environment (Env.appEnv == 'test').
  /// - Disabled when baseUrl points to localhost or uses plain HTTP.
  /// - Otherwise controlled by feature flag `enableHeartbeat` (defaults true in prod/stage, false in dev).
  static bool get enableHeartbeat {
    // Auto-disable in tests
    if (Env.appEnv.toLowerCase() == 'test') return false;

    // Disable for localhost/non-TLS to avoid noisy failures in CI/dev
    try {
      final u = Uri.parse(baseUrl);
      final isLocal = u.host == 'localhost' || u.host == '127.0.0.1';
      if (isLocal || u.scheme != 'https') return false;
    } catch (_) {
      // If baseUrl is malformed, better to disable than spam errors
      return false;
    }

    // Feature flag override (enableHeartbeat: true/false)
    final env = Env.appEnv.toLowerCase();
    final defaultForEnv =
        (env == 'prod' ||
        env == 'production' ||
        env == 'stage' ||
        env == 'staging');
    final flag = Env.flag<bool>('enableHeartbeat', defaultForEnv);
    return flag;
  }
}
