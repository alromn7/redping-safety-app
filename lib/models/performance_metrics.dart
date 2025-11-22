/// Performance metric model
class PerformanceMetric {
  final String operationName;
  final Duration duration;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const PerformanceMetric({
    required this.operationName,
    required this.duration,
    required this.timestamp,
    required this.metadata,
  });
}

/// Operation statistics model
class OperationStats {
  final String operationName;
  final int count;
  final Duration averageDuration;
  final Duration minDuration;
  final Duration maxDuration;
  final Duration medianDuration;
  final Duration p95Duration;

  const OperationStats({
    required this.operationName,
    required this.count,
    required this.averageDuration,
    required this.minDuration,
    required this.maxDuration,
    required this.medianDuration,
    required this.p95Duration,
  });
}

/// Performance report model
class PerformanceReport {
  final DateTime timestamp;
  final int totalMetrics;
  final Map<String, OperationStats> operationStats;
  final Map<String, dynamic> memoryMetrics;
  final Map<String, dynamic> networkMetrics;

  const PerformanceReport({
    required this.timestamp,
    required this.totalMetrics,
    required this.operationStats,
    required this.memoryMetrics,
    required this.networkMetrics,
  });
}

