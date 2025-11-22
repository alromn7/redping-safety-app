import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/extreme_activity.dart';

/// Service for managing extreme activity sessions, equipment, and safety checks
class ExtremeActivityService {
  ExtremeActivityService._();
  static final ExtremeActivityService _instance = ExtremeActivityService._();
  static ExtremeActivityService get instance => _instance;

  // Stream controllers
  final StreamController<ExtremeActivitySession?> _activeSessionController =
      StreamController<ExtremeActivitySession?>.broadcast();
  final StreamController<List<EquipmentItem>> _equipmentController =
      StreamController<List<EquipmentItem>>.broadcast();
  final StreamController<List<SafetyChecklistItem>> _checklistController =
      StreamController<List<SafetyChecklistItem>>.broadcast();

  // Current state
  ExtremeActivitySession? _activeSession;
  List<ExtremeActivitySession> _sessionHistory = [];
  List<EquipmentItem> _equipment = [];
  List<SafetyChecklistItem> _checklist = [];
  List<SafetyCheck> _safetyChecks = [];
  bool _isInitialized = false;

  // Storage keys
  static const String _activeSessionKey = 'extreme_active_session';
  static const String _sessionHistoryKey = 'extreme_session_history';
  static const String _equipmentKey = 'extreme_equipment';
  static const String _checklistKey = 'extreme_checklist';
  static const String _safetyChecksKey = 'extreme_safety_checks';

  // Getters
  Stream<ExtremeActivitySession?> get activeSessionStream =>
      _activeSessionController.stream;
  Stream<List<EquipmentItem>> get equipmentStream =>
      _equipmentController.stream;
  Stream<List<SafetyChecklistItem>> get checklistStream =>
      _checklistController.stream;

