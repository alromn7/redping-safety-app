# Work Mode Management System - Complete Guide

## Overview

The Work Mode Management System provides comprehensive tools for managing work shifts, tracking time, organizing tasks, and reporting workplace incidents. Whether you're a shift worker, contractor, or managing multiple jobs, this system helps you stay organized and professional.

## Key Features

### ⏰ Shift Management
- **Shift Scheduling**: Plan shifts with job details, locations, and requirements
- **8 Shift Types**: Regular, Overtime, On-Call, Remote, Field Work, Night, Weekend, Holiday
- **Shift Lifecycle**: Scheduled → In Progress → Completed workflow
- **Multi-Employer Support**: Track shifts across different employers/jobs
- **Supervisor Info**: Store supervisor contact details for each shift

### 🕐 Time Tracking
- **Clock In/Out**: Precise time tracking with location capture
- **Break Management**: Track lunch, coffee, and rest breaks
- **Overtime Detection**: Automatic flagging of extended hours
- **Late/Early Alerts**: Tracks punctuality automatically
- **Duration Calculation**: Real-time display of hours worked

### ✅ Task Management
- **Shift Tasks**: Organize work tasks by priority
- **4 Priority Levels**: Critical, High, Medium, Low
- **Progress Tracking**: Visual completion percentage
- **Task Completion**: Mark tasks done during shift
- **Task Notes**: Add details and completion notes

### ⚠️ Incident Reporting
- **7 Incident Types**: Safety, Equipment, Customer, Workplace, Health, Security, Other
- **4 Severity Levels**: Low, Medium, High, Critical
- **Detailed Reports**: Description, location, involved persons, action taken
- **Follow-up Tracking**: Flag incidents requiring additional action
- **Critical Alerts**: Prominent display of critical incidents

## User Interface

### Dashboard Tabs

#### 1. Shifts Tab
- **Active Shift**: Currently in-progress shift (max 1)
- **Upcoming Shifts**: Scheduled future shifts ordered by date
- **Past Shifts**: Completed shift history
- **Quick Actions**: Clock in/out, view details

#### 2. Time Tab
- **Live Clock**: Real-time display of hours worked
- **Shift Info**: Clock-in time, location, schedule
- **Break Manager**: Start/end breaks, view break history
- **Total Break Time**: Cumulative break duration
- **Clock Out Button**: End shift and record time

#### 3. Tasks Tab
- **Progress Bar**: Visual task completion percentage
- **Pending Tasks**: Outstanding tasks sorted by priority
- **Completed Tasks**: Finished tasks with completion time
- **Quick Toggle**: Check/uncheck to mark complete
- **Task Count**: Shows X/Y tasks completed

#### 4. Incidents Tab
- **Critical Alerts**: Red banner for critical incidents
- **Follow-up Alerts**: Orange banner for pending follow-ups
- **Incident List**: All reported incidents chronologically
- **Severity Badges**: Color-coded severity indicators
- **Incident Details**: Full report with action taken

## Common Workflows

### Starting a Shift

1. **Clock In**:
   ```
   Shifts Tab → Upcoming Shift → "Clock In"
   ```

2. **System Records**:
   - Actual clock-in time
   - Location (if GPS enabled)
   - Late status (if > 5 min after scheduled start)

3. **Shift Activates**:
   - Status changes to "In Progress"
   - Time tracking begins
   - Tasks become accessible

### During the Shift

1. **View Today's Tasks**:
   ```
   Tasks Tab → Pending Tasks section
   ```

2. **Complete Tasks**:
   ```
   Tap checkbox → Task marked complete
   Progress bar updates automatically
   ```

3. **Take Breaks**:
   ```
   Time Tab → "Start Break" → Work on break
   Time Tab → "End Break" → Resume work
   ```

4. **Report Incidents**:
   ```
   Incidents Tab → FAB → Fill incident form
   Select severity, type, add details
   ```

### Ending a Shift

1. **Clock Out**:
   ```
   Time Tab → "Clock Out" button
   ```

2. **System Records**:
   - Actual clock-out time
   - Location
   - Early departure status (if applicable)
   - Total hours worked
   - Total break time

3. **Shift Completes**:
   - Status changes to "Completed"
   - Saved to history
   - Statistics calculated

## API Reference

### WorkModeService

#### Shift Management

