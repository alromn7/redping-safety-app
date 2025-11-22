import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_activity.dart';
import '../models/sos_session.dart'; // For LocationInfo
import 'location_service.dart';
import 'notification_service.dart';
import 'user_profile_service.dart';

/// Service for managing user activities and safety monitoring
class ActivityService {
  void wake() {
    // TODO: Implement wake logic if needed
    debugPrint('ActivityService: wake called');
  }

  void hibernate() {
    // TODO: Implement hibernate logic if needed
    debugPrint('ActivityService: hibernate called');
  }

  static final ActivityService _instance = ActivityService._internal();
  factory ActivityService() => _instance;
  ActivityService._internal();

  // Dependencies
  LocationService? _locationService;
  NotificationService? _notificationService;
  UserProfileService? _userProfileService;

  // State
  bool _isInitialized = false;
  UserActivity? _currentActivity;
  List<UserActivity> _activities = [];
  List<ActivityTemplate> _templates = [];
  ActivityPreferences _preferences = ActivityPreferences(
    lastUpdated: DateTime.now(),
  );

  // Check-in monitoring
  Timer? _checkInTimer;
  Timer? _locationTrackingTimer;

  // Callbacks
  Function(UserActivity)? _onActivityStarted;
  Function(UserActivity)? _onActivityUpdated;
  Function(UserActivity)? _onActivityEnded;
  Function(ActivityCheckIn)? _onCheckInRequired;

  /// Initialize the activity service
  Future<void> initialize({
    LocationService? locationService,
    NotificationService? notificationService,
    UserProfileService? userProfileService,
  }) async {
    if (_isInitialized) return;

    try {
      // Inject dependencies
      _locationService = locationService;
      _notificationService = notificationService;
      _userProfileService = userProfileService;

      // Load data
      await _loadActivities();
      await _loadPreferences();
      await _loadTemplates();

      // Setup monitoring
      _setupCheckInMonitoring();

      _isInitialized = true;
      debugPrint('ActivityService: Initialized successfully');
    } catch (e) {
      debugPrint('ActivityService: Initialization error - $e');
      throw Exception('Failed to initialize ActivityService: $e');
    }
  }

  /// Start a new activity
  Future<UserActivity> startActivity({
    required ActivityType type,
    required String title,
    String? description,
    String? customActivityName,
    ActivityRiskLevel? riskLevel,
    ActivityEnvironment? environment,
    Duration? estimatedDuration,
    List<ActivityEquipment>? equipment,
    List<String>? safetyNotes,
    bool? hasCheckInSchedule,
    Duration? checkInInterval,
  }) async {
    try {
      // Get current location
      final currentLocation = await _locationService?.getCurrentLocation();

      // Get template for default values
      final template = _getTemplateForActivity(type);

      final activity = UserActivity(
        id: _generateActivityId(),
        userId: _userProfileService?.currentProfile?.id ?? 'unknown',
        type: type,
        title: title,
        description: description,
        customActivityName: customActivityName,
        riskLevel:
            riskLevel ??
            template?.defaultRiskLevel ??
            ActivityRiskLevel.moderate,
        environment:
            environment ??
            template?.defaultEnvironment ??
            ActivityEnvironment.urban,
        status: ActivityStatus.active,
        createdAt: DateTime.now(),
        startTime: DateTime.now(),
        startLocation: currentLocation,
        currentLocation: currentLocation,
        breadcrumbs: currentLocation != null ? [currentLocation] : [],
        equipment: equipment ?? template?.recommendedEquipment ?? [],
        safetyNotes: safetyNotes ?? template?.safetyTips ?? [],
        hasCheckInSchedule:
            hasCheckInSchedule ?? template?.requiresCheckIn ?? false,
        checkInInterval:
            checkInInterval ??
            template?.recommendedCheckInInterval ??
            _preferences.defaultCheckInInterval,
        isHighRisk:
            (riskLevel ??
                template?.defaultRiskLevel ??
                ActivityRiskLevel.moderate) ==
            ActivityRiskLevel.extreme,
        requiresSpecialMonitoring: _requiresSpecialMonitoring(
          type,
          riskLevel ?? template?.defaultRiskLevel ?? ActivityRiskLevel.moderate,
        ),
        specialRequirements: template?.specialRequirements ?? [],
      );

      // End current activity if exists
      if (_currentActivity != null) {
        await endActivity(_currentActivity!.id, ActivityStatus.completed);
      }

      // Set as current activity
      _currentActivity = activity;
      _activities.add(activity);
      await _saveActivities();

      // Start monitoring
      _startActivityMonitoring(activity);

      // Notify
      _onActivityStarted?.call(activity);
      await _notificationService?.showNotification(
        title: '🎯 Activity Started',
        body: 'Started ${activity.title}. Stay safe!',
        importance: NotificationImportance.defaultImportance,
      );

      debugPrint('ActivityService: Started activity ${activity.title}');
      return activity;
    } catch (e) {
      debugPrint('ActivityService: Error starting activity - $e');
      throw Exception('Failed to start activity: $e');
    }
  }

