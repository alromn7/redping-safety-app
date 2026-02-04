// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/app/app_launch_config.dart';
import '../../../../core/app_variant.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/app_service_manager.dart';
import '../../../../services/user_profile_service.dart';
import '../../../../services/emergency_contacts_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/feature_access_service.dart';
import '../../../../services/sar_identity_service.dart';
import '../../../sos/presentation/widgets/emergency_hotline_card.dart';
import '../../../../models/user_profile.dart';
import '../../../../models/emergency_contact.dart' as emergency_contact_model;
import '../../../../models/auth_user.dart';
import '../../../../services/connectivity_monitor_service.dart';

/// Profile page with user information, emergency contacts, and medical info
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<void> _showEmergencyHotlineSheet() async {
    final countryCode = Localizations.localeOf(context).countryCode;
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.neutralGray.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Emergency Hotline (Manual Dial)',
                      style: TextStyle(
                        color: AppTheme.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'This does not place calls automatically. It opens your phone dialer so you can call local emergency services yourself.',
                      style: TextStyle(
                        color: AppTheme.secondaryText,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  EmergencyHotlineCard(userCountryCode: countryCode),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditMedicalDialog() async {
    final ageController = TextEditingController(
      text: _userProfile?.age?.toString() ?? '',
    );
    final genderController = TextEditingController(
      text: _userProfile?.gender ?? '',
    );
    final bloodTypeController = TextEditingController(
      text: _userProfile?.bloodType ?? '',
    );
    final allergiesController = TextEditingController(
      text: (_userProfile?.allergies ?? []).join(', '),
    );
    final conditionsController = TextEditingController(
      text: (_userProfile?.medicalConditions ?? []).join(', '),
    );
    final medicationsController = TextEditingController(
      text: (_userProfile?.medications ?? []).join(', '),
    );

    String? selectedGender = _userProfile?.gender;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Medical Information'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: ageController,
                      decoration: const InputDecoration(labelText: 'Age'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(
                          value: 'female',
                          child: Text('Female'),
                        ),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedGender = value;
                          genderController.text = value ?? '';
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: bloodTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Blood Type',
                      ),
                    ),
                    TextField(
                      controller: allergiesController,
                      decoration: const InputDecoration(
                        labelText: 'Allergies (comma separated)',
                      ),
                    ),
                    TextField(
                      controller: conditionsController,
                      decoration: const InputDecoration(
                        labelText: 'Medical Conditions (comma separated)',
                      ),
                    ),
                    TextField(
                      controller: medicationsController,
                      decoration: const InputDecoration(
                        labelText: 'Medications (comma separated)',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      try {
        final updatedProfile = _userProfile?.copyWith(
          age: int.tryParse(ageController.text.trim()),
          gender: selectedGender,
          bloodType: bloodTypeController.text.trim(),
          allergies: allergiesController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
          medicalConditions: conditionsController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
          medications: medicationsController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
        );
        if (updatedProfile != null) {
          await _profileService.updateProfile(updatedProfile);
          if (!mounted) return;
          setState(() {
            _userProfile = updatedProfile;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Medical information updated successfully!'),
              backgroundColor: AppTheme.safeGreen,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving medical info: $e'),
            backgroundColor: AppTheme.criticalRed,
          ),
        );
      }
    }
  }

  final AppServiceManager _serviceManager = AppServiceManager();
  late final UserProfileService _profileService;
  final EmergencyContactsService _contactsService = EmergencyContactsService();
  final AuthService _authService = AuthService.instance;
  final SARIdentityService _sarIdentityService = SARIdentityService();

  StreamSubscription<AuthUser>? _authSub;

  UserProfile? _userProfile;
  List<emergency_contact_model.EmergencyContact> _emergencyContacts = [];
  bool _isLoading = true;
  bool _isSARVerified = false;

  bool get _isSarVariant => AppLaunchConfig.variant == AppVariant.sar;

  @override
  void initState() {
    super.initState();
    // Initialize profile service from AppServiceManager
    _profileService = _serviceManager.profileService;
    _loadData();
    // Refresh profile when auth user changes (e.g., Google sign-in completes)
    _authSub = _authService.userStream.listen((_) {
      if (!mounted) return;
      _loadData();
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      await _profileService.initialize();
      // If authenticated but no profile loaded yet, refresh from auth to create/load
      if (_profileService.currentProfile == null &&
          _authService.isAuthenticated) {
        try {
          await _profileService.refreshFromAuth();
        } catch (_) {}
      }

      if (!_isSarVariant) {
        await _contactsService.initialize();
      }
      // Initialize SAR identity to check verification badge
      try {
        await _sarIdentityService.initialize();
        _isSARVerified = _sarIdentityService.isCurrentUserVerified;
      } catch (_) {
        _isSARVerified = false;
      }

      setState(() {
        _userProfile = _profileService.currentProfile;
        _emergencyContacts =
            _isSarVariant ? [] : _contactsService.enabledContacts.take(3).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('ProfilePage: Error loading data - $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: _isSarVariant ? 'Back to SAR Dashboard' : 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppLaunchConfig.homeRoute);
            }
          },
        ),
        title: Text(_isSarVariant ? 'SAR Profile' : 'Profile'),
        actions: _isSarVariant
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit basic info',
                  onPressed: _openEditBasicInfoSheet,
                ),
              ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
              child: Column(
                children: [
                  // Profile Header
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppTheme.infoBlue,
                            backgroundImage: () {
                              final offline = ConnectivityMonitorService().isEffectivelyOffline;
                              final profileAvatar = _userProfile?.avatar;
                              if (profileAvatar != null &&
                                  profileAvatar.isNotEmpty) {
                                if (!offline) return NetworkImage(profileAvatar);
                              }
                              final authAvatar =
                                  _authService.currentUser.photoUrl;
                              if (authAvatar != null && authAvatar.isNotEmpty) {
                                if (!offline) return NetworkImage(authAvatar);
                              }
                              return null;
                            }(),
                            child: () {
                              final profileAvatar = _userProfile?.avatar;
                              final authAvatar =
                                  _authService.currentUser.photoUrl;
                              final hasAnyAvatar =
                                  (profileAvatar != null &&
                                      profileAvatar.isNotEmpty) ||
                                  (authAvatar != null && authAvatar.isNotEmpty);
                              if (!hasAnyAvatar) {
                                return Text(
                                  _getInitials(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }
                              return null;
                            }(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getDisplayName(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: AppTheme.primaryText,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _primaryContactLine(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppTheme.secondaryText,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: [
                                    if (!_isSarVariant) _buildTierChip(),
                                    if (_authService.currentUser.isAdmin)
                                      _buildBadgeChip(
                                        text: 'ADMIN',
                                        color: Colors.purple,
                                        icon: Icons.admin_panel_settings,
                                      ),
                                    if (_authService.currentUser.isDeveloper)
                                      _buildBadgeChip(
                                        text: 'DEVELOPER',
                                        color: Colors.orange,
                                        icon: Icons.code,
                                      ),
                                    if (_isSARVerified)
                                      _buildBadgeChip(
                                        text: 'SAR VERIFIED',
                                        color: AppTheme.safeGreen,
                                        icon: Icons.verified,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Quick actions
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 3.4,
                    children: [
                      if (_isSarVariant)
                        _actionButton(
                          label: 'Map',
                          icon: Icons.map_outlined,
                          color: AppTheme.infoBlue,
                          onPressed: () => context.push('/sar/map'),
                        )
                      else
                        _actionButton(
                          label: 'Medical',
                          icon: Icons.medical_services,
                          color: AppTheme.successGreen,
                          onPressed: _showEditMedicalDialog,
                        ),
                      if (_isSarVariant)
                        _actionButton(
                          label: 'Sessions',
                          icon: Icons.history,
                          color: AppTheme.warningOrange,
                          onPressed: () => context.push('/session-history'),
                        )
                      else
                        _actionButton(
                          label: 'Contacts',
                          icon: Icons.contacts,
                          color: AppTheme.warningOrange,
                          onPressed: () =>
                              context.go('/profile/emergency-contacts'),
                        ),
                      if (_isSarVariant)
                        _actionButton(
                          label: 'SOS Pings',
                          icon: Icons.emergency,
                          color: AppTheme.criticalRed,
                          onPressed: () => context.push('/sos-ping-dashboard'),
                        )
                      else
                        _actionButton(
                          label: 'Edit',
                          icon: Icons.edit,
                          color: AppTheme.infoBlue,
                          onPressed: _openEditBasicInfoSheet,
                        ),
                      if (!_isSarVariant)
                        _actionButton(
                          label: 'Share',
                          icon: Icons.share,
                          color: AppTheme.infoBlue,
                          onPressed: _shareProfile,
                        )
                      else
                        _actionButton(
                          label: 'Privacy',
                          icon: Icons.privacy_tip,
                          color: AppTheme.infoBlue,
                          onPressed: () => context.push('/settings/privacy'),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (_isSarVariant) ...[
                    _buildSarServicesSection(context),
                    const SizedBox(height: 16),
                  ],

                  if (!_isSarVariant) ...[
                    // Emergency Contacts
                    Text(
                      'Emergency Contacts',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'SOS alerts notify your personal contacts. For national emergency services, use Emergency Hotline (manual dial).',
                      style: TextStyle(
                        color: AppTheme.secondaryText,
                        fontSize: 12,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          if (_emergencyContacts.isNotEmpty) ...[
                            for (
                              int i = 0;
                              i < _emergencyContacts.length;
                              i++
                            ) ...[
                              ListTile(
                                leading: Icon(
                                  Icons.emergency,
                                  color: AppTheme.criticalRed,
                                ),
                                title: Text(
                                  _emergencyContacts[i].name,
                                  style: const TextStyle(
                                    color: AppTheme.primaryText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  _emergencyContacts[i].phoneNumber,
                                  style: TextStyle(
                                    color: AppTheme.secondaryText,
                                  ),
                                ),
                                trailing: Text(
                                  _emergencyContacts[i].relationship ??
                                      'Unknown',
                                  style: TextStyle(
                                    color: AppTheme.infoBlue,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              if (i < _emergencyContacts.length - 1)
                                const Divider(height: 1),
                            ],
                          ] else
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'No emergency contacts added',
                                style:
                                    TextStyle(color: AppTheme.secondaryText),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _showEmergencyHotlineSheet,
                      icon: const Icon(Icons.local_phone),
                      label: const Text('Emergency Hotline (Manual Dial)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.criticalRed,
                        side: const BorderSide(color: AppTheme.criticalRed),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (!_isSarVariant) ...[
                    // Medical Information
                    Text(
                      'Medical Information',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_userProfile?.age != null ||
                                _userProfile?.gender != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    if (_userProfile?.age != null) ...[
                                      Expanded(
                                        child: _buildMedicalInfoRow(
                                          'Age',
                                          '${_userProfile!.age}',
                                        ),
                                      ),
                                      if (_userProfile?.gender != null)
                                        const SizedBox(width: 16),
                                    ],
                                    if (_userProfile?.gender != null)
                                      Expanded(
                                        child: _buildMedicalInfoRow(
                                          'Gender',
                                          _userProfile!.gender == 'male'
                                              ? 'Male ♂'
                                              : _userProfile!.gender == 'female'
                                              ? 'Female ♀'
                                              : _userProfile!.gender!,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            _buildMedicalInfoRow(
                              'Blood Type',
                              _userProfile?.bloodType ?? 'Not specified',
                            ),
                            const SizedBox(height: 12),
                            _buildMedicalInfoRow(
                              'Allergies',
                              (_userProfile?.allergies.isNotEmpty == true)
                                  ? _userProfile!.allergies.join(', ')
                                  : 'None',
                            ),
                            const SizedBox(height: 12),
                            _buildMedicalInfoRow(
                              'Medical Conditions',
                              (_userProfile?.medicalConditions.isNotEmpty ==
                                      true)
                                  ? _userProfile!.medicalConditions.join(', ')
                                  : 'None',
                            ),
                            const SizedBox(height: 12),
                            _buildMedicalInfoRow(
                              'Medications',
                              (_userProfile?.medications.isNotEmpty == true)
                                  ? _userProfile!.medications.join(', ')
                                  : 'None',
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _showEditMedicalDialog,
                                icon: const Icon(Icons.edit),
                                label: const Text(
                                  'Edit Medical Information',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (!_isSarVariant) ...[
                    // RedPing Doctor quick links
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.local_hospital_outlined),
                            title: const Text('RedPing Doctor'),
                            subtitle: const Text(
                              'Medical profile, coverage info',
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () => context.push('/doctor/profile'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.medication_outlined),
                            title: const Text('Medications'),
                            subtitle: const Text(
                              'Schedules, reminders, scan prescription',
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () => context.push('/doctor/medications'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.event_note_outlined),
                            title: const Text('Appointments'),
                            subtitle: const Text('Upcoming health visits'),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                            ),
                            onTap: () => context.push('/doctor/appointments'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Account Actions
                  Text(
                    'Account',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(
                            Icons.privacy_tip,
                            color: AppTheme.infoBlue,
                          ),
                          title: const Text(
                            'Privacy & Security',
                            style: TextStyle(color: AppTheme.primaryText),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: AppTheme.neutralGray,
                            size: 16,
                          ),
                          onTap: () {
                            context.push('/settings/privacy');
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.backup,
                            color: AppTheme.warningOrange,
                          ),
                          title: const Text(
                            'Backup & Sync',
                            style: TextStyle(color: AppTheme.primaryText),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: AppTheme.neutralGray,
                            size: 16,
                          ),
                          onTap: () {
                            // Navigate to backup settings
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.delete_forever,
                            color: AppTheme.criticalRed,
                          ),
                          title: const Text(
                            'Delete Account',
                            style: TextStyle(color: AppTheme.criticalRed),
                          ),
                          subtitle: const Text(
                            'Permanently delete your account',
                            style: TextStyle(fontSize: 12),
                          ),
                          onTap: () {
                            _showDeleteAccountDialog(context);
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(
                            Icons.logout,
                            color: AppTheme.criticalRed,
                          ),
                          title: const Text(
                            'Sign Out',
                            style: TextStyle(color: AppTheme.criticalRed),
                          ),
                          onTap: () {
                            _showSignOutDialog(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSarServicesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SAR Services',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.local_hospital,
                  color: AppTheme.primaryRed,
                ),
                title: const Text(
                  'SAR Member Registration',
                  style: TextStyle(
                    color: AppTheme.primaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: const Text(
                  'Register as a Search and Rescue professional',
                  style: TextStyle(color: AppTheme.secondaryText),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.neutralGray,
                  size: 16,
                ),
                onTap: () async {
                  final featureAccessService = FeatureAccessService.instance;

                  final allowed =
                      await featureAccessService.checkFeatureAccessWithUpgrade(
                    context,
                    'sarVolunteerRegistration',
                  );
                  if (!mounted) return;
                  if (allowed) {
                    context.push('/sar-registration');
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.business,
                  color: AppTheme.infoBlue,
                ),
                title: const Text(
                  'Organization Registration',
                  style: TextStyle(
                    color: AppTheme.primaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: const Text(
                  'Register your SAR organization',
                  style: TextStyle(color: AppTheme.secondaryText),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.neutralGray,
                  size: 16,
                ),
                onTap: () {
                  context.push('/organization-registration');
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.dashboard,
                  color: AppTheme.warningOrange,
                ),
                title: const Text(
                  'Organization Dashboard',
                  style: TextStyle(
                    color: AppTheme.primaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: const Text(
                  'Manage your SAR organization',
                  style: TextStyle(color: AppTheme.secondaryText),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.neutralGray,
                  size: 16,
                ),
                onTap: () {
                  context.push('/organization-dashboard');
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.verified_user,
                  color: AppTheme.safeGreen,
                ),
                title: const Text(
                  'SAR Verification',
                  style: TextStyle(
                    color: AppTheme.primaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: const Text(
                  'Admin verification for SAR members',
                  style: TextStyle(color: AppTheme.secondaryText),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.neutralGray,
                  size: 16,
                ),
                onTap: () async {
                  final featureAccessService = FeatureAccessService.instance;

                  final allowed =
                      await featureAccessService.checkFeatureAccessWithUpgrade(
                    context,
                    'organizationManagement',
                  );
                  if (!mounted) return;
                  if (allowed) {
                    context.push('/sar-verification');
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.emergency,
                  color: AppTheme.criticalRed,
                ),
                title: const Text(
                  'SOS Ping Dashboard',
                  style: TextStyle(
                    color: AppTheme.primaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: const Text(
                  'Monitor emergency pings (SAR members)',
                  style: TextStyle(color: AppTheme.secondaryText),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.neutralGray,
                  size: 16,
                ),
                onTap: () {
                  context.push('/sos-ping-dashboard');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedicalInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.primaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: AppTheme.secondaryText),
          ),
        ),
      ],
    );
  }

  // Build an access badge chip for the header
  Widget _buildTierChip() {
    return _buildBadgeChip(
      text: 'FULL ACCESS',
      color: AppTheme.safeGreen,
      icon: Icons.workspace_premium,
    );
  }

  Widget _buildBadgeChip({
    required String text,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getDisplayName() {
    final name = _userProfile?.name;
    if (name != null && name.isNotEmpty) return name;
    final authName = _authService.currentUser.displayName;
    if (authName.isNotEmpty) return authName;
    return 'User';
  }

  String _getInitials() {
    if (_userProfile == null) return 'U';

    final name = _userProfile!.name;

    if (name.isEmpty) {
      return 'U';
    }

    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0][0].toUpperCase();
    }

    return 'U';
  }

  String _primaryContactLine() {
    final email = (_userProfile?.email?.isNotEmpty == true)
        ? _userProfile!.email
        : (_authService.currentUser.email.isNotEmpty
              ? _authService.currentUser.email
              : null);
    final phone = (_userProfile?.phoneNumber?.isNotEmpty == true)
        ? _userProfile!.phoneNumber
        : (_userProfile?.phone?.isNotEmpty == true)
        ? _userProfile!.phone
        : _authService.currentUser.phoneNumber;
    if ((email == null || email.isEmpty) && (phone == null || phone.isEmpty)) {
      return 'No contact set';
    }
    if (email != null &&
        email.isNotEmpty &&
        phone != null &&
        phone.isNotEmpty) {
      return '$email • $phone';
    }
    return email?.isNotEmpty == true ? email! : phone!;
  }

  /// Show delete account confirmation dialog
  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          title: const Text(
            '⚠️ Delete Account',
            style: TextStyle(color: AppTheme.criticalRed),
          ),
          content: const Text(
            'This will PERMANENTLY delete your account and all data. This action cannot be undone.\n\nAre you absolutely sure?',
            style: TextStyle(color: AppTheme.secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.neutralGray),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteAccount();
              },
              child: const Text(
                'Delete Forever',
                style: TextStyle(
                  color: AppTheme.criticalRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show sign out confirmation dialog
  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          title: const Text(
            'Sign Out',
            style: TextStyle(color: AppTheme.primaryText),
          ),
          content: const Text(
            'Are you sure you want to sign out?',
            style: TextStyle(color: AppTheme.secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.neutralGray),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _signOut();
              },
              child: const Text(
                'Sign Out',
                style: TextStyle(color: AppTheme.criticalRed),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Delete the user account permanently
  Future<void> _deleteAccount() async {
    try {
      await _authService.deleteAccount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Account deleted successfully'),
            backgroundColor: AppTheme.safeGreen,
          ),
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error deleting account: $e'),
            backgroundColor: AppTheme.criticalRed,
          ),
        );
      }
    }
  }

  /// Sign out the user
  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: AppTheme.criticalRed,
          ),
        );
      }
    }
  }

  // Profile quick action helpers
  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _shareProfile() async {
    final id = _userProfile?.id;
    if (id == null || id.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not available to share')),
      );
      return;
    }

    final shareText = 'RedPing Profile ID: $id';
    await Clipboard.setData(ClipboardData(text: shareText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile ID copied for sharing')),
    );
  }

  // Removed _copyUserId in favor of _shareProfile

  void _openEditBasicInfoSheet() {
    final nameController = TextEditingController(
      text: _userProfile?.name ?? '',
    );
    final emailController = TextEditingController(
      text: _userProfile?.email ?? '',
    );
    final phoneController = TextEditingController(
      text: _userProfile?.phoneNumber ?? _userProfile?.phone ?? '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Edit Profile',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Save changes'),
                  onPressed: () async {
                    debugPrint('=== SAVE BUTTON CLICKED ===');
                    final name = nameController.text.trim();
                    debugPrint('Name entered: "$name"');

                    if (name.isEmpty) {
                      debugPrint('ERROR: Name is empty');
                      // Use bottom sheet context for validation error
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Name cannot be empty'),
                          backgroundColor: AppTheme.criticalRed,
                          duration: Duration(seconds: 2),
                        ),
                      );
                      return;
                    }

                    try {
                      debugPrint('Starting profile update...');
                      final now = DateTime.now();
                      final base =
                          _userProfile ??
                          UserProfile(
                            id: 'user_${now.millisecondsSinceEpoch}',
                            name: 'User',
                            createdAt: now,
                            updatedAt: now,
                          );
                      final updated = base.copyWith(
                        name: name,
                        email: emailController.text.trim().isEmpty
                            ? null
                            : emailController.text.trim(),
                        phoneNumber: phoneController.text.trim().isEmpty
                            ? null
                            : phoneController.text.trim(),
                        updatedAt: DateTime.now(),
                      );

                      debugPrint('Calling updateProfile...');
                      debugPrint('Profile service instance: $_profileService');
                      await _profileService.updateProfile(updated);
                      debugPrint('Profile updated successfully in service');

                      // Update state first while still mounted
                      if (mounted) {
                        debugPrint('Updating local state...');
                        setState(() => _userProfile = updated);
                        debugPrint('Local state updated');
                      }

                      // Close the bottom sheet
                      debugPrint('Closing bottom sheet...');
                      Navigator.of(ctx).pop();

                      // Show success message on main page
                      if (mounted) {
                        debugPrint('Showing success message...');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile updated successfully!'),
                            backgroundColor: AppTheme.safeGreen,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                      debugPrint('=== SAVE COMPLETE ===');
                    } catch (e) {
                      debugPrint('ERROR saving profile: $e');
                      // Show error on bottom sheet without closing it
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text('Error saving profile: $e'),
                          backgroundColor: AppTheme.criticalRed,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}
