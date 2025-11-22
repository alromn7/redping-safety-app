import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/help_request.dart';

/// Widget to display priority indicator for help requests
class HelpPriorityIndicator extends StatelessWidget {
  final HelpPriority priority;
  final bool showLabel;

  const HelpPriorityIndicator({
    super.key,
    required this.priority,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getPriorityColor(),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _getPriorityColor().withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getPriorityIcon(), color: Colors.white, size: 12),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              _getPriorityLabel(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getPriorityColor() {
    switch (priority) {
      case HelpPriority.critical:
        return AppTheme.criticalRed;
      case HelpPriority.high:
        return AppTheme.warningOrange;
      case HelpPriority.medium:
        return AppTheme.infoBlue;
      case HelpPriority.low:
        return AppTheme.safeGreen;
    }
  }

  IconData _getPriorityIcon() {
    switch (priority) {
      case HelpPriority.critical:
        return Icons.priority_high;
      case HelpPriority.high:
        return Icons.keyboard_arrow_up;
      case HelpPriority.medium:
        return Icons.remove;
      case HelpPriority.low:
        return Icons.keyboard_arrow_down;
    }
  }

  String _getPriorityLabel() {
    switch (priority) {
      case HelpPriority.critical:
        return 'CRITICAL';
      case HelpPriority.high:
        return 'HIGH';
      case HelpPriority.medium:
        return 'MEDIUM';
      case HelpPriority.low:
        return 'LOW';
    }
  }
}