  /// End an activity
  Future<void> endActivity(String activityId, ActivityStatus endStatus) async {
    try {
      final activityIndex = _activities.indexWhere((a) => a.id == activityId);
      if (activityIndex == -1) return;

      final activity = _activities[activityIndex];
      final updatedActivity = activity.copyWith(
        status: endStatus,
        endTime: DateTime.now(),
        currentLocation: await _locationService?.getCurrentLocation(),
      );

      _activities[activityIndex] = updatedActivity;

      if (_currentActivity?.id == activityId) {
        _currentActivity = null;
        _stopActivityMonitoring();
      }

      await _saveActivities();

      // Notify
      _onActivityEnded?.call(updatedActivity);
      await _notificationService?.showNotification(
        title: '✅ Activity Completed',
        body: 'Completed ${activity.title}',
        importance: NotificationImportance.defaultImportance,
      );

      debugPrint('ActivityService: Ended activity ${activity.title}');
    } catch (e) {
      debugPrint('ActivityService: Error ending activity - $e');
    }
  }

  /// Update current activity
  Future<void> updateCurrentActivity({
    String? description,
    ActivityStatus? status,
    LocationInfo? currentLocation,
    List<String>? safetyNotes,
    Map<String, dynamic>? activityData,
  }) async {
    if (_currentActivity == null) return;

    try {
      final updatedActivity = _currentActivity!.copyWith(
        description: description,
        status: status,
        currentLocation:
            currentLocation ?? await _locationService?.getCurrentLocation(),
        safetyNotes: safetyNotes,
        activityData: activityData,
      );

      final activityIndex = _activities.indexWhere(
        (a) => a.id == _currentActivity!.id,
      );
      if (activityIndex != -1) {
        _activities[activityIndex] = updatedActivity;
        _currentActivity = updatedActivity;
        await _saveActivities();

        _onActivityUpdated?.call(updatedActivity);
      }
    } catch (e) {
      debugPrint('ActivityService: Error updating activity - $e');
    }
  }

