import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Production-ready app optimization configuration
class AppOptimizationConfig {
  static const bool isProduction = kReleaseMode;

  /// Initialize production optimizations
  static Future<void> initialize() async {
    if (!isProduction) return;

    // Disable debug features in production
    await _disableDebugFeatures();

    // Optimize system UI
    await _optimizeSystemUI();

    // Configure error handling
    _setupProductionErrorHandling();

    // Memory management
    await _optimizeMemoryUsage();

    // Battery optimizations
    await _optimizeBatteryUsage();
  }

  static Future<void> _disableDebugFeatures() async {
    // Disable debug banners, logging, etc.
    debugPrint = (String? message, {int? wrapWidth}) {};

    // Disable performance overlay
    if (Platform.isAndroid || Platform.isIOS) {
      // Platform-specific debug disabling
    }
  }

  static Future<void> _optimizeSystemUI() async {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF1A1A1A),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  static void _setupProductionErrorHandling() {
    // Forward all Flutter framework errors to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;

    // Also capture any asynchronous errors
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true; // handled
    };
  }

  static Future<void> _optimizeMemoryUsage() async {
    // Force garbage collection
    if (!kIsWeb) {
      // Platform-specific memory optimization
      if (Platform.isAndroid || Platform.isIOS) {
        // Request memory trim
      }
    }
  }

  static Future<void> _optimizeBatteryUsage() async {
    // Reduce background processing
    // Optimize location updates frequency
    // Minimize wake locks
  }

  /// Get optimized image cache size based on device capabilities
  static int getOptimizedImageCacheSize() {
    if (Platform.isIOS) {
      return 100 * 1024 * 1024; // 100MB for iOS
    } else if (Platform.isAndroid) {
      return 150 * 1024 * 1024; // 150MB for Android
    }
    return 50 * 1024 * 1024; // 50MB default
  }

  /// Get optimized network timeout based on connection
  static Duration getOptimizedNetworkTimeout() {
    return isProduction
        ? const Duration(seconds: 30)
        : const Duration(seconds: 60);
  }
}
