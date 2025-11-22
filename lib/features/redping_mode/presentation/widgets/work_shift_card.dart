import 'package:flutter/material.dart';
import '../../../../models/work_shift.dart';

class WorkShiftCard extends StatelessWidget {
  final WorkShift shift;
  final VoidCallback? onTap;
  final VoidCallback? onClockIn;
  final VoidCallback? onClockOut;

  const WorkShiftCard({
    super.key,
    required this.shift,
    this.onTap,
    this.onClockIn,
    this.onClockOut,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    _getShiftTypeIcon(shift.type),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shift.jobTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          shift.employer,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(context),
                ],
              ),
              const SizedBox(height: 12),

              // Date and Time
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(shift.shiftDate),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${_formatTime(shift.startTime)} - ${_formatTime(shift.endTime)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Location
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      shift.location,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Info chips
              if (shift.tasks.isNotEmpty || shift.incidents.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    if (shift.tasks.isNotEmpty)
                      Chip(
                        avatar: const Icon(Icons.task_alt, size: 16),
                        label: Text(
                          '${shift.completedTasksCount}/${shift.totalTasksCount} Tasks',
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    if (shift.incidents.isNotEmpty)
                      Chip(
                        avatar: Icon(
                          Icons.warning,
                          size: 16,
                          color: shift.criticalIncidentsCount > 0
                              ? Colors.red
                              : Colors.orange,
                        ),
                        label: Text('${shift.incidents.length} Incidents'),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],

              // Action buttons
              if (onClockIn != null || onClockOut != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onClockIn != null)
                      OutlinedButton.icon(
                        onPressed: onClockIn,
                        icon: const Icon(Icons.login, size: 18),
                        label: const Text('Clock In'),
                      ),
                    if (onClockOut != null)
                      ElevatedButton.icon(
                        onPressed: onClockOut,
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Clock Out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ],

              // Time tracking info
              if (shift.timeTracking != null) ...[
                const Divider(height: 24),
                Row(
                  children: [
                    const Icon(Icons.timer, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      shift.actualDuration != null
                          ? 'Worked: ${_formatDuration(shift.actualDuration!)}'
                          : 'In Progress',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (shift.timeTracking!.isLate) ...[
                      const SizedBox(width: 12),
                      const Chip(
                        label: Text('Late', style: TextStyle(fontSize: 10)),
                        backgroundColor: Colors.orange,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    Color color;
    String text;

    switch (shift.status) {
      case WorkShiftStatus.scheduled:
        color = Theme.of(context).colorScheme.primary;
        text = 'Scheduled';
        break;
      case WorkShiftStatus.inProgress:
        color = Colors.green;
        text = 'Active';
        break;
      case WorkShiftStatus.completed:
        color = Colors.grey;
        text = 'Completed';
        break;
      case WorkShiftStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  IconData _getShiftTypeIcon(WorkShiftType type) {
    switch (type) {
      case WorkShiftType.regular:
        return Icons.work;
      case WorkShiftType.overtime:
        return Icons.timer;
      case WorkShiftType.onCall:
        return Icons.phone_in_talk;
      case WorkShiftType.remote:
        return Icons.home_work;
      case WorkShiftType.fieldWork:
        return Icons.location_city;
      case WorkShiftType.night:
        return Icons.nights_stay;
      case WorkShiftType.weekend:
        return Icons.weekend;
      case WorkShiftType.holiday:
        return Icons.celebration;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final shiftDay = DateTime(date.year, date.month, date.day);

    if (shiftDay == today) {
      return 'Today';
    } else if (shiftDay == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (shiftDay == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }

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

  String _formatTime(DateTime time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }
}
