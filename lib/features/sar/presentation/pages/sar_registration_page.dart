import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/sar_identity.dart';
import '../../../../services/sar_identity_service.dart';

/// Page for SAR member registration with credential verification
class SARRegistrationPage extends StatefulWidget {
  const SARRegistrationPage({super.key});

  @override
  State<SARRegistrationPage> createState() => _SARRegistrationPageState();
}

class _SARRegistrationPageState extends State<SARRegistrationPage>
    with TickerProviderStateMixin {
  final SARIdentityService _identityService = SARIdentityService();

  late TabController _tabController;
  final PageController _pageController = PageController();

  // Form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _notesController = TextEditingController();

  // Registration data
  SARMemberType _selectedMemberType = SARMemberType.volunteer;
  DateTime? _dateOfBirth;
  final List<SARCredential> _credentials = [];
  final List<SARCertification> _certifications = [];
  SARExperience _experience = const SARExperience(
    yearsOfExperience: 0,
    numberOfMissions: 0,
    specializations: [],
    previousOrganizations: [],
    equipmentProficiency: [],
    terrainExperience: [],
  );

  bool _isLoading = false;
  int _currentStep = 0;
  bool _termsAccepted = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _initializeService() async {
    setState(() => _isLoading = true);

    try {
      await _identityService.initialize();
    } catch (e) {
      _showError('Failed to initialize registration service: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SAR Member Registration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Personal', icon: Icon(Icons.person)),
            Tab(text: 'Credentials', icon: Icon(Icons.badge)),
            Tab(text: 'Certifications', icon: Icon(Icons.school)),
            Tab(text: 'Experience', icon: Icon(Icons.work)),
            Tab(text: 'Terms', icon: Icon(Icons.description)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPersonalInfoTab(),
                _buildCredentialsTab(),
                _buildCertificationsTab(),
                _buildExperienceTab(),
                _buildTermsAndConditionsTab(),
              ],
            ),
      bottomNavigationBar: _buildNavigationBar(),
    );
  }

  Widget _buildPersonalInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Member type selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SAR Member Type',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<SARMemberType>(
                    initialValue: _selectedMemberType,
                    decoration: const InputDecoration(
                      labelText: 'Member Type',
                      border: OutlineInputBorder(),
                    ),
                    items: SARMemberType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(
                          _identityService.getMemberTypeDisplayName(type),
                        ),
                      );
                    }).toList(),
                    onChanged: (type) {
                      if (type != null) {
                        setState(() => _selectedMemberType = type);
                      }
                    },
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
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name fields
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'First Name *',
                            border: OutlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Last Name *',
                            border: OutlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Date of birth
                  InkWell(
                    onTap: _selectDateOfBirth,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Date of Birth *',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _dateOfBirth != null
                            ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                            : 'Select date of birth',
                        style: TextStyle(
                          color: _dateOfBirth != null
                              ? AppTheme.primaryText
                              : AppTheme.disabledText,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Contact information
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 16),

                  // Address
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.home),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'City *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _stateController,
                          decoration: const InputDecoration(
                            labelText: 'State *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _zipController,
                          decoration: const InputDecoration(
                            labelText: 'ZIP *',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Emergency contact
                  TextFormField(
                    controller: _emergencyContactController,
                    decoration: const InputDecoration(
                      labelText: 'Emergency Contact Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.contact_emergency),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emergencyPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Emergency Contact Phone',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialsTab() {
    final requiredCredentials = _getRequiredCredentialsForType(
      _selectedMemberType,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Required credentials info
          Card(
            color: AppTheme.infoBlue.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info, color: AppTheme.infoBlue),
                      SizedBox(width: 8),
                      Text(
                        'Required Credentials',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.infoBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please upload photos of the following documents for verification:',
                    style: const TextStyle(color: AppTheme.secondaryText),
                  ),
                  const SizedBox(height: 8),
                  ...requiredCredentials.map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AppTheme.safeGreen,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _identityService.getCredentialTypeDisplayName(type),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Credentials list
          ...requiredCredentials.map((type) => _buildCredentialCard(type)),

          const SizedBox(height: 16),

          // Add additional credential button
          OutlinedButton.icon(
            onPressed: _showAddCredentialDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Additional Credential'),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialCard(SARCredentialType type) {
    final existingCredential = _credentials
        .where((cred) => cred.type == type)
        .firstOrNull;

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
                  _getCredentialIcon(type),
                  color: existingCredential != null
                      ? AppTheme.safeGreen
                      : AppTheme.warningOrange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _identityService.getCredentialTypeDisplayName(type),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (existingCredential != null)
                  const Icon(Icons.check_circle, color: AppTheme.safeGreen),
              ],
            ),

            if (existingCredential != null) ...[
              const SizedBox(height: 12),
              _buildCredentialDetails(existingCredential),
            ] else ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _uploadCredential(type),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Upload Document'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.infoBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialDetails(SARCredential credential) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.safeGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Document photo thumbnail
              Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.neutralGray),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.file(
                    File(credential.photoPath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Document #: ${credential.documentNumber}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Issued by: ${credential.issuingAuthority}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.secondaryText,
                      ),
                    ),
                    Text(
                      'Expires: ${credential.expirationDate.day}/${credential.expirationDate.month}/${credential.expirationDate.year}',
                      style: TextStyle(
                        fontSize: 11,
                        color: credential.isExpired
                            ? AppTheme.criticalRed
                            : AppTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _editCredential(credential),
                icon: const Icon(Icons.edit, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationsTab() {
    final requiredCertifications = _identityService.getRequiredCertifications(
      _selectedMemberType,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Required certifications info
          Card(
            color: AppTheme.safeGreen.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.school, color: AppTheme.safeGreen),
                      SizedBox(width: 8),
                      Text(
                        'Required Certifications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.safeGreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload photos of your rescue training certificates:',
                    style: const TextStyle(color: AppTheme.secondaryText),
                  ),
                  const SizedBox(height: 8),
                  ...requiredCertifications.map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified,
                            size: 16,
                            color: AppTheme.safeGreen,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _identityService.getCertificationTypeDisplayName(
                              type,
                            ),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Certifications list
          ...requiredCertifications.map(
            (type) => _buildCertificationCard(type),
          ),

          const SizedBox(height: 16),

          // Add additional certification button
          OutlinedButton.icon(
            onPressed: _showAddCertificationDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Additional Certification'),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificationCard(SARCertificationType type) {
    final existingCertification = _certifications
        .where((cert) => cert.type == type)
        .firstOrNull;

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
                  _getCertificationIcon(type),
                  color: existingCertification != null
                      ? AppTheme.safeGreen
                      : AppTheme.warningOrange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _identityService.getCertificationTypeDisplayName(type),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (existingCertification != null)
                  const Icon(Icons.verified, color: AppTheme.safeGreen),
              ],
            ),

            if (existingCertification != null) ...[
              const SizedBox(height: 12),
              _buildCertificationDetails(existingCertification),
            ] else ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _uploadCertification(type),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Upload Certificate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.safeGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCertificationDetails(SARCertification certification) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.safeGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Certificate photo thumbnail
              Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.neutralGray),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.file(
                    File(certification.photoPath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      certification.certificationName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Cert #: ${certification.certificateNumber}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.secondaryText,
                      ),
                    ),
                    Text(
                      'Issued by: ${certification.issuingOrganization}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.secondaryText,
                      ),
                    ),
                    if (certification.expirationDate != null)
                      Text(
                        'Expires: ${certification.expirationDate!.day}/${certification.expirationDate!.month}/${certification.expirationDate!.year}',
                        style: TextStyle(
                          fontSize: 11,
                          color: certification.isExpired
                              ? AppTheme.criticalRed
                              : AppTheme.secondaryText,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _editCertification(certification),
                icon: const Icon(Icons.edit, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SAR Experience',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Experience fields
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Years of Experience',
                            border: OutlineInputBorder(),
                            suffixText: 'years',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final years = int.tryParse(value) ?? 0;
                            _experience = _experience.copyWith(
                              yearsOfExperience: years,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Number of Missions',
                            border: OutlineInputBorder(),
                            suffixText: 'missions',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final missions = int.tryParse(value) ?? 0;
                            _experience = _experience.copyWith(
                              numberOfMissions: missions,
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Current organization
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Current Organization (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    onChanged: (value) {
                      _experience = _experience.copyWith(
                        currentOrganization: value,
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // Specializations
                  const Text(
                    'Specializations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SARSpecialization.values.map((specialization) {
                      final isSelected = _experience.specializations.contains(
                        specialization,
                      );
                      return FilterChip(
                        selected: isSelected,
                        label: Text(
                          _getSpecializationDisplayName(specialization),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            final specializations =
                                List<SARSpecialization>.from(
                                  _experience.specializations,
                                );
                            if (selected) {
                              specializations.add(specialization);
                            } else {
                              specializations.remove(specialization);
                            }
                            _experience = _experience.copyWith(
                              specializations: specializations,
                            );
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Additional notes
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Additional Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Additional Skills, Equipment, or Notes',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsAndConditionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Card(
            color: AppTheme.warningOrange.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.description, color: AppTheme.warningOrange),
                      SizedBox(width: 8),
                      Text(
                        'Terms and Conditions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.warningOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please read and accept the following terms before registering as a SAR member:',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // SAR Terms and Conditions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SAR Network Terms and Conditions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildTermsSection(
                    '1. SAR Member Responsibilities',
                    'As a registered SAR member, you agree to:',
                    [
                      'Respond promptly to emergency callouts within your capability and availability',
                      'Maintain current certifications and credentials as required',
                      'Follow established SAR protocols and safety procedures',
                      'Cooperate with incident commanders and team leaders',
                      'Report any safety concerns or incidents immediately',
                      'Maintain professional conduct during all SAR operations',
                    ],
                  ),

                  _buildTermsSection(
                    '2. SOS Verification Requirements',
                    'CRITICAL: All SAR members, teams, and organizations must conduct independent SOS verification before initiating search and rescue operations, even though REDP!NG provides multi-layer SOS verification.',
                    [
                      'You are obligated to perform final verification of SOS alerts before deploying resources',
                      'Contact the user directly using provided contact information to confirm the emergency',
                      'Verify location accuracy through multiple sources when possible',
                      'Coordinate with emergency services and other SAR teams before independent action',
                      'SOS alerts will include user details and immediate contact persons for verification',
                      'Failure to verify may result in false alarms and unnecessary resource deployment',
                    ],
                  ),

                  _buildTermsSection(
                    '3. Emergency Response Protocol',
                    'When responding to SOS alerts:',
                    [
                      'First, attempt direct contact with the user via provided contact information',
                      'If no response, contact emergency contacts listed in the SOS alert',
                      'Verify the location and nature of the emergency',
                      'Coordinate with local emergency services (911, police, fire, EMS)',
                      'Only proceed with SAR operations after verification and coordination',
                      'Document all response actions and outcomes',
                    ],
                  ),

                  _buildTermsSection(
                    '4. Liability and Insurance',
                    'Important legal considerations:',
                    [
                      'SAR operations carry inherent risks and potential liability',
                      'Ensure you have appropriate insurance coverage for volunteer activities',
                      'REDP!NG is a communication platform and does not assume liability for SAR operations',
                      'You are responsible for your own safety and the safety of those you assist',
                      'Follow all applicable local, state, and federal regulations',
                      'Maintain records of training, certifications, and insurance coverage',
                    ],
                  ),

                  _buildTermsSection(
                    '5. Data Privacy and Confidentiality',
                    'Protection of sensitive information:',
                    [
                      'All user data and emergency information must be kept confidential',
                      'Do not share personal information with unauthorized parties',
                      'Follow HIPAA guidelines when dealing with medical information',
                      'Report any data breaches or privacy violations immediately',
                      'Respect user privacy and dignity in all communications',
                    ],
                  ),

                  _buildTermsSection(
                    '6. Code of Conduct',
                    'Professional standards for SAR members:',
                    [
                      'Treat all individuals with respect and dignity',
                      'Maintain professionalism in all communications and interactions',
                      'Avoid conflicts of interest and maintain impartiality',
                      'Report any misconduct by other SAR members',
                      'Contribute positively to the SAR community',
                      'Continuously improve skills and knowledge through training',
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Acceptance checkbox
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _termsAccepted,
                    onChanged: (value) {
                      setState(() => _termsAccepted = value ?? false);
                    },
                    activeColor: AppTheme.safeGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'I accept the Terms and Conditions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'By checking this box, I acknowledge that I have read, understood, and agree to abide by all terms and conditions outlined above, including the mandatory SOS verification requirements.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Important notice
          Card(
            color: AppTheme.criticalRed.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning, color: AppTheme.criticalRed),
                      SizedBox(width: 8),
                      Text(
                        'Important Notice',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.criticalRed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'SOS verification is mandatory before any search and rescue operation. REDP!NG provides multi-layer verification, but SAR members must conduct their own final verification to ensure legitimate emergencies and prevent false alarms.',
                    style: TextStyle(fontSize: 14, color: AppTheme.primaryText),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSection(
    String title,
    String description,
    List<String> items,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
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
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(fontSize: 13, color: AppTheme.secondaryText),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ', style: TextStyle(color: AppTheme.infoBlue)),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Previous'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentStep > 0 ? 1 : 2,
            child: ElevatedButton(
              onPressed: _currentStep < 4 ? _nextStep : _submitRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentStep < 4
                    ? AppTheme.infoBlue
                    : AppTheme.safeGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_currentStep < 4 ? 'Next' : 'Submit Registration'),
            ),
          ),
        ],
      ),
    );
  }

  // Photo capture and upload methods
  Future<void> _uploadCredential(SARCredentialType type) async {
    try {
      final source = await _showImageSourceDialog();
      if (source == null) return;

      final photoPath = await _identityService.uploadCredentialPhoto(
        credentialType: type,
        source: source,
      );

      // Show credential details dialog
      final credential = await _showCredentialDetailsDialog(type, photoPath);
      if (credential != null) {
        setState(() {
          _credentials.removeWhere((cred) => cred.type == type);
          _credentials.add(credential);
        });
        _showSuccess('Credential uploaded successfully');
      }
    } catch (e) {
      _showError('Failed to upload credential: $e');
    }
  }

  Future<void> _uploadCertification(SARCertificationType type) async {
    try {
      final source = await _showImageSourceDialog();
      if (source == null) return;

      final photoPath = await _identityService.uploadCertificationPhoto(
        certificationType: type,
        source: source,
      );

      // Show certification details dialog
      final certification = await _showCertificationDetailsDialog(
        type,
        photoPath,
      );
      if (certification != null) {
        setState(() {
          _certifications.removeWhere((cert) => cert.type == type);
          _certifications.add(certification);
        });
        _showSuccess('Certification uploaded successfully');
      }
    } catch (e) {
      _showError('Failed to upload certification: $e');
    }
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<SARCredential?> _showCredentialDetailsDialog(
    SARCredentialType type,
    String photoPath,
  ) async {
    final documentController = TextEditingController();
    final authorityController = TextEditingController();
    DateTime? issueDate;
    DateTime? expirationDate;

    return showDialog<SARCredential>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            '${_identityService.getCredentialTypeDisplayName(type)} Details',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Document photo preview
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.neutralGray),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(photoPath), fit: BoxFit.cover),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: documentController,
                  decoration: const InputDecoration(
                    labelText: 'Document Number *',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: authorityController,
                  decoration: const InputDecoration(
                    labelText: 'Issuing Authority *',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                // Issue date
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setDialogState(() => issueDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Issue Date *',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      issueDate != null
                          ? '${issueDate!.day}/${issueDate!.month}/${issueDate!.year}'
                          : 'Select issue date',
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Expiration date
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(
                        const Duration(days: 365),
                      ),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2050),
                    );
                    if (date != null) {
                      setDialogState(() => expirationDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Expiration Date *',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      expirationDate != null
                          ? '${expirationDate!.day}/${expirationDate!.month}/${expirationDate!.year}'
                          : 'Select expiration date',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Delete uploaded photo
                _identityService.deleteCredentialPhoto(photoPath);
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (documentController.text.isNotEmpty &&
                    authorityController.text.isNotEmpty &&
                    issueDate != null &&
                    expirationDate != null) {
                  final credential = SARCredential(
                    id: _generateCredentialId(),
                    type: type,
                    documentNumber: documentController.text.trim(),
                    issuingAuthority: authorityController.text.trim(),
                    issueDate: issueDate!,
                    expirationDate: expirationDate!,
                    photoPath: photoPath,
                    verificationStatus: SARVerificationStatus.pending,
                  );
                  Navigator.pop(context, credential);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<SARCertification?> _showCertificationDetailsDialog(
    SARCertificationType type,
    String photoPath,
  ) async {
    final nameController = TextEditingController();
    final organizationController = TextEditingController();
    final certificateController = TextEditingController();
    DateTime? issueDate;
    DateTime? expirationDate;
    List<String> specializations = [];

    return showDialog<SARCertification>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            '${_identityService.getCertificationTypeDisplayName(type)} Details',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Certificate photo preview
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.neutralGray),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(photoPath), fit: BoxFit.cover),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Certification Name *',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: organizationController,
                  decoration: const InputDecoration(
                    labelText: 'Issuing Organization *',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: certificateController,
                  decoration: const InputDecoration(
                    labelText: 'Certificate Number *',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 12),

                // Issue date
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setDialogState(() => issueDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Issue Date *',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      issueDate != null
                          ? '${issueDate!.day}/${issueDate!.month}/${issueDate!.year}'
                          : 'Select issue date',
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Expiration date (optional)
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(
                        const Duration(days: 365),
                      ),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2050),
                    );
                    setDialogState(() => expirationDate = date);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Expiration Date (Optional)',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      expirationDate != null
                          ? '${expirationDate!.day}/${expirationDate!.month}/${expirationDate!.year}'
                          : 'No expiration',
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Delete uploaded photo
                _identityService.deleteCredentialPhoto(photoPath);
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    organizationController.text.isNotEmpty &&
                    certificateController.text.isNotEmpty &&
                    issueDate != null) {
                  final certification = SARCertification(
                    id: _generateCertificationId(),
                    type: type,
                    certificationName: nameController.text.trim(),
                    issuingOrganization: organizationController.text.trim(),
                    certificateNumber: certificateController.text.trim(),
                    issueDate: issueDate!,
                    expirationDate: expirationDate,
                    photoPath: photoPath,
                    verificationStatus: SARVerificationStatus.pending,
                    specializations: specializations,
                  );
                  Navigator.pop(context, certification);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // Navigation methods
  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
      _tabController.animateTo(_currentStep);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _tabController.animateTo(_currentStep);
    }
  }

  // Date selection
  Future<void> _selectDateOfBirth() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 6570),
      ), // 18 years ago
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 6570)),
    );

    if (date != null) {
      setState(() => _dateOfBirth = date);
    }
  }

  // Form submission
  Future<void> _submitRegistration() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final personalInfo = PersonalInfo(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        dateOfBirth: _dateOfBirth!,
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        zipCode: _zipController.text.trim(),
        country: 'USA', // Default for now
        emergencyContact: _emergencyContactController.text.trim().isNotEmpty
            ? _emergencyContactController.text.trim()
            : null,
        emergencyPhone: _emergencyPhoneController.text.trim().isNotEmpty
            ? _emergencyPhoneController.text.trim()
            : null,
      );

      await _identityService.registerSARMember(
        memberType: _selectedMemberType,
        personalInfo: personalInfo,
        credentials: _credentials,
        certifications: _certifications,
        experience: _experience,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      _showSuccess('SAR registration submitted successfully!');

      // Navigate back after short delay
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showError('Failed to submit registration: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validateForm() {
    // Validate personal info
    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty ||
        _stateController.text.trim().isEmpty ||
        _zipController.text.trim().isEmpty ||
        _dateOfBirth == null) {
      _showError('Please complete all required personal information fields');
      return false;
    }

    // Validate credentials
    if (!_identityService.validateCredentialRequirements(
      _selectedMemberType,
      _credentials,
    )) {
      _showError('Please upload all required credential documents');
      return false;
    }

    // Validate certifications
    final requiredCertifications = _identityService.getRequiredCertifications(
      _selectedMemberType,
    );
    for (final required in requiredCertifications) {
      final hasCertification = _certifications.any(
        (cert) => cert.type == required,
      );
      if (!hasCertification) {
        _showError('Please upload all required training certificates');
        return false;
      }
    }

    // Validate terms acceptance
    if (!_termsAccepted) {
      _showError('Please accept the Terms and Conditions to continue');
      return false;
    }

    return true;
  }

  // Helper methods
  void _editCredential(SARCredential credential) {
    // Implementation for editing existing credential
    _showError('Edit credential functionality coming soon');
  }

  void _editCertification(SARCertification certification) {
    // Implementation for editing existing certification
    _showError('Edit certification functionality coming soon');
  }

  void _showAddCredentialDialog() {
    // Implementation for adding additional credentials
    _showError('Add credential functionality coming soon');
  }

  void _showAddCertificationDialog() {
    // Implementation for adding additional certifications
    _showError('Add certification functionality coming soon');
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

  String _generateCredentialId() {
    return 'CRED_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _generateCertificationId() {
    return 'CERT_${DateTime.now().millisecondsSinceEpoch}';
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

  List<SARCredentialType> _getRequiredCredentialsForType(
    SARMemberType memberType,
  ) {
    switch (memberType) {
      case SARMemberType.volunteer:
        return [
          SARCredentialType.driversLicense,
          SARCredentialType.backgroundCheck,
        ];
      case SARMemberType.professional:
        return [
          SARCredentialType.driversLicense,
          SARCredentialType.professionalLicense,
          SARCredentialType.backgroundCheck,
        ];
      case SARMemberType.emergencyServices:
        return [
          SARCredentialType.governmentId,
          SARCredentialType.professionalLicense,
        ];
      case SARMemberType.medicalPersonnel:
        return [
          SARCredentialType.driversLicense,
          SARCredentialType.professionalLicense,
          SARCredentialType.backgroundCheck,
        ];
      case SARMemberType.teamLeader:
      case SARMemberType.coordinator:
        return [
          SARCredentialType.driversLicense,
          SARCredentialType.professionalLicense,
          SARCredentialType.backgroundCheck,
        ];
    }
  }
}
