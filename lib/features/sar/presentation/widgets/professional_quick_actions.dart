import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

/// Professional quick actions widget for SAR dashboard
class ProfessionalQuickActions extends StatelessWidget {
  final VoidCallback onCreateTestEmergency;
  final VoidCallback onRefreshData;
  final VoidCallback onViewMap;
  final VoidCallback onTeamChat;

  const ProfessionalQuickActions({
    super.key,
    required this.onCreateTestEmergency,
    required this.onRefreshData,
    required this.onViewMap,
    required this.onTeamChat,
  });

  @override
  Widget build(BuildContext context) {
    void showMessagingNotAvailable() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Messaging is not available in-app in this build.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.warningOrange.withValues(alpha: 0.3),
        ),
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
                  color: AppTheme.warningOrange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.flash_on,
                  color: AppTheme.warningOrange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Quick Actions',
                  style: TextStyle(
                    color: AppTheme.primaryText,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Action Buttons Grid
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      'Test Emergency',
                      'Create test emergency for training',
                      Icons.bug_report,
                      AppTheme.infoBlue,
                      onCreateTestEmergency,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      'Refresh Data',
                      'Update dashboard information',
                      Icons.refresh,
                      AppTheme.safeGreen,
                      onRefreshData,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      'View Map',
                      'Open area coverage map',
                      Icons.map,
                      AppTheme.warningOrange,
                      onViewMap,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      'Messaging (Web Only)',
                      'Not available in-app in this build',
                      Icons.public,
                      AppTheme.neutralGray,
                      showMessagingNotAvailable,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Emergency Procedures
          _buildEmergencyProcedures(),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.secondaryText,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyProcedures() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.criticalRed.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning, color: AppTheme.criticalRed, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Emergency Procedures',
                style: TextStyle(
                  color: AppTheme.criticalRed,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildProcedureStep(
            '1',
            'Assess the emergency situation and priority level',
            Icons.assessment,
          ),
          _buildProcedureStep(
            '2',
            'Coordinate with team members and dispatch',
            Icons.group,
          ),
          _buildProcedureStep(
            '3',
            'Update status and maintain communication',
            Icons.message,
          ),
          _buildProcedureStep(
            '4',
            'Complete rescue and file incident report',
            Icons.check_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildProcedureStep(String number, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.criticalRed.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.criticalRed),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: AppTheme.criticalRed,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, color: AppTheme.secondaryText, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(color: AppTheme.primaryText, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}






