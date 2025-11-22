# Work Mode - Quick Start Guide

## What is Work Mode?

Work Mode is a comprehensive shift management system for RedPing that helps you track work hours, organize tasks, take breaks, and report workplace incidents. Whether you're a security guard, warehouse worker, retail associate, or field technician, Work Mode keeps you organized and professional.

## Quick Start

### 1. Generate Test Data (Development)

```dart
import 'package:redping_14v/utils/work_mode_test_data.dart';

// Generate sample shifts, tasks, incidents
await WorkModeTestData.generateAll();
```

This creates:
- 5 sample shifts (active, upcoming, past)
- Tasks with various priorities
- Break records
- Incident reports (including critical)
- Emergency contacts

### 2. Access Work Manager

**From SOS Page** (when Work mode active):
```
SOS Page → "Work Manager" button
```

**Direct Navigation**:
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const WorkModeDashboard()),
);
```

## Core Features at a Glance

### 📅 Shift Management
- Schedule shifts with job details and location
- 8 shift types (Regular, Overtime, On-Call, Remote, Night, Weekend, etc.)
- Track multiple employers/jobs
- Store supervisor contact info

### ⏱️ Time Tracking
- Clock in/out with precise timestamps
- Location capture (GPS optional)
- Automatic late/early detection (5-min threshold)
- Break time tracking (lunch, coffee, rest)
- Real-time hours worked display

### ✅ Task Management
- Organize tasks by priority (Critical, High, Medium, Low)
- Visual progress tracking (X/Y completed, %)
- Quick toggle to mark complete
- Task notes and descriptions

### ⚠️ Incident Reporting
- 7 incident types (Safety, Equipment, Customer, etc.)
- 4 severity levels (Low, Medium, High, Critical)
- Document action taken
- Flag for follow-up
- Critical incident alerts

## Common Operations

### Schedule a Shift

```dart
final shift = await WorkModeService.instance.createShift(
  jobTitle: 'Security Guard',
  employer: 'SecureZone Security',
  shiftDate: DateTime(2024, 12, 1),
  startTime: DateTime(2024, 12, 1, 8, 0),
  endTime: DateTime(2024, 12, 1, 16, 0),
  type: WorkShiftType.regular,
  location: 'Downtown Office',
  supervisor: 'Mike Johnson',
  supervisorPhone: '+1-555-0200',
);
```

### Clock In/Out

```dart
// Start shift (clock in)
await WorkModeService.instance.startShift(
  shiftId,
  location: 'Office Building',
);

// End shift (clock out)
await WorkModeService.instance.endShift(
  shiftId,
  location: 'Office Building',
);
```

### Add Task

```dart
await WorkModeService.instance.addTask(
  shiftId,
  WorkTask(
    id: 'task_1',
    title: 'Morning patrol - all floors',
    description: 'Check all floors, test emergency exits',
    priority: TaskPriority.high,
  ),
);

// Complete task
await WorkModeService.instance.completeTask(shiftId, taskId);
```

### Manage Breaks

```dart
// Start break
await WorkModeService.instance.startBreak(shiftId, BreakType.lunch);

// End break
await WorkModeService.instance.endBreak(shiftId, breakId);