  /// Perform check-in for current activity
  Future<void> performCheckIn({
    String? message,
    String status = 'safe',
    bool isAutomatic = false,
  }) async {
    if (_currentActivity == null) return;

    try {
      final checkIn = ActivityCheckIn(
        id: _generateCheckInId(),
        activityId: _currentActivity!.id,
        timestamp: DateTime.now(),
        location: await _locationService?.getCurrentLocation(),
        status: status,
        message: message,
        isAutomatic: isAutomatic,
      );

      // Update activity with check-in
      final updatedActivity = _currentActivity!.copyWith(
        lastCheckIn: checkIn.timestamp,
        nextCheckInDue: _currentActivity!.hasCheckInSchedule
            ? checkIn.timestamp.add(
                _currentActivity!.checkInInterval ??
                    _preferences.defaultCheckInInterval,
              )
            : null,
      );

      final activityIndex = _activities.indexWhere(
        (a) => a.id == _currentActivity!.id,
      );
      if (activityIndex != -1) {
        _activities[activityIndex] = updatedActivity;
        _currentActivity = updatedActivity;
        await _saveActivities();
      }

      // Notify emergency contacts if configured
      if (_preferences.shareActivityWithContacts && status != 'safe') {
        await _notifyEmergencyContacts(checkIn);
      }

      debugPrint(
        'ActivityService: Check-in completed for ${_currentActivity!.title}',
      );
    } catch (e) {
      debugPrint('ActivityService: Error performing check-in - $e');
    }
  }

  /// Get activity templates
  List<ActivityTemplate> getActivityTemplates() {
    return List.unmodifiable(_templates);
  }

  /// Get template for specific activity type
  ActivityTemplate? getTemplateForActivity(ActivityType type) {
    return _getTemplateForActivity(type);
  }

  /// Get user's activities
  List<UserActivity> getUserActivities({ActivityStatus? status}) {
    if (status == null) {
      return List.unmodifiable(_activities);
    }
    return _activities.where((a) => a.status == status).toList();
  }

  /// Get recent activities
  List<UserActivity> getRecentActivities({int limit = 10}) {
    final sortedActivities = List<UserActivity>.from(_activities)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedActivities.take(limit).toList();
  }

  /// Update activity preferences
  Future<void> updatePreferences(ActivityPreferences newPreferences) async {
    try {
      _preferences = newPreferences.copyWith(lastUpdated: DateTime.now());
      await _savePreferences();

      // Restart monitoring with new preferences
      if (_currentActivity != null) {
        _setupCheckInMonitoring();
      }

      debugPrint('ActivityService: Preferences updated');
    } catch (e) {
      debugPrint('ActivityService: Error updating preferences - $e');
    }
  }

  /// Start activity monitoring
  void _startActivityMonitoring(UserActivity activity) {
    if (!activity.hasCheckInSchedule) return;

    _checkInTimer?.cancel();

    final interval =
        activity.checkInInterval ?? _preferences.defaultCheckInInterval;
    _checkInTimer = Timer.periodic(interval, (_) async {
      if (_currentActivity?.id == activity.id) {
        await _handleCheckInDue();
      }
    });

    // Start location tracking if enabled
    if (_preferences.enableLocationTracking) {
      _startLocationTracking();
    }

    debugPrint('ActivityService: Started monitoring for ${activity.title}');
  }

  /// Stop activity monitoring
  void _stopActivityMonitoring() {
    _checkInTimer?.cancel();
    _locationTrackingTimer?.cancel();
    debugPrint('ActivityService: Stopped activity monitoring');
  }

  /// Setup check-in monitoring
  void _setupCheckInMonitoring() {
    if (_currentActivity == null || !_currentActivity!.hasCheckInSchedule) {
      return;
    }

    final now = DateTime.now();
    final nextCheckIn = _currentActivity!.nextCheckInDue;

    if (nextCheckIn != null && nextCheckIn.isAfter(now)) {
      final timeUntilCheckIn = nextCheckIn.difference(now);

      Timer(timeUntilCheckIn, () async {
        if (_currentActivity != null) {
          await _handleCheckInDue();
        }
      });
    }
  }

  /// Handle when check-in is due
  Future<void> _handleCheckInDue() async {
    if (_currentActivity == null) return;

    try {
      // Notify user
      await _notificationService?.showNotification(
        title: '⏰ Check-In Required',
        body: 'Time to check in for ${_currentActivity!.title}',
        importance: NotificationImportance.high,
      );

      // Trigger callback
      final checkIn = ActivityCheckIn(
        id: _generateCheckInId(),
        activityId: _currentActivity!.id,
        timestamp: DateTime.now(),
        location: await _locationService?.getCurrentLocation(),
        status: 'pending',
        message: 'Automatic check-in reminder',
        isAutomatic: true,
      );

      _onCheckInRequired?.call(checkIn);

      debugPrint(
        'ActivityService: Check-in due for ${_currentActivity!.title}',
      );
    } catch (e) {
      debugPrint('ActivityService: Error handling check-in due - $e');
    }
  }

