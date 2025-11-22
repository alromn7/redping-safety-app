import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'lib/services/location_service.dart';
import 'lib/services/location_sharing_service.dart';
import 'lib/services/app_service_manager.dart';

/// Comprehensive test for location sharing, phone map opening, and SAR integration
class LocationMapSARIntegrationTest {
  static final LocationMapSARIntegrationTest _instance =
      LocationMapSARIntegrationTest._internal();
  factory LocationMapSARIntegrationTest() => _instance;
  LocationMapSARIntegrationTest._internal();

  final AppServiceManager _serviceManager = AppServiceManager();
  bool _isInitialized = false;

  /// Initialize all services for testing
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🧪 LocationMapSARIntegrationTest: Initializing services...');

    try {
      // Initialize app service manager
      await _serviceManager.initializeAllServices();

      // Initialize location service
      await _serviceManager.locationService.initialize();

      // Initialize Firebase service
      await _serviceManager.firebaseService.initialize();

      // Initialize location sharing service
      await _serviceManager.locationSharingService.initialize();

      // Initialize emergency detection service
      await _serviceManager.emergencyDetectionService.initialize();

      _isInitialized = true;
      debugPrint(
        '✅ LocationMapSARIntegrationTest: All services initialized successfully',
      );
    } catch (e) {
      debugPrint('❌ LocationMapSARIntegrationTest: Initialization failed - $e');
      rethrow;
    }
  }

  /// Test location sharing functionality
  Future<Map<String, dynamic>> testLocationSharing() async {
    debugPrint('🧪 Testing Location Sharing...');

    final results = <String, dynamic>{
      'test_name': 'Location Sharing Test',
      'timestamp': DateTime.now().toIso8601String(),
      'tests': <Map<String, dynamic>>[],
      'overall_success': false,
    };

    try {
      // Test 1: Check location permission
      debugPrint('📍 Test 1: Checking location permission...');
      final hasPermission = await _serviceManager.locationService
          .hasLocationPermission();
      results['tests'].add({
        'name': 'Location Permission Check',
        'success': hasPermission,
        'details': hasPermission
            ? 'Location permission granted'
            : 'Location permission denied',
      });

      // Test 2: Get current location
      debugPrint('📍 Test 2: Getting current location...');
      Position? currentLocation;
      try {
        currentLocation = await LocationService.getCurrentLocationStatic();
        results['tests'].add({
          'name': 'Get Current Location',
          'success': true,
          'details':
              'Location: ${currentLocation.latitude}, ${currentLocation.longitude}',
          'accuracy': currentLocation.accuracy,
        });
      } catch (e) {
        results['tests'].add({
          'name': 'Get Current Location',
          'success': false,
          'details': 'Failed to get location: $e',
        });
      }

      // Test 3: Share location with SAR
      debugPrint('📍 Test 3: Sharing location with SAR...');
      try {
        await LocationSharingService.shareLocationWithSAR();
        results['tests'].add({
          'name': 'Share Location with SAR',
          'success': true,
          'details': 'Location shared with SAR system successfully',
        });
      } catch (e) {
        results['tests'].add({
          'name': 'Share Location with SAR',
          'success': false,
          'details': 'Failed to share location with SAR: $e',
        });
      }

      // Test 4: Share location with specific team
      debugPrint('📍 Test 4: Sharing location with specific SAR team...');
      try {
        await LocationSharingService.shareLocationWithTeam('test_team_123');
        results['tests'].add({
          'name': 'Share Location with Team',
          'success': true,
          'details': 'Location shared with SAR team successfully',
        });
      } catch (e) {
        results['tests'].add({
          'name': 'Share Location with Team',
          'success': false,
          'details': 'Failed to share location with team: $e',
        });
      }

      // Test 5: Share location with emergency contacts
      debugPrint('📍 Test 5: Sharing location with emergency contacts...');
      try {
        await LocationSharingService.shareLocationWithContacts();
        results['tests'].add({
          'name': 'Share Location with Contacts',
          'success': true,
          'details': 'Location shared with emergency contacts successfully',
        });
      } catch (e) {
        results['tests'].add({
          'name': 'Share Location with Contacts',
          'success': false,
          'details': 'Failed to share location with contacts: $e',
        });
      }

      // Calculate overall success
      final successfulTests = results['tests']
          .where((test) => test['success'] == true)
          .length;
      results['overall_success'] = successfulTests == results['tests'].length;
      results['success_rate'] = '$successfulTests/${results['tests'].length}';

      debugPrint(
        '✅ Location Sharing Test completed: ${results['success_rate']} tests passed',
      );
      return results;
    } catch (e) {
      debugPrint('❌ Location Sharing Test failed: $e');
      results['error'] = e.toString();
      return results;
    }
  }

  /// Test phone map opening functionality
  Future<Map<String, dynamic>> testPhoneMapOpening() async {
    debugPrint('🧪 Testing Phone Map Opening...');

    final results = <String, dynamic>{
      'test_name': 'Phone Map Opening Test',
      'timestamp': DateTime.now().toIso8601String(),
      'tests': <Map<String, dynamic>>[],
      'overall_success': false,
    };

    try {
      // Test coordinates (San Francisco)
      const testLat = 37.7749;
      const testLng = -122.4194;

      // Test 1: Open map with location
      debugPrint('🗺️ Test 1: Opening map with location...');
      try {
        await LocationService.openMapApp(testLat, testLng);
        results['tests'].add({
          'name': 'Open Map with Location',
          'success': true,
          'details': 'Map opened with coordinates: $testLat, $testLng',
        });
      } catch (e) {
        results['tests'].add({
          'name': 'Open Map with Location',
          'success': false,
          'details': 'Failed to open map: $e',
        });
      }

      // Test 2: Open map with navigation
      debugPrint('🗺️ Test 2: Opening map with navigation...');
      try {
        await LocationService.openMapWithNavigation(testLat, testLng);
        results['tests'].add({
          'name': 'Open Map with Navigation',
          'success': true,
          'details': 'Navigation opened to: $testLat, $testLng',
        });
      } catch (e) {
        results['tests'].add({
          'name': 'Open Map with Navigation',
          'success': false,
          'details': 'Failed to open navigation: $e',
        });
      }

      // Test 3: Open map with search
      debugPrint('🗺️ Test 3: Opening map with search...');
      try {
        await LocationService.openMapWithSearch('Emergency Services');
        results['tests'].add({
          'name': 'Open Map with Search',
          'success': true,
          'details': 'Map opened with search: Emergency Services',
        });
      } catch (e) {
        results['tests'].add({
          'name': 'Open Map with Search',
          'success': false,
          'details': 'Failed to open map search: $e',
        });
      }

      // Test 4: Open map with waypoints
      debugPrint('🗺️ Test 4: Opening map with waypoints...');
      try {
        final waypoints = [
          {'lat': testLat, 'lng': testLng},
          {'lat': 37.7849, 'lng': -122.4094},
        ];
        await LocationService.openMapWithWaypoints(waypoints);
        results['tests'].add({
          'name': 'Open Map with Waypoints',
          'success': true,
          'details': 'Map opened with ${waypoints.length} waypoints',
        });
      } catch (e) {
        results['tests'].add({
          'name': 'Open Map with Waypoints',
          'success': false,
          'details': 'Failed to open map with waypoints: $e',
        });
      }

      // Calculate overall success
      final successfulTests = results['tests']
          .where((test) => test['success'] == true)
          .length;
      results['overall_success'] = successfulTests == results['tests'].length;
      results['success_rate'] = '$successfulTests/${results['tests'].length}';

      debugPrint(
        '✅ Phone Map Opening Test completed: ${results['success_rate']} tests passed',
      );
      return results;
    } catch (e) {
      debugPrint('❌ Phone Map Opening Test failed: $e');
      results['error'] = e.toString();
      return results;
    }
  }

  /// Test SAR system integration
  Future<Map<String, dynamic>> testSARIntegration() async {
    debugPrint('🧪 Testing SAR System Integration...');

    final results = <String, dynamic>{
      'test_name': 'SAR System Integration Test',
      'timestamp': DateTime.now().toIso8601String(),
      'tests': <Map<String, dynamic>>[],
      'overall_success': false,
    };

    try {
      // Test 1: Check SAR service status
      debugPrint('🚁 Test 1: Checking SAR service status...');
      try {
        final sarService = _serviceManager.sarService;
        final status = sarService.getStatus();
        results['tests'].add({
          'name': 'SAR Service Status',
          'success': true,
          'details': 'SAR service status: $status',
        });
      } catch (e) {
        results['tests'].add({
          'name': 'SAR Service Status',
          'success': false,
          'details': 'Failed to get SAR service status: $e',
        });
      }

      // Test 2: Test emergency detection service
      debugPrint('🚁 Test 2: Testing emergency detection service...');
      try {
        final emergencyService = _serviceManager.emergencyDetectionService;
        final status = emergencyService.getStatus();
        results['tests'].add({
          'name': 'Emergency Detection Service',
          'success': true,
          'details': 'Emergency detection status: $status',
        });
      } catch (e) {
        results['tests'].add({
          'name': 'Emergency Detection Service',
          'success': false,
          'details': 'Failed to get emergency detection status: $e',
        });
      }

      // Test 3: Test Firebase service
      debugPrint('🚁 Test 3: Testing Firebase service...');
      try {
        final firebaseService = _serviceManager.firebaseService;
        final currentUser = firebaseService.currentUser;
        results['tests'].add({
          'name': 'Firebase Service',
          'success': true,
          'details':
              'Firebase service active, user: ${currentUser?.uid ?? 'anonymous'}',
        });
      } catch (e) {
        results['tests'].add({
          'name': 'Firebase Service',
          'success': false,
          'details': 'Failed to access Firebase service: $e',
        });
      }

      // Test 4: Test location service integration
      debugPrint('🚁 Test 4: Testing location service integration...');
      try {
        final locationService = _serviceManager.locationService;
        final status = locationService.getStatus();
        results['tests'].add({
          'name': 'Location Service Integration',
          'success': true,
          'details': 'Location service status: $status',
        });
      } catch (e) {
        results['tests'].add({
          'name': 'Location Service Integration',
          'success': false,
          'details': 'Failed to get location service status: $e',
        });
      }

      // Test 5: Test distance calculation
      debugPrint('🚁 Test 5: Testing distance calculation...');
      try {
        const lat1 = 37.7749;
        const lng1 = -122.4194;
        const lat2 = 37.7849;
        const lng2 = -122.4094;

        final distance = LocationService.getDistanceBetweenPoints(
          lat1,
          lng1,
          lat2,
          lng2,
        );
        results['tests'].add({
          'name': 'Distance Calculation',
          'success': true,
          'details':
              'Distance calculated: ${distance.toStringAsFixed(2)} meters',
        });
      } catch (e) {
        results['tests'].add({
          'name': 'Distance Calculation',
          'success': false,
          'details': 'Failed to calculate distance: $e',
        });
      }

      // Test 6: Test bearing calculation
      debugPrint('🚁 Test 6: Testing bearing calculation...');
      try {
        const lat1 = 37.7749;
        const lng1 = -122.4194;
        const lat2 = 37.7849;
        const lng2 = -122.4094;

        final bearing = LocationService.getBearingBetweenPoints(
          lat1,
          lng1,
          lat2,
          lng2,
        );
        results['tests'].add({
          'name': 'Bearing Calculation',
          'success': true,
          'details':
              'Bearing calculated: ${bearing.toStringAsFixed(2)} degrees',
        });
      } catch (e) {
        results['tests'].add({
          'name': 'Bearing Calculation',
          'success': false,
          'details': 'Failed to calculate bearing: $e',
        });
      }

      // Calculate overall success
      final successfulTests = results['tests']
          .where((test) => test['success'] == true)
          .length;
      results['overall_success'] = successfulTests == results['tests'].length;
      results['success_rate'] = '$successfulTests/${results['tests'].length}';

      debugPrint(
        '✅ SAR System Integration Test completed: ${results['success_rate']} tests passed',
      );
      return results;
    } catch (e) {
      debugPrint('❌ SAR System Integration Test failed: $e');
      results['error'] = e.toString();
      return results;
    }
  }

  /// Run all tests
  Future<Map<String, dynamic>> runAllTests() async {
    debugPrint(
      '🚀 Starting comprehensive Location, Map, and SAR integration tests...',
    );

    final allResults = <String, dynamic>{
      'test_suite': 'Location, Map, and SAR Integration Tests',
      'timestamp': DateTime.now().toIso8601String(),
      'tests': <Map<String, dynamic>>[],
      'overall_success': false,
    };

    try {
      // Initialize services
      await initialize();

      // Run location sharing tests
      debugPrint('\n📍 Running Location Sharing Tests...');
      final locationResults = await testLocationSharing();
      allResults['tests'].add(locationResults);

      // Run phone map opening tests
      debugPrint('\n🗺️ Running Phone Map Opening Tests...');
      final mapResults = await testPhoneMapOpening();
      allResults['tests'].add(mapResults);

      // Run SAR integration tests
      debugPrint('\n🚁 Running SAR System Integration Tests...');
      final sarResults = await testSARIntegration();
      allResults['tests'].add(sarResults);

      // Calculate overall success
      final successfulTestSuites = allResults['tests']
          .where((suite) => suite['overall_success'] == true)
          .length;
      allResults['overall_success'] =
          successfulTestSuites == allResults['tests'].length;
      allResults['success_rate'] =
          '$successfulTestSuites/${allResults['tests'].length}';

      debugPrint('\n🎉 All tests completed!');
      debugPrint('📊 Overall Success Rate: ${allResults['success_rate']}');
      debugPrint('✅ Overall Success: ${allResults['overall_success']}');

      return allResults;
    } catch (e) {
      debugPrint('❌ Test suite failed: $e');
      allResults['error'] = e.toString();
      return allResults;
    }
  }

  /// Print detailed test results
  void printDetailedResults(Map<String, dynamic> results) {
    debugPrint('\n📋 DETAILED TEST RESULTS');
    debugPrint('=' * 50);
    debugPrint('Test Suite: ${results['test_suite']}');
    debugPrint('Timestamp: ${results['timestamp']}');
    debugPrint('Overall Success: ${results['overall_success']}');
    debugPrint('Success Rate: ${results['success_rate']}');
    debugPrint('=' * 50);

    for (final testSuite in results['tests']) {
      debugPrint('\n🧪 ${testSuite['test_name']}');
      debugPrint('Success: ${testSuite['overall_success']}');
      debugPrint('Success Rate: ${testSuite['success_rate']}');

      for (final test in testSuite['tests']) {
        final status = test['success'] ? '✅' : '❌';
        debugPrint('  $status ${test['name']}: ${test['details']}');
      }
    }

    debugPrint('\n${'=' * 50}');
  }
}

/// Main function to run the tests
Future<void> main() async {
  debugPrint('🚀 Starting Location, Map, and SAR Integration Tests...');

  final testRunner = LocationMapSARIntegrationTest();

  try {
    // Run all tests
    final results = await testRunner.runAllTests();

    // Print detailed results
    testRunner.printDetailedResults(results);

    // Exit with appropriate code
    exit(results['overall_success'] ? 0 : 1);
  } catch (e) {
    debugPrint('❌ Test execution failed: $e');
    exit(1);
  }
}
