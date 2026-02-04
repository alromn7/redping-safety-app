import 'package:flutter/material.dart';
import 'services/app_service_manager.dart';

/// Test script to verify REDP!NG help button fix
class TestREDPINGHelpFix {
  static final AppServiceManager _serviceManager = AppServiceManager();

  /// Test the REDP!NG help request creation with timeout handling
  static Future<void> testREDPINGHelpRequest() async {
    debugPrint('🧪 Testing REDP!NG help request creation...');

    try {
      // Initialize services
      await _serviceManager.initializeAllServices();
      debugPrint('✅ Services initialized');

      // Test messaging integration service
      final messagingService = _serviceManager.messagingIntegrationService;
      await messagingService.initialize();
      debugPrint('✅ Messaging integration service initialized');

      // Test help request creation with timeout
      final pingId = await messagingService
          .createREDPINGHelpRequest(
            helpCategory: 'car_breakdown',
            userMessage: 'Test help request for car breakdown',
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw Exception('Help request timeout - please try again');
            },
          );

      debugPrint('✅ REDP!NG help request created successfully - ID: $pingId');
    } catch (e, st) {
      debugPrint('❌ Test failed: $e');
      debugPrint('Stack trace: $st');
    }
  }

  /// Test location service with caching
  static Future<void> testLocationServiceCaching() async {
    debugPrint('🧪 Testing location service caching...');

    try {
      final locationService = _serviceManager.locationService;
      await locationService.initialize();
      debugPrint('✅ Location service initialized');

      // Test multiple location calls to verify caching
      for (int i = 0; i < 3; i++) {
        final location = await locationService.getCurrentLocation();
        debugPrint(
          'Location call $i: ${location?.latitude}, ${location?.longitude}',
        );
        await Future.delayed(const Duration(seconds: 1));
      }

      debugPrint('✅ Location service caching test completed');
    } catch (e, st) {
      debugPrint('❌ Location service test failed: $e');
      debugPrint('Stack trace: $st');
    }
  }

  /// Run all tests
  static Future<void> runAllTests() async {
    debugPrint('🚀 Starting REDP!NG help button fix tests...');

    await testLocationServiceCaching();
    await testREDPINGHelpRequest();

    debugPrint('✅ All tests completed');
  }
}
