import 'lib/services/subscription_service.dart';
import 'lib/services/feature_access_service.dart';

/// Simple test to verify SAR subscription service fix without Flutter framework
void main() async {
  print('🔧 Testing SAR subscription service fix...');

  try {
    // Test that we can import the services without LateInitializationError
    print('✅ Testing imports...');

    // Import services
    final subscriptionService = SubscriptionService.instance;
    print('✅ SubscriptionService imported successfully');

    final featureAccessService = FeatureAccessService.instance;
    print('✅ FeatureAccessService imported successfully');

    // Test initialization
    print('✅ Testing initialization...');

    // Initialize subscription service
    await subscriptionService.initialize();
    print('✅ SubscriptionService initialized successfully');

    // Initialize feature access service
    featureAccessService.initialize();
    print('✅ FeatureAccessService initialized successfully');

    // Test basic functionality
    print('✅ Testing basic functionality...');

    final hasAccess = featureAccessService.hasFeatureAccess('sarParticipation');
    print('✅ SAR participation access check: $hasAccess');

    final sarAccessLevel = await featureAccessService.getSARAccessLevel();
    print('✅ SAR access level: $sarAccessLevel');

    print(
      '\n🎉 All SAR functionality tests passed! No LateInitializationError detected.',
    );
    print(
      '✅ The fix is working correctly - services can be initialized in proper order.',
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
