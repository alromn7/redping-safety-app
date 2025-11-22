import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Professional team status widget showing team member availability and roles
class ProfessionalTeamStatusWidget extends StatelessWidget {
  final List<Map<String, dynamic>> teamMembers;
  final int activeMembers;

  const ProfessionalTeamStatusWidget({
    super.key,
    required this.teamMembers,
    required this.activeMembers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.infoBlue.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.infoBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.group,
                  color: AppTheme.infoBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Team Status',
                      style: TextStyle(
                        color: AppTheme.primaryText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$activeMembers of ${teamMembers.length} members online',
                      style: TextStyle(
                        color: AppTheme.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: activeMembers > 0
                      ? AppTheme.safeGreen.withValues(alpha: 0.2)
                      : AppTheme.neutralGray.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: activeMembers > 0
                        ? AppTheme.safeGreen
                        : AppTheme.neutralGray,
                  ),
                ),
                child: Text(
                  activeMembers > 0 ? 'ACTIVE' : 'STANDBY',
                  style: TextStyle(
                    color: activeMembers > 0
                        ? AppTheme.safeGreen
                        : AppTheme.neutralGray,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Team Members Grid
          if (teamMembers.isEmpty)
            _buildEmptyState()
          else
            Column(
              children: teamMembers
                  .map((member) => _buildTeamMemberCard(member))
                  .toList(),
            ),

          const SizedBox(height: 16),

          // Team Performance Summary
          _buildPerformanceSummary(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.group_outlined,
            size: 48,
            color: AppTheme.neutralGray.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 16),
          Text(
            'No Team Members Available',
            style: TextStyle(
              color: AppTheme.secondaryText,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Team members will appear here when they join',
            style: TextStyle(color: AppTheme.secondaryText, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMemberCard(Map<String, dynamic> member) {
    final name = member['name'] ?? 'Unknown';
    final status = member['status'] ?? 'offline';
    final role = member['role'] ?? 'Team Member';

    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: statusColor, width: 2),
            ),
            child: Icon(Icons.person, color: statusColor, size: 24),
          ),

          const SizedBox(width: 16),

          // Member Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppTheme.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  style: TextStyle(color: AppTheme.secondaryText, fontSize: 14),
                ),
              ],
            ),
          ),

          // Status Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: statusColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, color: statusColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  status.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSummary() {
    final totalMembers = teamMembers.length;
    final onlineMembers = teamMembers
        .where((m) => m['status'] == 'online')
        .length;
    final busyMembers = teamMembers.where((m) => m['status'] == 'busy').length;
    final availability = totalMembers > 0
        ? (onlineMembers / totalMembers * 100)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.infoBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Team Performance',
            style: TextStyle(
              color: AppTheme.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildPerformanceMetric(
                  'Availability',
                  '${availability.toStringAsFixed(1)}%',
                  availability >= 80
                      ? AppTheme.safeGreen
                      : availability >= 60
                      ? AppTheme.warningOrange
                      : AppTheme.criticalRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPerformanceMetric(
                  'Online',
                  onlineMembers.toString(),
                  AppTheme.safeGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPerformanceMetric(
                  'Busy',
                  busyMembers.toString(),
                  AppTheme.warningOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: AppTheme.secondaryText, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return AppTheme.safeGreen;
      case 'busy':
        return AppTheme.warningOrange;
      case 'offline':
        return AppTheme.neutralGray;
      case 'away':
        return AppTheme.infoBlue;
      default:
        return AppTheme.neutralGray;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return Icons.circle;
      case 'busy':
        return Icons.schedule;
      case 'offline':
        return Icons.circle_outlined;
      case 'away':
        return Icons.person_off;
      default:
        return Icons.circle_outlined;
    }
  }
}