```dart
// Create new shift
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

// Update shift
await WorkModeService.instance.updateShift(
  shift.copyWith(notes: 'Updated notes'),
);

// Start shift (clock in)
await WorkModeService.instance.startShift(shift.id, location: 'Office');

// End shift (clock out)
await WorkModeService.instance.endShift(shift.id, location: 'Office');

// Get shifts by status
final activeShifts = WorkModeService.instance.getShiftsByStatus(WorkShiftStatus.inProgress);
final upcomingShifts = WorkModeService.instance.getUpcomingShifts();
final pastShifts = WorkModeService.instance.getPastShifts();

// Get today's shift
final todaysShift = WorkModeService.instance.getTodaysShift();
```

#### Task Management

```dart
// Add task to shift
await WorkModeService.instance.addTask(
  shiftId,
  WorkTask(
    id: 'task_1',
    title: 'Morning patrol',
    description: 'Check all entry points',
    priority: TaskPriority.high,
  ),
);

// Complete task
await WorkModeService.instance.completeTask(shiftId, taskId);

// Update task
await WorkModeService.instance.updateTask(
  shiftId,
  task.copyWith(notes: 'Updated notes'),
);

// Remove task
await WorkModeService.instance.removeTask(shiftId, taskId);
```

#### Break Management

```dart
// Start break
await WorkModeService.instance.startBreak(shiftId, BreakType.lunch);

// End break
await WorkModeService.instance.endBreak(shiftId, breakId);

// Get active break
final activeBreak = WorkModeService.instance.getActiveBreak(shiftId);
```

#### Incident Management

```dart
// Report incident
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

// Get critical incidents
final criticalIncidents = WorkModeService.instance.getCriticalIncidents(shiftId);

// Get incidents requiring follow-up
final followUpIncidents = WorkModeService.instance.getIncidentsRequiringFollowUp();
```

#### Statistics

```dart
// Get shift statistics
final stats = WorkModeService.instance.getShiftStats(shiftId);
// Returns:
{
  'scheduledHours': 8.0,
  'actualHours': 8.5,
  'breakHours': 0.5,
  'tasksCompleted': 7,
  'totalTasks': 10,
  'completionRate': 70.0,
  'incidentsCount': 2,
  'criticalIncidents': 0,
  'wasLate': false,
  'earlyDeparture': false,
}

// Get overall statistics
final overallStats = WorkModeService.instance.getOverallStats();
// Returns:
{
  'totalShifts': 45,
  'totalHours': 360.0,
  'lateShifts': 3,
  'totalIncidents': 8,
  'upcomingShifts': 5,
}
```

## Data Models

### WorkShift
- `id`, `jobTitle`, `employer`, `shiftDate`
- `startTime`, `endTime`, `status`, `type`
- `location`, `address`, `supervisor`, `supervisorPhone`
- `tasks[]`, `breaks[]`, `incidents[]`
- `timeTracking`, `uniformRequirements`, `equipment`
- Computed: `isActive`, `isUpcoming`, `isPast`, `isToday`, `scheduledDuration`, `actualDuration`, `taskCompletionRate`, `hasIncidents`

### WorkTask
- `id`, `title`, `description`, `priority`
- `isCompleted`, `completedAt`, `notes`

### WorkBreak
- `id`, `type`, `startTime`, `endTime`, `notes`
- Computed: `duration`, `isActive`

### WorkIncident
- `id`, `title`, `description`, `type`, `severity`
- `reportedAt`, `location`, `involvedPersons[]`
- `actionTaken`, `requiresFollowUp`, `followUpNotes`

### WorkTimeTracking
- `clockInTime`, `clockOutTime`
- `clockInLocation`, `clockOutLocation`
- `isLate`, `isEarlyDeparture`, `notes`
- Computed: `isClockedIn`, `isClockedOut`, `totalTime`

## Testing

### Generate Test Data

```dart
import 'package:redping_14v/utils/work_mode_test_data.dart';

// Generate all test data
await WorkModeTestData.generateAll();

// Clear test data
await WorkModeTestData.clearAll();
```

Test data includes:
- Active shift (security guard, in progress)
- Upcoming shifts (warehouse, retail)
- Past shifts (completed night shift)
- Tasks with various priorities and completion states
- Breaks (coffee, lunch)
- Incidents (security issue, safety incident)
- Emergency contacts (dispatch, HR, safety)

