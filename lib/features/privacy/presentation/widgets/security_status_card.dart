import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/privacy_security.dart';

/// Widget to display security status information
class SecurityStatusCard extends StatelessWidget {
  final SecurityStatus status;
  final VoidCallback onRefresh;

  const SecurityStatusCard({
    super.key,
    required this.status,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getThreatLevelColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getThreatLevelIcon(),
                    color: _getThreatLevelColor(),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Security Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      Text(
                        _getThreatLevelDisplayName(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _getThreatLevelColor(),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh Security Status',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Security metrics
            Row(
              children: [
                Expanded(
                  child: _buildSecurityMetric(
                    'Device',
                    status.isDeviceSecure ? 'Secure' : 'At Risk',
                    status.isDeviceSecure ? Icons.shield : Icons.warning,
                    status.isDeviceSecure
                        ? AppTheme.safeGreen
                        : AppTheme.criticalRed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSecurityMetric(
                    'Network',
                    status.isNetworkSecure ? 'Secure' : 'At Risk',
                    status.isNetworkSecure ? Icons.wifi_lock : Icons.wifi_off,
                    status.isNetworkSecure
                        ? AppTheme.safeGreen
                        : AppTheme.warningOrange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildSecurityMetric(
                    'Data',
                    status.isDataEncrypted ? 'Encrypted' : 'Unencrypted',
                    status.isDataEncrypted ? Icons.lock : Icons.lock_open,
                    status.isDataEncrypted
                        ? AppTheme.safeGreen
                        : AppTheme.criticalRed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSecurityMetric(
                    'Threats',
                    '${status.activeThreats}',
                    status.activeThreats > 0 ? Icons.security : Icons.verified,
                    status.activeThreats > 0
                        ? AppTheme.criticalRed
                        : AppTheme.safeGreen,
                  ),
                ),
              ],
            ),

            // Last scan info
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 14,
                    color: AppTheme.secondaryText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Last scan: ${_formatTimeAgo(status.lastSecurityScan)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),

            // Security recommendations
            if (status.securityRecommendations.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Security Recommendations:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              ...status.securityRecommendations
                  .take(3)
                  .map(
                    (recommendation) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb,
                            color: AppTheme.warningOrange,
                            size: 12,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              recommendation,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.secondaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppTheme.secondaryText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getThreatLevelColor() {
    switch (status.overallThreatLevel) {
      case ThreatLevel.none:
        return AppTheme.safeGreen;
      case ThreatLevel.low:
        return AppTheme.infoBlue;
      case ThreatLevel.medium:
        return AppTheme.warningOrange;
      case ThreatLevel.high:
        return AppTheme.criticalRed;
      case ThreatLevel.critical:
        return AppTheme.primaryRed;
    }
  }

  IconData _getThreatLevelIcon() {
    switch (status.overallThreatLevel) {
      case ThreatLevel.none:
        return Icons.shield;
      case ThreatLevel.low:
        return Icons.info;
      case ThreatLevel.medium:
        return Icons.warning_amber;
      case ThreatLevel.high:
        return Icons.warning;
      case ThreatLevel.critical:
        return Icons.dangerous;
    }
  }

  String _getThreatLevelDisplayName() {
    switch (status.overallThreatLevel) {
      case ThreatLevel.none:
        return 'No Threats Detected';
      case ThreatLevel.low:
        return 'Low Risk';
      case ThreatLevel.medium:
        return 'Medium Risk';
      case ThreatLevel.high:
        return 'High Risk - Action Required';
      case ThreatLevel.critical:
        return 'Critical Risk - Immediate Action Required';
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
}
