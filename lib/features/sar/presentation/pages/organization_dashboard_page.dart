// ignore_for_file: unused_field, unused_element
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/sar_organization.dart';
import '../../../../models/sar_identity.dart';
import '../../../../services/sar_organization_service.dart';
import '../../../../services/app_service_manager.dart';

/// Organization management dashboard
class OrganizationDashboardPage extends StatefulWidget {
  const OrganizationDashboardPage({super.key});

  @override
  State<OrganizationDashboardPage> createState() =>
      _OrganizationDashboardPageState();
}

class _OrganizationDashboardPageState extends State<OrganizationDashboardPage>
    with TickerProviderStateMixin {
  final AppServiceManager _serviceManager = AppServiceManager();
  final SAROrganizationService _organizationService = SAROrganizationService();

  late TabController _tabController;

  SAROrganization? _currentOrganization;
  List<SAROrganizationMember> _members = [];
  List<SAROrganizationOperation> _activeOperations = [];
  List<SAROrganizationOperation> _allOperations = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);

    try {
      await _organizationService.initialize();
      _loadOrganizationData();
    } catch (e) {
      _showError('Failed to initialize organization dashboard: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _loadOrganizationData() {
    _currentOrganization = _organizationService.currentUserOrganization;

    if (_currentOrganization != null) {
      _members = _organizationService.getOrganizationMembers(
        _currentOrganization!.id,
      );
      _activeOperations = _organizationService.getActiveOperations(
        _currentOrganization!.id,
      );
      _allOperations = _organizationService.getOrganizationOperations(
        _currentOrganization!.id,
      );
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentOrganization == null) {
      return _buildNoOrganizationView();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentOrganization!.organizationName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            onPressed: _showOrganizationInfo,
            icon: const Icon(Icons.info),
            tooltip: 'Organization Info',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_member',
                child: Row(
                  children: [
                    Icon(Icons.person_add, color: AppTheme.infoBlue),
                    SizedBox(width: 8),
                    Text('Add Member'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'start_operation',
                child: Row(
                  children: [
                    Icon(Icons.play_arrow, color: AppTheme.safeGreen),
                    SizedBox(width: 8),
                    Text('Start Operation'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: AppTheme.neutralGray),
                    SizedBox(width: 8),
                    Text('Organization Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Members', icon: Icon(Icons.people)),
            Tab(text: 'Operations', icon: Icon(Icons.assignment)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildMembersTab(),
          _buildOperationsTab(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildNoOrganizationView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organization Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.business, size: 64, color: AppTheme.neutralGray),
              const SizedBox(height: 16),
              const Text(
                'No Organization Found',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You are not associated with any SAR organization. Register a new organization to manage members and coordinate rescue operations.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppTheme.secondaryText),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/organization-registration'),
                icon: const Icon(Icons.add),
                label: const Text('Register Organization'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.infoBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Organization status card
          _buildOrganizationStatusCard(),

          const SizedBox(height: 16),

          // Quick stats
          _buildQuickStatsGrid(),

          const SizedBox(height: 16),

          // Active operations summary
          if (_activeOperations.isNotEmpty) ...[
            _buildActiveOperationsSummary(),
            const SizedBox(height: 16),
          ],

          // Recent activity
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildOrganizationStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_getStatusIcon(), color: _getStatusColor()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentOrganization!.organizationName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      Text(
                        _getVerificationStatusText(),
                        style: TextStyle(
                          fontSize: 14,
                          color: _getStatusColor(),
                          fontWeight: FontWeight.w500,
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
                    color: _getOperationalStatusColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _getOperationalStatusText(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getOperationalStatusColor(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              _currentOrganization!.organizationInfo.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.secondaryText,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: AppTheme.secondaryText,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_currentOrganization!.organizationInfo.city}, ${_currentOrganization!.organizationInfo.state}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppTheme.secondaryText,
                ),
                const SizedBox(width: 4),
                Text(
                  'Founded ${_currentOrganization!.organizationInfo.foundedYear}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Members',
            _members.length.toString(),
            Icons.people,
            AppTheme.infoBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Active Ops',
            _activeOperations.length.toString(),
            Icons.emergency,
            AppTheme.criticalRed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total Ops',
            _allOperations.length.toString(),
            Icons.assignment,
            AppTheme.safeGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOperationsSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Active Operations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 12),

            ..._activeOperations
                .take(3)
                .map(
                  (operation) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: AppTheme.criticalRed.withValues(alpha: 0.05),
                    child: ListTile(
                      leading: const Icon(
                        Icons.emergency,
                        color: AppTheme.criticalRed,
                      ),
                      title: Text(operation.operationName),
                      subtitle: Text(
                        '${operation.assignedMemberIds.length} members • ${_formatDuration(DateTime.now().difference(operation.startTime))}',
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => _viewOperation(operation),
                    ),
                  ),
                ),

            if (_activeOperations.length > 3)
              TextButton(
                onPressed: () => _tabController.animateTo(2),
                child: Text(
                  'View all ${_activeOperations.length} active operations',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 12),

            // Mock recent activities
            _buildActivityItem(
              'New member joined',
              'John Smith added as Team Leader',
              Icons.person_add,
              AppTheme.safeGreen,
              '2 hours ago',
            ),
            _buildActivityItem(
              'Operation completed',
              'Mountain rescue operation successfully completed',
              Icons.check_circle,
              AppTheme.safeGreen,
              '1 day ago',
            ),
            _buildActivityItem(
              'Training session',
              'Monthly training session conducted',
              Icons.school,
              AppTheme.infoBlue,
              '3 days ago',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String description,
    IconData icon,
    Color color,
    String time,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryText,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(fontSize: 11, color: AppTheme.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Members header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Organization Members (${_members.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryText,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addMember,
                icon: const Icon(Icons.person_add),
                label: const Text('Add Member'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.infoBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Members list
          if (_members.isEmpty)
            const Center(
              child: Text(
                'No members found',
                style: TextStyle(color: AppTheme.secondaryText),
              ),
            )
          else
            ..._members.map((member) => _buildMemberCard(member)),
        ],
      ),
    );
  }

  Widget _buildMemberCard(SAROrganizationMember member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: _getMemberRoleColor(
                member.role,
              ).withValues(alpha: 0.2),
              child: Icon(
                _getMemberRoleIcon(member.role),
                color: _getMemberRoleColor(member.role),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.memberName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  Text(
                    _getMemberRoleDisplayName(member.role),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                  if (member.specializations.isNotEmpty)
                    Text(
                      'Specializations: ${member.specializations.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondaryText,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getMemberStatusColor(
                  member.status,
                ).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getMemberStatusDisplayName(member.status),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _getMemberStatusColor(member.status),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Operations header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rescue Operations (${_allOperations.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryText,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _startOperation,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Operation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.criticalRed,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Operations list
          if (_allOperations.isEmpty)
            const Center(
              child: Text(
                'No operations found',
                style: TextStyle(color: AppTheme.secondaryText),
              ),
            )
          else
            ..._allOperations.map(
              (operation) => _buildOperationCard(operation),
            ),
        ],
      ),
    );
  }

  Widget _buildOperationCard(SAROrganizationOperation operation) {
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
                  _getOperationTypeIcon(operation.type),
                  color: _getOperationStatusColor(operation.status),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    operation.operationName,
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
                    color: _getOperationStatusColor(
                      operation.status,
                    ).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getOperationStatusDisplayName(operation.status),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _getOperationStatusColor(operation.status),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              operation.description,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.secondaryText,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(
                  Icons.people,
                  size: 16,
                  color: AppTheme.secondaryText,
                ),
                const SizedBox(width: 4),
                Text(
                  '${operation.assignedMemberIds.length} members',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppTheme.secondaryText,
                ),
                const SizedBox(width: 4),
                Text(
                  operation.endTime != null
                      ? _formatDuration(
                          operation.endTime!.difference(operation.startTime),
                        )
                      : _formatDuration(
                          DateTime.now().difference(operation.startTime),
                        ),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    switch (_tabController.index) {
      case 1: // Members tab
        return FloatingActionButton.extended(
          onPressed: _addMember,
          icon: const Icon(Icons.person_add),
          label: const Text('Add Member'),
          backgroundColor: AppTheme.infoBlue,
        );
      case 2: // Operations tab
        return FloatingActionButton.extended(
          onPressed: _startOperation,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Operation'),
          backgroundColor: AppTheme.criticalRed,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // Helper methods
  Color _getStatusColor() {
    switch (_currentOrganization!.verificationStatus) {
      case SARVerificationStatus.verified:
        return AppTheme.safeGreen;
      case SARVerificationStatus.pending:
      case SARVerificationStatus.underReview:
        return AppTheme.warningOrange;
      case SARVerificationStatus.rejected:
      case SARVerificationStatus.suspended:
        return AppTheme.criticalRed;
      case SARVerificationStatus.expired:
        return AppTheme.neutralGray;
    }
  }

  IconData _getStatusIcon() {
    switch (_currentOrganization!.verificationStatus) {
      case SARVerificationStatus.verified:
        return Icons.verified;
      case SARVerificationStatus.pending:
        return Icons.pending;
      case SARVerificationStatus.underReview:
        return Icons.rate_review;
      case SARVerificationStatus.rejected:
        return Icons.cancel;
      case SARVerificationStatus.suspended:
        return Icons.pause_circle;
      case SARVerificationStatus.expired:
        return Icons.schedule;
    }
  }

  String _getVerificationStatusText() {
    switch (_currentOrganization!.verificationStatus) {
      case SARVerificationStatus.verified:
        return 'Verified Organization';
      case SARVerificationStatus.pending:
        return 'Pending Verification';
      case SARVerificationStatus.underReview:
        return 'Under Review';
      case SARVerificationStatus.rejected:
        return 'Verification Rejected';
      case SARVerificationStatus.suspended:
        return 'Suspended';
      case SARVerificationStatus.expired:
        return 'Verification Expired';
    }
  }

  Color _getOperationalStatusColor() {
    switch (_currentOrganization!.operationalStatus) {
      case SAROperationalStatus.active:
      case SAROperationalStatus.deployed:
        return AppTheme.criticalRed;
      case SAROperationalStatus.standby:
        return AppTheme.safeGreen;
      case SAROperationalStatus.training:
        return AppTheme.infoBlue;
      case SAROperationalStatus.maintenance:
        return AppTheme.warningOrange;
      case SAROperationalStatus.unavailable:
        return AppTheme.neutralGray;
    }
  }

  String _getOperationalStatusText() {
    switch (_currentOrganization!.operationalStatus) {
      case SAROperationalStatus.active:
        return 'Active';
      case SAROperationalStatus.deployed:
        return 'Deployed';
      case SAROperationalStatus.standby:
        return 'Standby';
      case SAROperationalStatus.training:
        return 'Training';
      case SAROperationalStatus.maintenance:
        return 'Maintenance';
      case SAROperationalStatus.unavailable:
        return 'Unavailable';
    }
  }

  Color _getMemberRoleColor(SARMemberRole role) {
    switch (role) {
      case SARMemberRole.admin:
        return AppTheme.criticalRed;
      case SARMemberRole.incidentCommander:
        return AppTheme.warningOrange;
      case SARMemberRole.teamLeader:
        return AppTheme.infoBlue;
      case SARMemberRole.seniorMember:
        return AppTheme.safeGreen;
      case SARMemberRole.member:
        return AppTheme.infoBlue;
      case SARMemberRole.trainee:
        return AppTheme.infoBlue;
      case SARMemberRole.support:
        return AppTheme.neutralGray;
    }
  }

  IconData _getMemberRoleIcon(SARMemberRole role) {
    switch (role) {
      case SARMemberRole.admin:
        return Icons.admin_panel_settings;
      case SARMemberRole.incidentCommander:
        return Icons.military_tech;
      case SARMemberRole.teamLeader:
        return Icons.supervisor_account;
      case SARMemberRole.seniorMember:
        return Icons.star;
      case SARMemberRole.member:
        return Icons.person;
      case SARMemberRole.trainee:
        return Icons.school;
      case SARMemberRole.support:
        return Icons.support;
    }
  }

  String _getMemberRoleDisplayName(SARMemberRole role) {
    switch (role) {
      case SARMemberRole.admin:
        return 'Administrator';
      case SARMemberRole.incidentCommander:
        return 'Incident Commander';
      case SARMemberRole.teamLeader:
        return 'Team Leader';
      case SARMemberRole.seniorMember:
        return 'Senior Member';
      case SARMemberRole.member:
        return 'Member';
      case SARMemberRole.trainee:
        return 'Trainee';
      case SARMemberRole.support:
        return 'Support';
    }
  }

  Color _getMemberStatusColor(SARMemberStatus status) {
    switch (status) {
      case SARMemberStatus.active:
        return AppTheme.safeGreen;
      case SARMemberStatus.inactive:
        return AppTheme.neutralGray;
      case SARMemberStatus.training:
        return AppTheme.infoBlue;
      case SARMemberStatus.probationary:
        return AppTheme.warningOrange;
      case SARMemberStatus.suspended:
        return AppTheme.criticalRed;
      case SARMemberStatus.retired:
        return AppTheme.secondaryText;
    }
  }

  String _getMemberStatusDisplayName(SARMemberStatus status) {
    switch (status) {
      case SARMemberStatus.active:
        return 'Active';
      case SARMemberStatus.inactive:
        return 'Inactive';
      case SARMemberStatus.training:
        return 'Training';
      case SARMemberStatus.probationary:
        return 'Probationary';
      case SARMemberStatus.suspended:
        return 'Suspended';
      case SARMemberStatus.retired:
        return 'Retired';
    }
  }

  IconData _getOperationTypeIcon(SAROperationType type) {
    switch (type) {
      case SAROperationType.searchRescue:
        return Icons.search;
      case SAROperationType.medicalEmergency:
        return Icons.medical_services;
      case SAROperationType.disasterResponse:
        return Icons.warning;
      case SAROperationType.trainingExercise:
        return Icons.school;
      case SAROperationType.publicService:
        return Icons.public;
      case SAROperationType.mutualAid:
        return Icons.handshake;
    }
  }

  Color _getOperationStatusColor(SAROperationStatus status) {
    switch (status) {
      case SAROperationStatus.active:
        return AppTheme.criticalRed;
      case SAROperationStatus.planning:
        return AppTheme.infoBlue;
      case SAROperationStatus.suspended:
        return AppTheme.warningOrange;
      case SAROperationStatus.completed:
        return AppTheme.safeGreen;
      case SAROperationStatus.cancelled:
        return AppTheme.neutralGray;
      case SAROperationStatus.transferred:
        return AppTheme.infoBlue;
    }
  }

  String _getOperationStatusDisplayName(SAROperationStatus status) {
    switch (status) {
      case SAROperationStatus.active:
        return 'Active';
      case SAROperationStatus.planning:
        return 'Planning';
      case SAROperationStatus.suspended:
        return 'Suspended';
      case SAROperationStatus.completed:
        return 'Completed';
      case SAROperationStatus.cancelled:
        return 'Cancelled';
      case SAROperationStatus.transferred:
        return 'Transferred';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }

  // Action methods
  void _handleMenuAction(String action) {
    switch (action) {
      case 'add_member':
        _addMember();
        break;
      case 'start_operation':
        _startOperation();
        break;
      case 'settings':
        _showOrganizationSettings();
        break;
    }
  }

  void _showOrganizationInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_currentOrganization!.organizationName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow(
                'Type',
                _organizationService.getOrganizationTypeDisplayName(
                  _currentOrganization!.type,
                ),
              ),
              _buildInfoRow(
                'Founded',
                _currentOrganization!.organizationInfo.foundedYear.toString(),
              ),
              _buildInfoRow('Members', _members.length.toString()),
              _buildInfoRow(
                'Specializations',
                _currentOrganization!.capabilities.primarySpecializations.length
                    .toString(),
              ),
              _buildInfoRow(
                '24/7 Available',
                _currentOrganization!.capabilities.has24x7Availability
                    ? 'Yes'
                    : 'No',
              ),
              _buildInfoRow(
                'Max Deployment',
                '${_currentOrganization!.capabilities.maxMemberDeployment} members',
              ),
              _buildInfoRow(
                'Response Time',
                '${_currentOrganization!.capabilities.averageResponseTime} minutes',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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

  void _addMember() {
    // TODO: Implement add member dialog
    _showError('Add member functionality coming soon');
  }

  void _startOperation() {
    // TODO: Implement start operation dialog
    _showError('Start operation functionality coming soon');
  }

  void _showOrganizationSettings() {
    // TODO: Implement organization settings
    _showError('Organization settings coming soon');
  }

  void _viewOperation(SAROrganizationOperation operation) {
    // TODO: Implement operation detail view
    _showError('Operation details coming soon');
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