  /// Start location tracking for current activity
  void _startLocationTracking() {
    if (_currentActivity == null) return;

    _locationTrackingTimer?.cancel();
    _locationTrackingTimer = Timer.periodic(const Duration(minutes: 5), (
      _,
    ) async {
      if (_currentActivity != null) {
        final location = await _locationService?.getCurrentLocation();
        if (location != null) {
          await _updateActivityLocation(location);
        }
      }
    });
  }

  /// Update activity location
  Future<void> _updateActivityLocation(LocationInfo location) async {
    if (_currentActivity == null) return;

    try {
      final breadcrumbs = List<LocationInfo>.from(
        _currentActivity!.breadcrumbs,
      );
      breadcrumbs.add(location);

      // Keep only last 100 breadcrumbs to manage memory
      if (breadcrumbs.length > 100) {
        breadcrumbs.removeRange(0, breadcrumbs.length - 100);
      }

      final updatedActivity = _currentActivity!.copyWith(
        currentLocation: location,
        breadcrumbs: breadcrumbs,
      );

      final activityIndex = _activities.indexWhere(
        (a) => a.id == _currentActivity!.id,
      );
      if (activityIndex != -1) {
        _activities[activityIndex] = updatedActivity;
        _currentActivity = updatedActivity;
        await _saveActivities();
      }
    } catch (e) {
      debugPrint('ActivityService: Error updating activity location - $e');
    }
  }

  /// Notify emergency contacts about activity status
  Future<void> _notifyEmergencyContacts(ActivityCheckIn checkIn) async {
    if (_currentActivity == null) return;

    try {
      // Simplified - use main emergency contacts for now
      final contacts = [];
      if (contacts.isEmpty) return;

      final message =
          '''
🎯 Activity Update: ${_currentActivity!.title}

Status: ${checkIn.status.toUpperCase()}
Time: ${checkIn.timestamp.toString()}
${checkIn.location != null ? 'Location: ${checkIn.location!.latitude.toStringAsFixed(4)}, ${checkIn.location!.longitude.toStringAsFixed(4)}' : ''}
${checkIn.message != null ? 'Message: ${checkIn.message}' : ''}

This is an automated safety check-in.
''';

      for (final contact in contacts) {
        // In a real implementation, this would send actual messages
        debugPrint('ActivityService: Notifying ${contact.name} - $message');
      }

      await _notificationService?.showNotification(
        title: '📞 Emergency Contacts Notified',
        body: 'Activity status shared with ${contacts.length} contact(s)',
        importance: NotificationImportance.defaultImportance,
      );
    } catch (e) {
      debugPrint('ActivityService: Error notifying emergency contacts - $e');
    }
  }

  /// Load activity templates
  Future<void> _loadTemplates() async {
    try {
      // Load built-in templates
      _templates = _getBuiltInTemplates();

      // Custom templates will be added in future updates

      debugPrint(
        'ActivityService: Loaded ${_templates.length} activity templates',
      );
    } catch (e) {
      debugPrint('ActivityService: Error loading templates - $e');
    }
  }

