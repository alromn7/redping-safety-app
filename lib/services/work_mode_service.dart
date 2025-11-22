import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/work_shift.dart';

/// Service for managing work shifts, tasks, and time tracking
class WorkModeService {
  static final WorkModeService instance = WorkModeService._internal();
  WorkModeService._internal();

  // State
  WorkShift? _activeShift;
  List<WorkShift> _shifts = [];
  List<WorkplaceEmergencyContact> _emergencyContacts = [];

  // Streams
  final _activeShiftController = StreamController<WorkShift?>.broadcast();
  final _shiftsController = StreamController<List<WorkShift>>.broadcast();
  final _emergencyContactsController =
      StreamController<List<WorkplaceEmergencyContact>>.broadcast();

  Stream<WorkShift?> get activeShiftStream => _activeShiftController.stream;
  Stream<List<WorkShift>> get shiftsStream => _shiftsController.stream;
  Stream<List<WorkplaceEmergencyContact>> get emergencyContactsStream =>
      _emergencyContactsController.stream;

  // Getters
  WorkShift? get activeShift => _activeShift;
  List<WorkShift> get shifts => List.unmodifiable(_shifts);
  List<WorkplaceEmergencyContact> get emergencyContacts =>
      List.unmodifiable(_emergencyContacts);

  // Storage keys
  static const String _keyActiveShift = 'work_active_shift';
  static const String _keyShifts = 'work_shifts';
  static const String _keyEmergencyContacts = 'work_emergency_contacts';

  /// Initialize service and load data
  Future<void> initialize() async {
    await _loadFromStorage();
    _activeShiftController.add(_activeShift);
    _shiftsController.add(_shifts);
    _emergencyContactsController.add(_emergencyContacts);
  }

  /// Load data from storage
  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();

    // Load active shift
    final activeShiftJson = prefs.getString(_keyActiveShift);
    if (activeShiftJson != null) {
      _activeShift = WorkShift.fromJson(jsonDecode(activeShiftJson));
    }

    // Load shifts
    final shiftsJson = prefs.getString(_keyShifts);
    if (shiftsJson != null) {
      final List<dynamic> shiftsList = jsonDecode(shiftsJson);
      _shifts = shiftsList.map((s) => WorkShift.fromJson(s)).toList();
    }

