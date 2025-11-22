import 'package:flutter/material.dart';
import '../../../../models/work_shift.dart';
import '../../../../services/work_mode_service.dart';
import '../widgets/work_shift_card.dart';
import '../widgets/work_task_card.dart';
import '../widgets/work_incident_card.dart';

class WorkModeDashboard extends StatefulWidget {
  const WorkModeDashboard({super.key});

  @override
  State<WorkModeDashboard> createState() => _WorkModeDashboardState();
}

class _WorkModeDashboardState extends State<WorkModeDashboard>
    with SingleTickerProviderStateMixin {
  final _service = WorkModeService.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _service.initialize();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Work Mode'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_today), text: 'Shifts'),
            Tab(icon: Icon(Icons.access_time), text: 'Time'),
            Tab(icon: Icon(Icons.task_alt), text: 'Tasks'),
            Tab(icon: Icon(Icons.warning), text: 'Incidents'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildShiftsTab(),
          _buildTimeTab(),
          _buildTasksTab(),
          _buildIncidentsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _tabController.index == 0
            ? _createShift()
            : _tabController.index == 2
            ? _addTask()
            : _tabController.index == 3
            ? _reportIncident()
            : null,
        child: Icon(
          _tabController.index == 0
              ? Icons.add
              : _tabController.index == 2
              ? Icons.add_task
              : Icons.report,
        ),
      ),
    );
  }

  Widget _buildShiftsTab() {
    return StreamBuilder<List<WorkShift>>(
      stream: _service.shiftsStream,
      initialData: _service.shifts,
      builder: (context, snapshot) {
        final shifts = snapshot.data ?? [];
        final activeShifts = shifts
            .where((s) => s.status == WorkShiftStatus.inProgress)
            .toList();
        final upcomingShifts = shifts.where((s) => s.isUpcoming).toList();
        final pastShifts = shifts
            .where((s) => s.status == WorkShiftStatus.completed)
            .toList();

        if (shifts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.work_outline, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No shifts scheduled',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _createShift,
                  icon: const Icon(Icons.add),
                  label: const Text('Schedule Shift'),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Active Shifts
            if (activeShifts.isNotEmpty) ...[
              _buildSectionHeader('Active Shift', Icons.work),
              ...activeShifts.map(
                (shift) => WorkShiftCard(
                  shift: shift,
                  onTap: () => _viewShiftDetails(shift),
                  onClockOut: () => _clockOut(shift.id),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Upcoming Shifts
            if (upcomingShifts.isNotEmpty) ...[
              _buildSectionHeader(
                'Upcoming Shifts (${upcomingShifts.length})',
                Icons.schedule,
              ),
              ...upcomingShifts
                  .take(5)
                  .map(
                    (shift) => WorkShiftCard(
                      shift: shift,
                      onTap: () => _viewShiftDetails(shift),
                      onClockIn: () => _clockIn(shift.id),
                    ),
                  ),
              const SizedBox(height: 24),
            ],

            // Past Shifts
            if (pastShifts.isNotEmpty) ...[
              _buildSectionHeader(
                'Past Shifts (${pastShifts.length})',
                Icons.history,
              ),
              ...pastShifts
                  .take(5)
                  .map(
                    (shift) => WorkShiftCard(
                      shift: shift,
                      onTap: () => _viewShiftDetails(shift),
                    ),
                  ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTimeTab() {
    return StreamBuilder<WorkShift?>(
      stream: _service.activeShiftStream,
      initialData: _service.activeShift,
      builder: (context, snapshot) {
        final activeShift = snapshot.data;

        if (activeShift == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No active shift', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                const Text('Clock in to start tracking time'),
              ],
            ),
          );
        }

        final tracking = activeShift.timeTracking;
        final activeBreak = _service.getActiveBreak(activeShift.id);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Shift Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeShift.jobTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(activeShift.employer),
                    const Divider(height: 24),
                    _buildInfoRow(
                      Icons.login,
                      'Clock In',
                      _formatTime(tracking?.clockInTime),
                      tracking?.isLate == true ? Colors.orange : null,
                    ),
                    if (tracking?.clockInLocation != null)
                      _buildInfoRow(
                        Icons.location_on,
                        'Location',
                        tracking!.clockInLocation!,
                      ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.schedule,
                      'Scheduled',
                      '${_formatTime(activeShift.startTime)} - ${_formatTime(activeShift.endTime)}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Current Time Display
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(Icons.access_time, size: 48),
                    const SizedBox(height: 8),
                    StreamBuilder(
                      stream: Stream.periodic(const Duration(seconds: 1)),
                      builder: (context, snapshot) {
                        if (tracking?.clockInTime == null) {
                          return const SizedBox();
                        }
                        final duration = DateTime.now().difference(
                          tracking!.clockInTime!,
                        );
                        return Text(
                          _formatDuration(duration),
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                    const Text('Time Worked'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Breaks Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Breaks',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (activeBreak == null)
                          ElevatedButton.icon(
                            onPressed: () => _startBreak(activeShift.id),
                            icon: const Icon(Icons.coffee, size: 18),
                            label: const Text('Start Break'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          )
                        else
                          ElevatedButton.icon(
                            onPressed: () =>
                                _endBreak(activeShift.id, activeBreak.id),
                            icon: const Icon(Icons.play_arrow, size: 18),
                            label: const Text('End Break'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (activeShift.breaks.isEmpty)
                      const Text(
                        'No breaks taken',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      ...activeShift.breaks.map(
                        (b) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(_getBreakIcon(b.type), size: 16),
                              const SizedBox(width: 8),
                              Text(_formatBreakType(b.type)),
                              const Spacer(),
                              Text(
                                b.duration != null
                                    ? _formatDuration(b.duration!)
                                    : 'In progress...',
                                style: TextStyle(
                                  fontWeight: b.isActive
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: b.isActive
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const Divider(height: 24),
                    _buildInfoRow(
                      Icons.timer,
                      'Total Break Time',
                      _formatDuration(activeShift.totalBreakTime),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Clock Out Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _clockOut(activeShift.id),
                icon: const Icon(Icons.logout),
                label: const Text('Clock Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTasksTab() {
    return StreamBuilder<WorkShift?>(
      stream: _service.activeShiftStream,
      initialData: _service.activeShift,
      builder: (context, snapshot) {
        final activeShift = snapshot.data;

        if (activeShift == null) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.task_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No active shift', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Clock in to manage tasks'),
              ],
            ),
          );
        }

        final tasks = activeShift.tasks;
        final pendingTasks = tasks.where((t) => !t.isCompleted).toList()
          ..sort((a, b) => b.priority.index.compareTo(a.priority.index));
        final completedTasks = tasks.where((t) => t.isCompleted).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Progress Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Task Progress',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${activeShift.completedTasksCount}/${activeShift.totalTasksCount}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: activeShift.totalTasksCount > 0
                          ? activeShift.taskCompletionRate / 100
                          : 0,
                      minHeight: 8,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${activeShift.taskCompletionRate.toStringAsFixed(0)}% Complete',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pending Tasks
            if (pendingTasks.isNotEmpty) ...[
              _buildSectionHeader(
                'Pending Tasks (${pendingTasks.length})',
                Icons.pending_actions,
              ),
              ...pendingTasks.map(
                (task) => WorkTaskCard(
                  task: task,
                  onToggle: () => _toggleTask(activeShift.id, task.id),
                  onDelete: () => _deleteTask(activeShift.id, task.id),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Completed Tasks
            if (completedTasks.isNotEmpty) ...[
              _buildSectionHeader(
                'Completed (${completedTasks.length})',
                Icons.check_circle,
              ),
              ...completedTasks.map(
                (task) => WorkTaskCard(
                  task: task,
                  onToggle: () => _toggleTask(activeShift.id, task.id),
                  onDelete: () => _deleteTask(activeShift.id, task.id),
                ),
              ),
            ],

            if (tasks.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No tasks for this shift',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildIncidentsTab() {
    return StreamBuilder<List<WorkShift>>(
      stream: _service.shiftsStream,
      initialData: _service.shifts,
      builder: (context, snapshot) {
        final shifts = snapshot.data ?? [];
        final allIncidents = <MapEntry<WorkShift, WorkIncident>>[];

        for (final shift in shifts) {
          for (final incident in shift.incidents) {
            allIncidents.add(MapEntry(shift, incident));
          }
        }

        allIncidents.sort(
          (a, b) => b.value.reportedAt.compareTo(a.value.reportedAt),
        );

        final criticalIncidents = allIncidents
            .where((e) => e.value.severity == IncidentSeverity.critical)
            .toList();
        final followUpRequired = allIncidents
            .where((e) => e.value.requiresFollowUp)
            .toList();

        if (allIncidents.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text('No incidents reported', style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text('Great job staying safe!'),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Critical Incidents Alert
            if (criticalIncidents.isNotEmpty) ...[
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 32),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Critical Incidents',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${criticalIncidents.length} critical incident(s) require attention',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Follow-up Required
            if (followUpRequired.isNotEmpty) ...[
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.assignment_late,
                        color: Colors.orange,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Follow-up Required',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${followUpRequired.length} incident(s) need follow-up',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // All Incidents
            _buildSectionHeader(
              'All Incidents (${allIncidents.length})',
              Icons.list,
            ),
            ...allIncidents.map(
              (entry) => WorkIncidentCard(
                incident: entry.value,
                shiftInfo:
                    '${entry.key.jobTitle} - ${_formatDate(entry.key.shiftDate)}',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, [
    Color? color,
  ]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  // Helper methods
  String _formatTime(DateTime? time) {
    if (time == null) return '--:--';
    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  IconData _getBreakIcon(BreakType type) {
    switch (type) {
      case BreakType.lunch:
        return Icons.restaurant;
      case BreakType.coffee:
        return Icons.coffee;
      case BreakType.rest:
        return Icons.hotel;
      case BreakType.other:
        return Icons.more_horiz;
    }
  }

  String _formatBreakType(BreakType type) {
    return type.name[0].toUpperCase() + type.name.substring(1);
  }

  // Action methods
  void _createShift() {
    // TODO: Implement shift creation dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create shift dialog would open here')),
    );
  }

  void _viewShiftDetails(WorkShift shift) {
    // TODO: Implement shift details view
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Viewing shift: ${shift.jobTitle}')));
  }

  Future<void> _clockIn(String shiftId) async {
    await _service.startShift(shiftId);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Clocked in successfully')));
    }
  }

  Future<void> _clockOut(String shiftId) async {
    await _service.endShift(shiftId);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Clocked out successfully')));
    }
  }

  Future<void> _startBreak(String shiftId) async {
    await _service.startBreak(shiftId, BreakType.rest);
  }

  Future<void> _endBreak(String shiftId, String breakId) async {
    await _service.endBreak(shiftId, breakId);
  }

  void _addTask() {
    // TODO: Implement task creation dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add task dialog would open here')),
    );
  }

  Future<void> _toggleTask(String shiftId, String taskId) async {
    await _service.completeTask(shiftId, taskId);
  }

  Future<void> _deleteTask(String shiftId, String taskId) async {
    await _service.removeTask(shiftId, taskId);
  }

  void _reportIncident() {
    // TODO: Implement incident reporting dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report incident dialog would open here')),
    );
  }
}
