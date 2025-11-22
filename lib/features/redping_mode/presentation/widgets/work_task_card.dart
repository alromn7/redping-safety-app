import 'package:flutter/material.dart';
import '../../../../models/work_shift.dart';

class WorkTaskCard extends StatelessWidget {
  final WorkTask task;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;

  const WorkTaskCard({
    super.key,
    required this.task,
    this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: task.isCompleted ? 0 : 1,
      color: task.isCompleted ? Colors.grey[100] : null,
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: onToggle != null ? (_) => onToggle!() : null,
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            color: task.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: task.description != null
            ? Text(
                task.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: task.isCompleted ? Colors.grey : null),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPriorityChip(context),
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
                color: Colors.red,
                iconSize: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(BuildContext context) {
    Color color;
    IconData icon;

    switch (task.priority) {
      case TaskPriority.critical:
        color = Colors.red;
        icon = Icons.priority_high;
        break;
      case TaskPriority.high:
        color = Colors.orange;
        icon = Icons.arrow_upward;
        break;
      case TaskPriority.medium:
        color = Colors.blue;
        icon = Icons.drag_handle;
        break;
      case TaskPriority.low:
        color = Colors.grey;
        icon = Icons.arrow_downward;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            _formatPriority(task.priority),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPriority(TaskPriority priority) {
    return priority.name[0].toUpperCase() + priority.name.substring(1);
  }
}
