import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for tracking feature usage.
///
/// Subscription/tier enforcement has been removed; all features are treated as
/// available with no blocking limits.
class UsageTrackingService {
  UsageTrackingService._();

  static final UsageTrackingService _instance = UsageTrackingService._();
  static UsageTrackingService get instance => _instance;

  // Usage tracking data
  Map<String, int> _currentUsage = {};
  Map<String, DateTime> _lastUsage = {};
  DateTime? _lastResetDate;

  // Storage keys
  static const String _usageKey = 'feature_usage';
  static const String _lastResetKey = 'last_usage_reset';

  /// Initialize the usage tracking service
  Future<void> initialize() async {
    await _loadUsageData();
    await _checkAndResetMonthlyUsage();
    debugPrint('UsageTrackingService: Initialized');
  }

  /// Track feature usage
  Future<bool> trackFeatureUsage(String feature, {int increment = 1}) async {
    try {
      // Get current usage for the feature
      final currentCount = _currentUsage[feature] ?? 0;

      // Increment usage
      _currentUsage[feature] = currentCount + increment;
      _lastUsage[feature] = DateTime.now();

      // Save usage data
      await _saveUsageData();

      debugPrint(
        'UsageTrackingService: Tracked $feature usage: ${_currentUsage[feature]}',
      );
      return true;
    } catch (e) {
      debugPrint('UsageTrackingService: Error tracking usage - $e');
      return false;
    }
  }

  /// Check if user can use a feature (considering limits)
  bool canUseFeature(String feature) {
    return true;
  }

  /// Get remaining usage for a feature
  int getRemainingUsage(String feature) {
    return -1; // Unlimited
  }

  /// Get current usage for a feature
  int getCurrentUsage(String feature) {
    return _currentUsage[feature] ?? 0;
  }

  /// Get usage percentage for a feature
  double getUsagePercentage(String feature) {
    return 0.0;
  }

  /// Check if user has reached usage limit
  bool hasReachedLimit(String feature) {
    return !canUseFeature(feature);
  }

  /// Get usage status for all features
  Map<String, dynamic> getUsageStatus() {
    return {
      'usage': _currentUsage,
      'lastUsed': _lastUsage.map((k, v) => MapEntry(k, v.toIso8601String())),
    };
  }

  /// Get features that are near their limits (80%+ usage)
  List<String> getFeaturesNearLimit() {
    final nearLimit = <String>[];

    for (final feature in _currentUsage.keys) {
      final percentage = getUsagePercentage(feature);
      if (percentage >= 0.8) {
        nearLimit.add(feature);
      }
    }

    return nearLimit;
  }

  /// Reset usage for a specific feature (admin function)
  Future<void> resetFeatureUsage(String feature) async {
    _currentUsage[feature] = 0;
    _lastUsage.remove(feature);
    await _saveUsageData();
    debugPrint('UsageTrackingService: Reset usage for $feature');
  }

  /// Reset all usage (admin function)
  Future<void> resetAllUsage() async {
    _currentUsage.clear();
    _lastUsage.clear();
    await _saveUsageData();
    debugPrint('UsageTrackingService: Reset all usage');
  }

  /// Load usage data from storage
  Future<void> _loadUsageData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usageJson = prefs.getString(_usageKey);
      final lastResetStr = prefs.getString(_lastResetKey);

      if (usageJson != null) {
        final data = jsonDecode(usageJson);
        _currentUsage = Map<String, int>.from(data['usage'] ?? {});
        _lastUsage =
            (data['lastUsage'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, DateTime.parse(v)),
            ) ??
            {};
      }

      if (lastResetStr != null) {
        _lastResetDate = DateTime.parse(lastResetStr);
      }

      debugPrint('UsageTrackingService: Loaded usage data');
    } catch (e) {
      debugPrint('UsageTrackingService: Error loading usage data - $e');
    }
  }

  /// Save usage data to storage
  Future<void> _saveUsageData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'usage': _currentUsage,
        'lastUsage': _lastUsage.map((k, v) => MapEntry(k, v.toIso8601String())),
      };
      await prefs.setString(_usageKey, jsonEncode(data));
    } catch (e) {
      debugPrint('UsageTrackingService: Error saving usage data - $e');
    }
  }

  /// Check and reset monthly usage if needed
  Future<void> _checkAndResetMonthlyUsage() async {
    final now = DateTime.now();

    // Check if we need to reset monthly usage
    if (_lastResetDate == null ||
        now.month != _lastResetDate!.month ||
        now.year != _lastResetDate!.year) {
      // Reset monthly usage
      _currentUsage.clear();
      _lastUsage.clear();
      _lastResetDate = now;

      await _saveUsageData();
      await _saveLastResetDate();

      debugPrint('UsageTrackingService: Reset monthly usage');
    }
  }

  /// Save last reset date
  Future<void> _saveLastResetDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastResetKey, _lastResetDate!.toIso8601String());
    } catch (e) {
      debugPrint('UsageTrackingService: Error saving reset date - $e');
    }
  }

  /// Get usage analytics for subscription tier
  Map<String, dynamic> getUsageAnalytics() {
    final usedFeatures = _currentUsage.keys.length;
    final nearLimitFeatures = getFeaturesNearLimit().length;

    return {
      'used_features': usedFeatures,
      'near_limit_features': nearLimitFeatures,
      'features_near_limit': getFeaturesNearLimit(),
      'usage_status': getUsageStatus(),
    };
  }
}
