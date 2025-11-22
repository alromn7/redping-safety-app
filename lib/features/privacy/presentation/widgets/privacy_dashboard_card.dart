import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/app_service_manager.dart';
import '../../../../models/privacy_security.dart';

/// Privacy and security dashboard card for settings
class PrivacyDashboardCard extends StatefulWidget {
  const PrivacyDashboardCard({super.key});

  @override
  State<PrivacyDashboardCard> createState() => _PrivacyDashboardCardState();
}

class _PrivacyDashboardCardState extends State<PrivacyDashboardCard>
    with TickerProviderStateMixin {
  final AppServiceManager _serviceManager = AppServiceManager();

  SecurityStatus? _securityStatus;
  ComplianceStatus? _complianceStatus;
  int _deniedPermissions = 0;
  bool _isLoading = true;

  late AnimationController _alertController;
  late Animation<double> _alertAnimation;

  @override
  void initState() {
    super.initState();

    _alertController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _alertAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _alertController, curve: Curves.easeInOut),
    );

    _loadSecurityData();
  }

  @override
  void dispose() {
    // Detach service callbacks to avoid setState after dispose
    try {
      _serviceManager.privacySecurityService.setSecurityStatusChangedCallback(
        (_) {},
      );
    } catch (_) {}

    // Stop any animations
    _alertController.dispose();
    super.dispose();
  }

  Future<void> _loadSecurityData() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      await _serviceManager.privacySecurityService.initialize();

      // Set up callbacks
      _serviceManager.privacySecurityService.setSecurityStatusChangedCallback(
        _onSecurityStatusChanged,
      );

      // Load current data
      _securityStatus =
          _serviceManager.privacySecurityService.currentSecurityStatus;
      _complianceStatus =
          _serviceManager.privacySecurityService.complianceStatus;

      // Count denied permissions
      final permissions = _serviceManager.privacySecurityService.permissions;
      _deniedPermissions = permissions
          .where(
            (p) =>
                p.isRequired &&
                (p.status == PermissionStatus.denied ||
                    p.status == PermissionStatus.permanentlyDenied),
          )
          .length;

      // Start alert animation if there are security issues
      if (_hasSecurityIssues()) {
        _alertController.repeat(reverse: true);
      }
    } catch (e) {
      debugPrint('PrivacyDashboardCard: Error loading data - $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onSecurityStatusChanged(SecurityStatus status) {
    if (!mounted) return;
    setState(() {
      _securityStatus = status;

      // Update animation based on threat level
      if (_hasSecurityIssues()) {
        _alertController.repeat(reverse: true);
      } else {
        _alertController.stop();
        _alertController.reset();
      }
    });
  }

  bool _hasSecurityIssues() {
    return _securityStatus?.overallThreatLevel == ThreatLevel.high ||
        _securityStatus?.overallThreatLevel == ThreatLevel.critical ||
        _deniedPermissions > 0 ||
        _complianceStatus?.complianceIssues.isNotEmpty == true;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/settings/privacy'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _alertAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _hasSecurityIssues()
                            ? _alertAnimation.value
                            : 1.0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getOverallStatusColor().withValues(
                              alpha: 0.2,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getOverallStatusIcon(),
                            color: _getOverallStatusColor(),
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Privacy & Security',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryText,
                          ),
                        ),
                        Text(
                          _getOverallStatusText(),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getOverallStatusColor(),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.secondaryText,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Status indicators
              Row(
                children: [
                  Expanded(
                    child: _buildStatusIndicator(
                      'Permissions',
                      _deniedPermissions == 0
                          ? 'All Granted'
                          : '$_deniedPermissions Denied',
                      _deniedPermissions == 0
                          ? Icons.check_circle
                          : Icons.warning,
                      _deniedPermissions == 0
                          ? AppTheme.safeGreen
                          : AppTheme.warningOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusIndicator(
                      'Security',
                      _securityStatus != null
                          ? _getThreatLevelShortName()
                          : 'Unknown',
                      _securityStatus != null
                          ? _getThreatLevelIcon()
                          : Icons.help,
                      _securityStatus != null
                          ? _getThreatLevelColor()
                          : AppTheme.neutralGray,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildStatusIndicator(
                      'Encryption',
                      _securityStatus?.isDataEncrypted == true
                          ? 'Active'
                          : 'Disabled',
                      _securityStatus?.isDataEncrypted == true
                          ? Icons.enhanced_encryption
                          : Icons.lock_open,
                      _securityStatus?.isDataEncrypted == true
                          ? AppTheme.safeGreen
                          : AppTheme.criticalRed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatusIndicator(
                      'Compliance',
                      _getComplianceStatusText(),
                      _getComplianceStatusIcon(),
                      _getComplianceStatusColor(),
                    ),
                  ),
                ],
              ),

              // Quick actions if there are issues
              if (_hasSecurityIssues()) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.warningOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.warningOrange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.priority_high,
                        color: AppTheme.warningOrange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Security issues detected',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.warningOrange,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/settings/privacy'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.warningOrange,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                        child: const Text(
                          'Fix Now',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: AppTheme.secondaryText),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getOverallStatusColor() {
    if (_hasSecurityIssues()) {
      return AppTheme.warningOrange;
    }
    return AppTheme.safeGreen;
  }

  IconData _getOverallStatusIcon() {
    if (_hasSecurityIssues()) {
      return Icons.security;
    }
    return Icons.verified_user;
  }

  String _getOverallStatusText() {
    if (_deniedPermissions > 0) {
      return 'Permissions needed';
    } else if (_securityStatus?.overallThreatLevel == ThreatLevel.high ||
        _securityStatus?.overallThreatLevel == ThreatLevel.critical) {
      return 'Security issues detected';
    } else if (_complianceStatus?.complianceIssues.isNotEmpty == true) {
      return 'Compliance issues';
    } else {
      return 'All systems secure';
    }
  }

  Color _getThreatLevelColor() {
    if (_securityStatus == null) return AppTheme.neutralGray;

    switch (_securityStatus!.overallThreatLevel) {
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
    if (_securityStatus == null) return Icons.help;

    switch (_securityStatus!.overallThreatLevel) {
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

  String _getThreatLevelShortName() {
    if (_securityStatus == null) return 'Unknown';

    switch (_securityStatus!.overallThreatLevel) {
      case ThreatLevel.none:
        return 'Secure';
      case ThreatLevel.low:
        return 'Low Risk';
      case ThreatLevel.medium:
        return 'Medium';
      case ThreatLevel.high:
        return 'High Risk';
      case ThreatLevel.critical:
        return 'Critical';
    }
  }

  String _getComplianceStatusText() {
    if (_complianceStatus == null) return 'Unknown';

    final issues = _complianceStatus!.complianceIssues.length;
    if (issues == 0) {
      return 'Compliant';
    } else {
      return '$issues Issues';
    }
  }

  IconData _getComplianceStatusIcon() {
    if (_complianceStatus == null) return Icons.help;

    return _complianceStatus!.complianceIssues.isEmpty
        ? Icons.verified_user
        : Icons.warning;
  }

  Color _getComplianceStatusColor() {
    if (_complianceStatus == null) return AppTheme.neutralGray;

    return _complianceStatus!.complianceIssues.isEmpty
        ? AppTheme.safeGreen
        : AppTheme.warningOrange;
  }
}
