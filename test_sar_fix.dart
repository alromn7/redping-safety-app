import 'package:flutter/material.dart';
import 'lib/services/app_service_manager.dart';

/// Test script to verify SAR functionality after fixing LateInitializationError
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🔧 Testing SAR subscription service fix...');

  try {
    // Initialize app service manager
    final appServiceManager = AppServiceManager();
    await appServiceManager.initializeAllServices();

    print('✅ App service manager initialized successfully');

    // Test feature access service
    final featureAccessService = appServiceManager.featureAccessService;
    print('✅ Feature access service accessible');

    // Test SAR feature access
    final canParticipateSAR = featureAccessService.canJoinSAROperations();
    final canManageOrgs = featureAccessService.canManageOrganizations();
    final sarAccessLevel = await featureAccessService.getSARAccessLevel();

    print('✅ SAR feature access tests:');
    print('   - Can join SAR operations: $canParticipateSAR');
    print('   - Can manage organizations: $canManageOrgs');
    print('   - SAR access level: $sarAccessLevel');

    // Test SAR service
    final sarService = appServiceManager.sarService;
    print(
      '✅ SAR service accessible: ${sarService.isInitialized ? 'Initialized' : 'Not initialized'}',
    );

    print(
      '\n🎉 All SAR functionality tests passed! No LateInitializationError detected.',
    );
  } catch (e) {
    print('❌ Error during SAR functionality test: $e');
    if (e.toString().contains('LateInitializationError')) {
      print('❌ LateInitializationError still present - fix not complete');
    } else {
      print('⚠️  Different error occurred - may need additional investigation');
    }
  }
}
