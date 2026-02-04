import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Singleton service to monitor network connectivity status for battery optimization
class ConnectivityMonitorService {
  static final ConnectivityMonitorService _instance =
      ConnectivityMonitorService._internal();
  factory ConnectivityMonitorService() => _instance;
  ConnectivityMonitorService._internal();

  bool _isOffline = false;
  bool _hasInternetAccess = true;
  final StreamController<bool> _offlineController =
      StreamController<bool>.broadcast();
    final StreamController<List<ConnectivityResult>> _connectivityController =
      StreamController<List<ConnectivityResult>>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

    List<ConnectivityResult>? _lastResults;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    if (_connectivitySub != null) return;
    await _primeStatus();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      _lastResults = results;
      _connectivityController.add(results);
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (_isOffline != offline) {
        _isOffline = offline;
        _offlineController.add(_isOffline);
      }
    });

    // Periodically probe internet reachability (handles captive portals)
    Timer.periodic(const Duration(seconds: 15), (_) async {
      try {
        final reachable = await isInternetReachable(
          timeout: const Duration(seconds: 2),
        );
        // Only update flag; expose via getter. Do not spam stream.
        _hasInternetAccess = reachable;
      } catch (_) {}
    });
  }

  /// Get current offline status
  bool get isOffline => _isOffline;
  bool get hasInternetAccess => _hasInternetAccess;
  bool get isEffectivelyOffline => _isOffline || !_hasInternetAccess;

  /// Stream for offline status changes
  Stream<bool> get offlineStream => _offlineController.stream;

  /// Stream for raw connectivity changes (mobile/wifi/none)
  Stream<List<ConnectivityResult>> get connectivityStream =>
      _connectivityController.stream;

  /// Last connectivity results as reported by connectivity_plus
  List<ConnectivityResult>? get lastConnectivityResults => _lastResults;

  Future<void> _primeStatus() async {
    final results = await Connectivity().checkConnectivity();
    // In newer connectivity_plus, checkConnectivity returns a List<ConnectivityResult>
    _lastResults = results;
    _connectivityController.add(results);
    _isOffline = results.every((r) => r == ConnectivityResult.none);
    _offlineController.add(_isOffline);
    try {
      _hasInternetAccess = await isInternetReachable(
        timeout: const Duration(seconds: 2),
      );
    } catch (_) {
      _hasInternetAccess = false;
    }
  }

  /// Lightweight internet reachability check using Google's 204 endpoint.
  /// Treats Wi‑Fi without internet (captive portals) as offline.
  Future<bool> isInternetReachable({
    Duration timeout = const Duration(seconds: 2),
  }) async {
    try {
      final client = HttpClient()..connectionTimeout = timeout;
      final request = await client.getUrl(
        Uri.parse('https://www.google.com/generate_204'),
      ).timeout(timeout);
      final response = await request.close().timeout(timeout);
      // HTTP 204 expected; any 2xx implies reachability
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _connectivitySub?.cancel();
    _offlineController.close();
    _connectivityController.close();
  }
}