  /// Get built-in activity templates
  List<ActivityTemplate> _getBuiltInTemplates() {
    return [
      ActivityTemplate(
        id: 'hiking_template',
        type: ActivityType.hiking,
        name: 'Hiking',
        description: 'Trail hiking and walking in natural areas',
        defaultRiskLevel: ActivityRiskLevel.moderate,
        defaultEnvironment: ActivityEnvironment.wilderness,
        recommendedEquipment: [
          ActivityEquipment(
            id: 'hiking_boots',
            name: 'Hiking Boots',
            description: 'Sturdy footwear for trail hiking',
            isRequired: true,
            isAvailable: true,
          ),
          ActivityEquipment(
            id: 'water_bottle',
            name: 'Water Bottle',
            description: 'Adequate hydration',
            isRequired: true,
            isAvailable: true,
          ),
          ActivityEquipment(
            id: 'first_aid',
            name: 'First Aid Kit',
            description: 'Basic medical supplies',
            isRequired: true,
            isAvailable: true,
          ),
        ],
        safetyTips: [
          'Tell someone your planned route',
          'Check weather conditions',
          'Carry emergency whistle',
          'Stay on marked trails',
        ],
        typicalDuration: const Duration(hours: 4),
        requiresCheckIn: true,
        recommendedCheckInInterval: const Duration(hours: 2),
        specialRequirements: ['GPS tracking recommended'],
      ),

      ActivityTemplate(
        id: 'fishing_template',
        type: ActivityType.fishing,
        name: 'Fishing',
        description: 'Recreational fishing activities',
        defaultRiskLevel: ActivityRiskLevel.low,
        defaultEnvironment: ActivityEnvironment.water,
        recommendedEquipment: [
          ActivityEquipment(
            id: 'life_jacket',
            name: 'Life Jacket',
            description: 'Personal flotation device',
            isRequired: true,
            isAvailable: true,
          ),
          ActivityEquipment(
            id: 'fishing_license',
            name: 'Fishing License',
            description: 'Valid fishing permit',
            isRequired: true,
            isAvailable: true,
          ),
        ],
        safetyTips: [
          'Wear life jacket near water',
          'Check weather and water conditions',
          'Inform others of your location',
        ],
        typicalDuration: const Duration(hours: 6),
        requiresCheckIn: false,
      ),

      ActivityTemplate(
        id: 'kayaking_template',
        type: ActivityType.kayaking,
        name: 'Kayaking',
        description: 'Paddling activities on water',
        defaultRiskLevel: ActivityRiskLevel.high,
        defaultEnvironment: ActivityEnvironment.water,
        recommendedEquipment: [
          ActivityEquipment(
            id: 'life_jacket_kayak',
            name: 'Life Jacket',
            description: 'Coast Guard approved PFD',
            isRequired: true,
            isAvailable: true,
          ),
          ActivityEquipment(
            id: 'whistle',
            name: 'Safety Whistle',
            description: 'Emergency signaling device',
            isRequired: true,
            isAvailable: true,
          ),
          ActivityEquipment(
            id: 'dry_bag',
            name: 'Dry Bag',
            description: 'Waterproof storage for phone/emergency items',
            isRequired: true,
            isAvailable: true,
          ),
        ],
        safetyTips: [
          'Always wear life jacket',
          'Check water and weather conditions',
          'Paddle with a buddy when possible',
          'Know your limits and skill level',
        ],
        typicalDuration: const Duration(hours: 4),
        requiresCheckIn: true,
        recommendedCheckInInterval: const Duration(hours: 1),
        specialRequirements: ['Water safety training recommended'],
      ),

      ActivityTemplate(
        id: 'driving_template',
        type: ActivityType.driving,
        name: 'Driving',
        description: 'Road travel and driving activities',
        defaultRiskLevel: ActivityRiskLevel.low,
        defaultEnvironment: ActivityEnvironment.urban,
        safetyTips: [
          'Ensure vehicle is in good condition',
          'Keep emergency kit in vehicle',
          'Share travel plans with others',
        ],
        requiresCheckIn: false,
      ),

      ActivityTemplate(
        id: 'fourwd_template',
        type: ActivityType.fourWD,
        name: '4WD Off-Road',
        description: 'Off-road driving and 4WD adventures',
        defaultRiskLevel: ActivityRiskLevel.high,
        defaultEnvironment: ActivityEnvironment.wilderness,
        recommendedEquipment: [
          ActivityEquipment(
            id: 'recovery_gear',
            name: 'Recovery Gear',
            description: 'Tow straps, shovel, etc.',
            isRequired: true,
            isAvailable: true,
          ),
          ActivityEquipment(
            id: 'spare_tire',
            name: 'Spare Tire',
            description: 'Full-size spare tire',
            isRequired: true,
            isAvailable: true,
          ),
          ActivityEquipment(
            id: 'emergency_kit',
            name: 'Emergency Kit',
            description: 'Food, water, blankets, tools',
            isRequired: true,
            isAvailable: true,
          ),
        ],
        safetyTips: [
          'Travel with another vehicle when possible',
          'Carry satellite communication device',
          'Know your route and alternate exits',
          'Check weather and trail conditions',
        ],
        typicalDuration: const Duration(hours: 8),
        requiresCheckIn: true,
        recommendedCheckInInterval: const Duration(hours: 2),
        specialRequirements: ['Satellite communication recommended'],
      ),

      ActivityTemplate(
        id: 'skydiving_template',
        type: ActivityType.skydiving,
        name: 'Skydiving',
        description: 'Parachuting and skydiving activities',
        defaultRiskLevel: ActivityRiskLevel.extreme,
        defaultEnvironment: ActivityEnvironment.rural,
        recommendedEquipment: [
          ActivityEquipment(
            id: 'parachute',
            name: 'Parachute System',
            description: 'Main and reserve parachutes',
            isRequired: true,
            isAvailable: true,
          ),
          ActivityEquipment(
            id: 'altimeter',
            name: 'Altimeter',
            description: 'Altitude measuring device',
            isRequired: true,
            isAvailable: true,
          ),
        ],
        safetyTips: [
          'Use certified equipment only',
          'Follow all safety protocols',
          'Check weather conditions',
          'Ensure proper training and certification',
        ],
        typicalDuration: const Duration(hours: 4),
        requiresCheckIn: true,
        recommendedCheckInInterval: const Duration(minutes: 30),
        specialRequirements: [
          'Professional supervision required',
          'Certification required',
        ],
      ),

      ActivityTemplate(
        id: 'scuba_diving_template',
        type: ActivityType.scubaDiving,
        name: 'Scuba Diving',
        description: 'Underwater diving with breathing apparatus',
        defaultRiskLevel: ActivityRiskLevel.extreme,
        defaultEnvironment: ActivityEnvironment.water,
        recommendedEquipment: [
          ActivityEquipment(
            id: 'scuba_gear',
            name: 'Scuba Gear',
            description: 'Complete diving equipment set',
            isRequired: true,
            isAvailable: true,
          ),
          ActivityEquipment(
            id: 'dive_computer',
            name: 'Dive Computer',
            description: 'Depth and decompression monitor',
            isRequired: true,
            isAvailable: true,
          ),
        ],
        safetyTips: [
          'Never dive alone',
          'Check equipment before each dive',
          'Plan your dive and dive your plan',
          'Monitor air supply constantly',
        ],
        typicalDuration: const Duration(hours: 3),
        requiresCheckIn: true,
        recommendedCheckInInterval: const Duration(minutes: 45),
        specialRequirements: ['Dive buddy required', 'Certification required'],
      ),

      // Add more templates for other activities...
      ActivityTemplate(
        id: 'swimming_template',
        type: ActivityType.swimming,
        name: 'Swimming',
        description: 'Swimming in pools, lakes, or ocean',
        defaultRiskLevel: ActivityRiskLevel.moderate,
        defaultEnvironment: ActivityEnvironment.water,
        safetyTips: [
          'Swim in designated areas',
          'Never swim alone',
          'Know your swimming ability',
          'Be aware of water conditions',
        ],
        requiresCheckIn: false,
      ),

      ActivityTemplate(
        id: 'remote_work_template',
        type: ActivityType.remoteWork,
        name: 'Remote Work',
        description: 'Working from remote locations',
        defaultRiskLevel: ActivityRiskLevel.low,
        defaultEnvironment: ActivityEnvironment.rural,
        safetyTips: [
          'Ensure reliable communication',
          'Have backup power source',
          'Share location with colleagues',
        ],
        requiresCheckIn: true,
        recommendedCheckInInterval: const Duration(hours: 4),
      ),
    ];
  }

