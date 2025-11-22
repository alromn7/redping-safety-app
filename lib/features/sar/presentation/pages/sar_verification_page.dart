import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/sar_identity.dart';
import '../../../../services/sar_identity_service.dart';
import '../../../../services/feature_access_service.dart';

/// Page for verifying SAR member registrations
class SARVerificationPage extends StatefulWidget {
  const SARVerificationPage({super.key});

  @override
  State<SARVerificationPage> createState() => _SARVerificationPageState();
}

class _SARVerificationPageState extends State<SARVerificationPage>
    with TickerProviderStateMixin {
  final SARIdentityService _identityService = SARIdentityService();

  late TabController _tabController;
  List<SARIdentity> _pendingMembers = [];
  List<SARIdentity> _verifiedMembers = [];
  List<SARIdentity> _rejectedMembers = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    // 🔒 SUBSCRIPTION GATE: SAR Admin requires Ultra subscription
    final featureAccess = FeatureAccessService.instance;
    if (!featureAccess.hasFeatureAccess('sarAdminAccess')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _showUpgradeDialog();
        Navigator.pop(context);
      });
      return;
    }

    _tabController = TabController(length: 3, vsync: this);
    _loadMembers();
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: AppTheme.criticalRed),
            SizedBox(width: 8),
            Expanded(child: Text('Upgrade to Ultra')),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SAR Admin Management is available on Ultra plans only.',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Manage and verify SAR team members, coordinate operations, and oversee your organization.',
                style: TextStyle(color: AppTheme.secondaryText),
              ),
              SizedBox(height: 16),
              Text(
                'What you\'ll get with Ultra:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              SizedBox(height: 8),
              Text('• Full SAR Admin Access'),
              SizedBox(height: 6),
              Text('• Verify SAR Member Registrations'),
              SizedBox(height: 6),
              Text('• Organization Management'),
              SizedBox(height: 6),
              Text('• Team Coordination Tools'),
              SizedBox(height: 6),
              Text('• Add Pro Members (+\$5/member)'),
              SizedBox(height: 6),
              Text('• All Pro Features Included'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to subscription page
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.criticalRed,
            ),
            child: const Text('View Ultra Plan'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);

    try {
      await _identityService.initialize();

      final allMembers = _identityService.registeredMembers;

      setState(() {
        _pendingMembers = allMembers
            .where(
              (m) =>
                  m.verificationStatus == SARVerificationStatus.pending ||
                  m.verificationStatus == SARVerificationStatus.underReview,
            )
            .toList();

        _verifiedMembers = allMembers
            .where(
              (m) => m.verificationStatus == SARVerificationStatus.verified,
            )
            .toList();

        _rejectedMembers = allMembers
            .where(
              (m) => m.verificationStatus == SARVerificationStatus.rejected,
            )
            .toList();
      });
    } catch (e) {
      _showError('Failed to load SAR members: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SAR Member Verification'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Pending',
              icon: Badge(
                isLabelVisible: _pendingMembers.isNotEmpty,
                label: Text('${_pendingMembers.length}'),
                child: const Icon(Icons.pending),
              ),
            ),
            Tab(
              text: 'Verified',
              icon: Badge(
                isLabelVisible: _verifiedMembers.isNotEmpty,
                label: Text('${_verifiedMembers.length}'),
                child: const Icon(Icons.verified),
              ),
            ),
            Tab(
              text: 'Rejected',
              icon: Badge(
                isLabelVisible: _rejectedMembers.isNotEmpty,
                label: Text('${_rejectedMembers.length}'),
                child: const Icon(Icons.cancel),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMembersList(_pendingMembers, 'pending'),
                _buildMembersList(_verifiedMembers, 'verified'),
                _buildMembersList(_rejectedMembers, 'rejected'),
              ],
            ),
    );
  }

  Widget _buildMembersList(List<SARIdentity> members, String type) {
    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'pending'
                  ? Icons.pending_actions
                  : type == 'verified'
                  ? Icons.verified_user
                  : Icons.cancel,
              size: 64,
              color: AppTheme.neutralGray,
            ),
            const SizedBox(height: 16),
            Text(
              'No $type members',
              style: const TextStyle(
                fontSize: 18,
                color: AppTheme.secondaryText,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return _buildMemberCard(member, type);
      },
    );
  }

  Widget _buildMemberCard(SARIdentity member, String type) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showMemberDetails(member),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getStatusColor(
                      member.verificationStatus,
                    ).withValues(alpha: 0.2),
                    child: Icon(
                      _getMemberTypeIcon(member.memberType),
                      color: _getStatusColor(member.verificationStatus),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.personalInfo.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryText,
                          ),
                        ),
                        Text(
                          _identityService.getMemberTypeDisplayName(
                            member.memberType,
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(member.verificationStatus),
                ],
              ),

              const SizedBox(height: 12),

              // Registration details
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppTheme.secondaryText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Registered: ${_formatDate(member.registrationDate)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${member.credentials.length} credentials, ${member.certifications.length} certs',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ],
              ),

              // Experience summary
              if (member.experience.yearsOfExperience > 0 ||
                  member.experience.numberOfMissions > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.work,
                        size: 16,
                        color: AppTheme.secondaryText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${member.experience.yearsOfExperience} years, ${member.experience.numberOfMissions} missions',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),

              // Action buttons for pending members
              if (type == 'pending') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectMember(member),
                        icon: const Icon(Icons.cancel),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.criticalRed,
                          side: const BorderSide(color: AppTheme.criticalRed),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveMember(member),
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.safeGreen,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(SARVerificationStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _identityService.getVerificationStatusDisplayName(status),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _getStatusColor(status),
        ),
      ),
    );
  }

  void _showMemberDetails(SARIdentity member) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: _MemberDetailsDialog(
          member: member,
          identityService: _identityService,
          onMemberUpdated: _loadMembers,
        ),
      ),
    );
  }

  Future<void> _approveMember(SARIdentity member) async {
    try {
      await _identityService.verifyMemberIdentity(
        identityId: member.id,
        verifiedBy: 'SAR_ADMIN', // In production, use actual admin ID
        approved: true,
        notes: 'Approved by SAR administrator',
      );

      _showSuccess('${member.personalInfo.fullName} approved successfully');
      await _loadMembers();
    } catch (e) {
      _showError('Failed to approve member: $e');
    }
  }

  Future<void> _rejectMember(SARIdentity member) async {
    final reason = await _showRejectReasonDialog();
    if (reason == null) return;

    try {
      await _identityService.verifyMemberIdentity(
        identityId: member.id,
        verifiedBy: 'SAR_ADMIN', // In production, use actual admin ID
        approved: false,
        notes: reason,
      );

      _showSuccess('${member.personalInfo.fullName} rejected');
      await _loadMembers();
    } catch (e) {
      _showError('Failed to reject member: $e');
    }
  }

  Future<String?> _showRejectReasonDialog() async {
    final reasonController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejection Reason'),
        content: TextFormField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, reasonController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.criticalRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(SARVerificationStatus status) {
    switch (status) {
      case SARVerificationStatus.pending:
      case SARVerificationStatus.underReview:
        return AppTheme.warningOrange;
      case SARVerificationStatus.verified:
        return AppTheme.safeGreen;
      case SARVerificationStatus.rejected:
        return AppTheme.criticalRed;
      case SARVerificationStatus.expired:
      case SARVerificationStatus.suspended:
        return AppTheme.neutralGray;
    }
  }

  IconData _getMemberTypeIcon(SARMemberType type) {
    switch (type) {
      case SARMemberType.volunteer:
        return Icons.volunteer_activism;
      case SARMemberType.professional:
        return Icons.work;
      case SARMemberType.emergencyServices:
        return Icons.emergency_share;
      case SARMemberType.medicalPersonnel:
        return Icons.medical_services;
      case SARMemberType.teamLeader:
        return Icons.group;
      case SARMemberType.coordinator:
        return Icons.admin_panel_settings;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.criticalRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.safeGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Full-screen dialog for member details verification
class _MemberDetailsDialog extends StatefulWidget {
  final SARIdentity member;
  final SARIdentityService identityService;
  final VoidCallback onMemberUpdated;

  const _MemberDetailsDialog({
    required this.member,
    required this.identityService,
    required this.onMemberUpdated,
  });

  @override
  State<_MemberDetailsDialog> createState() => _MemberDetailsDialogState();
}

class _MemberDetailsDialogState extends State<_MemberDetailsDialog>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.member.personalInfo.fullName} - Verification'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Personal', icon: Icon(Icons.person)),
            Tab(text: 'Credentials', icon: Icon(Icons.badge)),
            Tab(text: 'Certifications', icon: Icon(Icons.school)),
          ],
        ),
        actions: [
          if (widget.member.verificationStatus == SARVerificationStatus.pending)
            PopupMenuButton<String>(
              onSelected: (action) => _handleAction(action),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'approve',
                  child: Row(
                    children: [
                      Icon(Icons.check, color: AppTheme.safeGreen),
                      SizedBox(width: 8),
                      Text('Approve'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'reject',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: AppTheme.criticalRed),
                      SizedBox(width: 8),
                      Text('Reject'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPersonalInfoView(),
          _buildCredentialsView(),
          _buildCertificationsView(),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoView() {
    final member = widget.member;
    final info = member.personalInfo;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Member type and status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getMemberTypeIcon(member.memberType),
                        color: AppTheme.infoBlue,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.identityService.getMemberTypeDisplayName(
                                member.memberType,
                              ),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryText,
                              ),
                            ),
                            Text(
                              widget.identityService
                                  .getVerificationStatusDisplayName(
                                    member.verificationStatus,
                                  ),
                              style: TextStyle(
                                fontSize: 14,
                                color: _getStatusColor(
                                  member.verificationStatus,
                                ),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _buildInfoRow(
                    'Registration Date',
                    _formatDate(member.registrationDate),
                  ),
                  if (member.verificationDate != null)
                    _buildInfoRow(
                      'Verification Date',
                      _formatDate(member.verificationDate!),
                    ),
                  if (member.expirationDate != null)
                    _buildInfoRow(
                      'Expires',
                      _formatDate(member.expirationDate!),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Personal information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildInfoRow('Full Name', info.fullName),
                  _buildInfoRow('Date of Birth', _formatDate(info.dateOfBirth)),
                  _buildInfoRow('Phone', info.phoneNumber),
                  _buildInfoRow('Email', info.email),
                  _buildInfoRow(
                    'Address',
                    '${info.address}, ${info.city}, ${info.state} ${info.zipCode}',
                  ),

                  if (info.emergencyContact != null) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow('Emergency Contact', info.emergencyContact!),
                    if (info.emergencyPhone != null)
                      _buildInfoRow('Emergency Phone', info.emergencyPhone!),
                  ],
                ],
              ),
            ),
          ),

          // Experience summary
          if (member.experience.yearsOfExperience > 0 ||
              member.experience.specializations.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Experience Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildInfoRow(
                      'Years of Experience',
                      '${member.experience.yearsOfExperience}',
                    ),
                    _buildInfoRow(
                      'Number of Missions',
                      '${member.experience.numberOfMissions}',
                    ),

                    if (member.experience.specializations.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Specializations:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: member.experience.specializations.map((spec) {
                          return Chip(
                            label: Text(
                              _getSpecializationDisplayName(spec),
                              style: const TextStyle(fontSize: 11),
                            ),
                            backgroundColor: AppTheme.infoBlue.withValues(
                              alpha: 0.2,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCredentialsView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.member.credentials.length,
      itemBuilder: (context, index) {
        final credential = widget.member.credentials[index];
        return _buildCredentialDetailCard(credential);
      },
    );
  }

  Widget _buildCertificationsView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.member.certifications.length,
      itemBuilder: (context, index) {
        final certification = widget.member.certifications[index];
        return _buildCertificationDetailCard(certification);
      },
    );
  }

  Widget _buildCredentialDetailCard(SARCredential credential) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getCredentialIcon(credential.type),
                  color: AppTheme.infoBlue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.identityService.getCredentialTypeDisplayName(
                      credential.type,
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      credential.verificationStatus,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.identityService.getVerificationStatusDisplayName(
                      credential.verificationStatus,
                    ),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(credential.verificationStatus),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Document photo
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.neutralGray),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(credential.photoPath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.image_not_supported, size: 48),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            _buildInfoRow('Document Number', credential.documentNumber),
            _buildInfoRow('Issuing Authority', credential.issuingAuthority),
            _buildInfoRow('Issue Date', _formatDate(credential.issueDate)),
            _buildInfoRow(
              'Expiration Date',
              _formatDate(credential.expirationDate),
            ),

            if (credential.notes != null)
              _buildInfoRow('Notes', credential.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificationDetailCard(SARCertification certification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getCertificationIcon(certification.type),
                  color: AppTheme.safeGreen,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    certification.certificationName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      certification.verificationStatus,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.identityService.getVerificationStatusDisplayName(
                      certification.verificationStatus,
                    ),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(certification.verificationStatus),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Certificate photo
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.neutralGray),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(certification.photoPath),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.image_not_supported, size: 48),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            _buildInfoRow(
              'Certificate Number',
              certification.certificateNumber,
            ),
            _buildInfoRow(
              'Issuing Organization',
              certification.issuingOrganization,
            ),
            _buildInfoRow('Issue Date', _formatDate(certification.issueDate)),
            if (certification.expirationDate != null)
              _buildInfoRow(
                'Expiration Date',
                _formatDate(certification.expirationDate!),
              ),

            if (certification.specializations.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Specializations:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: certification.specializations.map((spec) {
                  return Chip(
                    label: Text(spec, style: const TextStyle(fontSize: 11)),
                    backgroundColor: AppTheme.safeGreen.withValues(alpha: 0.2),
                  );
                }).toList(),
              ),
            ],

            if (certification.notes != null)
              _buildInfoRow('Notes', certification.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12, color: AppTheme.primaryText),
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(String action) async {
    switch (action) {
      case 'approve':
        await _approveMember();
        break;
      case 'reject':
        await _rejectMember();
        break;
    }
  }

  Future<void> _approveMember() async {
    // ignore: use_build_context_synchronously
    final messenger = ScaffoldMessenger.of(context);
    // ignore: use_build_context_synchronously
    final navigator = Navigator.of(context);
    try {
      await widget.identityService.verifyMemberIdentity(
        identityId: widget.member.id,
        verifiedBy: 'SAR_ADMIN',
        approved: true,
        notes: 'Approved after detailed verification',
      );

      widget.onMemberUpdated();
      navigator.pop();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${widget.member.personalInfo.fullName} approved successfully',
          ),
          backgroundColor: AppTheme.safeGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to approve member: $e'),
          backgroundColor: AppTheme.criticalRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _rejectMember() async {
    final reason = await _showRejectReasonDialog();
    if (reason == null) return;

    // ignore: use_build_context_synchronously
    final messenger = ScaffoldMessenger.of(context);
    // ignore: use_build_context_synchronously
    final navigator = Navigator.of(context);
    try {
      await widget.identityService.verifyMemberIdentity(
        identityId: widget.member.id,
        verifiedBy: 'SAR_ADMIN',
        approved: false,
        notes: reason,
      );

      widget.onMemberUpdated();
      navigator.pop();

      messenger.showSnackBar(
        SnackBar(
          content: Text('${widget.member.personalInfo.fullName} rejected'),
          backgroundColor: AppTheme.criticalRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to reject member: $e'),
          backgroundColor: AppTheme.criticalRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<String?> _showRejectReasonDialog() async {
    final reasonController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejection Reason'),
        content: TextFormField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, reasonController.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.criticalRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  // Helper methods
  Color _getStatusColor(SARVerificationStatus status) {
    switch (status) {
      case SARVerificationStatus.pending:
      case SARVerificationStatus.underReview:
        return AppTheme.warningOrange;
      case SARVerificationStatus.verified:
        return AppTheme.safeGreen;
      case SARVerificationStatus.rejected:
        return AppTheme.criticalRed;
      case SARVerificationStatus.expired:
      case SARVerificationStatus.suspended:
        return AppTheme.neutralGray;
    }
  }

  IconData _getMemberTypeIcon(SARMemberType type) {
    switch (type) {
      case SARMemberType.volunteer:
        return Icons.volunteer_activism;
      case SARMemberType.professional:
        return Icons.work;
      case SARMemberType.emergencyServices:
        return Icons.emergency_share;
      case SARMemberType.medicalPersonnel:
        return Icons.medical_services;
      case SARMemberType.teamLeader:
        return Icons.group;
      case SARMemberType.coordinator:
        return Icons.admin_panel_settings;
    }
  }

  IconData _getCredentialIcon(SARCredentialType type) {
    switch (type) {
      case SARCredentialType.driversLicense:
        return Icons.drive_eta;
      case SARCredentialType.passport:
        return Icons.flight;
      case SARCredentialType.stateId:
      case SARCredentialType.governmentId:
        return Icons.badge;
      case SARCredentialType.professionalLicense:
        return Icons.work;
      case SARCredentialType.backgroundCheck:
        return Icons.security;
    }
  }

  IconData _getCertificationIcon(SARCertificationType type) {
    switch (type) {
      case SARCertificationType.wildernessFirstAid:
      case SARCertificationType.medicalTraining:
        return Icons.medical_services;
      case SARCertificationType.cprCertification:
        return Icons.favorite;
      case SARCertificationType.rescueTechnician:
      case SARCertificationType.technicalRescue:
        return Icons.construction;
      case SARCertificationType.mountainRescue:
        return Icons.terrain;
      case SARCertificationType.waterRescue:
        return Icons.waves;
      case SARCertificationType.incidentCommand:
      case SARCertificationType.searchManagement:
        return Icons.settings;
      case SARCertificationType.radioOperator:
        return Icons.radio;
      case SARCertificationType.k9Handler:
        return Icons.pets;
      case SARCertificationType.aviationRescue:
        return Icons.flight;
    }
  }

  String _getSpecializationDisplayName(SARSpecialization specialization) {
    switch (specialization) {
      case SARSpecialization.groundSearch:
        return 'Ground Search';
      case SARSpecialization.technicalRescue:
        return 'Technical Rescue';
      case SARSpecialization.waterRescue:
        return 'Water Rescue';
      case SARSpecialization.mountainRescue:
        return 'Mountain Rescue';
      case SARSpecialization.urbanRescue:
        return 'Urban Rescue';
      case SARSpecialization.medicalSupport:
        return 'Medical Support';
      case SARSpecialization.k9Search:
        return 'K9 Search';
      case SARSpecialization.aviationSupport:
        return 'Aviation Support';
      case SARSpecialization.communications:
        return 'Communications';
      case SARSpecialization.logistics:
        return 'Logistics';
      case SARSpecialization.commandControl:
        return 'Command & Control';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
