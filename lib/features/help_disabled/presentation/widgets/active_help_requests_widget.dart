import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/help_request.dart';

/// Widget to display active help requests
class ActiveHelpRequestsWidget extends StatelessWidget {
  final List<HelpRequest> requests;

  const ActiveHelpRequestsWidget({super.key, required this.requests});

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.pending_actions,
              color: AppTheme.warningOrange,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              'Active Help Requests (${requests.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ...requests.map((request) => _buildRequestCard(context, request)),
      ],
    );
  }

  Widget _buildRequestCard(BuildContext context, HelpRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: _getStatusColor(request.status).withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  _getCategoryIconById(request.categoryId),
                  color: _getStatusColor(request.status),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getRequestTitle(request),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusDisplayName(request.status),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Description
            Text(
              request.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.secondaryText,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Stats
            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: AppTheme.secondaryText),
                const SizedBox(width: 4),
                Text(
                  _formatTimeAgo(request.createdAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.people, size: 16, color: AppTheme.secondaryText),
                const SizedBox(width: 4),
                Text(
                  '${request.responses.length} response${request.responses.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showRequestOptions(context, request),
                  iconSize: 16,
                ),
              ],
            ),

            // Responses preview
            if (request.responses.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.safeGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.safeGreen,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Latest: ${request.responses.last.responderName} responded',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.safeGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showRequestOptions(BuildContext context, HelpRequest request) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility, color: AppTheme.infoBlue),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _viewRequestDetails(context, request);
              },
            ),
            ListTile(
              leading: const Icon(Icons.message, color: AppTheme.safeGreen),
              title: const Text('View Responses'),
              onTap: () {
                Navigator.pop(context);
                _viewResponses(context, request);
              },
            ),
            if (request.status != HelpRequestStatus.resolved &&
                request.status != HelpRequestStatus.cancelled)
              ListTile(
                leading: const Icon(Icons.cancel, color: AppTheme.criticalRed),
                title: const Text('Cancel Request'),
                onTap: () {
                  Navigator.pop(context);
                  _cancelRequest(context, request);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _viewRequestDetails(BuildContext context, HelpRequest request) {
    // TODO: Implement detailed request view
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Detailed request view coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _viewResponses(BuildContext context, HelpRequest request) {
    // TODO: Implement responses view
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Responses view coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _cancelRequest(BuildContext context, HelpRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Help Request'),
        content: Text(
          'Are you sure you want to cancel "${_getRequestTitle(request)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement cancel request
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Request cancelled'),
                  backgroundColor: AppTheme.criticalRed,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.criticalRed,
            ),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(HelpRequestStatus status) {
    switch (status) {
      case HelpRequestStatus.active:
        return AppTheme.warningOrange;
      case HelpRequestStatus.assigned:
        return AppTheme.infoBlue;
      case HelpRequestStatus.inProgress:
        return AppTheme.infoBlue;
      case HelpRequestStatus.resolved:
        return AppTheme.safeGreen;
      case HelpRequestStatus.cancelled:
        return AppTheme.neutralGray;
      case HelpRequestStatus.expired:
        return AppTheme.criticalRed;
    }
  }

  IconData _getCategoryIconById(String categoryId) {
    switch (categoryId) {
      case 'vehicle':
        return Icons.directions_car;
      case 'home_security':
        return Icons.security;
      case 'personal_safety':
        return Icons.shield_outlined;
      case 'lost_found':
        return Icons.search;
      case 'marine':
        return Icons.directions_boat;
      case 'community':
        return Icons.groups;
      case 'legal':
        return Icons.gavel;
      case 'utilities':
        return Icons.power;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusDisplayName(HelpRequestStatus status) {
    switch (status) {
      case HelpRequestStatus.active:
        return 'ACTIVE';
      case HelpRequestStatus.assigned:
        return 'ASSIGNED';
      case HelpRequestStatus.inProgress:
        return 'IN PROGRESS';
      case HelpRequestStatus.resolved:
        return 'RESOLVED';
      case HelpRequestStatus.cancelled:
        return 'CANCELLED';
      case HelpRequestStatus.expired:
        return 'EXPIRED';
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  String _getRequestTitle(HelpRequest request) {
    // Prefer additionalInfo as title if provided; else use description fallback
    final title = request.additionalInfo?.trim();
    if (title != null && title.isNotEmpty) return title;
    // Use a truncated description as a title fallback
    final desc = request.description.trim();
    if (desc.length <= 60) return desc;
    return '${desc.substring(0, 57)}...';
  }
}