  ExtremeActivitySession? get activeSession => _activeSession;
  List<ExtremeActivitySession> get sessionHistory =>
      List.unmodifiable(_sessionHistory);
  List<EquipmentItem> get equipment => List.unmodifiable(_equipment);
  List<SafetyChecklistItem> get checklist => List.unmodifiable(_checklist);
  bool get hasActiveSession =>
      _activeSession != null && _activeSession!.isActive;
  bool get isInitialized => _isInitialized;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('ExtremeActivityService: Already initialized');
      return;
    }

    try {
      await _loadData();
      await _initializeDefaultChecklist();
      _isInitialized = true;
      debugPrint('ExtremeActivityService: Initialized successfully');
    } catch (e) {
      debugPrint('ExtremeActivityService: Initialization error - $e');
      rethrow;
    }
  }

  /// Load data from storage
  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load active session
      final sessionJson = prefs.getString(_activeSessionKey);
      if (sessionJson != null) {
        _activeSession = ExtremeActivitySession.fromJson(
          jsonDecode(sessionJson),
        );
        _activeSessionController.add(_activeSession);
      }

      // Load session history
      final historyJson = prefs.getString(_sessionHistoryKey);
      if (historyJson != null) {
        final list = jsonDecode(historyJson) as List<dynamic>;
        _sessionHistory = list
            .map(
              (e) => ExtremeActivitySession.fromJson(e as Map<String, dynamic>),
            )
            .toList();
      }

      // Load equipment
      final equipmentJson = prefs.getString(_equipmentKey);
      if (equipmentJson != null) {
        final list = jsonDecode(equipmentJson) as List<dynamic>;
        _equipment = list
            .map((e) => EquipmentItem.fromJson(e as Map<String, dynamic>))
            .toList();
        _equipmentController.add(_equipment);
      }

      // Load checklist
      final checklistJson = prefs.getString(_checklistKey);
      if (checklistJson != null) {
        final list = jsonDecode(checklistJson) as List<dynamic>;
        _checklist = list
            .map((e) => SafetyChecklistItem.fromJson(e as Map<String, dynamic>))
            .toList();
        _checklistController.add(_checklist);
      }

      // Load safety checks
      final checksJson = prefs.getString(_safetyChecksKey);
      if (checksJson != null) {
        final list = jsonDecode(checksJson) as List<dynamic>;
        _safetyChecks = list
            .map((e) => SafetyCheck.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      debugPrint('ExtremeActivityService: Data loaded');
    } catch (e) {
      debugPrint('ExtremeActivityService: Error loading data - $e');
    }
  }

  /// Save data to storage
  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save active session
      if (_activeSession != null) {
        await prefs.setString(
          _activeSessionKey,
          jsonEncode(_activeSession!.toJson()),
        );
      } else {
        await prefs.remove(_activeSessionKey);
      }

      // Save session history
      await prefs.setString(
        _sessionHistoryKey,
        jsonEncode(_sessionHistory.map((e) => e.toJson()).toList()),
      );

      // Save equipment
      await prefs.setString(
        _equipmentKey,
        jsonEncode(_equipment.map((e) => e.toJson()).toList()),
      );

      // Save checklist
      await prefs.setString(
        _checklistKey,
        jsonEncode(_checklist.map((e) => e.toJson()).toList()),
      );

      // Save safety checks
      await prefs.setString(
        _safetyChecksKey,
        jsonEncode(_safetyChecks.map((e) => e.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('ExtremeActivityService: Error saving data - $e');
    }
  }

  /// Start a new activity session
  Future<ExtremeActivitySession> startSession({
    required String activityType,
    String? location,
    String? description,
    List<String>? equipmentIds,
    List<String>? buddies,
    WeatherConditions? conditions,
  }) async {
    try {
      if (_activeSession != null && _activeSession!.isActive) {
        throw Exception('Already have an active session');
      }

      final session = ExtremeActivitySession(
        id: 'session_${DateTime.now().millisecondsSinceEpoch}',
        activityType: activityType,
        startTime: DateTime.now(),
        location: location,
        description: description,
        equipmentUsed: equipmentIds ?? [],
        buddies: buddies ?? [],
        conditions: conditions,
      );

      _activeSession = session;
      _activeSessionController.add(_activeSession);
      await _saveData();

      debugPrint('ExtremeActivityService: Started session for $activityType');
      return session;
    } catch (e) {
      debugPrint('ExtremeActivityService: Error starting session - $e');
      rethrow;
    }
  }

  /// Update active session
  Future<void> updateSession({
    double? distance,
    Duration? duration,
    double? maxSpeed,
    double? maxAltitude,
    double? altitudeGain,
    double? altitudeLoss,
    double? averageSpeed,
    String? notes,
  }) async {
    if (_activeSession == null) return;

    _activeSession = _activeSession!.copyWith(
      distance: distance ?? _activeSession!.distance,
      duration: duration ?? _activeSession!.duration,
      maxSpeed: maxSpeed ?? _activeSession!.maxSpeed,
      maxAltitude: maxAltitude ?? _activeSession!.maxAltitude,
      altitudeGain: altitudeGain ?? _activeSession!.altitudeGain,
      altitudeLoss: altitudeLoss ?? _activeSession!.altitudeLoss,
      averageSpeed: averageSpeed ?? _activeSession!.averageSpeed,
      notes: notes ?? _activeSession!.notes,
    );

    _activeSessionController.add(_activeSession);
    await _saveData();
  }

  /// End active session
  Future<void> endSession({int? rating, String? notes}) async {
    if (_activeSession == null) return;

    _activeSession = _activeSession!.copyWith(
      endTime: DateTime.now(),
      rating: rating,
      notes: notes ?? _activeSession!.notes,
    );

    // Add to history
    _sessionHistory.insert(0, _activeSession!);
    if (_sessionHistory.length > 100) {
      _sessionHistory = _sessionHistory.sublist(0, 100);
    }

    _activeSession = null;
    _activeSessionController.add(null);
    await _saveData();

    debugPrint('ExtremeActivityService: Session ended');
  }

  /// Add incident to active session
  Future<void> addIncident(String incident) async {
    if (_activeSession == null) return;

    final incidents = [..._activeSession!.incidents, incident];
    _activeSession = _activeSession!.copyWith(incidents: incidents);
    _activeSessionController.add(_activeSession);
    await _saveData();
  }

  /// Get sessions for activity type
  List<ExtremeActivitySession> getSessionsForActivity(String activityType) {
    return _sessionHistory
        .where((s) => s.activityType == activityType)
        .toList();
  }

  /// Get activity statistics
  Map<String, dynamic> getActivityStats(String activityType) {
    final sessions = getSessionsForActivity(activityType);
    if (sessions.isEmpty) {
      return {};
    }

    final totalSessions = sessions.length;
    final totalDistance = sessions
        .where((s) => s.distance != null)
        .fold<double>(0, (sum, s) => sum + s.distance!);
    final totalDuration = sessions.fold<Duration>(
      Duration.zero,
      (sum, s) => sum + s.actualDuration,
    );
    final maxSpeed = sessions
        .where((s) => s.maxSpeed != null)
        .map((s) => s.maxSpeed!)
        .fold<double>(0, (max, s) => s > max ? s : max);
    final maxAltitude = sessions
        .where((s) => s.maxAltitude != null)
        .map((s) => s.maxAltitude!)
        .fold<double>(0, (max, s) => s > max ? s : max);
    final avgRating = sessions.where((s) => s.rating != null).isNotEmpty
        ? sessions
                  .where((s) => s.rating != null)
                  .fold<int>(0, (sum, s) => sum + s.rating!) /
              sessions.where((s) => s.rating != null).length
        : 0.0;

    return {
      'totalSessions': totalSessions,
      'totalDistance': totalDistance,
      'totalDuration': totalDuration,
      'maxSpeed': maxSpeed,
      'maxAltitude': maxAltitude,
      'averageRating': avgRating,
    };
  }

  // ====== EQUIPMENT MANAGEMENT ======

  /// Add equipment
  Future<void> addEquipment(EquipmentItem item) async {
    _equipment.add(item);
    _equipmentController.add(_equipment);
    await _saveData();
    debugPrint('ExtremeActivityService: Equipment added - ${item.name}');
  }

  /// Update equipment
  Future<void> updateEquipment(EquipmentItem item) async {
    final index = _equipment.indexWhere((e) => e.id == item.id);
    if (index != -1) {
      _equipment[index] = item;
      _equipmentController.add(_equipment);
      await _saveData();
    }
  }

  /// Remove equipment
  Future<void> removeEquipment(String id) async {
    _equipment.removeWhere((e) => e.id == id);
    _equipmentController.add(_equipment);
    await _saveData();
  }

  /// Get equipment for activity
  List<EquipmentItem> getEquipmentForActivity(String activityType) {
    return _equipment
        .where((e) => e.activityTypes.contains(activityType))
        .toList();
  }

  /// Get equipment needing inspection
  List<EquipmentItem> getEquipmentNeedingInspection() {
    return _equipment.where((e) => e.needsInspection).toList();
  }

  /// Get expired equipment
  List<EquipmentItem> getExpiredEquipment() {
    return _equipment.where((e) => e.isExpired).toList();
  }

  // ====== SAFETY CHECKLIST ======

  /// Initialize default checklist
  Future<void> _initializeDefaultChecklist() async {
    if (_checklist.isNotEmpty) return;

    _checklist = _getDefaultChecklist();
    _checklistController.add(_checklist);
    await _saveData();
  }

  /// Get default checklist items
  List<SafetyChecklistItem> _getDefaultChecklist() {
    return [
      // General checks
      const SafetyChecklistItem(
        id: 'check_weather',
        title: 'Check weather forecast',
        activityTypes: ['*'], // All activities
        description: 'Verify weather conditions are suitable for the activity',
        category: ChecklistCategory.weather,
        order: 1,
      ),
      const SafetyChecklistItem(
        id: 'check_equipment',
        title: 'Inspect equipment condition',
        activityTypes: ['*'],
        description: 'Ensure all equipment is in good condition',
        category: ChecklistCategory.equipment,
        order: 2,
      ),
      const SafetyChecklistItem(
        id: 'notify_someone',
        title: 'Notify someone of plans',
        activityTypes: ['*'],
        description:
            'Tell someone where you\'re going and expected return time',
        category: ChecklistCategory.communication,
        order: 3,
      ),
      const SafetyChecklistItem(
        id: 'check_emergency_contact',
        title: 'Verify emergency contact info',
        activityTypes: ['*'],
        description: 'Ensure emergency contacts are up to date',
        category: ChecklistCategory.communication,
        order: 4,
      ),

      // Skiing/Snowboarding
      const SafetyChecklistItem(
        id: 'avalanche_check',
        title: 'Check avalanche forecast',
        activityTypes: ['skiing'],
        description: 'Review avalanche danger ratings for the area',
        category: ChecklistCategory.weather,
        order: 10,
      ),
      const SafetyChecklistItem(
        id: 'beacon_check',
        title: 'Test avalanche beacon',
        activityTypes: ['skiing'],
        description: 'Ensure beacon is functional and batteries are good',
        category: ChecklistCategory.equipment,
        order: 11,
      ),

      // Climbing
      const SafetyChecklistItem(
        id: 'harness_check',
        title: 'Inspect harness',
        activityTypes: ['climbing'],
        description: 'Check for wear, damage, and proper buckles',
        category: ChecklistCategory.equipment,
        order: 20,
      ),
      const SafetyChecklistItem(
        id: 'rope_check',
        title: 'Inspect climbing rope',
        activityTypes: ['climbing'],
        description: 'Check for cuts, abrasions, or excessive wear',
        category: ChecklistCategory.equipment,
        order: 21,
      ),
      const SafetyChecklistItem(
        id: 'partner_check',
        title: 'Verify partner check completed',
        activityTypes: ['climbing'],
        description: 'Both climbers check each other\'s setup',
        category: ChecklistCategory.skills,
        order: 22,
      ),

      // Water activities
      const SafetyChecklistItem(
        id: 'life_jacket',
        title: 'Life jacket/PFD check',
        activityTypes: ['boating', 'swimming'],
        description:
            'Ensure life jacket fits properly and is in good condition',
        category: ChecklistCategory.equipment,
        order: 30,
      ),
      const SafetyChecklistItem(
        id: 'water_conditions',
        title: 'Check water conditions',
        activityTypes: ['boating', 'swimming', 'scuba_diving'],
        description: 'Verify tide, currents, and water temperature',
        category: ChecklistCategory.weather,
        order: 31,
      ),

      // Scuba diving
      const SafetyChecklistItem(
        id: 'dive_computer',
        title: 'Check dive computer',
        activityTypes: ['scuba_diving'],
        description: 'Verify dive computer is functioning',
        category: ChecklistCategory.equipment,
        order: 40,
      ),
      const SafetyChecklistItem(
        id: 'air_check',
        title: 'Check air supply',
        activityTypes: ['scuba_diving'],
        description: 'Verify tank is full and regulator works',
        category: ChecklistCategory.equipment,
        order: 41,
      ),

      // Skydiving
      const SafetyChecklistItem(
        id: 'parachute_inspect',
        title: 'Parachute inspection',
        activityTypes: ['skydiving'],
        description: 'Verify main and reserve parachutes are packed correctly',
        category: ChecklistCategory.equipment,
        order: 50,
      ),
      const SafetyChecklistItem(
        id: 'altimeter_check',
        title: 'Check altimeter',
        activityTypes: ['skydiving', 'flying'],
        description: 'Ensure altimeter is calibrated and functional',
        category: ChecklistCategory.equipment,
        order: 51,
      ),
    ];
  }

  /// Add custom checklist item
  Future<void> addChecklistItem(SafetyChecklistItem item) async {
    _checklist.add(item);
    _checklistController.add(_checklist);
    await _saveData();
  }

  /// Get checklist for activity
  List<SafetyChecklistItem> getChecklistForActivity(String activityType) {
    return _checklist
        .where(
          (c) =>
              c.activityTypes.contains('*') ||
              c.activityTypes.contains(activityType),
        )
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  /// Complete safety check
  Future<void> completeSafetyCheck({
    required String activityType,
    required String checklistItemId,
    bool passed = true,
    String? notes,
  }) async {
    final check = SafetyCheck(
      id: 'check_${DateTime.now().millisecondsSinceEpoch}',
      activityType: activityType,
      checklistItemId: checklistItemId,
      completedAt: DateTime.now(),
      passed: passed,
      notes: notes,
    );

    _safetyChecks.add(check);
    await _saveData();
  }

  /// Get completed checks for today
  List<SafetyCheck> getTodaysSafetyChecks(String activityType) {
    final today = DateTime.now();
    return _safetyChecks.where((c) {
      final checkDate = c.completedAt;
      return c.activityType == activityType &&
          checkDate.year == today.year &&
          checkDate.month == today.month &&
          checkDate.day == today.day;
    }).toList();
  }

  /// Check if all required items completed
  bool allRequiredChecksCompleted(String activityType) {
    final required = getChecklistForActivity(
      activityType,
    ).where((c) => c.isRequired).map((c) => c.id).toSet();
    final completed = getTodaysSafetyChecks(
      activityType,
    ).where((c) => c.passed).map((c) => c.checklistItemId).toSet();
    return required.every((id) => completed.contains(id));
  }

  /// Dispose of resources
  void dispose() {
    _activeSessionController.close();
    _equipmentController.close();
    _checklistController.close();
  }
}