// Check active break
final activeBreak = WorkModeService.instance.getActiveBreak(shiftId);
```

### Report Incident

```dart
await WorkModeService.instance.reportIncident(
  shiftId,
  WorkIncident(
    id: 'inc_1',
    title: 'Equipment Failure',
    description: 'Security camera offline in sector 3',
    type: IncidentType.equipment,
    severity: IncidentSeverity.medium,
    reportedAt: DateTime.now(),
    location: 'Sector 3',
    actionTaken: 'IT notified, backup camera activated',
    requiresFollowUp: true,
  ),
);
```

## Dashboard Guide

### Shifts Tab
- **Active Shift**: Currently in-progress (max 1)
- **Upcoming Shifts**: Next 5 scheduled shifts
- **Past Shifts**: Last 5 completed shifts
- **Actions**: Clock in, clock out, view details

### Time Tab
- **Live Clock**: Real-time hours worked (updates every second)
- **Shift Details**: Schedule, supervisor, location
- **Break Manager**: Start/end breaks, view history
- **Total Break Time**: Cumulative break duration
- **Clock Out**: End shift button

### Tasks Tab
- **Progress Bar**: Visual completion percentage
- **Pending Tasks**: Outstanding tasks (sorted by priority)
- **Completed Tasks**: Finished tasks with timestamps
- **Quick Toggle**: Tap checkbox to complete
- **Priority Colors**: Red (Critical), Orange (High), Blue (Medium), Grey (Low)

### Incidents Tab
- **Critical Alert**: RED banner for critical incidents
- **Follow-up Alert**: ORANGE banner for pending actions
- **Incident List**: All reports in chronological order
- **Severity Badges**: Color-coded severity indicators
- **Full Details**: Description, action, follow-up notes

## Data Models

### WorkShift
```dart
{
  id, jobTitle, employer,
  shiftDate, startTime, endTime, status, type,
  location, address, supervisor, supervisorPhone,
  tasks[], breaks[], incidents[],
  timeTracking, uniformRequirements, equipment,
  // Computed:
  isActive, isUpcoming, isPast, scheduledDuration, actualDuration, taskCompletionRate
}
```

### Shift Status
- `scheduled` - Planned but not started
- `inProgress` - Currently active (only 1 allowed)
- `completed` - Finished
- `cancelled` - Cancelled but preserved

### Shift Types
`regular`, `overtime`, `onCall`, `remote`, `fieldWork`, `night`, `weekend`, `holiday`

### Task Priority
`low`, `medium`, `high`, `critical`

### Break Types
`lunch`, `coffee`, `rest`, `other`

### Incident Types
`safety`, `equipment`, `customer`, `workplace`, `health`, `security`, `other`

### Incident Severity
`low`, `medium`, `high`, `critical`

## Service API

### WorkModeService.instance

#### Shift Management
```dart
createShift(...)              // Schedule new shift
updateShift(shift)            // Update shift details
deleteShift(shiftId)          // Delete shift
startShift(shiftId, location) // Clock in
endShift(shiftId, location)   // Clock out
getShiftsByStatus(status)     // Filter by status
getUpcomingShifts()           // Future shifts
getPastShifts()               // Completed shifts
getTodaysShift()              // Today's shift
```

#### Task Management
```dart
addTask(shiftId, task)        // Add task to shift
updateTask(shiftId, task)     // Update task
completeTask(shiftId, taskId) // Mark complete
removeTask(shiftId, taskId)   // Delete task
```

#### Break Management
```dart
startBreak(shiftId, type)     // Start break
endBreak(shiftId, breakId)    // End break
getActiveBreak(shiftId)       // Get current break
```

#### Incident Management
```dart
reportIncident(shiftId, incident)      // File incident report
getCriticalIncidents(shiftId)          // Get critical only
getIncidentsRequiringFollowUp()        // Get follow-up needed
```

#### Statistics
```dart
getShiftStats(shiftId)  // Returns:
{
  scheduledHours: 8.0,
  actualHours: 8.5,
  breakHours: 0.5,
  tasksCompleted: 7,
  totalTasks: 10,
  completionRate: 70.0,
  incidentsCount: 2,
  criticalIncidents: 0,
  wasLate: false,
  earlyDeparture: false,
}

getOverallStats()  // Returns:
{
  totalShifts: 45,
  totalHours: 360.0,
  lateShifts: 3,
  totalIncidents: 8,
  upcomingShifts: 5,
}
```

## Streams (Reactive UI)

```dart
// Listen to active shift changes
WorkModeService.instance.activeShiftStream.listen((shift) {
  // UI updates when shift starts/ends
});

// Listen to shifts list changes
WorkModeService.instance.shiftsStream.listen((shifts) {
  // UI updates when shifts added/removed/updated
});

// Listen to emergency contacts
WorkModeService.instance.emergencyContactsStream.listen((contacts) {
  // UI updates when contacts change
});
```

## Important: Time Tracking Rules

### Late Clock-In
- **Threshold**: 5 minutes after scheduled start
- **Effect**: Shift marked as "Late"
- **Display**: Orange "Late" chip on shift card

### Early Departure
- **Threshold**: 5 minutes before scheduled end
- **Effect**: Shift marked as "Early Departure"
- **Display**: Noted in time tracking

### Break Time
- **Deducted**: From total hours worked
- **Tracked**: Separate break duration display
- **Required**: Many jurisdictions require break tracking

## File Structure

```
lib/
├── models/
│   └── work_shift.dart              # All data models
├── services/
│   └── work_mode_service.dart       # Business logic
├── features/redping_mode/presentation/
│   ├── pages/
│   │   └── work_mode_dashboard.dart     # Main UI
│   └── widgets/
│       ├── work_shift_card.dart
│       ├── work_task_card.dart
│       └── work_incident_card.dart
└── utils/
    └── work_mode_test_data.dart     # Test data generator
