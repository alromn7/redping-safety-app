/// Full App Functionality Test and Analysis
///
/// This file provides a comprehensive test and analysis of all REDP!NG
/// app functionalities, implementation status, and network wiring.
library;

import 'package:flutter/material.dart';
import 'services/app_service_manager.dart';
import 'models/sos_session.dart';

/// Comprehensive functionality test for the entire REDP!NG application
class FullAppFunctionalityTest {
  static final AppServiceManager _serviceManager = AppServiceManager();

  /// Test results storage
  static final Map<String, dynamic> _testResults = {};

  /// Run comprehensive functionality tests
  static Future<Map<String, dynamic>> runFullAppTests() async {
    debugPrint('🧪 Starting Full App Functionality Tests...');

    try {
      // Initialize all services
      await _initializeAllServices();

      // Test core functionalities
      await _testCoreFunctionalities();

      // Test SOS system
      await _testSOSSystem();

      // Test SAR system
      await _testSARSystem();

      // Test communication system
      await _testCommunicationSystem();

      // Test profile management
      await _testProfileManagement();

      // Test subscription system
      await _testSubscriptionSystem();

      // Test AI assistant
      await _testAIAssistant();

      // Test activity tracking
      await _testActivityTracking();

      // Test privacy and security
      await _testPrivacySecurity();

      // Test hazard alerts
      await _testHazardAlerts();

      // Test help system
      await _testHelpSystem();

      // Test network connectivity
      await _testNetworkConnectivity();

      // Test cross-emulator communication
      await _testCrossEmulatorCommunication();

      // Generate comprehensive report
      return _generateTestReport();
    } catch (e) {
      debugPrint('❌ Full App Test Error: $e');
      return {
        'status': 'error',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Initialize all services
  static Future<void> _initializeAllServices() async {
    debugPrint('🔧 Initializing all services...');

    try {
      await _serviceManager.initializeAllServices();
      _testResults['service_initialization'] = {
        'status': 'success',
        'message': 'All services initialized successfully',
        'timestamp': DateTime.now().toIso8601String(),
      };
      debugPrint('✅ All services initialized');
    } catch (e) {
      _testResults['service_initialization'] = {
        'status': 'error',
        'message': 'Service initialization failed: $e',
        'timestamp': DateTime.now().toIso8601String(),
      };
      debugPrint('❌ Service initialization failed: $e');
    }
  }

  /// Test core functionalities
  static Future<void> _testCoreFunctionalities() async {
    debugPrint('🎯 Testing core functionalities...');

    final coreTests = <String, dynamic>{};

    // Test service manager
    try {
      final isInitialized = _serviceManager.isInitialized;
      coreTests['service_manager'] = {
        'status': isInitialized ? 'success' : 'error',
        'message': isInitialized
            ? 'Service manager initialized'
            : 'Service manager not initialized',
      };
    } catch (e) {
      coreTests['service_manager'] = {
        'status': 'error',
        'message': 'Service manager test failed: $e',
      };
    }

    // Test location service
    try {
      final locationService = _serviceManager.locationService;
      final location = await locationService.getCurrentLocation();
      coreTests['location_service'] = {
        'status': location != null ? 'success' : 'warning',
        'message': location != null
            ? 'Location service working'
            : 'Location service not available',
        'location': location?.toJson(),
      };
    } catch (e) {
      coreTests['location_service'] = {
        'status': 'error',
        'message': 'Location service test failed: $e',
      };
    }

    // Test notification service
    try {
      _serviceManager.notificationService; // Access to verify it exists
      coreTests['notification_service'] = {
        'status': 'success',
        'message': 'Notification service available',
      };
    } catch (e) {
      coreTests['notification_service'] = {
        'status': 'error',
        'message': 'Notification service test failed: $e',
      };
    }

    _testResults['core_functionalities'] = coreTests;
    debugPrint('✅ Core functionalities tested');
  }

  /// Test SOS system
  static Future<void> _testSOSSystem() async {
    debugPrint('🚨 Testing SOS system...');

    final sosTests = <String, dynamic>{};

    try {
      final sosService = _serviceManager.sosService;

      // Test SOS countdown
      try {
        final session = await sosService.startSOSCountdown(
          type: SOSType.manual,
          userMessage: 'Test SOS message',
        );

        sosTests['sos_countdown'] = {
          'status': 'success',
          'message': 'SOS countdown started successfully',
          'session_id': session.id,
          'session_status': session.status.name,
        };

        // Cancel the test session
        sosService.cancelSOS();
      } catch (e) {
        sosTests['sos_countdown'] = {
          'status': 'error',
          'message': 'SOS countdown test failed: $e',
        };
      }

      // Test SOS ping service
      try {
        final sosPingService = _serviceManager.sosPingService;
        final activePings = sosPingService.getActivePings();

        sosTests['sos_ping_service'] = {
          'status': 'success',
          'message': 'SOS ping service working',
          'active_pings_count': activePings.length,
        };
      } catch (e) {
        sosTests['sos_ping_service'] = {
          'status': 'error',
          'message': 'SOS ping service test failed: $e',
        };
      }
    } catch (e) {
      sosTests['sos_system'] = {
        'status': 'error',
        'message': 'SOS system test failed: $e',
      };
    }

    _testResults['sos_system'] = sosTests;
    debugPrint('✅ SOS system tested');
  }

  /// Test SAR system
  static Future<void> _testSARSystem() async {
    debugPrint('🚁 Testing SAR system...');

    final sarTests = <String, dynamic>{};

    try {
      final sarService = _serviceManager.sarService;
      final sarMessagingService = _serviceManager.sarMessagingService;

      // Test SAR service initialization
      try {
        await sarService.initialize();
        sarTests['sar_service'] = {
          'status': 'success',
          'message': 'SAR service initialized',
        };
      } catch (e) {
        sarTests['sar_service'] = {
          'status': 'error',
          'message': 'SAR service initialization failed: $e',
        };
      }

      // Test SAR messaging service
      try {
        await sarMessagingService.initializeForTesting();
        sarTests['sar_messaging'] = {
          'status': 'success',
          'message': 'SAR messaging service initialized',
          'sar_member_id': sarMessagingService.sarMemberId,
          'sar_member_name': sarMessagingService.sarMemberName,
        };
      } catch (e) {
        sarTests['sar_messaging'] = {
          'status': 'error',
          'message': 'SAR messaging service test failed: $e',
        };
      }
    } catch (e) {
      sarTests['sar_system'] = {
        'status': 'error',
        'message': 'SAR system test failed: $e',
      };
    }

    _testResults['sar_system'] = sarTests;
    debugPrint('✅ SAR system tested');
  }

  /// Test communication system
  static Future<void> _testCommunicationSystem() async {
    debugPrint('💬 Testing communication system...');

    final communicationTests = <String, dynamic>{};

    try {
      final chatService = _serviceManager.chatService;
      final emergencyMessagingService =
          _serviceManager.emergencyMessagingService;

      // Test chat service
      try {
        await chatService.initialize();
        final chatRooms = chatService.chatRooms;

        communicationTests['chat_service'] = {
          'status': 'success',
          'message': 'Chat service initialized',
          'chat_rooms_count': chatRooms.length,
        };
      } catch (e) {
        communicationTests['chat_service'] = {
          'status': 'error',
          'message': 'Chat service test failed: $e',
        };
      }

      // Test emergency messaging service
      try {
        await emergencyMessagingService.initialize();
        communicationTests['emergency_messaging'] = {
          'status': 'success',
          'message': 'Emergency messaging service initialized',
        };
      } catch (e) {
        communicationTests['emergency_messaging'] = {
          'status': 'error',
          'message': 'Emergency messaging service test failed: $e',
        };
      }
    } catch (e) {
      communicationTests['communication_system'] = {
        'status': 'error',
        'message': 'Communication system test failed: $e',
      };
    }

    _testResults['communication_system'] = communicationTests;
    debugPrint('✅ Communication system tested');
  }

  /// Test profile management
  static Future<void> _testProfileManagement() async {
    debugPrint('👤 Testing profile management...');

    final profileTests = <String, dynamic>{};

    try {
      final profileService = _serviceManager.profileService;

      // Test profile service
      try {
        await profileService.initialize();
        final currentProfile = profileService.currentProfile;

        profileTests['profile_service'] = {
          'status': 'success',
          'message': 'Profile service initialized',
          'has_profile': currentProfile != null,
          'profile_id': currentProfile?.id,
        };
      } catch (e) {
        profileTests['profile_service'] = {
          'status': 'error',
          'message': 'Profile service test failed: $e',
        };
      }
    } catch (e) {
      profileTests['profile_management'] = {
        'status': 'error',
        'message': 'Profile management test failed: $e',
      };
    }

    _testResults['profile_management'] = profileTests;
    debugPrint('✅ Profile management tested');
  }

  /// Test subscription system
  static Future<void> _testSubscriptionSystem() async {
    debugPrint('💳 Testing subscription system...');

    final subscriptionTests = <String, dynamic>{};

    try {
      final subscriptionService = _serviceManager.subscriptionService;

      // Test subscription service
      try {
        await subscriptionService.initialize();
        final currentSubscription = subscriptionService.currentSubscription;
        final availablePlans = subscriptionService.availablePlans;

        subscriptionTests['subscription_service'] = {
          'status': 'success',
          'message': 'Subscription service initialized',
          'has_subscription': currentSubscription != null,
          'available_plans_count': availablePlans.length,
        };
      } catch (e) {
        subscriptionTests['subscription_service'] = {
          'status': 'error',
          'message': 'Subscription service test failed: $e',
        };
      }
    } catch (e) {
      subscriptionTests['subscription_system'] = {
        'status': 'error',
        'message': 'Subscription system test failed: $e',
      };
    }

    _testResults['subscription_system'] = subscriptionTests;
    debugPrint('✅ Subscription system tested');
  }

  /// Test AI assistant
  static Future<void> _testAIAssistant() async {
    debugPrint('🤖 Testing AI assistant...');

    final aiTests = <String, dynamic>{};

    try {
      final aiAssistantService = _serviceManager.aiAssistantService;

      // Test AI assistant service
      try {
        await aiAssistantService.initialize();
        aiTests['ai_assistant'] = {
          'status': 'success',
          'message': 'AI assistant service initialized',
        };
      } catch (e) {
        aiTests['ai_assistant'] = {
          'status': 'error',
          'message': 'AI assistant service test failed: $e',
        };
      }
    } catch (e) {
      aiTests['ai_assistant'] = {
        'status': 'error',
        'message': 'AI assistant test failed: $e',
      };
    }

    _testResults['ai_assistant'] = aiTests;
    debugPrint('✅ AI assistant tested');
  }

  /// Test activity tracking
  static Future<void> _testActivityTracking() async {
    debugPrint('🏃 Testing activity tracking...');

    final activityTests = <String, dynamic>{};

    try {
      final activityService = _serviceManager.activityService;

      // Test activity service
      try {
        await activityService.initialize();
        activityTests['activity_service'] = {
          'status': 'success',
          'message': 'Activity service initialized',
        };
      } catch (e) {
        activityTests['activity_service'] = {
          'status': 'error',
          'message': 'Activity service test failed: $e',
        };
      }
    } catch (e) {
      activityTests['activity_tracking'] = {
        'status': 'error',
        'message': 'Activity tracking test failed: $e',
      };
    }

    _testResults['activity_tracking'] = activityTests;
    debugPrint('✅ Activity tracking tested');
  }

  /// Test privacy and security
  static Future<void> _testPrivacySecurity() async {
    debugPrint('🔒 Testing privacy and security...');

    final privacyTests = <String, dynamic>{};

    try {
      final privacySecurityService = _serviceManager.privacySecurityService;

      // Test privacy security service
      try {
        await privacySecurityService.initialize();
        privacyTests['privacy_security'] = {
          'status': 'success',
          'message': 'Privacy security service initialized',
        };
      } catch (e) {
        privacyTests['privacy_security'] = {
          'status': 'error',
          'message': 'Privacy security service test failed: $e',
        };
      }
    } catch (e) {
      privacyTests['privacy_security'] = {
        'status': 'error',
        'message': 'Privacy security test failed: $e',
      };
    }

    _testResults['privacy_security'] = privacyTests;
    debugPrint('✅ Privacy and security tested');
  }

  /// Test hazard alerts
  static Future<void> _testHazardAlerts() async {
    debugPrint('⚠️ Testing hazard alerts...');

    final hazardTests = <String, dynamic>{};

    try {
      final hazardAlertService = _serviceManager.hazardService;

      // Test hazard alert service
      try {
        await hazardAlertService.initialize();
        hazardTests['hazard_alerts'] = {
          'status': 'success',
          'message': 'Hazard alert service initialized',
        };
      } catch (e) {
        hazardTests['hazard_alerts'] = {
          'status': 'error',
          'message': 'Hazard alert service test failed: $e',
        };
      }
    } catch (e) {
      hazardTests['hazard_alerts'] = {
        'status': 'error',
        'message': 'Hazard alerts test failed: $e',
      };
    }

    _testResults['hazard_alerts'] = hazardTests;
    debugPrint('✅ Hazard alerts tested');
  }

  /// Test help system
  static Future<void> _testHelpSystem() async {
    debugPrint('🆘 Testing help system...');

    final helpTests = <String, dynamic>{};

    try {
      final helpAssistantService = _serviceManager.helpAssistantService;

      // Test help assistant service
      try {
        await helpAssistantService.initialize();
        helpTests['help_system'] = {
          'status': 'success',
          'message': 'Help assistant service initialized',
        };
      } catch (e) {
        helpTests['help_system'] = {
          'status': 'error',
          'message': 'Help assistant service test failed: $e',
        };
      }
    } catch (e) {
      helpTests['help_system'] = {
        'status': 'error',
        'message': 'Help system test failed: $e',
      };
    }

    _testResults['help_system'] = helpTests;
    debugPrint('✅ Help system tested');
  }

  /// Test network connectivity
  static Future<void> _testNetworkConnectivity() async {
    debugPrint('🌐 Testing network connectivity...');

    final networkTests = <String, dynamic>{};

    try {
      // Test Firebase connectivity
      try {
        final sosPingService = _serviceManager.sosPingService;
        await sosPingService.initialize();

        networkTests['firebase_connectivity'] = {
          'status': 'success',
          'message': 'Firebase connectivity working',
        };
      } catch (e) {
        networkTests['firebase_connectivity'] = {
          'status': 'error',
          'message': 'Firebase connectivity test failed: $e',
        };
      }

      // Test location services
      try {
        final locationService = _serviceManager.locationService;
        final location = await locationService.getCurrentLocation();

        networkTests['location_services'] = {
          'status': location != null ? 'success' : 'warning',
          'message': location != null
              ? 'Location services working'
              : 'Location services not available',
        };
      } catch (e) {
        networkTests['location_services'] = {
          'status': 'error',
          'message': 'Location services test failed: $e',
        };
      }
    } catch (e) {
      networkTests['network_connectivity'] = {
        'status': 'error',
        'message': 'Network connectivity test failed: $e',
      };
    }

    _testResults['network_connectivity'] = networkTests;
    debugPrint('✅ Network connectivity tested');
  }

  /// Test cross-emulator communication
  static Future<void> _testCrossEmulatorCommunication() async {
    debugPrint('🔄 Testing cross-emulator communication...');

    final crossEmulatorTests = <String, dynamic>{};

    try {
      final messagingIntegrationService =
          _serviceManager.messagingIntegrationService;

      // Test messaging integration service
      try {
        await messagingIntegrationService.initialize();
        crossEmulatorTests['messaging_integration'] = {
          'status': 'success',
          'message': 'Messaging integration service initialized',
        };
      } catch (e) {
        crossEmulatorTests['messaging_integration'] = {
          'status': 'error',
          'message': 'Messaging integration service test failed: $e',
        };
      }
    } catch (e) {
      crossEmulatorTests['cross_emulator_communication'] = {
        'status': 'error',
        'message': 'Cross-emulator communication test failed: $e',
      };
    }

    _testResults['cross_emulator_communication'] = crossEmulatorTests;
    debugPrint('✅ Cross-emulator communication tested');
  }

  /// Generate comprehensive test report
  static Map<String, dynamic> _generateTestReport() {
    debugPrint('📊 Generating comprehensive test report...');

    final report = {
      'test_summary': {
        'total_tests': _testResults.length,
        'timestamp': DateTime.now().toIso8601String(),
        'app_version': 'REDP!NG v1.0.0',
      },
      'test_results': _testResults,
      'overall_status': _calculateOverallStatus(),
      'recommendations': _generateRecommendations(),
    };

    debugPrint('✅ Test report generated');
    return report;
  }

  /// Calculate overall test status
  static String _calculateOverallStatus() {
    int successCount = 0;
    int errorCount = 0;
    int warningCount = 0;

    for (final testCategory in _testResults.values) {
      if (testCategory is Map<String, dynamic>) {
        for (final test in testCategory.values) {
          if (test is Map<String, dynamic> && test.containsKey('status')) {
            switch (test['status']) {
              case 'success':
                successCount++;
                break;
              case 'error':
                errorCount++;
                break;
              case 'warning':
                warningCount++;
                break;
            }
          }
        }
      }
    }

    // Determine status based on test results
    final totalTests = successCount + errorCount + warningCount;

    if (totalTests == 0) {
      return 'no_tests';
    } else if (errorCount == 0 && warningCount == 0) {
      return 'excellent';
    } else if (errorCount == 0 && successCount > warningCount) {
      return 'good';
    } else if (errorCount < 3 && successCount >= errorCount) {
      return 'fair';
    } else {
      return 'poor';
    }
  }

  /// Generate recommendations based on test results
  static List<String> _generateRecommendations() {
    final recommendations = <String>[];

    // Check for common issues and provide recommendations
    if (_testResults.containsKey('service_initialization') &&
        _testResults['service_initialization']['status'] == 'error') {
      recommendations.add('Fix service initialization issues');
    }

    if (_testResults.containsKey('network_connectivity') &&
        _testResults['network_connectivity']['firebase_connectivity']['status'] ==
            'error') {
      recommendations.add('Check Firebase configuration and connectivity');
    }

    if (_testResults.containsKey('location_services') &&
        _testResults['location_services']['status'] == 'error') {
      recommendations.add('Verify location permissions and GPS functionality');
    }

    if (recommendations.isEmpty) {
      recommendations.add('All systems functioning properly');
    }

    return recommendations;
  }
}

/// Widget to display test results
class FullAppTestResultsWidget extends StatelessWidget {
  final Map<String, dynamic> testResults;

  const FullAppTestResultsWidget({super.key, required this.testResults});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Full App Test Results'),
        backgroundColor: Colors.blue[900],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTestSummary(),
            const SizedBox(height: 20),
            _buildTestResults(),
            const SizedBox(height: 20),
            _buildRecommendations(),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSummary() {
    final summary = testResults['test_summary'];
    final overallStatus = testResults['overall_status'];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 10),
            Text('Total Tests: ${summary['total_tests']}'),
            Text('Overall Status: ${overallStatus.toUpperCase()}'),
            Text('Timestamp: ${summary['timestamp']}'),
            Text('App Version: ${summary['app_version']}'),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResults() {
    final results = testResults['test_results'] as Map<String, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Test Results',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue[900],
          ),
        ),
        const SizedBox(height: 10),
        ...results.entries.map(
          (entry) => _buildTestCategory(entry.key, entry.value),
        ),
      ],
    );
  }

  Widget _buildTestCategory(String categoryName, dynamic categoryResults) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              categoryName.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (categoryResults is Map<String, dynamic>)
              ...categoryResults.entries.map(
                (entry) => _buildTestItem(entry.key, entry.value),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestItem(String itemName, dynamic itemResult) {
    if (itemResult is! Map<String, dynamic>) return const SizedBox();

    final status = itemResult['status'] ?? 'unknown';
    final message = itemResult['message'] ?? 'No message';

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'success':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'error':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      case 'warning':
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$itemName: $message',
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = testResults['recommendations'] as List<dynamic>;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommendations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            const SizedBox(height: 10),
            ...recommendations.map(
              (rec) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.amber, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(rec.toString())),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
