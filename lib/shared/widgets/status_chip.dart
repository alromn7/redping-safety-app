import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Small, reusable status chip for global use across the app.
/// Pass a short status string; colors/icons are mapped consistently.
class StatusChip extends StatelessWidget {
  final String status;
  final EdgeInsetsGeometry padding;
  final double? fontSize;
  final bool dense;

  const StatusChip({
    super.key,
    required this.status,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.fontSize,
    this.dense = true,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();

    // Map status to color and icon
    Color bgColor = AppTheme.neutralGray.withValues(alpha: 0.15);
    Color fgColor = AppTheme.primaryText;
    IconData icon = Icons.info_outline;
    String label = _displayLabel(normalized);

    switch (normalized) {
      case 'active':
      case 'armed':
      case 'sos_active':
        bgColor = AppTheme.warningOrange.withValues(alpha: 0.18);
        fgColor = AppTheme.warningOrange;
        icon = Icons.warning_amber_rounded;
        break;
      case 'acknowledged':
      case 'ack':
        bgColor = AppTheme.infoBlue.withValues(alpha: 0.18);
        fgColor = AppTheme.infoBlue;
        icon = Icons.handshake_outlined;
        break;
      case 'assigned':
      case 'responder_assigned':
        bgColor = AppTheme.infoBlue.withValues(alpha: 0.18);
        fgColor = AppTheme.infoBlue;
        icon = Icons.person_add_alt_1_outlined;
        break;
      case 'en_route':
      case 'enroute':
      case 'in_progress':
      case 'inprogress':
        bgColor = AppTheme.infoBlue.withValues(alpha: 0.18);
        fgColor = AppTheme.infoBlue;
        icon = Icons.directions_run;
        break;
      case 'on_scene':
      case 'onscene':
        bgColor = AppTheme.infoBlue.withValues(alpha: 0.18);
        fgColor = AppTheme.infoBlue;
        icon = Icons.location_on_outlined;
        break;
      case 'resolved':
      case 'closed':
        bgColor = AppTheme.safeGreen.withValues(alpha: 0.18);
        fgColor = AppTheme.safeGreen;
        icon = Icons.check_circle_outline;
        break;
      case 'unresolved':
      case 'open':
        bgColor = AppTheme.primaryRed.withValues(alpha: 0.18);
        fgColor = AppTheme.primaryRed;
        icon = Icons.error_outline;
        break;
      default:
        // leave neutral
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fgColor.withValues(alpha: 0.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: dense ? 14 : 16, color: fgColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fgColor,
              fontSize: fontSize ?? (dense ? 12 : 14),
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  String _displayLabel(String normalized) {
    switch (normalized) {
      case 'in_progress':
        return 'In Progress';
      case 'responder_assigned':
        return 'Assigned';
      case 'en_route':
        return 'En Route';
      case 'on_scene':
        return 'On Scene';
      case 'sos_active':
        return 'Active';
      default:
        // Capitalize first letter, keep underscores as spaces
        final withSpaces = normalized.replaceAll('_', ' ');
        if (withSpaces.isEmpty) return 'Status';
        return withSpaces[0].toUpperCase() + withSpaces.substring(1);
    }
  }
}
