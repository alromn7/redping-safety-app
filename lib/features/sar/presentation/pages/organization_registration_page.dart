// ignore_for_file: unused_field
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../models/sar_organization.dart';
import '../../../../models/sar_identity.dart';
import '../../../../services/sar_organization_service.dart';
import '../../../../services/app_service_manager.dart';

/// Page for registering SAR organizations
class OrganizationRegistrationPage extends StatefulWidget {
  const OrganizationRegistrationPage({super.key});

  @override
  State<OrganizationRegistrationPage> createState() =>
      _OrganizationRegistrationPageState();
}

class _OrganizationRegistrationPageState
    extends State<OrganizationRegistrationPage>
    with TickerProviderStateMixin {
  final AppServiceManager _serviceManager = AppServiceManager();
  final SAROrganizationService _organizationService = SAROrganizationService();

  late TabController _tabController;
  final PageController _pageController = PageController();

  // Form controllers
  final _organizationNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _legalNameController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _primaryPhoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactTitleController = TextEditingController();
  final _notesController = TextEditingController();

  // Form data
  SAROrganizationType _selectedType = SAROrganizationType.volunteerNonprofit;
  SARLegalStatus _selectedLegalStatus = SARLegalStatus.nonprofit501c3;
  int _foundedYear = DateTime.now().year;
  int _estimatedMembers = 1;
  final List<SARSpecialization> _selectedSpecializations = [];
  final List<String> _selectedEquipment = [];
  final List<String> _selectedVehicles = [];
  final List<String> _serviceAreas = [];
  bool _has24x7Availability = false;
  int _maxDeployment = 5;
  int _averageResponseTime = 30;
  bool _hasTrainingPrograms = false;
  bool _providesEducation = false;
  bool _hasInsurance = false;

  final List<SAROrganizationCredential> _credentials = [];
  final List<SAROrganizationCertification> _certifications = [];

  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _organizationNameController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _legalNameController.dispose();
    _registrationNumberController.dispose();
    _taxIdController.dispose();
    _primaryPhoneController.dispose();
    _emailController.dispose();
    _contactNameController.dispose();
    _contactTitleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _initializeService() async {
    setState(() => _isLoading = true);

    try {
      await _organizationService.initialize();
    } catch (e) {
      _showError('Failed to initialize organization service: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register SAR Organization'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Basic Info', icon: Icon(Icons.business)),
            Tab(text: 'Legal Info', icon: Icon(Icons.gavel)),
            Tab(text: 'Capabilities', icon: Icon(Icons.build)),
            Tab(text: 'Documents', icon: Icon(Icons.upload_file)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Registration warning banner
                _buildRegistrationWarningBanner(),

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBasicInfoTab(),
                      _buildLegalInfoTab(),
                      _buildCapabilitiesTab(),
                      _buildDocumentsTab(),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _buildNavigationBar(),
    );
  }

  Widget _buildRegistrationWarningBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.infoBlue,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: const Column(
        children: [
          Row(
            children: [
              Icon(Icons.business, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'SAR ORGANIZATION REGISTRATION',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'Register your organization to manage members and coordinate rescue operations',
            style: TextStyle(fontSize: 12, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Organization type
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Organization Type',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<SAROrganizationType>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Select organization type',
                      border: OutlineInputBorder(),
                    ),
                    items: SAROrganizationType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(
                          _organizationService.getOrganizationTypeDisplayName(
                            type,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (type) {
                      if (type != null) {
                        setState(() => _selectedType = type);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Basic information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Organization Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _organizationNameController,
                    decoration: const InputDecoration(
                      labelText: 'Organization Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description *',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _websiteController,
                    decoration: const InputDecoration(
                      labelText: 'Website',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.web),
                    ),
                    keyboardType: TextInputType.url,
                  ),

                  const SizedBox(height: 16),

                  // Founded year and member count
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _foundedYear.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Founded Year',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final year = int.tryParse(value);
                            if (year != null) _foundedYear = year;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: _estimatedMembers.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Estimated Members',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final members = int.tryParse(value);
                            if (members != null) _estimatedMembers = members;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Address information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Address Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Street Address *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    textCapitalization: TextCapitalization.words,
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
                          textCapitalization: TextCapitalization.words,
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
                          textCapitalization: TextCapitalization.characters,
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
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Contact information
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _primaryPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Primary Phone *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Primary Email *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _contactNameController,
                    decoration: const InputDecoration(
                      labelText: 'Primary Contact Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _contactTitleController,
                    decoration: const InputDecoration(
                      labelText: 'Contact Title *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.work),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legal status
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Legal Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<SARLegalStatus>(
                    initialValue: _selectedLegalStatus,
                    decoration: const InputDecoration(
                      labelText: 'Legal status',
                      border: OutlineInputBorder(),
                    ),
                    items: SARLegalStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(_getLegalStatusDisplayName(status)),
                      );
                    }).toList(),
                    onChanged: (status) {
                      if (status != null) {
                        setState(() => _selectedLegalStatus = status);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Legal details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Legal Documentation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _legalNameController,
                    decoration: const InputDecoration(
                      labelText: 'Legal Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _registrationNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Registration Number *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.numbers),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _taxIdController,
                    decoration: const InputDecoration(
                      labelText: 'Tax ID / EIN *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.receipt),
                    ),
                  ),

                  const SizedBox(height: 16),

                  CheckboxListTile(
                    title: const Text('Has Liability Insurance'),
                    subtitle: const Text(
                      'Organization carries liability insurance for rescue operations',
                    ),
                    value: _hasInsurance,
                    onChanged: (value) =>
                        setState(() => _hasInsurance = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilitiesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Specializations
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Primary Specializations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SARSpecialization.values.map((specialization) {
                      final isSelected = _selectedSpecializations.contains(
                        specialization,
                      );
                      return FilterChip(
                        selected: isSelected,
                        label: Text(
                          _getSpecializationDisplayName(specialization),
                        ),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedSpecializations.add(specialization);
                            } else {
                              _selectedSpecializations.remove(specialization);
                            }
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

          // Operational capabilities
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Operational Capabilities',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 16),

                  CheckboxListTile(
                    title: const Text('24/7 Availability'),
                    subtitle: const Text(
                      'Organization can respond at any time',
                    ),
                    value: _has24x7Availability,
                    onChanged: (value) =>
                        setState(() => _has24x7Availability = value ?? false),
                  ),

                  CheckboxListTile(
                    title: const Text('Training Programs'),
                    subtitle: const Text('Organization provides SAR training'),
                    value: _hasTrainingPrograms,
                    onChanged: (value) =>
                        setState(() => _hasTrainingPrograms = value ?? false),
                  ),

                  CheckboxListTile(
                    title: const Text('Public Education'),
                    subtitle: const Text(
                      'Organization provides public safety education',
                    ),
                    value: _providesEducation,
                    onChanged: (value) =>
                        setState(() => _providesEducation = value ?? false),
                  ),

                  const SizedBox(height: 16),

                  // Deployment capacity
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _maxDeployment.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Max Deployment',
                            border: OutlineInputBorder(),
                            suffixText: 'members',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final deployment = int.tryParse(value);
                            if (deployment != null) _maxDeployment = deployment;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          initialValue: _averageResponseTime.toString(),
                          decoration: const InputDecoration(
                            labelText: 'Response Time',
                            border: OutlineInputBorder(),
                            suffixText: 'minutes',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            final time = int.tryParse(value);
                            if (time != null) _averageResponseTime = time;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Equipment and vehicles
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Equipment & Vehicles',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'Available Equipment:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _getAvailableEquipment().map((equipment) {
                      final isSelected = _selectedEquipment.contains(equipment);
                      return FilterChip(
                        selected: isSelected,
                        label: Text(equipment),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedEquipment.add(equipment);
                            } else {
                              _selectedEquipment.remove(equipment);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Available Vehicles:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _getAvailableVehicles().map((vehicle) {
                      final isSelected = _selectedVehicles.contains(vehicle);
                      return FilterChip(
                        selected: isSelected,
                        label: Text(vehicle),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedVehicles.add(vehicle);
                            } else {
                              _selectedVehicles.remove(vehicle);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Required documents info
          Card(
            color: AppTheme.infoBlue.withValues(alpha: 0.1),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: AppTheme.infoBlue),
                      SizedBox(width: 8),
                      Text(
                        'Required Documents',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.infoBlue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please upload the required legal documents and certifications for your organization type. All documents will be reviewed by SAR administrators.',
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

          // Credentials section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Legal Documents',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addCredentialDocument,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Document'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.infoBlue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_credentials.isEmpty)
                    const Center(
                      child: Text(
                        'No documents uploaded yet',
                        style: TextStyle(color: AppTheme.secondaryText),
                      ),
                    )
                  else
                    ..._credentials.map(
                      (credential) => _buildCredentialCard(credential),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Certifications section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Certifications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addCertificationDocument,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Certificate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.safeGreen,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_certifications.isEmpty)
                    const Center(
                      child: Text(
                        'No certifications uploaded yet',
                        style: TextStyle(color: AppTheme.secondaryText),
                      ),
                    )
                  else
                    ..._certifications.map(
                      (cert) => _buildCertificationCard(cert),
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
                      labelText:
                          'Additional notes, partnerships, or special capabilities',
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

  Widget _buildCredentialCard(SAROrganizationCredential credential) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.description, color: AppTheme.infoBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    credential.documentName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Type: ${_getCredentialTypeDisplayName(credential.type)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _removeCredential(credential),
              icon: const Icon(Icons.delete, color: AppTheme.criticalRed),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertificationCard(SAROrganizationCertification certification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.verified, color: AppTheme.safeGreen),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    certification.certificationName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Type: ${_getCertificationTypeDisplayName(certification.type)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _removeCertification(certification),
              icon: const Icon(Icons.delete, color: AppTheme.criticalRed),
            ),
          ],
        ),
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
              onPressed: _currentStep < 3
                  ? _nextStep
                  : _canSubmit()
                  ? _submitRegistration
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentStep < 3
                    ? AppTheme.infoBlue
                    : _canSubmit()
                    ? AppTheme.safeGreen
                    : AppTheme.neutralGray,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_currentStep < 3 ? 'Next' : 'Register Organization'),
            ),
          ),
        ],
      ),
    );
  }

  // Navigation and validation methods
  void _nextStep() {
    if (_currentStep < 3) {
      if (_currentStep == 0 && !_validateBasicInfo()) return;
      if (_currentStep == 1 && !_validateLegalInfo()) return;
      if (_currentStep == 2 && !_validateCapabilities()) return;

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

  bool _validateBasicInfo() {
    if (_organizationNameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty ||
        _stateController.text.trim().isEmpty ||
        _zipController.text.trim().isEmpty ||
        _primaryPhoneController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _contactNameController.text.trim().isEmpty ||
        _contactTitleController.text.trim().isEmpty) {
      _showError('Please fill in all required basic information fields');
      return false;
    }
    return true;
  }

  bool _validateLegalInfo() {
    if (_legalNameController.text.trim().isEmpty ||
        _registrationNumberController.text.trim().isEmpty ||
        _taxIdController.text.trim().isEmpty) {
      _showError('Please fill in all required legal information fields');
      return false;
    }
    return true;
  }

  bool _validateCapabilities() {
    if (_selectedSpecializations.isEmpty) {
      _showError('Please select at least one specialization');
      return false;
    }
    return true;
  }

  bool _canSubmit() {
    return _validateBasicInfo() &&
        _validateLegalInfo() &&
        _validateCapabilities();
  }

  // Document management methods
  Future<void> _addCredentialDocument() async {
    // Show credential type selection
    final credentialType = await _showCredentialTypeDialog();
    if (credentialType == null) return;

    // Pick image
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      // Upload document
      final photoPath = await _organizationService.uploadCredentialDocument(
        credentialType: credentialType,
        photoFile: image,
      );

      // Show document details dialog
      final credential = await _showCredentialDetailsDialog(
        credentialType,
        photoPath,
      );
      if (credential != null) {
        setState(() {
          _credentials.add(credential);
        });
      }
    } catch (e) {
      _showError('Failed to upload credential document: $e');
    }
  }

  Future<void> _addCertificationDocument() async {
    // Show certification type selection
    final certificationType = await _showCertificationTypeDialog();
    if (certificationType == null) return;

    // Pick image
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      // Upload document
      final photoPath = await _organizationService.uploadCertificationDocument(
        certificationType: certificationType,
        photoFile: image,
      );

      // Show document details dialog
      final certification = await _showCertificationDetailsDialog(
        certificationType,
        photoPath,
      );
      if (certification != null) {
        setState(() {
          _certifications.add(certification);
        });
      }
    } catch (e) {
      _showError('Failed to upload certification document: $e');
    }
  }

  void _removeCredential(SAROrganizationCredential credential) {
    setState(() {
      _credentials.remove(credential);
    });
  }

  void _removeCertification(SAROrganizationCertification certification) {
    setState(() {
      _certifications.remove(certification);
    });
  }

  // Dialog methods
  Future<SAROrganizationCredentialType?> _showCredentialTypeDialog() async {
    return showDialog<SAROrganizationCredentialType>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Document Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: SAROrganizationCredentialType.values.map((type) {
            return ListTile(
              title: Text(_getCredentialTypeDisplayName(type)),
              onTap: () => Navigator.pop(context, type),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<SAROrganizationCertificationType?>
  _showCertificationTypeDialog() async {
    return showDialog<SAROrganizationCertificationType>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Certification Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: SAROrganizationCertificationType.values.map((type) {
            return ListTile(
              title: Text(_getCertificationTypeDisplayName(type)),
              onTap: () => Navigator.pop(context, type),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<SAROrganizationCredential?> _showCredentialDetailsDialog(
    SAROrganizationCredentialType type,
    String photoPath,
  ) async {
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    final authorityController = TextEditingController();
    DateTime? issueDate;
    DateTime? expirationDate;

    return showDialog<SAROrganizationCredential>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${_getCredentialTypeDisplayName(type)} Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Document Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: numberController,
                  decoration: const InputDecoration(
                    labelText: 'Document Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: authorityController,
                  decoration: const InputDecoration(
                    labelText: 'Issuing Authority',
                    border: OutlineInputBorder(),
                  ),
                ),
                // Add date pickers for issue and expiration dates
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
                final hasText =
                    nameController.text.isNotEmpty &&
                    numberController.text.isNotEmpty &&
                    authorityController.text.isNotEmpty;
                final hasDates =
                    issueDate is DateTime && expirationDate is DateTime;
                final valid = hasText && hasDates;
                if (valid) {
                  final credential = SAROrganizationCredential(
                    id: 'CRED_${DateTime.now().millisecondsSinceEpoch}',
                    type: type,
                    documentName: nameController.text.trim(),
                    documentNumber: numberController.text.trim(),
                    issueDate: issueDate,
                    expirationDate: expirationDate,
                    issuingAuthority: authorityController.text.trim(),
                    documentPath: photoPath,
                  );
                  Navigator.pop(context, credential);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<SAROrganizationCertification?> _showCertificationDetailsDialog(
    SAROrganizationCertificationType type,
    String photoPath,
  ) async {
    final nameController = TextEditingController();
    final numberController = TextEditingController();
    final bodyController = TextEditingController();
    DateTime? issueDate;
    DateTime? expirationDate;

    return showDialog<SAROrganizationCertification>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${_getCertificationTypeDisplayName(type)} Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Certification Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: numberController,
                  decoration: const InputDecoration(
                    labelText: 'Certificate Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: bodyController,
                  decoration: const InputDecoration(
                    labelText: 'Issuing Body',
                    border: OutlineInputBorder(),
                  ),
                ),
                // Add date pickers for issue and expiration dates
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
                final hasText =
                    nameController.text.isNotEmpty &&
                    numberController.text.isNotEmpty &&
                    bodyController.text.isNotEmpty;
                final hasIssueDate = issueDate is DateTime;
                final valid = hasText && hasIssueDate;
                if (valid) {
                  final certification = SAROrganizationCertification(
                    id: 'CERT_${DateTime.now().millisecondsSinceEpoch}',
                    type: type,
                    certificationName: nameController.text.trim(),
                    certificateNumber: numberController.text.trim(),
                    issueDate: issueDate,
                    expirationDate: expirationDate,
                    issuingBody: bodyController.text.trim(),
                    documentPath: photoPath,
                  );
                  Navigator.pop(context, certification);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // Form submission
  Future<void> _submitRegistration() async {
    if (!_canSubmit()) return;

    setState(() => _isLoading = true);

    try {
      // Create organization info
      final organizationInfo = SAROrganizationInfo(
        description: _descriptionController.text.trim(),
        website: _websiteController.text.trim(),
        foundedYear: _foundedYear,
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        zipCode: _zipController.text.trim(),
        country: 'USA',
        primaryLanguage: 'English',
        serviceAreas: _serviceAreas,
        estimatedMemberCount: _estimatedMembers,
        specializations: _selectedSpecializations,
      );

      // Create legal info
      final legalInfo = SARLegalInfo(
        legalName: _legalNameController.text.trim(),
        registrationNumber: _registrationNumberController.text.trim(),
        taxId: _taxIdController.text.trim(),
        legalStatus: _selectedLegalStatus,
        jurisdiction: _stateController.text.trim(),
        licenses: [],
        accreditations: [],
        hasInsurance: _hasInsurance,
      );

      // Create contact info
      final contactInfo = SARContactInfo(
        primaryPhone: _primaryPhoneController.text.trim(),
        email: _emailController.text.trim(),
        primaryContactName: _contactNameController.text.trim(),
        primaryContactTitle: _contactTitleController.text.trim(),
        communicationChannels: ['Phone', 'Email'],
      );

      // Create capabilities
      final capabilities = SARCapabilities(
        primarySpecializations: _selectedSpecializations,
        equipment: _selectedEquipment,
        vehicles: _selectedVehicles,
        has24x7Availability: _has24x7Availability,
        maxMemberDeployment: _maxDeployment,
        responseAreas: _serviceAreas,
        averageResponseTime: _averageResponseTime,
        hasTrainingPrograms: _hasTrainingPrograms,
        providesPublicEducation: _providesEducation,
        partnerships: [],
      );

      // Register organization
      await _organizationService.registerOrganization(
        organizationName: _organizationNameController.text.trim(),
        type: _selectedType,
        organizationInfo: organizationInfo,
        legalInfo: legalInfo,
        contactInfo: contactInfo,
        capabilities: capabilities,
        credentials: _credentials,
        certifications: _certifications,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      _showSuccess('Organization registration submitted successfully!');

      // Navigate back after short delay
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        context.go('/sar');
      }
    } catch (e) {
      _showError('Failed to register organization: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Helper methods
  List<String> _getAvailableEquipment() {
    return [
      'Rescue Ropes',
      'Medical Equipment',
      'Communication Radios',
      'GPS Devices',
      'Night Vision',
      'Thermal Imaging',
      'Drones/UAVs',
      'Search Dogs',
      'Climbing Gear',
      'Water Rescue Equipment',
      'Cave Rescue Equipment',
      'Emergency Shelters',
      'Power Equipment',
      'Specialized Tools',
    ];
  }

  List<String> _getAvailableVehicles() {
    return [
      'Emergency Response Vehicle',
      'All-Terrain Vehicle (ATV)',
      'Helicopter',
      'Boat/Watercraft',
      'Mobile Command Unit',
      'Ambulance',
      'Fire Truck',
      'Specialized Rescue Vehicle',
      'Drone/UAV',
      'Snowmobile',
      'Aircraft',
    ];
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

  String _getLegalStatusDisplayName(SARLegalStatus status) {
    switch (status) {
      case SARLegalStatus.nonprofit501c3:
        return '501(c)(3) Nonprofit';
      case SARLegalStatus.governmentEntity:
        return 'Government Entity';
      case SARLegalStatus.privateCorporation:
        return 'Private Corporation';
      case SARLegalStatus.partnership:
        return 'Partnership';
      case SARLegalStatus.soleProprietorship:
        return 'Sole Proprietorship';
      case SARLegalStatus.cooperative:
        return 'Cooperative';
    }
  }

  String _getCredentialTypeDisplayName(SAROrganizationCredentialType type) {
    switch (type) {
      case SAROrganizationCredentialType.businessLicense:
        return 'Business License';
      case SAROrganizationCredentialType.nonprofitRegistration:
        return 'Nonprofit Registration';
      case SAROrganizationCredentialType.taxExemption:
        return 'Tax Exemption';
      case SAROrganizationCredentialType.insuranceCertificate:
        return 'Insurance Certificate';
      case SAROrganizationCredentialType.governmentAuthorization:
        return 'Government Authorization';
      case SAROrganizationCredentialType.accreditation:
        return 'Accreditation';
    }
  }

  String _getCertificationTypeDisplayName(
    SAROrganizationCertificationType type,
  ) {
    switch (type) {
      case SAROrganizationCertificationType.sarAccreditation:
        return 'SAR Accreditation';
      case SAROrganizationCertificationType.trainingCertification:
        return 'Training Certification';
      case SAROrganizationCertificationType.safetyCertification:
        return 'Safety Certification';
      case SAROrganizationCertificationType.qualityManagement:
        return 'Quality Management';
      case SAROrganizationCertificationType.internationalStandard:
        return 'International Standard';
      case SAROrganizationCertificationType.governmentCertification:
        return 'Government Certification';
    }
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
