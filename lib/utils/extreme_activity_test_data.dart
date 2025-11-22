import '../models/extreme_activity.dart';
import '../services/extreme_activity_service.dart';

/// Utility class to generate test data for extreme activities
class ExtremeActivityTestData {
  static final _service = ExtremeActivityService.instance;

  /// Generate comprehensive test data for all extreme activity features
  static Future<void> generateAll() async {
    await generateEquipment();
    await Future.delayed(const Duration(milliseconds: 100));
    print('✅ Extreme Activity Test Data Generated Successfully!');
    print('   - ${_service.equipment.length} equipment items');
    print('   - ${_service.checklist.length} safety checklist items');
  }

  /// Generate equipment for all activity types
  static Future<void> generateEquipment() async {
    final equipment = [
      // Skiing equipment
      EquipmentItem(
        id: 'helmet_ski_1',
        name: 'Smith Vantage MIPS Helmet',
        category: EquipmentCategory.helmet,
        activityTypes: const ['skiing', 'mountain_biking'],
        manufacturer: 'Smith',
        model: 'Vantage MIPS',
        condition: EquipmentCondition.excellent,
        purchaseDate: DateTime(2023, 11, 15),
        lastInspection: DateTime(2024, 12, 1),
        nextInspection: DateTime(2025, 6, 1),
      ),
      EquipmentItem(
        id: 'beacon_1',
        name: 'Mammut Barryvox S Avalanche Beacon',
        category: EquipmentCategory.avalancheBeacon,
        activityTypes: const ['skiing'],
        manufacturer: 'Mammut',
        model: 'Barryvox S',
        condition: EquipmentCondition.good,
        purchaseDate: DateTime(2022, 10, 1),
        lastInspection: DateTime(2024, 11, 15),
        nextInspection: DateTime(2025, 5, 15),
        notes: 'Batteries replaced monthly',
      ),
      EquipmentItem(
        id: 'probe_1',
        name: 'BCA Stealth 270 Probe',
        category: EquipmentCategory.probe,
        activityTypes: const ['skiing'],
        manufacturer: 'BCA',
        model: 'Stealth 270',
        condition: EquipmentCondition.excellent,
        purchaseDate: DateTime(2023, 9, 20),
      ),
      EquipmentItem(
        id: 'shovel_1',
        name: 'Black Diamond Transfer Shovel',
        category: EquipmentCategory.shovel,
        activityTypes: const ['skiing'],
        manufacturer: 'Black Diamond',
        model: 'Transfer',
        condition: EquipmentCondition.good,
        purchaseDate: DateTime(2022, 11, 5),
      ),

      // Climbing equipment
      EquipmentItem(
        id: 'harness_climb_1',
        name: 'Petzl Corax Climbing Harness',
        category: EquipmentCategory.harness,
        activityTypes: const ['climbing'],
        manufacturer: 'Petzl',
        model: 'Corax',
        condition: EquipmentCondition.good,
        purchaseDate: DateTime(2021, 5, 10),
        lastInspection: DateTime(2024, 10, 1),
        nextInspection: DateTime(2025, 4, 1),
        notes: 'Check for wear on belay loop',
      ),
      EquipmentItem(
        id: 'rope_climb_1',
        name: 'Mammut 9.5mm Infinity Dry Rope',
        category: EquipmentCategory.rope,
        activityTypes: const ['climbing'],
        manufacturer: 'Mammut',
        model: '9.5 Infinity Dry',
        serialNumber: 'INF-95-2022-4567',
        condition: EquipmentCondition.fair,
        purchaseDate: DateTime(2020, 3, 15),
        lastInspection: DateTime(2024, 9, 10),
        nextInspection: DateTime(2025, 3, 10),
        notes: 'Some sheath wear, still safe. Replace in 2025.',
      ),
      EquipmentItem(
        id: 'carabiner_set_1',
        name: 'Black Diamond RockLock Carabiner (Set of 5)',
        category: EquipmentCategory.carabiner,
        activityTypes: const ['climbing'],
        manufacturer: 'Black Diamond',
        model: 'RockLock',
        condition: EquipmentCondition.excellent,
        purchaseDate: DateTime(2023, 6, 20),
      ),

      // Water sports equipment
      EquipmentItem(
        id: 'wetsuit_1',
        name: 'O\'Neill Reactor 3/2mm Wetsuit',
        category: EquipmentCategory.wetsuit,
        activityTypes: const ['scuba_diving', 'swimming'],
        manufacturer: 'O\'Neill',
        model: 'Reactor 3/2',
        condition: EquipmentCondition.good,
        purchaseDate: DateTime(2022, 4, 10),
      ),
      EquipmentItem(
        id: 'life_jacket_1',
        name: 'Mustang Survival Elite Inflatable PFD',
        category: EquipmentCategory.lifeJacket,
        activityTypes: const ['boating'],
        manufacturer: 'Mustang Survival',
        model: 'Elite Inflatable',
        condition: EquipmentCondition.excellent,
        purchaseDate: DateTime(2023, 7, 1),
        lastInspection: DateTime(2024, 11, 20),
        nextInspection: DateTime(2025, 5, 20),
        notes: 'CO2 cartridge checked and valid',
      ),

      // Skydiving equipment
      EquipmentItem(
        id: 'parachute_main_1',
        name: 'Icarus Safire 3 Main Parachute',
        category: EquipmentCategory.parachute,
        activityTypes: const ['skydiving'],
        manufacturer: 'Icarus',
        model: 'Safire 3',
        serialNumber: 'SAF3-2021-8901',
        condition: EquipmentCondition.excellent,
        purchaseDate: DateTime(2021, 8, 15),
        lastInspection: DateTime(2024, 12, 5),
        nextInspection: DateTime(2025, 3, 5),
        notes: 'Last repack: Dec 2024. 180 jumps.',
      ),
      EquipmentItem(
        id: 'parachute_reserve_1',
        name: 'PD Optimum Reserve Parachute',
        category: EquipmentCategory.reserve,
        activityTypes: const ['skydiving'],
        manufacturer: 'Performance Designs',
        model: 'Optimum',
        serialNumber: 'OPT-2020-3456',
        condition: EquipmentCondition.excellent,
        purchaseDate: DateTime(2020, 10, 1),
        lastInspection: DateTime(2024, 10, 1),
        nextInspection: DateTime(2025, 4, 1),
        notes: 'FAA certified repack required every 180 days',
      ),

      // General/Universal equipment
      EquipmentItem(
        id: 'gps_1',
        name: 'Garmin inReach Mini 2',
        category: EquipmentCategory.gps,
        activityTypes: const [
          'skiing',
          'climbing',
          'hiking',
          'mountain_biking',
          'offroad_4wd',
        ],
        manufacturer: 'Garmin',
        model: 'inReach Mini 2',
        condition: EquipmentCondition.excellent,
        purchaseDate: DateTime(2023, 3, 10),
        notes: 'Subscription active until Dec 2025',
      ),
      EquipmentItem(
        id: 'radio_1',
        name: 'Motorola T600 Two-Way Radio (Pair)',
        category: EquipmentCategory.radio,
        activityTypes: const [
          'skiing',
          'climbing',
          'hiking',
          'mountain_biking',
          'offroad_4wd',
        ],
        manufacturer: 'Motorola',
        model: 'T600',
        condition: EquipmentCondition.good,
        purchaseDate: DateTime(2022, 6, 15),
      ),
      EquipmentItem(
        id: 'first_aid_1',
        name: 'Adventure Medical Kits Ultralight/Watertight .9',
        category: EquipmentCategory.firstAid,
        activityTypes: const [
          'skiing',
          'climbing',
          'hiking',
          'mountain_biking',
          'trail_running',
          'offroad_4wd',
        ],
        manufacturer: 'Adventure Medical Kits',
        model: 'Ultralight/Watertight .9',
        condition: EquipmentCondition.good,
        purchaseDate: DateTime(2023, 1, 5),
        lastInspection: DateTime(2024, 11, 1),
        nextInspection: DateTime(2025, 5, 1),
        notes: 'Check expiry dates on medications',
      ),

      // 4WD equipment
      EquipmentItem(
        id: 'recovery_gear_1',
        name: 'ARB Recovery Kit',
        category: EquipmentCategory.other,
        activityTypes: const ['offroad_4wd'],
        manufacturer: 'ARB',
        model: 'Complete Recovery Kit',
        condition: EquipmentCondition.good,
        purchaseDate: DateTime(2022, 9, 20),
        notes: 'Includes snatch strap, shackles, gloves, and bag',
      ),

      // Expired/needs attention items for testing alerts
      EquipmentItem(
        id: 'helmet_old_1',
        name: 'Giro Range MIPS Helmet (OLD)',
        category: EquipmentCategory.helmet,
        activityTypes: const ['skiing'],
        manufacturer: 'Giro',
        model: 'Range MIPS',
        condition: EquipmentCondition.fair,
        purchaseDate: DateTime(2018, 11, 1), // >5 years = expired
        lastInspection: DateTime(2024, 8, 15),
        nextInspection: DateTime(2024, 11, 15), // Overdue!
        notes: 'EXPIRED - Replace immediately. Do not use.',
      ),
    ];

    for (final item in equipment) {
      await _service.addEquipment(item);
    }

    print('Added ${equipment.length} equipment items');
  }

