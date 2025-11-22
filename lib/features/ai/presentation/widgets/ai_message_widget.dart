import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/ai_assistant.dart';

/// Widget for displaying AI conversation messages
class AIMessageWidget extends StatefulWidget {
  final AIMessage message;
  final Function(AISuggestion)? onSuggestionTap;

  const AIMessageWidget({
    super.key,
    required this.message,
    this.onSuggestionTap,
  });

  // Cache isUserMessage computation
  bool get isUserMessage => message.type == AIMessageType.userInput;

  @override
  State<AIMessageWidget> createState() => _AIMessageWidgetState();
}

class _AIMessageWidgetState extends State<AIMessageWidget> {
  bool _isExpanded = true;
  bool _suggestionsExpanded = false;

  // Static text styles
  static const _timestampStyle = TextStyle(
    fontSize: 10,
    color: AppTheme.secondaryText,
  );
  static const _messageTextSize = 14.0;
  static const _messageLineHeight = 1.4;

  @override
  Widget build(BuildContext context) {
    final isUserMessage = widget.isUserMessage;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUserMessage) ...[_buildAIAvatar(), const SizedBox(width: 12)],

          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: isUserMessage
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // Message bubble with collapse/expand
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  child: _buildMessageBubble(isUserMessage),
                ),

                // Timestamp
                const SizedBox(height: 4),
                Text(
                  _formatTimestamp(widget.message.timestamp),
                  style: _timestampStyle,
                ),

                // Suggestions (only for AI messages)
                if (!isUserMessage &&
                    widget.message.suggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInlineSuggestions(),
                ],
              ],
            ),
          ),

          if (isUserMessage) ...[const SizedBox(width: 12), _buildUserAvatar()],
        ],
      ),
    );
  }

  Widget _buildAIAvatar() {
    Color avatarColor;
    IconData avatarIcon;

    switch (widget.message.type) {
      case AIMessageType.safetyAlert:
        avatarColor = AppTheme.criticalRed;
        avatarIcon = Icons.warning;
        break;
      case AIMessageType.performanceUpdate:
        avatarColor = AppTheme.warningOrange;
        avatarIcon = Icons.speed;
        break;
      case AIMessageType.systemNotification:
        avatarColor = AppTheme.infoBlue;
        avatarIcon = Icons.info;
        break;
      case AIMessageType.error:
        avatarColor = AppTheme.criticalRed;
        avatarIcon = Icons.error;
        break;
      default:
        avatarColor = AppTheme.infoBlue;
        avatarIcon = Icons.psychology;
    }

    return CircleAvatar(
      radius: 16,
      backgroundColor: avatarColor.withValues(alpha: 0.1),
      child: Icon(avatarIcon, color: avatarColor, size: 18),
    );
  }

  Widget _buildUserAvatar() {
    return const CircleAvatar(
      radius: 16,
      backgroundColor: AppTheme.neutralGray,
      child: Icon(Icons.person, color: Colors.white, size: 18),
    );
  }

  Widget _buildMessageBubble(bool isUserMessage) {
    final backgroundColor = isUserMessage
        ? AppTheme.infoBlue
        : _getMessageBackgroundColor();

    final textColor = isUserMessage ? Colors.white : AppTheme.primaryText;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16).copyWith(
          topLeft: isUserMessage
              ? const Radius.circular(16)
              : const Radius.circular(4),
          topRight: isUserMessage
              ? const Radius.circular(4)
              : const Radius.circular(16),
        ),
        border: isUserMessage
            ? null
            : Border.all(color: backgroundColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority indicator for important AI messages
          if (!isUserMessage &&
              widget.message.priority != AIMessagePriority.normal)
            _buildPriorityIndicator(),

          // Message content - collapsible
          AnimatedCrossFade(
            firstChild: Text(
              widget.message.content.length > 200
                  ? '${widget.message.content.substring(0, 200)}...'
                  : widget.message.content,
              style: TextStyle(
                fontSize: _messageTextSize,
                color: textColor,
                height: _messageLineHeight,
              ),
            ),
            secondChild: SingleChildScrollView(
              child: Text(
                widget.message.content,
                style: TextStyle(
                  fontSize: _messageTextSize,
                  color: textColor,
                  height: _messageLineHeight,
                ),
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),

          // Expand/collapse indicator for long messages
          if (widget.message.content.length > 200)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                _isExpanded ? 'Tap to collapse' : 'Tap to expand',
                style: TextStyle(
                  fontSize: 10,
                  color: textColor.withValues(alpha: 0.6),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),

          // Metadata for AI messages
          if (!isUserMessage && widget.message.metadata.isNotEmpty)
            _buildMetadata(),

          // AI source badge for AI responses
          if (!isUserMessage && widget.message.type == AIMessageType.aiResponse)
            _buildAISourceBadge(),
        ],
      ),
    );
  }

  Widget _buildPriorityIndicator() {
    final priorityInfo = _getPriorityInfo(widget.message.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: priorityInfo['color'].withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(priorityInfo['icon'], color: priorityInfo['color'], size: 14),
          const SizedBox(width: 4),
          Text(
            priorityInfo['label'],
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: priorityInfo['color'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata() {
    final commandType = widget.message.metadata['command_type'] as String?;
    if (commandType == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Text(
        'Command: $commandType',
        style: const TextStyle(
          fontSize: 10,
          color: AppTheme.secondaryText,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildInlineSuggestions() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.neutralGray.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.neutralGray.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header - always visible
          InkWell(
            onTap: () {
              setState(() {
                _suggestionsExpanded = !_suggestionsExpanded;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: AppTheme.infoBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Quick Actions (${widget.message.suggestions.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryText,
                      ),
                    ),
                  ),
                  Icon(
                    _suggestionsExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 20,
                    color: AppTheme.secondaryText,
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Container(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: widget.message.suggestions.map((suggestion) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Material(
                      color: _getSuggestionColor(
                        suggestion.priority,
                      ).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(6),
                      child: InkWell(
                        onTap: widget.onSuggestionTap != null
                            ? () => widget.onSuggestionTap!(suggestion)
                            : null,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _getSuggestionColor(
                                suggestion.priority,
                              ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getSuggestionIcon(suggestion.actionType),
                                size: 16,
                                color: _getSuggestionColor(suggestion.priority),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      suggestion.title,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _getSuggestionColor(
                                          suggestion.priority,
                                        ),
                                      ),
                                    ),
                                    if (suggestion.description.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        suggestion.description,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: AppTheme.secondaryText,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: AppTheme.secondaryText,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            crossFadeState: _suggestionsExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Color _getMessageBackgroundColor() {
    switch (widget.message.type) {
      case AIMessageType.safetyAlert:
        return AppTheme.criticalRed.withValues(alpha: 0.05);
      case AIMessageType.performanceUpdate:
        return AppTheme.warningOrange.withValues(alpha: 0.05);
      case AIMessageType.systemNotification:
        return AppTheme.infoBlue.withValues(alpha: 0.05);
      case AIMessageType.error:
        return AppTheme.criticalRed.withValues(alpha: 0.05);
      default:
        return AppTheme.infoBlue.withValues(alpha: 0.05);
    }
  }

  Map<String, dynamic> _getPriorityInfo(AIMessagePriority priority) {
    switch (priority) {
      case AIMessagePriority.critical:
        return {
          'color': AppTheme.criticalRed,
          'icon': Icons.priority_high,
          'label': 'CRITICAL',
        };
      case AIMessagePriority.high:
        return {
          'color': AppTheme.warningOrange,
          'icon': Icons.warning,
          'label': 'HIGH',
        };
      case AIMessagePriority.normal:
        return {
          'color': AppTheme.infoBlue,
          'icon': Icons.info,
          'label': 'NORMAL',
        };
      case AIMessagePriority.low:
        return {
          'color': AppTheme.safeGreen,
          'icon': Icons.info_outline,
          'label': 'INFO',
        };
    }
  }

  IconData _getSuggestionIcon(AIActionType actionType) {
    switch (actionType) {
      case AIActionType.navigateToPage:
        return Icons.navigation;
      case AIActionType.toggleSetting:
        return Icons.settings;
      case AIActionType.checkSystemStatus:
        return Icons.speed;
      case AIActionType.optimizeBattery:
        return Icons.battery_charging_full;
      case AIActionType.updateLocation:
        return Icons.location_on;
      case AIActionType.checkWeather:
        return Icons.wb_sunny;
      case AIActionType.sendHelpRequest:
        return Icons.sos;
      case AIActionType.callEmergencyContact:
        return Icons.phone;
      case AIActionType.activateSOS:
        return Icons.warning;
      case AIActionType.checkNearbyServices:
        return Icons.place;
      default:
        return Icons.touch_app;
    }
  }

  Color _getSuggestionColor(AISuggestionPriority priority) {
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  Widget _buildAISourceBadge() {
    final isAIPowered = widget.message.metadata['ai_powered'] == true;
    final badgeText = isAIPowered ? 'Gemini' : 'Native';
    final badgeColor = isAIPowered ? AppTheme.infoBlue : AppTheme.safeGreen;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: badgeColor.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAIPowered ? Icons.auto_awesome : Icons.offline_bolt,
              size: 10,
              color: badgeColor,
            ),
            const SizedBox(width: 3),
            Text(
              badgeText,
              style: TextStyle(
                fontSize: 9,
                color: badgeColor,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
