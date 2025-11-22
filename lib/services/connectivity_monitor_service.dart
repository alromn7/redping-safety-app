import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Singleton service to monitor network connectivity status for battery optimization
class ConnectivityMonitorService {
  static final ConnectivityMonitorService _instance =
      ConnectivityMonitorService._internal();
  factory ConnectivityMonitorService() => _instance;
  ConnectivityMonitorService._internal();

  bool _isOffline = false;
  final StreamController<bool> _offlineController =
      StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    if (_connectivitySub != null) return;
    await _primeStatus();
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.every((r) => r == ConnectivityResult.none);
      if (_isOffline != offline) {
        _isOffline = offline;
        _offlineController.add(_isOffline);
      }
    });
  }

  /// Get current offline status
  bool get isOffline => _isOffline;

  /// Stream for offline status changes
  Stream<bool> get offlineStream => _offlineController.stream;

  Future<void> _primeStatus() async {
    final results = await Connectivity().checkConnectivity();
    // In newer connectivity_plus, checkConnectivity returns a List<ConnectivityResult>
    _isOffline = results.every((r) => r == ConnectivityResult.none);
    _offlineController.add(_isOffline);
  }

  void dispose() {
    _connectivitySub?.cancel();
    _offlineController.close();
  }
}
