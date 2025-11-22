import 'package:flutter/material.dart';
import '../services/family_location_service.dart';
import '../services/geofence_service.dart';
import '../services/subscription_service.dart';
import '../models/auth_user.dart';
import '../models/subscription_tier.dart';

/// Helper class to generate test data for Family Tracking features
class FamilyTrackingTestData {
  /// Initialize test family subscription
  static Future<void> setupTestFamily() async {
    try {
      final subscriptionService = SubscriptionService.instance;
      await subscriptionService.initialize();

      // Check if family already exists
      if (subscriptionService.currentFamily != null) {
        debugPrint(
          'FamilyTrackingTestData: Family subscription already exists',
        );
        return;
      }

      // Create test family subscription
      await subscriptionService.createFamilySubscription(
        adminUserId: 'test_admin_001',
        paymentMethod: PaymentMethod.creditCard,
        familyName: 'Test Family',
      );

      // Add test family members
      await subscriptionService.addFamilyMember(
        familyId: subscriptionService.currentFamily!.id,
        userId: 'member_001',
        name: 'John Doe',
        assignedTier: SubscriptionTier.essentialPlus,
        email: 'john@example.com',
        relationship: 'Son',
      );

      await subscriptionService.addFamilyMember(
        familyId: subscriptionService.currentFamily!.id,
        userId: 'member_002',
        name: 'Jane Doe',
        assignedTier: SubscriptionTier.essentialPlus,
        email: 'jane@example.com',
        relationship: 'Daughter',
      );

      await subscriptionService.addFamilyMember(
        familyId: subscriptionService.currentFamily!.id,
        userId: 'member_003',
        name: 'Mary Doe',
        assignedTier: SubscriptionTier.pro,
        email: 'mary@example.com',
        relationship: 'Mother',
      );

      debugPrint('FamilyTrackingTestData: Created test family with 3 members');
    } catch (e) {
      debugPrint('FamilyTrackingTestData: Error setting up family - $e');
    }
  }

  /// Add test member locations
  static Future<void> addTestLocations() async {
    try {
      final locationService = FamilyLocationService.instance;
      await locationService.initialize();
      await locationService.enableSharing();

      // Test location: San Francisco area
      // John - At home
      await locationService.updateMemberLocation(
        memberId: 'member_001',
        memberName: 'John Doe',
        latitude: 37.7749,
        longitude: -122.4194,
        accuracy: 15.0,
        speed: 0.0,
        batteryLevel: 85,
      );

      // Jane - At school
      await locationService.updateMemberLocation(
        memberId: 'member_002',
        memberName: 'Jane Doe',
        latitude: 37.7849,
        longitude: -122.4094,
        accuracy: 12.0,
        speed: 0.5,
        batteryLevel: 45,
      );

      // Mary - Moving (in car)
      await locationService.updateMemberLocation(
        memberId: 'member_003',
        memberName: 'Mary Doe',
        latitude: 37.7949,
        longitude: -122.3994,
        accuracy: 20.0,
        speed: 15.5, // ~56 km/h
        batteryLevel: 92,
      );

      debugPrint('FamilyTrackingTestData: Added 3 member locations');
    } catch (e) {
      debugPrint('FamilyTrackingTestData: Error adding locations - $e');
    }
  }

  /// Create test geofence zones
  static Future<void> createTestGeofences() async {
    try {
      final geofenceService = GeofenceService.instance;
      await geofenceService.initialize();

      // Home zone
      await geofenceService.createZone(
        name: 'Home',
        centerLat: 37.7749,
        centerLon: -122.4194,
        radiusMeters: 200,
        createdBy: 'test_admin_001',
        description: 'Family home safe zone',
        color: '#4CAF50',
        alertOnEntry: false,
        alertOnExit: true,
      );

      // School zone
      await geofenceService.createZone(
        name: 'School',
        centerLat: 37.7849,
        centerLon: -122.4094,
        radiusMeters: 150,
        createdBy: 'test_admin_001',
        description: 'Children\'s school',
        color: '#2196F3',
        alertOnEntry: true,
        alertOnExit: true,
        allowedMembers: ['member_001', 'member_002'],
      );

      // Work zone
      await geofenceService.createZone(
        name: 'Office',
        centerLat: 37.7949,
        centerLon: -122.3994,
        radiusMeters: 100,
        createdBy: 'test_admin_001',
        description: 'Parent\'s workplace',
        color: '#FF9800',
        alertOnEntry: false,
        alertOnExit: false,
        allowedMembers: ['member_003'],
      );

      debugPrint('FamilyTrackingTestData: Created 3 geofence zones');
    } catch (e) {
      debugPrint('FamilyTrackingTestData: Error creating geofences - $e');
    }
  }

  /// Initialize all test data
  static Future<void> initializeAllTestData() async {
    debugPrint('FamilyTrackingTestData: Initializing all test data...');
    await setupTestFamily();
    await addTestLocations();
    await createTestGeofences();
    debugPrint('FamilyTrackingTestData: Test data initialization complete');
  }

  /// Clear all test data
  static Future<void> clearAllTestData() async {
    try {
      final locationService = FamilyLocationService.instance;
      final geofenceService = GeofenceService.instance;

      await locationService.initialize();
      await geofenceService.initialize();

      await locationService.clearAllLocations();
      await geofenceService.clearAllZones();

      debugPrint('FamilyTrackingTestData: Cleared all test data');
    } catch (e) {
      debugPrint('FamilyTrackingTestData: Error clearing test data - $e');
    }
  }
}
