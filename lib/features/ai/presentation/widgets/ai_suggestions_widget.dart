import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/ai_assistant.dart';

/// Widget for displaying AI suggestions
class AISuggestionsWidget extends StatelessWidget {
  final List<AISuggestion> suggestions;
  final Function(AISuggestion) onSuggestionTap;

  const AISuggestionsWidget({
    super.key,
    required this.suggestions,
    required this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) return const SizedBox.shrink();

    // Filter valid suggestions
    final validSuggestions = suggestions
        .where((s) => s.validUntil.isAfter(DateTime.now()))
        .toList();

    if (validSuggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: validSuggestions.map((suggestion) {
          return _buildSuggestionChip(suggestion);
        }).toList(),
      ),
    );
  }

  Widget _buildSuggestionChip(AISuggestion suggestion) {
    final priorityColor = _getPriorityColor(suggestion.priority);

    return ActionChip(
      avatar: Icon(
        _getActionIcon(suggestion.actionType),
        size: 14,
        color: priorityColor,
      ),
      label: Text(
        suggestion.title,
        style: TextStyle(fontSize: 11, color: priorityColor),
      ),
      onPressed: () => onSuggestionTap(suggestion),
      backgroundColor: priorityColor.withValues(alpha: 0.1),
      side: BorderSide(color: priorityColor.withValues(alpha: 0.3)),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Color _getPriorityColor(AISuggestionPriority priority) {
    switch (priority) {
      case AISuggestionPriority.urgent:
        return AppTheme.criticalRed;
      case AISuggestionPriority.high:
        return AppTheme.warningOrange;
      case AISuggestionPriority.medium:
        return AppTheme.infoBlue;
      case AISuggestionPriority.low:
        return AppTheme.safeGreen;
    }
  }

  IconData _getActionIcon(AIActionType actionType) {
    switch (actionType) {
      case AIActionType.navigateToPage:
        return Icons.navigation;
      case AIActionType.toggleSetting:
        return Icons.settings;
      case AIActionType.checkSystemStatus:
        return Icons.health_and_safety;
      case AIActionType.optimizeBattery:
        return Icons.battery_saver;
      case AIActionType.updateLocation:
        return Icons.location_on;
      case AIActionType.checkWeather:
        return Icons.cloud;
      case AIActionType.sendHelpRequest:
        return Icons.help;
      case AIActionType.callEmergencyContact:
        return Icons.phone;
      case AIActionType.activateSOS:
        return Icons.emergency;
      case AIActionType.checkNearbyServices:
        return Icons.business;
      case AIActionType.updateProfile:
        return Icons.person;
      case AIActionType.backupData:
        return Icons.backup;
      case AIActionType.clearCache:
        return Icons.clear_all;
      case AIActionType.restartServices:
        return Icons.refresh;
    }
  }
}
