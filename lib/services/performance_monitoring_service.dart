import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/performance_metrics.dart';

/// Service for monitoring app performance and collecting metrics
class PerformanceMonitoringService {
  static final PerformanceMonitoringService _instance =
      PerformanceMonitoringService._internal();
  factory PerformanceMonitoringService() => _instance;
  PerformanceMonitoringService._internal();

  // Performance metrics
  final List<PerformanceMetric> _metrics = [];
  final Map<String, DateTime> _operationStartTimes = {};

  // Monitoring settings
  bool _isMonitoring = true;
  final bool _isDebugMode = kDebugMode;

  // Timers
  Timer? _metricsCleanupTimer;
  Timer? _performanceReportTimer;

  // Callbacks
  Function(PerformanceMetric)? _onMetricRecorded;
  Function(PerformanceReport)? _onReportGenerated;

  /// Initialize the performance monitoring service
  Future<void> initialize() async {
    try {
      _startMetricsCleanup();
      _startPerformanceReporting();
      debugPrint('PerformanceMonitoringService: Initialized successfully');
    } catch (e) {
      debugPrint('PerformanceMonitoringService: Error initializing - $e');
    }
  }

  /// Start operation timing
  void startOperation(String operationName) {
    if (!_isMonitoring) return;

    _operationStartTimes[operationName] = DateTime.now();

    if (_isDebugMode) {
      debugPrint('PerformanceMonitoring: Started operation: $operationName');
    }
  }

  /// End operation timing and record metric
  void endOperation(String operationName, {Map<String, dynamic>? metadata}) {
    if (!_isMonitoring) return;

    final startTime = _operationStartTimes.remove(operationName);
    if (startTime == null) {
      debugPrint(
        'PerformanceMonitoring: Warning - No start time found for operation: $operationName',
      );
      return;
    }

    final duration = DateTime.now().difference(startTime);
    final metric = PerformanceMetric(
      operationName: operationName,
      duration: duration,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );

    _recordMetric(metric);
  }

  /// Record a performance metric
  void _recordMetric(PerformanceMetric metric) {
    _metrics.add(metric);

    // Keep only last 1000 metrics to prevent memory issues
    if (_metrics.length > 1000) {
      _metrics.removeRange(0, _metrics.length - 1000);
    }

    _onMetricRecorded?.call(metric);

    if (_isDebugMode) {
      debugPrint(
        'PerformanceMonitoring: ${metric.operationName} took ${metric.duration.inMilliseconds}ms',
      );
    }
  }

  /// Record memory usage
  void recordMemoryUsage(String context) {
    if (!_isMonitoring) return;

    try {
      final memoryInfo = _getMemoryInfo();
      final metric = PerformanceMetric(
        operationName: 'memory_usage',
        duration: Duration.zero,
        timestamp: DateTime.now(),
        metadata: {
          'context': context,
          'used_memory_mb': memoryInfo['used_memory_mb'],
          'total_memory_mb': memoryInfo['total_memory_mb'],
          'free_memory_mb': memoryInfo['free_memory_mb'],
        },
      );

      _recordMetric(metric);
    } catch (e) {
      debugPrint('PerformanceMonitoring: Error recording memory usage - $e');
    }
  }

  /// Record battery usage
  void recordBatteryUsage(String context, int batteryLevel) {
    if (!_isMonitoring) return;

    final metric = PerformanceMetric(
      operationName: 'battery_usage',
      duration: Duration.zero,
      timestamp: DateTime.now(),
      metadata: {'context': context, 'battery_level': batteryLevel},
    );

    _recordMetric(metric);
  }

  /// Record network request performance
  void recordNetworkRequest(
    String endpoint,
    Duration duration,
    int statusCode, {
    String? error,
  }) {
    if (!_isMonitoring) return;

    final metric = PerformanceMetric(
      operationName: 'network_request',
      duration: duration,
      timestamp: DateTime.now(),
      metadata: {
        'endpoint': endpoint,
        'status_code': statusCode,
        'error': error,
      },
    );

    _recordMetric(metric);
  }

