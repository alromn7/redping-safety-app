import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/help_request.dart';

/// Widget to track and display community help request status
class HelpStatusTracker extends StatelessWidget {
  final HelpRequest helpRequest;
  final Animation<double> animation;

  const HelpStatusTracker({
    super.key,
    required this.helpRequest,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor().withValues(alpha: 0.1),
            _getStatusColor().withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStatusColor().withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Status Header
          Row(
            children: [
              AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (animation.value * 0.1),
                    child: Icon(
                      _getStatusIcon(),
                      color: _getStatusColor(),
                      size: 32,
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStatusTitle(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getStatusDescription(),
                      style: const TextStyle(
                        color: AppTheme.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              _buildPriorityBadge(),
            ],
          ),

          const SizedBox(height: 16),

          // Progress Indicators
          _buildProgressIndicators(),

          const SizedBox(height: 16),

          // Response Information
          _buildResponseInfo(),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getPriorityColor(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        helpRequest.priority.name.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProgressIndicators() {
    final steps = _getProgressSteps();
    final currentStep = _getCurrentStep();

    return Row(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final isCompleted = index < currentStep;
        final isCurrent = index == currentStep;

        return Expanded(
          child: Row(
            children: [
              // Step Circle
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted || isCurrent
                      ? _getStatusColor()
                      : AppTheme.neutralGray.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted ? Icons.check : Icons.circle,
                  color: Colors.white,
                  size: 16,
                ),
              ),

              // Step Label
              if (index < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? _getStatusColor()
                          : AppTheme.neutralGray.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResponseInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.neutralGray.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: AppTheme.infoBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Response Time',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryText,
                ),
              ),
              const Spacer(),
              Text(
                _getEstimatedResponseTime(),
                style: const TextStyle(color: AppTheme.secondaryText),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.people, color: AppTheme.safeGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Community Helpers Assigned',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryText,
                ),
              ),
              const Spacer(),
              Text(
                '${helpRequest.assignedHelpers.length}',
                style: const TextStyle(color: AppTheme.secondaryText),
              ),
            ],
          ),
          if (helpRequest.assignedHelpers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Helpers: ${helpRequest.assignedHelpers.join(", ")}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.secondaryText,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<String> _getProgressSteps() {
    return [
      'Request Sent',
      'SAR Notified',
      'Team Assigned',
      'En Route',
      'On Scene',
      'Completed',
    ];
  }

  int _getCurrentStep() {
    switch (helpRequest.status) {
      case HelpRequestStatus.active:
        return 1; // Request Active
      case HelpRequestStatus.assigned:
        return 2; // Helper Assigned
      case HelpRequestStatus.inProgress:
        return 3; // In Progress
      case HelpRequestStatus.resolved:
        return 4; // Resolved
      case HelpRequestStatus.expired:
        return 0; // Expired
      case HelpRequestStatus.cancelled:
        return 0; // Cancelled
    }
  }

  String _getStatusTitle() {
    switch (helpRequest.status) {
      case HelpRequestStatus.active:
        return 'Help Request Active';
      case HelpRequestStatus.assigned:
        return 'Community Helper Assigned';
      case HelpRequestStatus.inProgress:
        return 'Community Helper Responding';
      case HelpRequestStatus.resolved:
        return 'Request Resolved';
      case HelpRequestStatus.expired:
        return 'Request Expired';
      case HelpRequestStatus.cancelled:
        return 'Request Cancelled';
    }
  }

  String _getStatusDescription() {
    switch (helpRequest.status) {
      case HelpRequestStatus.active:
        return 'Your help request has been sent to the community help network';
      case HelpRequestStatus.assigned:
        return 'A community helper has been assigned to your request';
      case HelpRequestStatus.inProgress:
        return 'Community helper is responding to your request';
      case HelpRequestStatus.resolved:
        return 'Your help request has been successfully resolved';
      case HelpRequestStatus.expired:
        return 'Your help request has expired';
      case HelpRequestStatus.cancelled:
        return 'Your help request has been cancelled';
    }
  }

  IconData _getStatusIcon() {
    switch (helpRequest.status) {
      case HelpRequestStatus.active:
        return Icons.send;
      case HelpRequestStatus.assigned:
        return Icons.assignment;
      case HelpRequestStatus.inProgress:
        return Icons.directions_car;
      case HelpRequestStatus.resolved:
        return Icons.check_circle;
      case HelpRequestStatus.expired:
        return Icons.schedule;
      case HelpRequestStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getStatusColor() {
    switch (helpRequest.status) {
      case HelpRequestStatus.active:
        return AppTheme.infoBlue;
      case HelpRequestStatus.assigned:
        return AppTheme.warningOrange;
      case HelpRequestStatus.inProgress:
        return AppTheme.safeGreen;
      case HelpRequestStatus.resolved:
        return AppTheme.safeGreen;
      case HelpRequestStatus.expired:
        return AppTheme.neutralGray;
      case HelpRequestStatus.cancelled:
        return AppTheme.criticalRed;
    }
  }

  Color _getPriorityColor() {
    switch (helpRequest.priority) {
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

  String _getEstimatedResponseTime() {
    return 'Depends on local services';
  }
}
