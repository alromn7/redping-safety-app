// ignore_for_file: undefined_method, undefined_getter, undefined_identifier, undefined_setter, deprecated_member_use
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/user_profile_service.dart';
import '../../../../models/user_profile.dart';

/// Test page for UserProfileService functionalities
class ProfileTestPage extends StatefulWidget {
  const ProfileTestPage({super.key});

  @override
  State<ProfileTestPage> createState() => _ProfileTestPageState();
}

class _ProfileTestPageState extends State<ProfileTestPage> {
  final UserProfileService _profileService = UserProfileService();
  UserProfile? _currentProfile;
  bool _isLoading = false;
  String _testResults = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _profileService.initialize();
      setState(() {
        _currentProfile = _profileService.currentProfile;
      });
    } catch (e) {
      _addTestResult('❌ Error loading profile: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addTestResult(String result) {
    final sanitized = _sanitizeText(result);
    setState(() {
      _testResults += '$sanitized\n';
    });
  }

  String _sanitizeText(String input) {
    // Remove non-printable and non-ASCII glyphs, and map common garbled prefixes
    var out = input
        .replaceAll('�?O', 'Error:')
        .replaceAll('�o.', 'Success.')
        .replaceAll('dYs?', '')
        .replaceAll('dY"S', '')
        .replaceAll('dY"<', '')
        .replaceAll('dY\u0015�', '')
        .replaceAll('�s��,?', '')
        .replaceAll('??', '')
        .replaceAll('dY`', '')
        .replaceAll("dY'", '')
        .replaceAll('dY"', '');
    // Strip any remaining non-ASCII except newline and carriage return
    out = out.replaceAll(RegExp(r'[^\x0A\x0D\x20-\x7E]'), '');
    return out.trim();
  }

  Future<void> _testProfileCreation() async {
    _addTestResult('🧪 Testing profile creation...');

    try {
      // Test creating a new profile
      final testProfile = UserProfile(
        id: 'test_user_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Test User Profile',
        email: 'test@redping.com',
        phoneNumber: '+1-555-TEST',
        dateOfBirth: DateTime(1990, 5, 15),
        bloodType: 'A+',
        medicalConditions: const ['Diabetes'],
        allergies: const ['Peanuts', 'Shellfish'],
        medications: const ['Insulin'],
        emergencyContacts: const [],
        preferences: UserPreferences.defaultSettings(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _profileService.updateProfile(testProfile);
      _addTestResult('✅ Profile created successfully');

      // Reload to verify
      await _loadProfile();
    } catch (e) {
      _addTestResult('❌ Profile creation failed: $e');
    }
  }

  Future<void> _testProfileFieldsUpdate() async {
    _addTestResult('🧪 Testing profile fields update...');

    try {
      await _profileService.updateProfileFields(
        name: 'Updated Test User',
        email: 'updated@redping.com',
        phoneNumber: '+1-555-UPDATED',
        bloodType: 'B+',
        allergies: const ['Updated Allergy'],
        medicalConditions: const ['Updated Condition'],
      );

      _addTestResult('✅ Profile fields updated successfully');
      await _loadProfile();
    } catch (e) {
      _addTestResult('❌ Profile fields update failed: $e');
    }
  }

  Future<void> _testEmergencyContactManagement() async {
    _addTestResult('🧪 Testing emergency contact management...');

    try {
      // Add new emergency contact
      final newContact = EmergencyContact(
        id: 'contact_${DateTime.now().millisecondsSinceEpoch}',
        name: 'New Emergency Contact',
        phoneNumber: '+1-555-NEW',
        relationship: 'Friend',
        isPrimary: false,
      );

      await _profileService.addEmergencyContact(newContact);
      _addTestResult('✅ Emergency contact added');

      // Reload to verify
      await _loadProfile();

      // Test removing contact (if we have contacts)
      if (_currentProfile?.emergencyContacts.isNotEmpty == true) {
        final contactToRemove = _currentProfile!.emergencyContacts.first.id;
        await _profileService.removeEmergencyContact(contactToRemove);
        _addTestResult('✅ Emergency contact removed');
        await _loadProfile();
      }
    } catch (e) {
      _addTestResult('❌ Emergency contact management failed: $e');
    }
  }

  Future<void> _testPreferencesUpdate() async {
    _addTestResult('🧪 Testing preferences update...');

    try {
      final newPreferences = UserPreferences(
        crashDetectionEnabled: false,
        fallDetectionEnabled: true,
        voiceVerificationEnabled: false,
        automaticSOSEnabled: true,
        sosCountdownDuration: 15,
        locationSharingEnabled: false,
        hazardAlertsEnabled: true,
        communityFeaturesEnabled: false,
        meshNetworkingEnabled: true,
        crashSensitivity: 0.8,
        fallSensitivity: 0.6,
        preferredLanguage: 'es',
        darkModeEnabled: true,
        soundEnabled: false,
        vibrationEnabled: true,
        volume: 0.7,
        notifications: NotificationSettings(
          emergencyAlerts: true,
          hazardAlerts: true,
          communityUpdates: true,
          systemNotifications: false,
          pushNotifications: true,
          smsNotifications: false,
          emailNotifications: false,
        ),
      );

      await _profileService.updatePreferences(newPreferences);
      _addTestResult('✅ Preferences updated successfully');
      await _loadProfile();
    } catch (e) {
      _addTestResult('❌ Preferences update failed: $e');
    }
  }

  Future<void> _testProfileValidation() async {
    _addTestResult('🧪 Testing profile validation...');

    try {
      final completionPercentage = _profileService
          .getProfileCompletionPercentage();
      final isReadyForEmergency = _profileService.isProfileReadyForEmergency();
      final emergencySummary = _profileService.getEmergencyProfileSummary();

      _addTestResult(
        '📊 Profile completion: ${(completionPercentage * 100).toStringAsFixed(1)}%',
      );
      _addTestResult(
        '🚨 Ready for emergency: ${isReadyForEmergency ? "YES" : "NO"}',
      );
      _addTestResult('📋 Emergency summary: ${emergencySummary.length} fields');

      if (isReadyForEmergency) {
        _addTestResult('✅ Profile is ready for emergency use');
      } else {
        _addTestResult('⚠️ Profile needs more information for emergency use');
      }
    } catch (e) {
      _addTestResult('❌ Profile validation failed: $e');
    }
  }

  Future<void> _runAllTests() async {
    _addTestResult('🚀 Starting comprehensive UserProfileService tests...\n');

    await _testProfileCreation();
    await _testProfileFieldsUpdate();
    await _testEmergencyContactManagement();
    await _testPreferencesUpdate();
    await _testProfileValidation();

    _addTestResult('\n🎉 All tests completed!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UserProfileService Test'),
        backgroundColor: AppTheme.darkSurface,
        foregroundColor: AppTheme.primaryText,
      ),
      backgroundColor: AppTheme.darkBackground,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.infoBlue),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Test Controls
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.infoBlue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'UserProfileService Test Suite',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Test all profile management functionalities',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _testProfileCreationClean,
                              icon: const Icon(Icons.person_add, size: 16),
                              label: const Text('Test Creation'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryRed,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _testProfileFieldsUpdateClean,
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Test Update'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.infoBlue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _testEmergencyContactManagementClean,
                              icon: const Icon(Icons.contact_phone, size: 16),
                              label: const Text('Test Contacts'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.safeGreen,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _testPreferencesUpdateClean,
                              icon: const Icon(Icons.settings, size: 16),
                              label: const Text('Test Preferences'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.warningOrange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _testProfileValidationClean,
                              icon: const Icon(Icons.check_circle, size: 16),
                              label: const Text('Test Validation'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.successGreen,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _runAllTestsClean,
                              icon: const Icon(Icons.play_arrow, size: 16),
                              label: const Text('Run All Tests'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.criticalRed,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Current Profile Display
                  if (_currentProfile != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.darkSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.safeGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Profile',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryText,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildProfileField('ID', _currentProfile!.id),
                          _buildProfileField('Name', _currentProfile!.name),
                          _buildProfileField(
                            'Email',
                            _currentProfile!.email ?? 'Not set',
                          ),
                          _buildProfileField(
                            'Phone',
                            _currentProfile!.phoneNumber ?? 'Not set',
                          ),
                          _buildProfileField(
                            'Blood Type',
                            _currentProfile!.bloodType ?? 'Not set',
                          ),
                          _buildProfileField(
                            'Allergies',
                            _currentProfile!.allergies.join(', '),
                          ),
                          _buildProfileField(
                            'Medical Conditions',
                            _currentProfile!.medicalConditions.join(', '),
                          ),
                          _buildProfileField(
                            'Emergency Contacts',
                            '${_currentProfile!.emergencyContacts.length} contacts',
                          ),
                          _buildProfileField(
                            'Created',
                            _currentProfile!.createdAt.toString(),
                          ),
                          _buildProfileField(
                            'Updated',
                            _currentProfile!.updatedAt.toString(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Test Results
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.darkSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.warningOrange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.science,
                              color: AppTheme.warningOrange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Test Results',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryText,
                              ),
                            ),
                            const Spacer(),
                            if (_testResults.isNotEmpty)
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _testResults = '';
                                  });
                                },
                                icon: const Icon(
                                  Icons.clear,
                                  color: AppTheme.secondaryText,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          height: 300,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.darkBackground,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.secondaryText.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _testResults.isEmpty
                                  ? 'No test results yet. Run tests to see results.'
                                  : _testResults,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.secondaryText,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Clean test runner and methods using clear ASCII-only strings
  Future<void> _runAllTestsClean() async {
    _addTestResult('Starting comprehensive UserProfileService tests...');

    await _testProfileCreationClean();
    await _testProfileFieldsUpdateClean();
    await _testEmergencyContactManagementClean();
    await _testPreferencesUpdateClean();
    await _testProfileValidationClean();

    _addTestResult('\nAll tests completed!');
  }

  Future<void> _testProfileCreationClean() async {
    _addTestResult('Testing profile creation...');
    try {
      final testProfile = UserProfile(
        id: 'test_user_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Test User Profile',
        email: 'test@redping.com',
        phoneNumber: '+1-555-TEST',
        dateOfBirth: DateTime(1990, 5, 15),
        bloodType: 'A+',
        medicalConditions: const ['Diabetes'],
        allergies: const ['Peanuts', 'Shellfish'],
        medications: const ['Insulin'],
        emergencyContacts: const [],
        preferences: UserPreferences.defaultSettings(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _profileService.updateProfile(testProfile);
      _addTestResult('Success. Profile created successfully');
      await _loadProfile();
    } catch (e) {
      _addTestResult('Error: Profile creation failed: $e');
    }
  }

  Future<void> _testProfileFieldsUpdateClean() async {
    _addTestResult('Testing profile fields update...');
    try {
      await _profileService.updateProfileFields(
        name: 'Updated Test User',
        email: 'updated@redping.com',
        phoneNumber: '+1-555-UPDATED',
        bloodType: 'B+',
        allergies: const ['Updated Allergy'],
        medicalConditions: const ['Updated Condition'],
      );
      _addTestResult('Success. Profile fields updated successfully');
      await _loadProfile();
    } catch (e) {
      _addTestResult('Error: Profile fields update failed: $e');
    }
  }

  Future<void> _testEmergencyContactManagementClean() async {
    _addTestResult('Testing emergency contact management...');
    try {
      final newContact = EmergencyContact(
        id: 'contact_${DateTime.now().millisecondsSinceEpoch}',
        name: 'New Emergency Contact',
        phoneNumber: '+1-555-NEW',
        relationship: 'Friend',
        isPrimary: false,
      );

      await _profileService.addEmergencyContact(newContact);
      _addTestResult('Success. Emergency contact added');
      await _loadProfile();

      if (_currentProfile?.emergencyContacts.isNotEmpty == true) {
        final contactToRemove = _currentProfile!.emergencyContacts.first.id;
        await _profileService.removeEmergencyContact(contactToRemove);
        _addTestResult('Success. Emergency contact removed');
        await _loadProfile();
      }
    } catch (e) {
      _addTestResult('Error: Emergency contact management failed: $e');
    }
  }

  Future<void> _testPreferencesUpdateClean() async {
    _addTestResult('Testing preferences update...');
    try {
      final newPreferences = UserPreferences(
        crashDetectionEnabled: false,
        fallDetectionEnabled: true,
        voiceVerificationEnabled: false,
        automaticSOSEnabled: true,
        sosCountdownDuration: 15,
        locationSharingEnabled: false,
        hazardAlertsEnabled: true,
        communityFeaturesEnabled: false,
        meshNetworkingEnabled: true,
        crashSensitivity: 0.8,
        fallSensitivity: 0.6,
        preferredLanguage: 'es',
        darkModeEnabled: true,
        soundEnabled: false,
        vibrationEnabled: true,
        volume: 0.7,
        notifications: NotificationSettings(
          emergencyAlerts: true,
          hazardAlerts: true,
          communityUpdates: true,
          systemNotifications: false,
          pushNotifications: true,
          smsNotifications: false,
          emailNotifications: false,
        ),
      );

      await _profileService.updatePreferences(newPreferences);
      _addTestResult('Success. Preferences updated successfully');
      await _loadProfile();
    } catch (e) {
      _addTestResult('Error: Preferences update failed: $e');
    }
  }

  Future<void> _testProfileValidationClean() async {
    _addTestResult('Testing profile validation...');
    try {
      final completionPercentage = _profileService
          .getProfileCompletionPercentage();
      final isReadyForEmergency = _profileService.isProfileReadyForEmergency();
      final emergencySummary = _profileService.getEmergencyProfileSummary();

      _addTestResult(
        'Profile completion: ${(completionPercentage * 100).toStringAsFixed(1)}%',
      );
      _addTestResult(
        'Ready for emergency: ${isReadyForEmergency ? "YES" : "NO"}',
      );
      _addTestResult('Emergency summary: ${emergencySummary.length} fields');

      if (isReadyForEmergency) {
        _addTestResult('Success. Profile is ready for emergency use');
      } else {
        _addTestResult('Profile needs more information for emergency use');
      }
    } catch (e) {
      _addTestResult('Error: Profile validation failed: $e');
    }
  }

  Widget _buildProfileField(String label, String value) {
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
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