  /// Generate sample activity sessions
  static Future<void> generateSessions() async {
    final sessions = [
      // Completed skiing session
      ExtremeActivitySession(
        id: 'session_ski_1',
        activityType: 'skiing',
        startTime: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
        endTime: DateTime.now().subtract(const Duration(days: 2)),
        location: 'Whistler Blackcomb, BC',
        description: 'Blue run practice',
        distance: 15.3,
        duration: const Duration(hours: 4),
        maxSpeed: 52.3,
        averageSpeed: 28.5,
        maxAltitude: 2284,
        altitudeGain: 450,
        altitudeLoss: 2100,
        equipmentUsed: ['helmet_ski_1', 'beacon_1', 'probe_1', 'shovel_1'],
        conditions: const WeatherConditions(
          temperature: -5,
          windSpeed: 15,
          windDirection: 'NW',
          visibility: 8,
          conditions: 'Partly cloudy',
          cloudCover: 40,
        ),
        buddies: ['Sarah', 'Mike'],
        rating: 5,
        notes: 'Perfect conditions! Fresh powder on upper runs.',
      ),

      // Completed climbing session
      ExtremeActivitySession(
        id: 'session_climb_1',
        activityType: 'climbing',
        startTime: DateTime.now().subtract(const Duration(days: 5, hours: 3)),
        endTime: DateTime.now().subtract(const Duration(days: 5)),
        location: 'Squamish Chief, BC',
        description: 'Multi-pitch climbing',
        duration: const Duration(hours: 3),
        maxAltitude: 650,
        altitudeGain: 350,
        equipmentUsed: [
          'harness_climb_1',
          'rope_climb_1',
          'carabiner_set_1',
          'helmet_ski_1',
        ],
        conditions: const WeatherConditions(
          temperature: 18,
          windSpeed: 8,
          conditions: 'Sunny',
          cloudCover: 10,
        ),
        buddies: ['Alex'],
        rating: 4,
        notes: 'Completed Diedre route. Some challenging sections.',
      ),
    ];

    // Note: Sessions would normally be managed through the service's
    // startSession/endSession flow. This is for test data only.
    print('Generated ${sessions.length} example sessions');
  }

  /// Clear all test data
  static Future<void> clearAll() async {
    // Clear equipment
    for (final item in _service.equipment) {
      await _service.removeEquipment(item.id);
    }
    print('Cleared all test data');
  }
}
