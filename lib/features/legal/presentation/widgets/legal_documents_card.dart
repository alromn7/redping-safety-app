import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/app_service_manager.dart';

/// Widget for displaying legal documents access and status in settings
class LegalDocumentsCard extends StatefulWidget {
  const LegalDocumentsCard({super.key});

  @override
  State<LegalDocumentsCard> createState() => _LegalDocumentsCardState();
}

class _LegalDocumentsCardState extends State<LegalDocumentsCard> {
  final AppServiceManager _serviceManager = AppServiceManager();

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    if (!_serviceManager.legalDocumentsService.isInitialized) {
      await _serviceManager.legalDocumentsService.initialize();
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _navigateToDocument({
    required String documentType,
    required String title,
    required String assetPath,
    bool showAcceptDecline = true,
  }) async {
    final result = await context.push(
      '/document-viewer',
      extra: {
        'documentType': documentType,
        'documentTitle': title,
        'documentPath': assetPath,
        'showAcceptDecline': showAcceptDecline,
      },
    );

    // Refresh the widget if user accepted/declined
    if (result != null && mounted) {
      setState(() {});
    }
  }

  Widget _buildDocumentTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isAccepted,
    required VoidCallback onTap,
    bool isRequired = false,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isAccepted
            ? AppTheme.successGreen.withValues(alpha: 0.1)
            : (isRequired
                  ? AppTheme.primaryRed.withValues(alpha: 0.1)
                  : AppTheme.infoBlue.withValues(alpha: 0.1)),
        child: Icon(
          icon,
          color: isAccepted
              ? AppTheme.successGreen
              : (isRequired ? AppTheme.primaryRed : AppTheme.infoBlue),
          size: 20,
        ),
      ),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isAccepted
                      ? AppTheme.successGreen.withValues(alpha: 0.1)
                      : (isRequired
                            ? AppTheme.primaryRed.withValues(alpha: 0.1)
                            : AppTheme.warningOrange.withValues(alpha: 0.1)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isAccepted
                      ? 'Accepted'
                      : (isRequired ? 'Required' : 'Not Required'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isAccepted
                        ? AppTheme.successGreen
                        : (isRequired
                              ? AppTheme.primaryRed
                              : AppTheme.warningOrange),
                  ),
                ),
              ),
              if (isRequired && !isAccepted) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.warning_amber,
                  size: 16,
                  color: AppTheme.primaryRed,
                ),
              ],
            ],
          ),
        ],
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildOverallStatus() {
    final allRequired =
        _serviceManager.legalDocumentsService.areAllDocumentsAccepted;
    final termsAccepted = _serviceManager.legalDocumentsService.isTermsAccepted;
    final privacyAccepted =
        _serviceManager.legalDocumentsService.isPrivacyAccepted;
    final securityAccepted =
        _serviceManager.legalDocumentsService.isSecurityAccepted;

    final acceptedCount = [
      termsAccepted,
      privacyAccepted,
      securityAccepted,
    ].where((e) => e).length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: allRequired
            ? AppTheme.successGreen.withValues(alpha: 0.1)
            : AppTheme.warningOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: allRequired
              ? AppTheme.successGreen.withValues(alpha: 0.3)
              : AppTheme.warningOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            allRequired ? Icons.check_circle : Icons.warning_amber,
            color: allRequired ? AppTheme.successGreen : AppTheme.warningOrange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allRequired
                      ? 'All Required Documents Accepted'
                      : 'Action Required',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: allRequired
                        ? AppTheme.successGreen
                        : AppTheme.warningOrange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  allRequired
                      ? 'You have accepted all required legal documents.'
                      : 'Please review and accept required documents ($acceptedCount/3 completed).',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        (allRequired
                                ? AppTheme.successGreen
                                : AppTheme.warningOrange)
                            .withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_serviceManager.legalDocumentsService.isInitialized) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Loading legal documents...'),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.infoBlue,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.gavel, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Legal Documents',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Terms, policies, and compliance',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Overall status
          _buildOverallStatus(),

          // Document list
          _buildDocumentTile(
            title: 'Terms & Conditions',
            subtitle: 'App usage terms and service limitations',
            icon: Icons.description,
            isAccepted: _serviceManager.legalDocumentsService.isTermsAccepted,
            isRequired: true,
            onTap: () => _navigateToDocument(
              documentType: 'terms',
              title: 'Terms & Conditions',
              assetPath: 'assets/docs/terms_and_conditions.md',
            ),
          ),

          const Divider(height: 1),

          _buildDocumentTile(
            title: 'Privacy Policy',
            subtitle: 'Data collection and privacy practices',
            icon: Icons.privacy_tip,
            isAccepted: _serviceManager.legalDocumentsService.isPrivacyAccepted,
            isRequired: true,
            onTap: () => _navigateToDocument(
              documentType: 'privacy',
              title: 'Privacy Policy',
              assetPath: 'assets/docs/privacy_policy.md',
            ),
          ),

          const Divider(height: 1),

          _buildDocumentTile(
            title: 'Security Policy',
            subtitle: 'Security measures and protocols',
            icon: Icons.security,
            isAccepted:
                _serviceManager.legalDocumentsService.isSecurityAccepted,
            isRequired: true,
            onTap: () => _navigateToDocument(
              documentType: 'security',
              title: 'Security Policy',
              assetPath: 'assets/docs/security_policy.md',
            ),
          ),

          const Divider(height: 1),

          _buildDocumentTile(
            title: 'Usage Policies',
            subtitle: 'Guidelines for app features and services',
            icon: Icons.rule,
            isAccepted: _serviceManager.legalDocumentsService.isUsageAccepted,
            onTap: () => _navigateToDocument(
              documentType: 'usage',
              title: 'Usage Policies',
              assetPath: 'assets/docs/usage_policies.md',
            ),
          ),

          const Divider(height: 1),

          _buildDocumentTile(
            title: 'Compliance Requirements',
            subtitle: 'Platform and regulatory compliance',
            icon: Icons.verified_user,
            isAccepted:
                _serviceManager.legalDocumentsService.isComplianceAccepted,
            onTap: () => _navigateToDocument(
              documentType: 'compliance',
              title: 'Compliance Requirements',
              assetPath: 'assets/docs/compliance_requirements.md',
            ),
          ),

          const Divider(height: 1),

          _buildDocumentTile(
            title: 'App Limitations',
            subtitle: 'Technical limitations and compatibility',
            icon: Icons.info,
            isAccepted: true, // Read-only document
            onTap: () => _navigateToDocument(
              documentType: 'limitations',
              title: 'App Limitations',
              assetPath: 'assets/docs/app_limitations.md',
              showAcceptDecline: false,
            ),
          ),

          // Footer with version info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Text(
              'Document Version: ${_serviceManager.legalDocumentsService.currentVersion} • Last Updated: December 2024',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
