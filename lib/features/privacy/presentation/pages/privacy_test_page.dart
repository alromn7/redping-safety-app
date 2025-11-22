import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/app_service_manager.dart';

/// Simple test page to debug privacy service
class PrivacyTestPage extends StatefulWidget {
  const PrivacyTestPage({super.key});

  @override
  State<PrivacyTestPage> createState() => _PrivacyTestPageState();
}

class _PrivacyTestPageState extends State<PrivacyTestPage> {
  final AppServiceManager _serviceManager = AppServiceManager();
  String _debugInfo = 'Loading...';

  @override
  void initState() {
    super.initState();
    _testService();
  }

  Future<void> _testService() async {
    try {
      debugPrint('PrivacyTestPage: Starting test...');

      // Check if service manager is initialized
      final isInitialized = _serviceManager.isInitialized;
      debugPrint(
        'PrivacyTestPage: Service manager initialized: $isInitialized',
      );

      if (!isInitialized) {
        await _serviceManager.initializeAllServices();
      }

      // Test privacy service
      final permissions = _serviceManager.privacySecurityService.permissions;
      final policies = _serviceManager.privacySecurityService.policies;
      final securityStatus =
          _serviceManager.privacySecurityService.currentSecurityStatus;

      setState(() {
        _debugInfo =
            '''
Service Manager Initialized: $isInitialized
Permissions Count: ${permissions.length}
Policies Count: ${policies.length}
Security Status: ${securityStatus != null ? 'Available' : 'Null'}

First Permission: ${permissions.isNotEmpty ? permissions.first.displayName : 'None'}
First Policy: ${policies.isNotEmpty ? policies.first.description : 'None'}
        ''';
      });

      debugPrint('PrivacyTestPage: Test completed');
    } catch (e) {
      setState(() {
        _debugInfo = 'Error: $e';
      });
      debugPrint('PrivacyTestPage: Error - $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Service Test'),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Service Debug Info:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _debugInfo,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testService,
                    child: const Text('Refresh Test'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.push('/settings/privacy'),
                    child: const Text('Go to Privacy Settings'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

















