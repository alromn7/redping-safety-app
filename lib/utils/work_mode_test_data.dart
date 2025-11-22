import '../models/work_shift.dart';
import '../services/work_mode_service.dart';

/// Utility class to generate test data for work mode
class WorkModeTestData {
  static final _service = WorkModeService.instance;

  /// Generate comprehensive test data for work mode
  static Future<void> generateAll() async {
    await generateShifts();
    await generateEmergencyContacts();
    await Future.delayed(const Duration(milliseconds: 100));
    print('✅ Work Mode Test Data Generated Successfully!');
    print('   - ${_service.shifts.length} shifts');
    print('   - ${_service.emergencyContacts.length} emergency contacts');
  }

  /// Generate sample shifts
  static Future<void> generateShifts() async {
    // Active shift - started 2 hours ago
    final activeShift = await _service.createShift(
      jobTitle: 'Security Guard',
      employer: 'SecureZone Security Services',
      shiftDate: DateTime.now(),
      startTime: DateTime.now().subtract(const Duration(hours: 2)),
      endTime: DateTime.now().add(const Duration(hours: 6)),
      type: WorkShiftType.regular,
      location: 'Downtown Office Complex',
      address: '456 Business Park Dr',
      supervisor: 'Mike Johnson',
      supervisorPhone: '+1-555-0200',
      uniformRequirements: 'Full security uniform, badge, radio',
      equipment: 'Radio, flashlight, incident report forms',
      notes: 'Check all entry points every hour',
    );

    // Start the shift (clock in)
    await _service.startShift(
      activeShift.id,
      location: 'Downtown Office Complex',
    );

    // Add tasks to active shift
    await _service.addTask(
      activeShift.id,
      const WorkTask(
        id: 'task_1',
        title: 'Morning patrol - all floors',
        description: 'Check all floors, test emergency exits',
        priority: TaskPriority.high,
      ),
    );

    await _service.addTask(
      activeShift.id,
      const WorkTask(
        id: 'task_2',
        title: 'Check security cameras',
        description: 'Verify all cameras operational',
        priority: TaskPriority.high,
      ),
    );

    await _service.addTask(
      activeShift.id,
      const WorkTask(
        id: 'task_3',
        title: 'Test alarm systems',
        description: 'Test fire alarm and intrusion detection',
        priority: TaskPriority.critical,
      ),
    );

    await _service.addTask(
      activeShift.id,
      WorkTask(
        id: 'task_4',
        title: 'Update logbook',
        description: 'Record all visitors and deliveries',
        priority: TaskPriority.medium,
        isCompleted: true,
        completedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
    );

    // Add a break
    await _service.startBreak(activeShift.id, BreakType.coffee);
    final activeBreak = _service.getActiveBreak(activeShift.id);
    if (activeBreak != null) {
      await Future.delayed(const Duration(milliseconds: 10));
      await _service.endBreak(activeShift.id, activeBreak.id);
    }

    // Upcoming shift tomorrow
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    await _service.createShift(
      jobTitle: 'Warehouse Associate',
      employer: 'LogisticsPro Inc.',
      shiftDate: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8, 0),
      startTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8, 0),
      endTime: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 16, 0),
      type: WorkShiftType.regular,
      location: 'Main Warehouse',
      address: '789 Industrial Blvd',
      supervisor: 'Sarah Martinez',
      supervisorPhone: '+1-555-0300',
      uniformRequirements: 'Steel-toe boots, hi-vis vest, safety glasses',
      equipment: 'Forklift certification card, scanner',
      notes: 'Loading dock operations, inventory management',
    );

    // Weekend shift (this Saturday)
    final now = DateTime.now();
    final daysUntilSaturday = (6 - now.weekday) % 7;
    final saturday = now.add(
      Duration(days: daysUntilSaturday == 0 ? 7 : daysUntilSaturday),
    );
    await _service.createShift(
      jobTitle: 'Retail Sales Associate',
      employer: 'TechGear Electronics',
      shiftDate: DateTime(saturday.year, saturday.month, saturday.day, 10, 0),
      startTime: DateTime(saturday.year, saturday.month, saturday.day, 10, 0),
      endTime: DateTime(saturday.year, saturday.month, saturday.day, 18, 0),
      type: WorkShiftType.weekend,
      location: 'Mall Location',
      address: '123 Shopping Center Way',
      supervisor: 'Tom Wilson',
      supervisorPhone: '+1-555-0400',
      uniformRequirements: 'Company polo shirt, khaki pants, name tag',
      notes: 'Weekend rush - expect high customer volume',
    );

    // Past shift with incident
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final pastShift = await _service.createShift(
      jobTitle: 'Night Security Guard',
      employer: 'SecureZone Security Services',
      shiftDate: DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
        22,
        0,
      ),
      startTime: DateTime(
        yesterday.year,
        yesterday.month,
        yesterday.day,
        22,
        0,
      ),
      endTime: DateTime.now().subtract(const Duration(hours: 2)),
      type: WorkShiftType.night,
      location: 'Downtown Office Complex',
      address: '456 Business Park Dr',
      supervisor: 'Mike Johnson',
      supervisorPhone: '+1-555-0200',
      uniformRequirements: 'Full security uniform, badge, radio',
      equipment: 'Radio, flashlight, incident report forms',
    );

    // Complete the past shift
    final completedShift = pastShift.copyWith(
      status: WorkShiftStatus.completed,
      timeTracking: WorkTimeTracking(
        clockInTime: DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
          22,
          5,
        ),
        clockOutTime: DateTime.now().subtract(const Duration(hours: 2)),
        clockInLocation: 'Downtown Office Complex',
        clockOutLocation: 'Downtown Office Complex',
        isLate: true, // 5 minutes late
        isEarlyDeparture: false,
      ),
    );
    await _service.updateShift(completedShift);

    // Add tasks to past shift
    await _service.addTask(
      pastShift.id,
      WorkTask(
        id: 'past_task_1',
        title: 'Night patrol',
        description: 'Patrol all areas',
        priority: TaskPriority.high,
        isCompleted: true,
        completedAt: yesterday.add(const Duration(hours: 2)),
      ),
    );

    await _service.addTask(
      pastShift.id,
      WorkTask(
        id: 'past_task_2',
        title: 'Monitor security feeds',
        description: 'Check all camera feeds',
        priority: TaskPriority.medium,
        isCompleted: true,
        completedAt: yesterday.add(const Duration(hours: 4)),
      ),
    );

    // Add incident to past shift
    await _service.reportIncident(
      pastShift.id,
      WorkIncident(
        id: 'incident_1',
        title: 'Suspicious Vehicle',
        description:
            'Unknown vehicle parked in restricted area at 2:30 AM. Ran license plate check.',
        type: IncidentType.security,
        severity: IncidentSeverity.medium,
        reportedAt: yesterday.add(const Duration(hours: 4, minutes: 30)),
        location: 'Parking Lot B',
        involvedPersons: const [],
        actionTaken:
            'Contacted local PD, vehicle owner identified and contacted. Owner arrived and moved vehicle.',
        requiresFollowUp: false,
      ),
    );

    // Past shift with critical incident
    final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
    final criticalShift = await _service.createShift(
      jobTitle: 'Warehouse Associate',
      employer: 'LogisticsPro Inc.',
      shiftDate: DateTime(
        twoDaysAgo.year,
        twoDaysAgo.month,
        twoDaysAgo.day,
        8,
        0,
      ),
      startTime: DateTime(
        twoDaysAgo.year,
        twoDaysAgo.month,
        twoDaysAgo.day,
        8,
        0,
      ),
      endTime: DateTime(
        twoDaysAgo.year,
        twoDaysAgo.month,
        twoDaysAgo.day,
        16,
        0,
      ),
      type: WorkShiftType.regular,
      location: 'Main Warehouse',
      address: '789 Industrial Blvd',
      supervisor: 'Sarah Martinez',
      supervisorPhone: '+1-555-0300',
    );

    // Complete it
    final completedCritical = criticalShift.copyWith(
      status: WorkShiftStatus.completed,
      timeTracking: WorkTimeTracking(
        clockInTime: DateTime(
          twoDaysAgo.year,
          twoDaysAgo.month,
          twoDaysAgo.day,
          7,
          58,
        ),
        clockOutTime: DateTime(
          twoDaysAgo.year,
          twoDaysAgo.month,
          twoDaysAgo.day,
          16,
          2,
        ),
        clockInLocation: 'Main Warehouse',
        clockOutLocation: 'Main Warehouse',
      ),
    );
    await _service.updateShift(completedCritical);

    // Add critical incident
    await _service.reportIncident(
      criticalShift.id,
      WorkIncident(
        id: 'incident_critical',
        title: 'Forklift Accident - Minor Injury',
        description:
            'Employee struck by reversing forklift in loading bay. Minor leg injury sustained.',
        type: IncidentType.safety,
        severity: IncidentSeverity.critical,
        reportedAt: twoDaysAgo.add(const Duration(hours: 4)),
        location: 'Loading Bay 3',
        involvedPersons: const ['John Smith (injured)', 'Driver: Mark Davis'],
        actionTaken:
            'First aid administered, employee taken to clinic. Area cordoned off, safety inspection conducted.',
        requiresFollowUp: true,
        followUpNotes:
            'Safety training review scheduled for all forklift operators',
      ),
    );

    print('Generated ${_service.shifts.length} sample shifts');
  }

  /// Generate emergency contacts
  static Future<void> generateEmergencyContacts() async {
    await _service.addEmergencyContact(
      const WorkplaceEmergencyContact(
        name: 'Security Dispatch',
        phone: '+1-555-SECURE',
        role: '24/7 Security Hotline',
        email: 'dispatch@securezone.com',
      ),
    );

    await _service.addEmergencyContact(
      const WorkplaceEmergencyContact(
        name: 'HR Department',
        phone: '+1-555-0HR00',
        role: 'Human Resources',
        email: 'hr@company.com',
      ),
    );

    await _service.addEmergencyContact(
      const WorkplaceEmergencyContact(
        name: 'Safety Officer',
        phone: '+1-555-SAFE1',
        role: 'Workplace Safety',
        email: 'safety@company.com',
      ),
    );

    await _service.addEmergencyContact(
      const WorkplaceEmergencyContact(
        name: 'Facilities Manager',
        phone: '+1-555-0500',
        role: 'Building Maintenance',
        email: 'facilities@company.com',
      ),
    );

    print('Added ${_service.emergencyContacts.length} emergency contacts');
  }

  /// Clear all test data
  static Future<void> clearAll() async {
    for (final shift in _service.shifts.toList()) {
      await _service.deleteShift(shift.id);
    }
    for (int i = _service.emergencyContacts.length - 1; i >= 0; i--) {
      await _service.removeEmergencyContact(i);
    }
    print('Cleared all work test data');
  }
}