  /// Get template for activity type
  ActivityTemplate? _getTemplateForActivity(ActivityType type) {
    try {
      return _templates.firstWhere((t) => t.type == type);
    } catch (e) {
      return null;
    }
  }

  /// Check if activity requires special monitoring
  bool _requiresSpecialMonitoring(
    ActivityType type,
    ActivityRiskLevel riskLevel,
  ) {
    if (riskLevel == ActivityRiskLevel.extreme) return true;

    switch (type) {
      case ActivityType.skydiving:
      case ActivityType.scubaDiving:
      case ActivityType.climbing:
      case ActivityType.fourWD:
        return true;
      default:
        return false;
    }
  }

  /// Load activities from storage
  Future<void> _loadActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activitiesJson = prefs.getString('user_activities');

      if (activitiesJson != null) {
        final List<dynamic> activitiesList = jsonDecode(activitiesJson);
        _activities = activitiesList
            .map((json) => UserActivity.fromJson(json))
            .toList();

        // Find current active activity
        _currentActivity =
            _activities
                .where((a) => a.status == ActivityStatus.active)
                .isNotEmpty
            ? _activities.firstWhere((a) => a.status == ActivityStatus.active)
            : null;
      }

      debugPrint('ActivityService: Loaded ${_activities.length} activities');
    } catch (e) {
      debugPrint('ActivityService: Error loading activities - $e');
    }
  }

  /// Save activities to storage
  Future<void> _saveActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final activitiesJson = jsonEncode(
        _activities.map((a) => a.toJson()).toList(),
      );
      await prefs.setString('user_activities', activitiesJson);
    } catch (e) {
      debugPrint('ActivityService: Error saving activities - $e');
    }
  }

  /// Load preferences from storage
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = prefs.getString('activity_preferences');

      if (preferencesJson != null) {
        final json = jsonDecode(preferencesJson);
        _preferences = ActivityPreferences.fromJson(json);
      }

      debugPrint('ActivityService: Preferences loaded');
    } catch (e) {
      debugPrint('ActivityService: Error loading preferences - $e');
    }
  }

  /// Save preferences to storage
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = jsonEncode(_preferences.toJson());
      await prefs.setString('activity_preferences', preferencesJson);
    } catch (e) {
      debugPrint('ActivityService: Error saving preferences - $e');
    }
  }

  /// Generate activity ID
  String _generateActivityId() {
    return 'activity_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  /// Generate check-in ID
  String _generateCheckInId() {
    return 'checkin_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  /// Set callbacks
  void setActivityStartedCallback(Function(UserActivity) callback) {
    _onActivityStarted = callback;
  }

  void setActivityUpdatedCallback(Function(UserActivity) callback) {
    _onActivityUpdated = callback;
  }

  void setActivityEndedCallback(Function(UserActivity) callback) {
    _onActivityEnded = callback;
  }

  void setCheckInRequiredCallback(Function(ActivityCheckIn) callback) {
    _onCheckInRequired = callback;
  }

  /// Dispose resources
  void dispose() {
    _checkInTimer?.cancel();
    _locationTrackingTimer?.cancel();
  }

  // Getters
  bool get isInitialized => _isInitialized;
  UserActivity? get currentActivity => _currentActivity;
  List<UserActivity> get activities => List.unmodifiable(_activities);
  ActivityPreferences get preferences => _preferences;
  bool get hasActiveActivity => _currentActivity != null;
}