## Best Practices

### Time Tracking
1. **Clock In On Time**: Arrive 5 minutes early to clock in punctually
2. **Accurate Breaks**: Record all breaks for accurate time reporting
3. **Location Tracking**: Enable GPS for location verification
4. **Clock Out Properly**: Always clock out at end of shift

### Task Management
1. **Priority First**: Complete critical and high-priority tasks first
2. **Update Status**: Mark tasks complete as you finish them
3. **Add Notes**: Record important details in task notes
4. **Review Daily**: Check task list at start of each shift

### Incident Reporting
1. **Report Immediately**: Document incidents as soon as they occur
2. **Be Detailed**: Include all relevant information
3. **Assess Severity**: Accurately rate incident severity
4. **Follow Up**: Complete follow-up actions for flagged incidents

### Professional Conduct
1. **Arrive Prepared**: Check uniform/equipment requirements before shift
2. **Stay Organized**: Review shift details and tasks in advance
3. **Communicate**: Keep supervisor contact info updated
4. **Document Everything**: Use incident reports for all notable events

## Troubleshooting

### Can't Clock In
- **Issue**: Clock in button not appearing
- **Solution**: Check that shift is scheduled for today and not already started

### Tasks Not Showing
- **Issue**: No tasks visible in Tasks tab
- **Solution**: Ensure you have an active shift (must clock in first)

### Break Won't End
- **Issue**: Can't end active break
- **Solution**: Check that break was started (should show "In progress")

### Incident Not Saving
- **Issue**: Incident report not appearing
- **Solution**: Ensure all required fields filled (title, description, type, severity)

## Security & Privacy

- All shift data stored locally via SharedPreferences
- Time tracking location data controlled by user
- Incident reports stored securely on device
- No automatic cloud sync (user controls data sharing)
- Supervisor contact info encrypted at rest

## Integration with RedPing

Work Mode integrates seamlessly:
- Available when Work mode selected in RedPing
- Accessible via "Work Manager" button on SOS page
- Active shift persists across app restarts
- Time tracking continues in background

## Statistics & Reporting

### Shift Statistics
- Total hours worked
- Break time breakdown
- Task completion rates
- Incident frequency
- Punctuality tracking (late/early departure)

### Overall Statistics
- Total shifts completed
- Total hours across all jobs
- Incident trends
- Upcoming shift count

## Future Enhancements

Potential features for future versions:
- Payroll integration (hours × rate)
- Schedule sync with employer systems
- Shift swap/trade with co-workers
- Mileage tracking for field work
- Photo attachments for incidents
- Voice notes during shift
- Multi-language support
- Export shift reports to PDF

## Shift Types Explained

| Type | Description | Common Uses |
|------|-------------|-------------|
| **Regular** | Standard scheduled shift | Normal work hours |
| **Overtime** | Extended hours beyond regular | Extra shifts, busy periods |
| **On-Call** | Available on demand | Emergency response, backup |
| **Remote** | Work from home/remote location | Office work, telecommuting |
| **Field Work** | Work at various external locations | Service calls, inspections |
| **Night** | Overnight shift | 24/7 operations, security |
| **Weekend** | Saturday/Sunday shift | Retail, hospitality |
| **Holiday** | Work on public holiday | Essential services |

## Incident Severity Guide

- **Low**: Minor issues, no immediate action needed
- **Medium**: Requires attention, document for review
- **High**: Serious issue, supervisor notification recommended
- **Critical**: Emergency situation, immediate action required

## Emergency Contacts

Add workplace emergency contacts for quick access:
- Security/Dispatch hotlines
- HR department
- Safety officer
- Facilities management
- Supervisor direct lines

Access anytime from the emergency contacts section.

## Best Use Cases

### Security Guards
- Track patrol schedules
- Document security incidents
- Monitor camera checks
- Record visitor logs

### Warehouse Workers
- Manage inventory tasks
- Track forklift operations
- Report safety issues
- Log equipment maintenance

### Retail Associates
- Schedule weekend/holiday shifts
- Track customer service tasks
- Report theft/security incidents
- Manage break schedules

### Field Service Technicians
- Track multiple job sites
- Document equipment issues
- Report customer interactions
- Manage travel time

### Healthcare Workers
- Track shift rotations
- Manage patient care tasks
- Report safety incidents
- Document break compliance
