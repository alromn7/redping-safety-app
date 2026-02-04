// ignore_for_file: unused_element
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/app_service_manager.dart';
import '../../../../models/privacy_security.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import '../widgets/privacy_permission_card.dart';
import '../widgets/data_collection_card.dart';
import '../widgets/security_status_card.dart';

/// Privacy and security settings page
class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage>
    with TickerProviderStateMixin {
  final AppServiceManager _serviceManager = AppServiceManager();

  late TabController _tabController;

  List<PrivacyPermission> _permissions = [];
  List<DataCollectionPolicy> _policies = [];
  PrivacyPreferences _privacyPreferences = PrivacyPreferences(
    lastUpdated: DateTime.now(),
  );
  SecurityConfiguration _securityConfig = SecurityConfiguration(
    lastUpdated: DateTime.now(),
  );
  SecurityStatus? _securityStatus;
  ComplianceStatus? _complianceStatus;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      debugPrint('PrivacySettingsPage: Starting initialization...');

      // Check if service is initialized
      if (!_serviceManager.isInitialized) {
        debugPrint(
          'PrivacySettingsPage: Service manager not initialized! Waiting...',
        );
        await _serviceManager.initializeAllServices();
      }

      debugPrint(
        'PrivacySettingsPage: Service manager initialized: ${_serviceManager.isInitialized}',
      );

      // Load the data
      _loadData();

      debugPrint(
        'PrivacySettingsPage: Data loaded - Permissions: ${_permissions.length}, Policies: ${_policies.length}',
      );

      // Set up callbacks
      _serviceManager.privacySecurityService.setPermissionChangedCallback(
        _onPermissionChanged,
      );
      _serviceManager.privacySecurityService.setSecurityStatusChangedCallback(
        _onSecurityStatusChanged,
      );

      debugPrint('PrivacySettingsPage: Callbacks set up successfully');
    } catch (e) {
      debugPrint('PrivacySettingsPage: Error initializing - $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _loadData() {
    try {
      debugPrint('PrivacySettingsPage: Loading data from service...');

      _permissions = _serviceManager.privacySecurityService.permissions;
      _policies = _serviceManager.privacySecurityService.policies;
      _privacyPreferences =
          _serviceManager.privacySecurityService.privacyPreferences;
      _securityConfig =
          _serviceManager.privacySecurityService.securityConfiguration;
      _securityStatus =
          _serviceManager.privacySecurityService.currentSecurityStatus;
      _complianceStatus =
          _serviceManager.privacySecurityService.complianceStatus;

      debugPrint(
        'PrivacySettingsPage: Loaded ${_permissions.length} permissions, ${_policies.length} policies',
      );
      debugPrint(
        'PrivacySettingsPage: Security status: ${_securityStatus != null ? "Available" : "Null"}',
      );
      debugPrint(
        'PrivacySettingsPage: Compliance status: ${_complianceStatus != null ? "Available" : "Null"}',
      );

      setState(() {});
    } catch (e) {
      debugPrint('PrivacySettingsPage: Error loading data - $e');
    }
  }

  void _onPermissionChanged(PrivacyPermission permission) {
    _loadData();
  }

  void _onSecurityStatusChanged(SecurityStatus status) {
    setState(() {
      _securityStatus = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showPrivacyHelp,
            tooltip: 'Privacy Help',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_data',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20),
                    SizedBox(width: 8),
                    Text('Export My Data'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete_data',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete My Data', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'privacy_policy',
                child: Row(
                  children: [
                    Icon(Icons.policy, size: 20),
                    SizedBox(width: 8),
                    Text('Privacy Policy'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Permissions', icon: Icon(Icons.security, size: 20)),
            Tab(text: 'Data', icon: Icon(Icons.storage, size: 20)),
            Tab(text: 'Security', icon: Icon(Icons.shield, size: 20)),
            Tab(text: 'Compliance', icon: Icon(Icons.verified_user, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPermissionsTab(),
          _buildDataTab(),
          _buildSecurityTab(),
          _buildComplianceTab(),
        ],
      ),
    );
  }

  // Simple test methods to debug the blank page issue
  Widget _buildSimplePermissionsTest() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Permissions Test',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Service Initialized: ${_serviceManager.isInitialized}'),
                  Text('Permissions Count: ${_permissions.length}'),
                  const SizedBox(height: 8),
                  if (_permissions.isNotEmpty) ...[
                    const Text(
                      'First Permission:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Name: ${_permissions.first.displayName}'),
                    Text('Type: ${_permissions.first.type.name}'),
                    Text('Status: ${_permissions.first.status.name}'),
                  ] else
                    const Text(
                      'No permissions loaded',
                      style: TextStyle(color: Colors.red),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeData,
            child: const Text('Reload Data'),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleDataTest() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Data Policies Test',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Policies Count: ${_policies.length}'),
                  const SizedBox(height: 8),
                  if (_policies.isNotEmpty) ...[
                    const Text(
                      'First Policy:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Purpose: ${_policies.first.purpose.name}'),
                    Text('Description: ${_policies.first.description}'),
                  ] else
                    const Text(
                      'No policies loaded',
                      style: TextStyle(color: Colors.red),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleSecurityTest() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security Status Test',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security Status: ${_securityStatus != null ? "Available" : "Null"}',
                  ),
                  if (_securityStatus != null) ...[
                    Text(
                      'Threat Level: ${_securityStatus!.overallThreatLevel.name}',
                    ),
                    Text('Device Secure: ${_securityStatus!.isDeviceSecure}'),
                    Text('Network Secure: ${_securityStatus!.isNetworkSecure}'),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleComplianceTest() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Compliance Test',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Compliance Status: ${_complianceStatus != null ? "Available" : "Null"}',
                  ),
                  if (_complianceStatus != null) ...[
                    Text(
                      'GDPR Compliant: ${_complianceStatus!.isGDPRCompliant}',
                    ),
                    Text(
                      'CCPA Compliant: ${_complianceStatus!.isCCPACompliant}',
                    ),
                    Text(
                      'Android Compliant: ${_complianceStatus!.isAndroidCompliant}',
                    ),
                    Text('iOS Compliant: ${_complianceStatus!.isiOSCompliant}'),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildSectionHeader(
            'App Permissions',
            'Manage what data the app can access',
            Icons.security,
          ),

          const SizedBox(height: 16),

          // Permissions list
          if (_permissions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.info, color: AppTheme.infoBlue, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'No Permissions Data',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Privacy permissions are being loaded. Please wait...',
                      style: TextStyle(color: AppTheme.secondaryText),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _initializeData(),
                      child: const Text('Retry Loading'),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._permissions.map(
              (permission) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PrivacyPermissionCard(
                  permission: permission,
                  onToggle: () => _togglePermission(permission),
                  onInfo: () => _showPermissionInfo(permission),
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Quick actions
          _buildQuickActionsSection(),
        ],
      ),
    );
  }

  Widget _buildDataTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildSectionHeader(
            'Data Collection',
            'Control how your data is collected and used',
            Icons.storage,
          ),

          const SizedBox(height: 16),

          // Privacy preferences
          _buildPrivacyPreferencesSection(),

          const SizedBox(height: 24),

          // Data collection policies
          _buildSectionHeader(
            'Data Collection Policies',
            'What data we collect and why',
            Icons.policy,
          ),

          const SizedBox(height: 16),

          if (_policies.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.info, color: AppTheme.infoBlue, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'No Data Policies',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Data collection policies are being loaded. Please wait...',
                      style: TextStyle(color: AppTheme.secondaryText),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ..._policies.map(
              (policy) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DataCollectionCard(
                  policy: policy,
                  isOptedOut: _privacyPreferences.optedOutPurposes.contains(
                    policy.purpose,
                  ),
                  onToggle: () => _toggleDataCollection(policy),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Security status
          if (_securityStatus != null) ...[
            SecurityStatusCard(
              status: _securityStatus!,
              onRefresh: _refreshSecurityStatus,
            ),
            const SizedBox(height: 24),
          ],

          // Security settings
          _buildSectionHeader(
            'Security Settings',
            'Configure app security features',
            Icons.shield,
          ),

          const SizedBox(height: 16),

          _buildSecuritySettingsSection(),
        ],
      ),
    );
  }

  Widget _buildComplianceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compliance status
          if (_complianceStatus != null) ...[
            _buildComplianceStatusCard(),
            const SizedBox(height: 24),
          ],

          // Data rights
          _buildSectionHeader(
            'Your Data Rights',
            'Exercise your privacy rights',
            Icons.gavel,
          ),

          const SizedBox(height: 16),

          _buildDataRightsSection(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryRed.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryRed, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryText,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyPreferencesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Preferences',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Data Collection'),
              subtitle: const Text('Allow app to collect usage data'),
              value: _privacyPreferences.enableDataCollection,
              onChanged: (value) =>
                  _updatePrivacyPreference('enableDataCollection', value),
            ),

            SwitchListTile(
              title: const Text('Analytics'),
              subtitle: const Text('Help improve the app with usage analytics'),
              value: _privacyPreferences.enableAnalytics,
              onChanged: (value) =>
                  _updatePrivacyPreference('enableAnalytics', value),
            ),

            SwitchListTile(
              title: const Text('Crash Reporting'),
              subtitle: const Text(
                'Automatically report crashes to improve stability',
              ),
              value: _privacyPreferences.enableCrashReporting,
              onChanged: (value) =>
                  _updatePrivacyPreference('enableCrashReporting', value),
            ),

            SwitchListTile(
              title: const Text('Location Sharing'),
              subtitle: const Text('Share location with emergency contacts'),
              value: _privacyPreferences.enableLocationSharing,
              onChanged: (value) =>
                  _updatePrivacyPreference('enableLocationSharing', value),
            ),

            SwitchListTile(
              title: const Text('Activity Sharing'),
              subtitle: const Text('Share activity status with contacts'),
              value: _privacyPreferences.enableActivitySharing,
              onChanged: (value) =>
                  _updatePrivacyPreference('enableActivitySharing', value),
            ),

            SwitchListTile(
              title: const Text('Automatic Backup'),
              subtitle: const Text('Backup data to secure cloud storage'),
              value: _privacyPreferences.enableAutomaticBackup,
              onChanged: (value) =>
                  _updatePrivacyPreference('enableAutomaticBackup', value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecuritySettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Security Configuration',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Auto Lock'),
              subtitle: const Text('Automatically lock app when inactive'),
              value: _securityConfig.enableAutoLock,
              onChanged: (value) =>
                  _updateSecurityConfig('enableAutoLock', value),
            ),

            SwitchListTile(
              title: const Text('Biometric Authentication'),
              subtitle: const Text(
                'Use fingerprint/face ID for sensitive data',
              ),
              value: _securityConfig.requireBiometricForSensitiveData,
              onChanged: (value) => _updateSecurityConfig(
                'requireBiometricForSensitiveData',
                value,
              ),
            ),

            SwitchListTile(
              title: const Text('Secure Storage'),
              subtitle: const Text('Encrypt data stored on device'),
              value: _securityConfig.enableSecureStorage,
              onChanged: (value) =>
                  _updateSecurityConfig('enableSecureStorage', value),
            ),

            SwitchListTile(
              title: const Text('Security Monitoring'),
              subtitle: const Text('Monitor for security threats'),
              value: _securityConfig.enableNetworkSecurityMonitoring,
              onChanged: (value) => _updateSecurityConfig(
                'enableNetworkSecurityMonitoring',
                value,
              ),
            ),

            SwitchListTile(
              title: const Text('Root/Jailbreak Detection'),
              subtitle: const Text('Detect compromised devices'),
              value: _securityConfig.enableRootDetection,
              onChanged: (value) =>
                  _updateSecurityConfig('enableRootDetection', value),
            ),

            SwitchListTile(
              title: const Text('Screenshot Prevention'),
              subtitle: const Text('Prevent screenshots of sensitive screens'),
              value: _securityConfig.enableScreenshotPrevention,
              onChanged: (value) =>
                  _updateSecurityConfig('enableScreenshotPrevention', value),
            ),

            const SizedBox(height: 16),

            // Encryption level
            const Text(
              'Data Encryption Level',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<EncryptionLevel>(
              initialValue: _securityConfig.dataEncryptionLevel,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: EncryptionLevel.values.map((level) {
                return DropdownMenuItem(
                  value: level,
                  child: Row(
                    children: [
                      Icon(_getEncryptionIcon(level), size: 16),
                      const SizedBox(width: 8),
                      Text(_getEncryptionDisplayName(level)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _updateSecurityConfig('dataEncryptionLevel', value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplianceStatusCard() {
    final compliance = _complianceStatus!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Compliance Status',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 16),

            // Compliance indicators
            _buildComplianceIndicator('GDPR', compliance.isGDPRCompliant),
            _buildComplianceIndicator('CCPA', compliance.isCCPACompliant),
            _buildComplianceIndicator('Android', compliance.isAndroidCompliant),
            _buildComplianceIndicator('iOS', compliance.isiOSCompliant),
            _buildComplianceIndicator('HIPAA Ready', compliance.isHIPAAReady),

            if (compliance.complianceIssues.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Issues to Address:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.criticalRed,
                ),
              ),
              const SizedBox(height: 8),
              ...compliance.complianceIssues.map(
                (issue) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning,
                        color: AppTheme.criticalRed,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          issue,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (compliance.recommendations.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Recommendations:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.infoBlue,
                ),
              ),
              const SizedBox(height: 8),
              ...compliance.recommendations.map(
                (rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb,
                        color: AppTheme.infoBlue,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(rec, style: const TextStyle(fontSize: 12)),
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

  Widget _buildComplianceIndicator(String label, bool isCompliant) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isCompliant ? Icons.check_circle : Icons.cancel,
            color: isCompliant ? AppTheme.safeGreen : AppTheme.criticalRed,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            isCompliant ? 'Compliant' : 'Issues',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isCompliant ? AppTheme.safeGreen : AppTheme.criticalRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _requestAllPermissions,
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('Grant All'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.safeGreen,
                      side: const BorderSide(color: AppTheme.safeGreen),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openAppSettings,
                    icon: const Icon(Icons.settings, size: 16),
                    label: const Text('App Settings'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.infoBlue,
                      side: const BorderSide(color: AppTheme.infoBlue),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRightsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Rights',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 16),

            _buildDataRightItem(
              'Right to Access',
              'View all data we have about you',
              Icons.visibility,
              () => _exportUserData(),
            ),

            _buildDataRightItem(
              'Right to Rectification',
              'Correct inaccurate personal data',
              Icons.edit,
              () => context.push('/profile'),
            ),

            _buildDataRightItem(
              'Right to Erasure',
              'Delete your personal data',
              Icons.delete_forever,
              () => _showDeleteDataDialog(),
            ),

            _buildDataRightItem(
              'Right to Portability',
              'Export your data in a portable format',
              Icons.download,
              () => _exportUserData(),
            ),

            _buildDataRightItem(
              'Right to Object',
              'Object to certain data processing',
              Icons.block,
              () => _showDataObjectionDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRightItem(
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.infoBlue, size: 20),
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
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.secondaryText,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // Action handlers
  void _togglePermission(PrivacyPermission permission) {
    _serviceManager.privacySecurityService.requestPermission(permission.type);
  }

  void _showPermissionInfo(PrivacyPermission permission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(permission.displayName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(permission.description),
            const SizedBox(height: 16),
            Text(
              'Purpose: ${permission.purpose}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Required: ${permission.isRequired ? "Yes" : "No"}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (permission.purposes.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Used for:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              ...permission.purposes.map(
                (purpose) => Text('• ${_getPurposeDisplayName(purpose)}'),
              ),
            ],
          ],
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

  void _toggleDataCollection(DataCollectionPolicy policy) {
    final optedOut = _privacyPreferences.optedOutPurposes.contains(
      policy.purpose,
    );
    final newOptedOut = List<DataCollectionPurpose>.from(
      _privacyPreferences.optedOutPurposes,
    );

    if (optedOut) {
      newOptedOut.remove(policy.purpose);
    } else {
      newOptedOut.add(policy.purpose);
    }

    final newPreferences = _privacyPreferences.copyWith(
      optedOutPurposes: newOptedOut,
    );
    _serviceManager.privacySecurityService.updatePrivacyPreferences(
      newPreferences,
    );
  }

  void _updatePrivacyPreference(String key, bool value) {
    PrivacyPreferences newPreferences;

    switch (key) {
      case 'enableDataCollection':
        newPreferences = _privacyPreferences.copyWith(
          enableDataCollection: value,
        );
        break;
      case 'enableAnalytics':
        newPreferences = _privacyPreferences.copyWith(enableAnalytics: value);
        break;
      case 'enableCrashReporting':
        newPreferences = _privacyPreferences.copyWith(
          enableCrashReporting: value,
        );
        break;
      case 'enableLocationSharing':
        newPreferences = _privacyPreferences.copyWith(
          enableLocationSharing: value,
        );
        break;
      case 'enableActivitySharing':
        newPreferences = _privacyPreferences.copyWith(
          enableActivitySharing: value,
        );
        break;
      case 'enableAutomaticBackup':
        newPreferences = _privacyPreferences.copyWith(
          enableAutomaticBackup: value,
        );
        break;
      default:
        return;
    }

    _serviceManager.privacySecurityService.updatePrivacyPreferences(
      newPreferences,
    );
    setState(() => _privacyPreferences = newPreferences);
  }

  void _updateSecurityConfig(String key, dynamic value) {
    SecurityConfiguration newConfig;

    switch (key) {
      case 'enableAutoLock':
        newConfig = _securityConfig.copyWith(enableAutoLock: value as bool);
        break;
      case 'requireBiometricForSensitiveData':
        newConfig = _securityConfig.copyWith(
          requireBiometricForSensitiveData: value as bool,
        );
        break;
      case 'enableSecureStorage':
        newConfig = _securityConfig.copyWith(
          enableSecureStorage: value as bool,
        );
        break;
      case 'enableSecurityMonitoring':
        newConfig = _securityConfig.copyWith(
          enableNetworkSecurityMonitoring: value as bool,
        );
        break;
      case 'enableRootDetection':
        newConfig = _securityConfig.copyWith(
          enableRootDetection: value as bool,
        );
        break;
      case 'enableScreenshotPrevention':
        newConfig = _securityConfig.copyWith(
          enableScreenshotPrevention: value as bool,
        );
        break;
      case 'dataEncryptionLevel':
        newConfig = _securityConfig.copyWith(
          dataEncryptionLevel: value as EncryptionLevel,
        );
        break;
      default:
        return;
    }

    _serviceManager.privacySecurityService.updateSecurityConfiguration(
      newConfig,
    );
    setState(() => _securityConfig = newConfig);
  }

  void _requestAllPermissions() async {
    final messenger = ScaffoldMessenger.of(context);
    final requiredPermissions = _permissions
        .where((p) => p.isRequired)
        .toList();

    for (final permission in requiredPermissions) {
      await _serviceManager.privacySecurityService.requestPermission(
        permission.type,
      );
    }

    messenger.showSnackBar(
      const SnackBar(
        content: Text('✅ Permission requests sent'),
        backgroundColor: AppTheme.safeGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openAppSettings() {
    ph.openAppSettings();
  }

  void _refreshSecurityStatus() {
    // Trigger security assessment
    _serviceManager.privacySecurityService.performSecurityAssessment();
  }

  void _exportUserData() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final data = await _serviceManager.privacySecurityService
          .exportUserData();

      // In a real app, this would save to file or share
      messenger.showSnackBar(
        SnackBar(
          content: Text('✅ Data exported (${data.keys.length} items)'),
          backgroundColor: AppTheme.safeGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ Export failed: $e'),
          backgroundColor: AppTheme.criticalRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete My Data'),
        content: const Text(
          'This will permanently delete all your data from the app. This action cannot be undone.\n\n'
          'Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteUserData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.criticalRed,
            ),
            child: const Text('Delete All Data'),
          ),
        ],
      ),
    );
  }

  void _deleteUserData() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _serviceManager.privacySecurityService.deleteUserData(
        dataTypes: [
          'profile',
          'activities',
          'emergency_contacts',
          'sos_sessions',
          'chat_messages',
        ],
        reason: 'User requested data deletion',
      );

      messenger.showSnackBar(
        const SnackBar(
          content: Text('✅ All data deleted'),
          backgroundColor: AppTheme.safeGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ Deletion failed: $e'),
          backgroundColor: AppTheme.criticalRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showDataObjectionDialog() {
    // Implementation for data objection
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Object to Data Processing'),
        content: const Text(
          'You can object to certain types of data processing. This may limit some app features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Configure'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyHelp() {
    context.push('/privacy-help');
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export_data':
        _exportUserData();
        break;
      case 'delete_data':
        _showDeleteDataDialog();
        break;
      case 'privacy_policy':
        _showPrivacyPolicy();
        break;
    }
  }

  void _showPrivacyPolicy() {
    context.push('/privacy-policy');
  }

  // Helper methods
  IconData _getEncryptionIcon(EncryptionLevel level) {
    switch (level) {
      case EncryptionLevel.none:
        return Icons.lock_open;
      case EncryptionLevel.basic:
        return Icons.lock_outline;
      case EncryptionLevel.standard:
        return Icons.lock;
      case EncryptionLevel.enterprise:
        return Icons.enhanced_encryption;
    }
  }

  String _getEncryptionDisplayName(EncryptionLevel level) {
    switch (level) {
      case EncryptionLevel.none:
        return 'None (Not Recommended)';
      case EncryptionLevel.basic:
        return 'Basic (AES-128)';
      case EncryptionLevel.standard:
        return 'Standard (AES-256)';
      case EncryptionLevel.enterprise:
        return 'Enterprise (AES-256+)';
    }
  }

  String _getPurposeDisplayName(DataCollectionPurpose purpose) {
    switch (purpose) {
      case DataCollectionPurpose.emergencyResponse:
        return 'Emergency Response';
      case DataCollectionPurpose.locationTracking:
        return 'Location Tracking';
      case DataCollectionPurpose.activityMonitoring:
        return 'Activity Monitoring';
      case DataCollectionPurpose.hazardAlerts:
        return 'Hazard Alerts';
      case DataCollectionPurpose.communicationServices:
        return 'Communication Services';
      case DataCollectionPurpose.userProfile:
        return 'User Profile';
      case DataCollectionPurpose.analytics:
        return 'Analytics';
      case DataCollectionPurpose.crashReporting:
        return 'Crash Reporting';
      case DataCollectionPurpose.performanceMonitoring:
        return 'Performance Monitoring';
      case DataCollectionPurpose.securityMonitoring:
        return 'Security Monitoring';
      case DataCollectionPurpose.backupRestore:
        return 'Backup & Restore';
      case DataCollectionPurpose.serviceImprovement:
        return 'Service Improvement';
    }
  }
}