  /// Record sensor processing performance
  void recordSensorProcessing(
    String sensorType,
    Duration processingTime,
    int dataPoints,
  ) {
    if (!_isMonitoring) return;

    final metric = PerformanceMetric(
      operationName: 'sensor_processing',
      duration: processingTime,
      timestamp: DateTime.now(),
      metadata: {'sensor_type': sensorType, 'data_points': dataPoints},
    );

    _recordMetric(metric);
  }

  /// Get memory information
  Map<String, dynamic> _getMemoryInfo() {
    // This is a simplified implementation
    // In a real app, you might use platform-specific APIs
    return {
      'used_memory_mb': 0, // Placeholder
      'total_memory_mb': 0, // Placeholder
      'free_memory_mb': 0, // Placeholder
    };
  }

  /// Start metrics cleanup timer
  void _startMetricsCleanup() {
    _metricsCleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupOldMetrics();
    });
  }

  /// Start performance reporting timer
  void _startPerformanceReporting() {
    _performanceReportTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _generatePerformanceReport();
    });
  }

  /// Clean up old metrics
  void _cleanupOldMetrics() {
    final cutoffTime = DateTime.now().subtract(const Duration(hours: 1));
    _metrics.removeWhere((metric) => metric.timestamp.isBefore(cutoffTime));

    if (_isDebugMode) {
      debugPrint(
        'PerformanceMonitoring: Cleaned up old metrics. Current count: ${_metrics.length}',
      );
    }
  }

  /// Generate performance report
  void _generatePerformanceReport() {
    if (_metrics.isEmpty) return;

    final report = _analyzeMetrics();
    _onReportGenerated?.call(report);

    if (_isDebugMode) {
      _logPerformanceReport(report);
    }
  }

  /// Analyze metrics and generate report
  PerformanceReport _analyzeMetrics() {
    final now = DateTime.now();
    final lastHour = now.subtract(const Duration(hours: 1));

    // Filter metrics from last hour
    final recentMetrics = _metrics
        .where((metric) => metric.timestamp.isAfter(lastHour))
        .toList();

    // Group by operation type
    final Map<String, List<PerformanceMetric>> groupedMetrics = {};
    for (final metric in recentMetrics) {
      groupedMetrics.putIfAbsent(metric.operationName, () => []).add(metric);
    }

    // Calculate statistics for each operation
    final Map<String, OperationStats> operationStats = {};
    for (final entry in groupedMetrics.entries) {
      final operationName = entry.key;
      final metrics = entry.value;

      if (metrics.isNotEmpty) {
        final durations = metrics
            .where((m) => m.duration != Duration.zero)
            .map((m) => m.duration.inMilliseconds)
            .toList();

        if (durations.isNotEmpty) {
          durations.sort();

          operationStats[operationName] = OperationStats(
            operationName: operationName,
            count: metrics.length,
            averageDuration: Duration(
              milliseconds:
                  (durations.reduce((a, b) => a + b) / durations.length)
                      .round(),
            ),
            minDuration: Duration(milliseconds: durations.first),
            maxDuration: Duration(milliseconds: durations.last),
            medianDuration: Duration(
              milliseconds: durations[durations.length ~/ 2],
            ),
            p95Duration: Duration(
              milliseconds: durations[(durations.length * 0.95).round()],
            ),
          );
        }
      }
    }

    return PerformanceReport(
      timestamp: now,
      totalMetrics: recentMetrics.length,
      operationStats: operationStats,
      memoryMetrics: _getMemoryMetrics(recentMetrics),
      networkMetrics: _getNetworkMetrics(recentMetrics),
    );
  }

  /// Get memory metrics from recent data
  Map<String, dynamic> _getMemoryMetrics(List<PerformanceMetric> metrics) {
    final memoryMetrics = metrics
        .where((m) => m.operationName == 'memory_usage')
        .toList();

    if (memoryMetrics.isEmpty) {
      return {};
    }

    final usedMemoryValues = memoryMetrics
        .map((m) => m.metadata['used_memory_mb'] as double?)
        .where((v) => v != null)
        .cast<double>()
        .toList();

    if (usedMemoryValues.isEmpty) {
      return {};
    }

    return {
      'average_used_mb':
          usedMemoryValues.reduce((a, b) => a + b) / usedMemoryValues.length,
      'max_used_mb': usedMemoryValues.reduce((a, b) => a > b ? a : b),
      'min_used_mb': usedMemoryValues.reduce((a, b) => a < b ? a : b),
    };
  }

  /// Get network metrics from recent data
  Map<String, dynamic> _getNetworkMetrics(List<PerformanceMetric> metrics) {
    final networkMetrics = metrics
        .where((m) => m.operationName == 'network_request')
        .toList();

    if (networkMetrics.isEmpty) {
      return {};
    }

    final durations = networkMetrics
        .map((m) => m.duration.inMilliseconds)
        .toList();

    final statusCodes = networkMetrics
        .map((m) => m.metadata['status_code'] as int?)
        .where((c) => c != null)
        .cast<int>()
        .toList();

    final errorCount = networkMetrics
        .where((m) => m.metadata['error'] != null)
        .length;

    return {
      'total_requests': networkMetrics.length,
      'error_count': errorCount,
      'success_rate': networkMetrics.isNotEmpty
          ? (networkMetrics.length - errorCount) / networkMetrics.length
          : 1.0,
      'average_duration_ms': durations.isNotEmpty
          ? durations.reduce((a, b) => a + b) / durations.length
          : 0.0,
      'status_codes': statusCodes,
    };
  }

  /// Log performance report to console
  void _logPerformanceReport(PerformanceReport report) {
    debugPrint('=== Performance Report (${report.timestamp}) ===');
    debugPrint('Total Metrics: ${report.totalMetrics}');

    for (final stats in report.operationStats.values) {
      debugPrint(
        '${stats.operationName}: '
        'avg=${stats.averageDuration.inMilliseconds}ms, '
        'p95=${stats.p95Duration.inMilliseconds}ms, '
        'count=${stats.count}',
      );
    }

    if (report.memoryMetrics.isNotEmpty) {
      debugPrint('Memory: ${report.memoryMetrics}');
    }

    if (report.networkMetrics.isNotEmpty) {
      debugPrint('Network: ${report.networkMetrics}');
    }
  }

  /// Get recent metrics for a specific operation
  List<PerformanceMetric> getMetricsForOperation(
    String operationName, {
    Duration? since,
  }) {
    final cutoffTime = since != null
        ? DateTime.now().subtract(since)
        : DateTime.now().subtract(const Duration(hours: 1));

    return _metrics
        .where(
          (m) =>
              m.operationName == operationName &&
              m.timestamp.isAfter(cutoffTime),
        )
        .toList();
  }

  /// Get all recent metrics
  List<PerformanceMetric> getRecentMetrics({Duration? since}) {
    final cutoffTime = since != null
        ? DateTime.now().subtract(since)
        : DateTime.now().subtract(const Duration(hours: 1));

    return _metrics.where((m) => m.timestamp.isAfter(cutoffTime)).toList();
  }

  /// Set metric recorded callback
  void setMetricRecordedCallback(Function(PerformanceMetric) callback) {
    _onMetricRecorded = callback;
  }

  /// Set report generated callback
  void setReportGeneratedCallback(Function(PerformanceReport) callback) {
    _onReportGenerated = callback;
  }

  /// Enable or disable monitoring
  void setMonitoringEnabled(bool enabled) {
    _isMonitoring = enabled;
    debugPrint(
      'PerformanceMonitoring: Monitoring ${enabled ? 'enabled' : 'disabled'}',
    );
  }

  /// Get current metrics count
  int get metricsCount => _metrics.length;

  /// Check if monitoring is enabled
  bool get isMonitoring => _isMonitoring;

  /// Dispose of resources
  void dispose() {
    _metricsCleanupTimer?.cancel();
    _performanceReportTimer?.cancel();
  }
}
