import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/ai_assistant.dart';

/// Widget for managing AI permissions
class AIPermissionsWidget extends StatefulWidget {
  final AIPermissions permissions;
  final Function(AIPermissions) onPermissionsChanged;

  const AIPermissionsWidget({
    super.key,
    required this.permissions,
    required this.onPermissionsChanged,
  });

  @override
  State<AIPermissionsWidget> createState() => _AIPermissionsWidgetState();
}

class _AIPermissionsWidgetState extends State<AIPermissionsWidget> {
  late AIPermissions _permissions;

  @override
  void initState() {
    super.initState();
    _permissions = widget.permissions;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),

          const SizedBox(height: 24),

          // Core Permissions
          _buildPermissionSection(
            'Core Functionality',
            'Basic AI assistant capabilities',
            Icons.psychology,
            AppTheme.infoBlue,
            [
              _PermissionItem(
                'Navigate App',
                'Allow AI to navigate between app pages for you',
                Icons.navigation,
                _permissions.canNavigateApp,
                (value) =>
                    _updatePermission((p) => p.copyWith(canNavigateApp: value)),
              ),
              _PermissionItem(
                'Send Notifications',
                'Allow AI to send helpful notifications and alerts',
                Icons.notifications,
                _permissions.canSendNotifications,
                (value) => _updatePermission(
                  (p) => p.copyWith(canSendNotifications: value),
                ),
              ),
              _PermissionItem(
                'Optimize Performance',
                'Allow AI to optimize app performance and battery usage',
                Icons.speed,
                _permissions.canOptimizePerformance,
                (value) => _updatePermission(
                  (p) => p.copyWith(canOptimizePerformance: value),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Safety Permissions
          _buildPermissionSection(
            'Safety & Emergency',
            'Safety monitoring and emergency assistance',
            Icons.security,
            AppTheme.safeGreen,
            [
              _PermissionItem(
                'Access Location',
                'Access your location for safety assessments and hazard alerts',
                Icons.location_on,
                _permissions.canAccessLocation,
                (value) => _updatePermission(
                  (p) => p.copyWith(canAccessLocation: value),
                ),
              ),
              _PermissionItem(
                'Access Sensor Data',
                'Monitor sensors for crash/fall detection optimization',
                Icons.sensors,
                _permissions.canAccessSensorData,
                (value) => _updatePermission(
                  (p) => p.copyWith(canAccessSensorData: value),
                ),
              ),
              _PermissionItem(
                'Access Hazard Alerts',
                'Monitor and provide updates on hazard alerts',
                Icons.warning,
                _permissions.canAccessHazardAlerts,
                (value) => _updatePermission(
                  (p) => p.copyWith(canAccessHazardAlerts: value),
                ),
              ),
              _PermissionItem(
                'Trigger SOS',
                'Allow AI to trigger SOS in critical situations (requires confirmation)',
                Icons.emergency,
                _permissions.canTriggerSOS,
                (value) =>
                    _updatePermission((p) => p.copyWith(canTriggerSOS: value)),
                isHighRisk: true,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Communication Permissions
          _buildPermissionSection(
            'Communication',
            'Contact management and communication features',
            Icons.chat,
            AppTheme.infoBlue,
            [
              _PermissionItem(
                'Access Contacts',
                'Access emergency contacts for assistance suggestions',
                Icons.contacts,
                _permissions.canAccessContacts,
                (value) => _updatePermission(
                  (p) => p.copyWith(canAccessContacts: value),
                ),
              ),
              _PermissionItem(
                'Manage Emergency Contacts',
                'Help manage and update emergency contact information',
                Icons.person_add,
                _permissions.canManageEmergencyContacts,
                (value) => _updatePermission(
                  (p) => p.copyWith(canManageEmergencyContacts: value),
                ),
              ),
              _PermissionItem(
                'Initiate Calls',
                'Make emergency and help calls on your behalf',
                Icons.phone,
                _permissions.canInitiateCalls,
                (value) => _updatePermission(
                  (p) => p.copyWith(canInitiateCalls: value),
                ),
                isHighRisk: true,
              ),
              _PermissionItem(
                'Send Messages',
                'Send messages to emergency contacts and services',
                Icons.message,
                _permissions.canSendMessages,
                (value) => _updatePermission(
                  (p) => p.copyWith(canSendMessages: value),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // System Permissions
          _buildPermissionSection(
            'System Control',
            'App settings and system management',
            Icons.settings,
            AppTheme.warningOrange,
            [
              _PermissionItem(
                'Modify Settings',
                'Update app settings for optimal safety and performance',
                Icons.tune,
                _permissions.canModifySettings,
                (value) => _updatePermission(
                  (p) => p.copyWith(canModifySettings: value),
                ),
              ),
              _PermissionItem(
                'Manage Profile',
                'Update user profile and preferences',
                Icons.person,
                _permissions.canManageProfile,
                (value) => _updatePermission(
                  (p) => p.copyWith(canManageProfile: value),
                ),
              ),
              _PermissionItem(
                'Access Camera',
                'Use camera for photo documentation in help requests',
                Icons.camera_alt,
                _permissions.canAccessCamera,
                (value) => _updatePermission(
                  (p) => p.copyWith(canAccessCamera: value),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Quick Actions
          _buildQuickActions(),

          const SizedBox(height: 24),

          // Permission Info
          _buildPermissionInfo(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.infoBlue, AppTheme.infoBlue.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI Assistant Permissions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Control what your AI assistant can do to help you. You can change these permissions anytime.',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionSection(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    List<_PermissionItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        ...items.map((item) => _buildPermissionItem(item)),
      ],
    );
  }

  Widget _buildPermissionItem(_PermissionItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: item.isHighRisk
          ? AppTheme.criticalRed.withValues(alpha: 0.05)
          : null,
      child: SwitchListTile(
        title: Row(
          children: [
            Icon(item.icon, size: 18, color: AppTheme.infoBlue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (item.isHighRisk)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.criticalRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'HIGH RISK',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          item.description,
          style: const TextStyle(fontSize: 12, color: AppTheme.secondaryText),
        ),
        value: item.value,
        onChanged: item.isHighRisk ? _handleHighRiskPermission : item.onChanged,
        activeThumbColor: AppTheme.infoBlue,
        dense: true,
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
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
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _enableAllSafePermissions,
                icon: const Icon(Icons.security, size: 18),
                label: const Text('Enable Safe Permissions'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.safeGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _disableAllPermissions,
                icon: const Icon(Icons.block, size: 18),
                label: const Text('Disable All'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.criticalRed,
                  side: const BorderSide(color: AppTheme.criticalRed),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPermissionInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.infoBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.infoBlue.withValues(alpha: 0.2)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: AppTheme.infoBlue, size: 18),
              SizedBox(width: 8),
              Text(
                'Permission Information',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.infoBlue,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• All permissions are optional and can be changed anytime\n'
            '• High-risk permissions require additional confirmation\n'
            '• AI never acts without your knowledge or consent\n'
            '• Your privacy and safety are our top priorities',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.secondaryText,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _updatePermission(AIPermissions Function(AIPermissions) updater) {
    final newPermissions = updater(_permissions);
    setState(() {
      _permissions = newPermissions;
    });
    widget.onPermissionsChanged(newPermissions);
  }

  void _handleHighRiskPermission(bool? value) {
    if (value == true) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('High-Risk Permission'),
          content: const Text(
            'This permission allows the AI to take significant actions on your behalf. '
            'Are you sure you want to enable this?\n\n'
            'You can disable it anytime in settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Enable the permission after confirmation
                // This would need to be handled per specific permission
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.criticalRed,
              ),
              child: const Text('Enable'),
            ),
          ],
        ),
      );
    }
  }

  void _enableAllSafePermissions() {
    final safePermissions = _permissions.copyWith(
      canNavigateApp: true,
      canAccessLocation: true,
      canSendNotifications: true,
      canAccessContacts: true,
      canAccessSensorData: true,
      canAccessHazardAlerts: true,
      canOptimizePerformance: true,
      canManageProfile: true,
      // Keep high-risk permissions as they are
    );

    setState(() {
      _permissions = safePermissions;
    });
    widget.onPermissionsChanged(safePermissions);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Safe permissions enabled'),
        backgroundColor: AppTheme.safeGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _disableAllPermissions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable All Permissions'),
        content: const Text(
          'This will disable all AI assistant permissions. '
          'The AI will only be able to provide basic responses.\n\n'
          'Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);

              final disabledPermissions = AIPermissions(
                lastUpdated: DateTime.now(),
              );

              setState(() {
                _permissions = disabledPermissions;
              });
              widget.onPermissionsChanged(disabledPermissions);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All permissions disabled'),
                  backgroundColor: AppTheme.warningOrange,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.criticalRed,
            ),
            child: const Text('Disable All'),
          ),
        ],
      ),
    );
  }
}

class _PermissionItem {
  final String title;
  final String description;
  final IconData icon;
  final bool value;
  final Function(bool) onChanged;
  final bool isHighRisk;

  const _PermissionItem(
    this.title,
    this.description,
    this.icon,
    this.value,
    this.onChanged, {
    this.isHighRisk = false,
  });
}
