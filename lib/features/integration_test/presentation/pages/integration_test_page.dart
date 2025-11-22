import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/integration_test_service.dart';

/// Page for testing integration between REDP!NG app and website
class IntegrationTestPage extends StatefulWidget {
  const IntegrationTestPage({super.key});

  @override
  State<IntegrationTestPage> createState() => _IntegrationTestPageState();
}

class _IntegrationTestPageState extends State<IntegrationTestPage> {
  final IntegrationTestService _integrationService = IntegrationTestService();

  bool _isLoading = false;
  Map<String, dynamic>? _testResults;
  String _statusMessage = 'Ready to test integration';

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      await _integrationService.initialize();
      setState(() {
        _statusMessage = 'Integration service initialized';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Failed to initialize: $e';
      });
    }
  }

  Future<void> _runFullTest() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Running integration tests...';
    });

    try {
      final results = await _integrationService.runFullIntegrationTest();
      setState(() {
        _testResults = results;
        _isLoading = false;
        _statusMessage = results['overall_success']
            ? 'All tests passed! ✅'
            : 'Some tests failed ❌';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Test failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Integration Test'),
        backgroundColor: AppTheme.darkSurface,
        foregroundColor: AppTheme.primaryText,
      ),
      backgroundColor: AppTheme.darkBackground,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: AppTheme.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: AppTheme.primaryText),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Test Button
            ElevatedButton(
              onPressed: _isLoading ? null : _runFullTest,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Run Full Integration Test'),
            ),

            const SizedBox(height: 16),

            // Results
            if (_testResults != null) ...[
              Card(
                color: AppTheme.cardBackground,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Results',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: AppTheme.primaryText),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Overall Success: ${_testResults!['overall_success'] ? '✅' : '❌'}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: _testResults!['overall_success']
                              ? AppTheme.accentGreen
                              : AppTheme.primaryRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tests Passed: ${_testResults!['success_count']}/${_testResults!['total_tests']}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Individual test results
                      if (_testResults!['results'] != null) ...[
                        Text(
                          'Individual Results:',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: AppTheme.primaryText,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        ...(_testResults!['results'] as Map<String, dynamic>)
                            .entries
                            .map(
                              (entry) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      entry.value
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: entry.value
                                          ? AppTheme.accentGreen
                                          : AppTheme.primaryRed,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      entry.key
                                          .replaceAll('_', ' ')
                                          .toUpperCase(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppTheme.secondaryText,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            const Spacer(),

            // Integration Status
            Card(
              color: AppTheme.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Integration Status',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: AppTheme.primaryText),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<Map<String, dynamic>>(
                      future: _getIntegrationStatus(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final status = snapshot.data!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'API Service: ${status['apiServiceStatus']['isConnected'] ? 'Connected' : 'Disconnected'}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color:
                                          status['apiServiceStatus']['isConnected']
                                          ? AppTheme.accentGreen
                                          : AppTheme.primaryRed,
                                    ),
                              ),
                              Text(
                                'WebSocket: ${status['websocketServiceStatus']['isAnyConnected'] ? 'Connected' : 'Disconnected'}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color:
                                          status['websocketServiceStatus']['isAnyConnected']
                                          ? AppTheme.accentGreen
                                          : AppTheme.primaryRed,
                                    ),
                              ),
                              Text(
                                'Configuration: ${status['configurationValid'] ? 'Valid' : 'Invalid'}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: status['configurationValid']
                                          ? AppTheme.accentGreen
                                          : AppTheme.primaryRed,
                                    ),
                              ),
                            ],
                          );
                        }
                        return const Text('Loading...');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _getIntegrationStatus() async {
    return _integrationService.getIntegrationStatus();
  }

  @override
  void dispose() {
    _integrationService.dispose();
    super.dispose();
  }
}