```

## Testing

### Generate Test Data
```dart
await WorkModeTestData.generateAll();
```

### Clear Test Data
```dart
await WorkModeTestData.clearAll();
```

### Test Scenarios Covered
- Active shift (security guard, in progress)
- Upcoming shifts (warehouse, retail)
- Past shifts (night shift with incident)
- Tasks (various priorities, some completed)
- Breaks (completed and active)
- Incidents (medium and critical severity)
- Emergency contacts (dispatch, HR, safety, facilities)

## Best Practices

### Before Shift
1. ✅ Review shift details (time, location, requirements)
2. ✅ Check uniform/equipment requirements
3. ✅ Set reminder to arrive early
4. ✅ Review pending tasks

### During Shift
1. ✅ Clock in on time (within 5-min window)
2. ✅ Complete high-priority tasks first
3. ✅ Track all breaks accurately
4. ✅ Report incidents immediately
5. ✅ Update task status as you go

### After Shift
1. ✅ Clock out properly
2. ✅ Ensure all tasks marked complete
3. ✅ Review incident reports
4. ✅ Check hours worked for accuracy

## Troubleshooting

**Q: Can't clock in to shift?**
A: Ensure shift is scheduled for today and not already active.

**Q: Tasks not showing?**
A: You must have an active shift (clocked in) to see tasks.

**Q: Break won't end?**
A: Check that break was started (should show "In progress").

**Q: Multiple active shifts?**
A: Only one shift can be active. Clock out of current shift first.

**Q: Late flag incorrect?**
A: Late threshold is 5 minutes after scheduled start time.

## Integration with RedPing

Work Mode integrates seamlessly:
- Available when Work mode selected
- Accessible via "Work Manager" button on SOS page
- Active shift persists across app restarts
- Time tracking continues in background (when app open)

## Use Cases

### Security Guards
- Track patrol schedules
- Document security incidents
- Monitor camera checks
- Record visitor/delivery logs

### Warehouse Workers
- Manage inventory tasks
- Track forklift operations
- Report safety incidents
- Log equipment maintenance

### Retail Associates
- Schedule weekend/holiday shifts
- Track customer service tasks
- Report theft/security issues
- Manage break compliance

### Field Technicians
- Track multiple job sites
- Document equipment problems
- Report customer interactions
- Manage travel/service time

### Healthcare Workers
- Track shift rotations
- Manage patient care tasks
- Report safety incidents
- Document break compliance

## Emergency Contacts

Add workplace emergency contacts for quick access:
- Security/Dispatch hotlines
- HR department
- Safety officer
- Facilities management
- Supervisor direct lines

Access from dashboard for immediate contact during incidents.

## Labor Law Compliance

Work Mode supports compliance with:
- Break time tracking (required in many jurisdictions)
- Overtime detection (automatic flagging)
- Accurate time records (clock-in/out timestamps)
- Incident documentation (OSHA-compliant)
- Location verification (GPS stamps)

**Note**: Users responsible for verifying local law compliance.

## Statistics & Reporting

### Per Shift
- Hours scheduled vs. actual
- Break time breakdown
- Task completion rate
- Incident count
- Punctuality (late/early)

### Overall
- Total shifts completed
- Total hours worked
- Incident trends
- Upcoming shift count

## Next Steps

1. **Generate test data** to explore features
2. **Schedule your first shift** for upcoming work
3. **Clock in** when shift starts
4. **Add tasks** for the day
5. **Track time** and take breaks
6. **Report incidents** as they occur

For detailed documentation, see:
- **WORK_MODE_GUIDE.md** - Comprehensive feature guide
- **WORK_MODE_IMPLEMENTATION_SUMMARY.md** - Technical architecture

Work smart, stay organized! 💼⏱️