    // Load emergency contacts
    final contactsJson = prefs.getString(_keyEmergencyContacts);
    if (contactsJson != null) {
      final List<dynamic> contactsList = jsonDecode(contactsJson);
      _emergencyContacts = contactsList
          .map((c) => WorkplaceEmergencyContact.fromJson(c))
          .toList();
    }
  }

  /// Save data to storage
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();

    // Save active shift
    if (_activeShift != null) {
      await prefs.setString(
        _keyActiveShift,
        jsonEncode(_activeShift!.toJson()),
      );
    } else {
      await prefs.remove(_keyActiveShift);
    }

    // Save shifts
    final shiftsJson = _shifts.map((s) => s.toJson()).toList();
    await prefs.setString(_keyShifts, jsonEncode(shiftsJson));

    // Save emergency contacts
    final contactsJson = _emergencyContacts.map((c) => c.toJson()).toList();
    await prefs.setString(_keyEmergencyContacts, jsonEncode(contactsJson));
  }

  // Shift Management

  /// Create new shift
  Future<WorkShift> createShift({
    required String jobTitle,
    required String employer,
    required DateTime shiftDate,
    required DateTime startTime,
    required DateTime endTime,
    required WorkShiftType type,
    required String location,
    String? address,
    String? supervisor,
    String? supervisorPhone,
    String? notes,
    String? uniformRequirements,
    String? equipment,
  }) async {
    final shift = WorkShift(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      jobTitle: jobTitle,
      employer: employer,
      shiftDate: shiftDate,
      startTime: startTime,
      endTime: endTime,
      status: WorkShiftStatus.scheduled,
      type: type,
      location: location,
      address: address,
      supervisor: supervisor,
      supervisorPhone: supervisorPhone,
      notes: notes,
      uniformRequirements: uniformRequirements,
      equipment: equipment,
    );

    _shifts.add(shift);
    _shifts.sort((a, b) => a.shiftDate.compareTo(b.shiftDate));
    await _saveToStorage();
    _shiftsController.add(_shifts);

    return shift;
  }

  /// Update shift
  Future<void> updateShift(WorkShift shift) async {
    final index = _shifts.indexWhere((s) => s.id == shift.id);
    if (index != -1) {
      _shifts[index] = shift;
      if (_activeShift?.id == shift.id) {
        _activeShift = shift;
        _activeShiftController.add(_activeShift);
      }
      await _saveToStorage();
      _shiftsController.add(_shifts);
    }
  }

  /// Delete shift
  Future<void> deleteShift(String shiftId) async {
    _shifts.removeWhere((s) => s.id == shiftId);
    if (_activeShift?.id == shiftId) {
      _activeShift = null;
      _activeShiftController.add(_activeShift);
    }
    await _saveToStorage();
    _shiftsController.add(_shifts);
  }

  /// Start shift (clock in)
  Future<void> startShift(String shiftId, {String? location}) async {
    // End any existing active shift
    if (_activeShift != null) {
      await endShift(_activeShift!.id);
    }

    final shift = _shifts.firstWhere((s) => s.id == shiftId);
    final now = DateTime.now();
    final scheduledStart = shift.startTime;
    final isLate = now.isAfter(scheduledStart.add(const Duration(minutes: 5)));

    final updatedShift = shift.copyWith(
      status: WorkShiftStatus.inProgress,
      timeTracking: WorkTimeTracking(
        clockInTime: now,
        clockInLocation: location,
        isLate: isLate,
      ),
    );

    await updateShift(updatedShift);
    _activeShift = updatedShift;
    _activeShiftController.add(_activeShift);
  }

  /// End shift (clock out)
  Future<void> endShift(String shiftId, {String? location}) async {
    final shift = _shifts.firstWhere((s) => s.id == shiftId);
    final now = DateTime.now();
    final scheduledEnd = shift.endTime;
    final isEarlyDeparture = now.isBefore(
      scheduledEnd.subtract(const Duration(minutes: 5)),
    );

    final updatedShift = shift.copyWith(
      status: WorkShiftStatus.completed,
      timeTracking: shift.timeTracking?.copyWith(
        clockOutTime: now,
        clockOutLocation: location,
        isEarlyDeparture: isEarlyDeparture,
      ),
    );

    await updateShift(updatedShift);
    if (_activeShift?.id == shiftId) {
      _activeShift = null;
      _activeShiftController.add(_activeShift);
    }
  }

  /// Get shifts by status
  List<WorkShift> getShiftsByStatus(WorkShiftStatus status) {
    return _shifts.where((s) => s.status == status).toList();
  }

  /// Get upcoming shifts
  List<WorkShift> getUpcomingShifts() {
    final now = DateTime.now();
    return _shifts
        .where(
          (s) =>
              s.status == WorkShiftStatus.scheduled && s.shiftDate.isAfter(now),
        )
        .toList();
  }

  /// Get past shifts
  List<WorkShift> getPastShifts() {
    return _shifts.where((s) => s.status == WorkShiftStatus.completed).toList();
  }

  /// Get today's shift
  WorkShift? getTodaysShift() {
    final now = DateTime.now();
    try {
      return _shifts.firstWhere(
        (s) =>
            s.shiftDate.year == now.year &&
            s.shiftDate.month == now.month &&
            s.shiftDate.day == now.day,
      );
    } catch (e) {
      return null;
    }
  }

  // Task Management

  /// Add task to shift
  Future<void> addTask(String shiftId, WorkTask task) async {
    final shift = _shifts.firstWhere((s) => s.id == shiftId);
    final updatedTasks = List<WorkTask>.from(shift.tasks)..add(task);
    final updatedShift = shift.copyWith(tasks: updatedTasks);
    await updateShift(updatedShift);
  }

  /// Update task
  Future<void> updateTask(String shiftId, WorkTask task) async {
    final shift = _shifts.firstWhere((s) => s.id == shiftId);
    final updatedTasks = shift.tasks
        .map((t) => t.id == task.id ? task : t)
        .toList();
    final updatedShift = shift.copyWith(tasks: updatedTasks);
    await updateShift(updatedShift);
  }

  /// Complete task
  Future<void> completeTask(String shiftId, String taskId) async {
    final shift = _shifts.firstWhere((s) => s.id == shiftId);
    final task = shift.tasks.firstWhere((t) => t.id == taskId);
    final completedTask = task.copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
    );
    await updateTask(shiftId, completedTask);
  }

  /// Remove task
  Future<void> removeTask(String shiftId, String taskId) async {
    final shift = _shifts.firstWhere((s) => s.id == shiftId);
    final updatedTasks = shift.tasks.where((t) => t.id != taskId).toList();
    final updatedShift = shift.copyWith(tasks: updatedTasks);
    await updateShift(updatedShift);
  }

  // Break Management

  /// Start break
  Future<void> startBreak(String shiftId, BreakType type) async {
    final shift = _shifts.firstWhere((s) => s.id == shiftId);
    final newBreak = WorkBreak(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      startTime: DateTime.now(),
    );
    final updatedBreaks = List<WorkBreak>.from(shift.breaks)..add(newBreak);
    final updatedShift = shift.copyWith(breaks: updatedBreaks);
    await updateShift(updatedShift);
  }

  /// End break
  Future<void> endBreak(String shiftId, String breakId) async {
    final shift = _shifts.firstWhere((s) => s.id == shiftId);
    final breakItem = shift.breaks.firstWhere((b) => b.id == breakId);
    final updatedBreak = WorkBreak(
      id: breakItem.id,
      type: breakItem.type,
      startTime: breakItem.startTime,
      endTime: DateTime.now(),
      notes: breakItem.notes,
    );
    final updatedBreaks = shift.breaks
        .map((b) => b.id == breakId ? updatedBreak : b)
        .toList();
    final updatedShift = shift.copyWith(breaks: updatedBreaks);
    await updateShift(updatedShift);
  }

  /// Get active break
  WorkBreak? getActiveBreak(String shiftId) {
    final shift = _shifts.firstWhere((s) => s.id == shiftId);
    try {
      return shift.breaks.firstWhere((b) => b.isActive);
    } catch (e) {
      return null;
    }
  }

  // Incident Management

  /// Report incident
  Future<void> reportIncident(String shiftId, WorkIncident incident) async {
    final shift = _shifts.firstWhere((s) => s.id == shiftId);
    final updatedIncidents = List<WorkIncident>.from(shift.incidents)
      ..add(incident);
    final updatedShift = shift.copyWith(incidents: updatedIncidents);
    await updateShift(updatedShift);
  }

  /// Get critical incidents
  List<WorkIncident> getCriticalIncidents(String shiftId) {
    final shift = _shifts.firstWhere((s) => s.id == shiftId);
    return shift.incidents
        .where((i) => i.severity == IncidentSeverity.critical)
        .toList();
  }

  /// Get incidents requiring follow-up
  List<WorkIncident> getIncidentsRequiringFollowUp() {
    final allIncidents = <WorkIncident>[];
    for (final shift in _shifts) {
      allIncidents.addAll(shift.incidents.where((i) => i.requiresFollowUp));
    }
    return allIncidents;
  }

  // Emergency Contacts Management

  /// Add emergency contact
  Future<void> addEmergencyContact(WorkplaceEmergencyContact contact) async {
    _emergencyContacts.add(contact);
    await _saveToStorage();
    _emergencyContactsController.add(_emergencyContacts);
  }

  /// Update emergency contact
  Future<void> updateEmergencyContact(
    int index,
    WorkplaceEmergencyContact contact,
  ) async {
    if (index >= 0 && index < _emergencyContacts.length) {
      _emergencyContacts[index] = contact;
      await _saveToStorage();
      _emergencyContactsController.add(_emergencyContacts);
    }
  }

  /// Remove emergency contact
  Future<void> removeEmergencyContact(int index) async {
    if (index >= 0 && index < _emergencyContacts.length) {
      _emergencyContacts.removeAt(index);
      await _saveToStorage();
      _emergencyContactsController.add(_emergencyContacts);
    }
  }

  // Statistics

  /// Get shift statistics
  Map<String, dynamic> getShiftStats(String shiftId) {
    final shift = _shifts.firstWhere((s) => s.id == shiftId);

    return {
      'scheduledHours': shift.scheduledDuration.inMinutes / 60,
      'actualHours': shift.actualDuration?.inMinutes != null
          ? shift.actualDuration!.inMinutes / 60
          : 0,
      'breakHours': shift.totalBreakTime.inMinutes / 60,
      'tasksCompleted': shift.completedTasksCount,
      'totalTasks': shift.totalTasksCount,
      'completionRate': shift.taskCompletionRate,
      'incidentsCount': shift.incidents.length,
      'criticalIncidents': shift.criticalIncidentsCount,
      'wasLate': shift.timeTracking?.isLate ?? false,
      'earlyDeparture': shift.timeTracking?.isEarlyDeparture ?? false,
    };
  }

  /// Get overall work statistics
  Map<String, dynamic> getOverallStats() {
    final totalShifts = _shifts
        .where((s) => s.status == WorkShiftStatus.completed)
        .length;
    final totalHours = _shifts
        .where((s) => s.status == WorkShiftStatus.completed)
        .fold<double>(
          0,
          (sum, s) => sum + (s.actualDuration?.inMinutes ?? 0) / 60,
        );

    final lateCount = _shifts
        .where((s) => s.timeTracking?.isLate ?? false)
        .length;
    final incidentCount = _shifts.fold<int>(
      0,
      (sum, s) => sum + s.incidents.length,
    );

    return {
      'totalShifts': totalShifts,
      'totalHours': totalHours,
      'lateShifts': lateCount,
      'totalIncidents': incidentCount,
      'upcomingShifts': getUpcomingShifts().length,
    };
  }

  /// Dispose streams
  void dispose() {
    _activeShiftController.close();
    _shiftsController.close();
    _emergencyContactsController.close();
  }
}
