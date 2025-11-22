// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import '../../../../models/subscription_tier.dart' as sub;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/user_profile_service.dart';
import '../../../../services/emergency_contacts_service.dart';
import '../../../../services/subscription_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/feature_access_service.dart';
import '../../../../services/sar_identity_service.dart';
import '../../../../models/user_profile.dart';
import '../../../../models/emergency_contact.dart' as emergency_contact_model;
import '../../../../models/auth_user.dart';

/// Profile page with user information, emergency contacts, and medical info
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<void> _showEditMedicalDialog() async {
    // 🔒 SUBSCRIPTION GATE: Medical Profile requires Essential+ or above
    if (!FeatureAccessService.instance.hasFeatureAccess('medicalProfile')) {
      _showUpgradeDialog(
        'Medical Profile',
        'Essential+',
        'Store medical information for emergency responders',
        [
          '• Blood Type & Allergies',
          '• Medical Conditions',
          '• Current Medications',
          '• Age & Gender Information',
          '• Critical Health Data for SAR Teams',
        ],
      );
      return;
    }

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
        setState(() {
          _userProfile = updatedProfile;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medical information updated!')),
        );
      }
    }
  }

  final UserProfileService _profileService = UserProfileService();
  final EmergencyContactsService _contactsService = EmergencyContactsService();
  final SubscriptionService _subscriptionService = SubscriptionService.instance;
  final AuthService _authService = AuthService.instance;
  final SARIdentityService _sarIdentityService = SARIdentityService();

  StreamSubscription<AuthUser>? _authSub;

  UserProfile? _userProfile;
  List<emergency_contact_model.EmergencyContact> _emergencyContacts = [];
  UserSubscription? _currentSubscription;
  FamilySubscription? _currentFamily;
  bool _isLoading = true;
  bool _isSARVerified = false;

  @override
  void initState() {
    super.initState();
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

  void _showUpgradeDialog(
    String featureName,
    String requiredTier,
    String description,
    List<String> benefits,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.lock, color: AppTheme.warningOrange),
            const SizedBox(width: 8),
            Expanded(child: Text('Upgrade to $requiredTier')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$featureName is available on $requiredTier plans and above.',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: const TextStyle(color: AppTheme.secondaryText),
              ),
              const SizedBox(height: 16),
              const Text(
                'What you\'ll get:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              ...benefits.map(
                (benefit) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(benefit, style: const TextStyle(fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/subscription/plans');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningOrange,
            ),
            child: const Text('View Plans'),
          ),
        ],
      ),
    );
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
      await _contactsService.initialize();
      // Initialize SAR identity to check verification badge
      try {
        await _sarIdentityService.initialize();
        _isSARVerified = _sarIdentityService.isCurrentUserVerified;
      } catch (_) {
        _isSARVerified = false;
      }

      setState(() {
        _userProfile = _profileService.currentProfile;
        _emergencyContacts = _contactsService.enabledContacts.take(3).toList();
        _currentSubscription = _subscriptionService.currentSubscription;
        _currentFamily = _subscriptionService.currentFamily;
        _isLoading = false;
      });

      // Listen for subscription changes
      _subscriptionService.subscriptionStream.listen((subscription) {
        if (!mounted) return;
        setState(() => _currentSubscription = subscription);
      });

      _subscriptionService.familyStream.listen((family) {
        if (!mounted) return;
        setState(() => _currentFamily = family);
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
        title: const Text('Profile'),
        actions: [
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
                              final profileAvatar = _userProfile?.avatar;
                              if (profileAvatar != null &&
                                  profileAvatar.isNotEmpty) {
                                return NetworkImage(profileAvatar);
                              }
                              final authAvatar =
                                  _authService.currentUser.photoUrl;
                              if (authAvatar != null && authAvatar.isNotEmpty) {
                                return NetworkImage(authAvatar);
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
                                    if (_currentSubscription != null)
                                      _buildTierChip(),
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

                  // Quick actions (4 buttons: Edit, Medical, Contacts, Share)
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 3.4,
                    children: [
                      _actionButton(
                        label: 'Edit',
                        icon: Icons.edit,
                        color: AppTheme.infoBlue,
                        onPressed: _openEditBasicInfoSheet,
                      ),
                      _actionButton(
                        label: 'Medical',
                        icon: Icons.medical_services,
                        color: AppTheme.successGreen,
                        onPressed: _showEditMedicalDialog,
                      ),
                      _actionButton(
                        label: 'Contacts',
                        icon: Icons.contacts,
                        color: AppTheme.warningOrange,
                        onPressed: () =>
                            context.go('/profile/emergency-contacts'),
                      ),
                      _actionButton(
                        label: 'Share',
                        icon: Icons.share,
                        color: AppTheme.infoBlue,
                        onPressed: _shareProfile,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Subscription Section
                  InkWell(
                    onTap: () => context.push('/subscription/manage'),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            'Subscription',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: AppTheme.primaryText,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppTheme.infoBlue,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSubscriptionCard(),

                  const SizedBox(height: 16),

                  // Emergency Contacts
                  Text(
                    'Emergency Contacts',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppTheme.primaryText,
                      fontWeight: FontWeight.w600,
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
                                style: TextStyle(color: AppTheme.secondaryText),
                              ),
                              trailing: Text(
                                _emergencyContacts[i].relationship ?? 'Unknown',
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
                              style: TextStyle(color: AppTheme.secondaryText),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Medical Information
                  Text(
                    'Medical Information',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                            (_userProfile?.medicalConditions.isNotEmpty == true)
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
                              label: const Text('Edit Medical Information'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // SAR Services Section
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
                            final featureAccessService =
                                FeatureAccessService.instance;

                            if (featureAccessService.hasFeatureAccess(
                              'sarVolunteerRegistration',
                            )) {
                              context.push('/sar-registration');
                            } else {
                              final shouldUpgrade = await featureAccessService
                                  .checkFeatureAccessWithUpgrade(
                                    context,
                                    'sarVolunteerRegistration',
                                  );
                              if (!mounted) return;
                              if (shouldUpgrade) {
                                context.push('/subscription');
                              }
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
                            final featureAccessService =
                                FeatureAccessService.instance;

                            if (featureAccessService.hasFeatureAccess(
                              'organizationManagement',
                            )) {
                              context.push('/sar-verification');
                            } else {
                              final shouldUpgrade = await featureAccessService
                                  .checkFeatureAccessWithUpgrade(
                                    context,
                                    'organizationManagement',
                                  );

                              if (!mounted) return;
                              if (shouldUpgrade) {
                                context.push('/subscription');
                              }
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

                  const SizedBox(height: 16),

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

  // Build subscription tier badge chip for header
  Widget _buildTierChip() {
    final color = _getSubscriptionColor();
    final title = _getSubscriptionTitle();
    return _buildBadgeChip(
      text: title,
      color: color,
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
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Name cannot be empty')),
                      );
                      return;
                    }
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

                    await _profileService.updateProfile(updated);
                    if (!mounted) return;
                    setState(() => _userProfile = updated);
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated')),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSubscriptionCard() {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          if (_currentSubscription != null) {
            // If user has active subscription, go to management page
            context.push('/subscription/manage');
          } else if (_currentSubscription?.plan.isFamilyPlan == true) {
            context.push('/subscription/family-dashboard');
          } else {
            // If no subscription, show plans
            context.push('/subscription/plans');
          }
        },
        borderRadius: BorderRadius.circular(12),
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
                      color: _getSubscriptionColor().withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getSubscriptionIcon(),
                      color: _getSubscriptionColor(),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getSubscriptionTitle(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.primaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getSubscriptionSubtitle(),
                          style: TextStyle(
                            color: AppTheme.secondaryText,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppTheme.neutralGray,
                    size: 16,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Features
              if (_currentSubscription != null) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _currentSubscription!.plan.features
                      .take(4)
                      .map((feature) => _buildFeatureChip(feature))
                      .toList(),
                ),
              ] else
                const Text(
                  'No active subscription',
                  style: TextStyle(color: AppTheme.secondaryText, fontSize: 14),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String feature) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.infoBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        feature,
        style: TextStyle(
          color: AppTheme.infoBlue,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getSubscriptionColor() {
    if (_currentSubscription == null) return AppTheme.neutralGray;

    switch (_currentSubscription!.plan.tier) {
      case sub.SubscriptionTier.essentialPlus:
        return AppTheme.successGreen.withValues(alpha: 0.7);
      case sub.SubscriptionTier.pro:
        return AppTheme.infoBlue;
      case sub.SubscriptionTier.ultra:
        return AppTheme.safeGreen;
      case sub.SubscriptionTier.family:
        return AppTheme.criticalRed;
      case sub.SubscriptionTier.free:
        return AppTheme.neutralGray;
    }
  }

  IconData _getSubscriptionIcon() {
    if (_currentSubscription == null) return Icons.info_outline;

    switch (_currentSubscription!.plan.tier) {
      case sub.SubscriptionTier.essentialPlus:
        return Icons.star_border_purple500;
      case sub.SubscriptionTier.pro:
        return Icons.star_half;
      case sub.SubscriptionTier.ultra:
        return Icons.star;
      case sub.SubscriptionTier.family:
        return Icons.family_restroom;
      case sub.SubscriptionTier.free:
        return Icons.lock_outline;
    }
  }

  String _getSubscriptionTitle() {
    if (_currentSubscription == null) return 'Free Plan';

    return _currentSubscription!.plan.name;
  }

  String _getSubscriptionSubtitle() {
    if (_currentSubscription == null) {
      return 'Upgrade to unlock premium features';
    }

    if (_currentSubscription!.plan.isFamilyPlan) {
      return 'Family plan with ${_currentFamily?.members.length ?? 0} members';
    }

    final endDate = _currentSubscription!.endDate;
    if (endDate != null) {
      return 'Active until ${endDate.day}/${endDate.month}/${endDate.year}';
    } else {
      return 'Active subscription';
    }
  }
}
