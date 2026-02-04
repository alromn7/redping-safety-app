import 'dart:convert';
import 'package:flutter/material.dart';
// Signature package removed in Phase 1 APK optimization - using checkbox acceptance
import '../../../../core/theme/app_theme.dart';
import '../../../../models/volunteer_participation.dart';
import '../../../../models/sar_session.dart';
import '../../../../services/volunteer_rescue_service.dart';

/// Page for joining volunteer rescue missions
class VolunteerMissionPage extends StatefulWidget {
  final String missionId;
  final SARSession? mission;

  const VolunteerMissionPage({
    super.key,
    required this.missionId,
    this.mission,
  });

  @override
  State<VolunteerMissionPage> createState() => _VolunteerMissionPageState();
}

class _VolunteerMissionPageState extends State<VolunteerMissionPage>
    with TickerProviderStateMixin {
  final VolunteerRescueService _volunteerService = VolunteerRescueService();

  late TabController _tabController;
  // Signature controller removed - using checkbox acceptance instead
  bool _hasSignedWaiver = false;

  // Form controllers
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _emergencyRelationshipController = TextEditingController();
  final _notesController = TextEditingController();

  // Form data
  VolunteerRole _selectedRole = VolunteerRole.generalSupport;
  final List<String> _selectedSkills = [];
  final List<String> _selectedEquipment = [];
  bool _hasFirstAid = false;
  bool _hasTransportation = false;
  bool _isLocalResident = false;
  bool _hasAcknowledgedRisks = false;
  bool _confirmedAdult = false;
  bool _confirmedPhysical = false;
  bool _confirmedInsurance = false;
  bool _confirmedEmergencyContact = false;

  bool _isLoading = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Signature controller removed - using checkbox
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _emergencyRelationshipController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _initializeService() async {
    setState(() => _isLoading = true);

    try {
      await _volunteerService.initialize();
    } catch (e) {
      _showError('Failed to initialize volunteer service: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Volunteer Rescue Mission'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Role & Skills', icon: Icon(Icons.person)),
            Tab(text: 'Risk Waiver', icon: Icon(Icons.warning)),
            Tab(text: 'Signature', icon: Icon(Icons.draw)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Mission info banner
                _buildMissionInfoBanner(),

                // Tab content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRoleAndSkillsTab(),
                      _buildRiskWaiverTab(),
                      _buildSignatureTab(),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _buildNavigationBar(),
    );
  }

  Widget _buildMissionInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppTheme.warningOrange,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.warning, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'VOLUNTEER RESCUE MISSION',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Mission ID: ${widget.missionId}',
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          ),
          if (widget.mission != null)
            Text(
              widget.mission!.description ?? 'Emergency rescue operation',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
        ],
      ),
    );
  }

  Widget _buildRoleAndSkillsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role selection
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Volunteer Role',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<VolunteerRole>(
                    initialValue: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Select your role',
                      border: OutlineInputBorder(),
                    ),
                    items: _volunteerService.getAvailableRoles().map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_volunteerService.getRoleDisplayName(role)),
                            Text(
                              _volunteerService.getRoleDescription(role),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (role) {
                      if (role != null) {
                        setState(() => _selectedRole = role);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Skills and capabilities
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Skills & Capabilities',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Capability checkboxes
                  CheckboxListTile(
                    title: const Text('First Aid Training'),
                    subtitle: const Text('CPR, basic medical assistance'),
                    value: _hasFirstAid,
                    onChanged: (value) =>
                        setState(() => _hasFirstAid = value ?? false),
                  ),

                  CheckboxListTile(
                    title: const Text('Transportation Available'),
                    subtitle: const Text('Can transport people/equipment'),
                    value: _hasTransportation,
                    onChanged: (value) =>
                        setState(() => _hasTransportation = value ?? false),
                  ),

                  CheckboxListTile(
                    title: const Text('Local Area Resident'),
                    subtitle: const Text('Familiar with local terrain/roads'),
                    value: _isLocalResident,
                    onChanged: (value) =>
                        setState(() => _isLocalResident = value ?? false),
                  ),

                  const SizedBox(height: 16),

                  // Skills selection
                  const Text(
                    'Additional Skills',
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
                    children: _getAvailableSkills().map((skill) {
                      final isSelected = _selectedSkills.contains(skill);
                      return FilterChip(
                        selected: isSelected,
                        label: Text(skill),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedSkills.add(skill);
                            } else {
                              _selectedSkills.remove(skill);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Equipment selection
                  const Text(
                    'Available Equipment',
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
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Emergency contact
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Emergency Contact (Required)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.criticalRed,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emergencyNameController,
                    decoration: const InputDecoration(
                      labelText: 'Emergency Contact Name *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _emergencyPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Emergency Contact Phone *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _emergencyRelationshipController,
                    decoration: const InputDecoration(
                      labelText: 'Relationship *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.family_restroom),
                    ),
                    textCapitalization: TextCapitalization.words,
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
                      labelText: 'Additional skills, experience, or notes',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
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

  Widget _buildRiskWaiverTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Warning header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.criticalRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.criticalRed),
            ),
            child: const Column(
              children: [
                Icon(Icons.warning, color: AppTheme.criticalRed, size: 32),
                SizedBox(height: 8),
                Text(
                  'VOLUNTEER RESCUE PARTICIPATION',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.criticalRed,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'ASSUMPTION OF RISK AND RELEASE OF LIABILITY',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.criticalRed,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Risk acknowledgment text
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Please read and acknowledge the following risks:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'By participating as a volunteer in this rescue mission, I understand and acknowledge that:',
                    style: TextStyle(fontSize: 14, color: AppTheme.primaryText),
                  ),
                  const SizedBox(height: 8),

                  ..._volunteerService.getStandardRisks().map(
                    (risk) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(
                              color: AppTheme.criticalRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              risk,
                              style: const TextStyle(
                                fontSize: 13,
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
            ),
          ),

          const SizedBox(height: 16),

          // Confirmations
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Required Confirmations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),

                  CheckboxListTile(
                    title: const Text('I am 18 years of age or older'),
                    value: _confirmedAdult,
                    onChanged: (value) =>
                        setState(() => _confirmedAdult = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),

                  CheckboxListTile(
                    title: const Text(
                      'I am physically capable of participating',
                    ),
                    subtitle: const Text(
                      'I have no medical conditions that would prevent safe participation',
                    ),
                    value: _confirmedPhysical,
                    onChanged: (value) =>
                        setState(() => _confirmedPhysical = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),

                  CheckboxListTile(
                    title: const Text('I understand insurance limitations'),
                    subtitle: const Text(
                      'I understand that my personal insurance may not cover volunteer rescue activities',
                    ),
                    value: _confirmedInsurance,
                    onChanged: (value) =>
                        setState(() => _confirmedInsurance = value ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),

                  CheckboxListTile(
                    title: const Text(
                      'I have provided valid emergency contact',
                    ),
                    subtitle: const Text(
                      'My emergency contact can be reached immediately if needed',
                    ),
                    value: _confirmedEmergencyContact,
                    onChanged: (value) => setState(
                      () => _confirmedEmergencyContact = value ?? false,
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Final risk acknowledgment
          Card(
            color: AppTheme.criticalRed.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: CheckboxListTile(
                title: const Text(
                  'I ACKNOWLEDGE ALL RISKS AND PARTICIPATE AT MY OWN RISK',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.criticalRed,
                  ),
                ),
                subtitle: const Text(
                  'I voluntarily assume all risks associated with rescue mission participation and release REDP!NG and all rescue organizations from liability.',
                  style: TextStyle(fontSize: 12),
                ),
                value: _hasAcknowledgedRisks,
                onChanged: (value) =>
                    setState(() => _hasAcknowledgedRisks = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppTheme.criticalRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Signature instructions
          Card(
            color: AppTheme.infoBlue.withValues(alpha: 0.1),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.draw, color: AppTheme.infoBlue),
                      SizedBox(width: 8),
                      Text(
                        'Digital Signature Required',
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
                    'Please sign below to confirm your voluntary participation and risk acknowledgment. Your signature indicates that you have read, understood, and agree to all terms.',
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

          // Signature pad
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Digital Signature',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Signature pad removed in Phase 1 APK optimization
                  // Using checkbox acceptance for liability waiver
                  CheckboxListTile(
                    value: _hasSignedWaiver,
                    onChanged: (value) {
                      setState(() => _hasSignedWaiver = value ?? false);
                    },
                    title: const Text(
                      'I have read and accept the liability waiver',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'By checking this box, I acknowledge that I have read, '
                      'understood, and agree to the terms of the volunteer '
                      'liability waiver.',
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Legal disclaimer
          Card(
            color: AppTheme.neutralGray.withValues(alpha: 0.1),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Legal Disclaimer',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This digital signature constitutes a legally binding agreement. By signing, you acknowledge that you have read, understood, and voluntarily agree to participate in rescue operations at your own risk. You release REDP!NG, rescue organizations, and all personnel from any liability for injuries or damages that may occur during your voluntary participation.',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.secondaryText,
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
              onPressed: _currentStep < 2
                  ? _nextStep
                  : _canSubmit()
                  ? _submitVolunteerRegistration
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentStep < 2
                    ? AppTheme.infoBlue
                    : _canSubmit()
                    ? AppTheme.safeGreen
                    : AppTheme.neutralGray,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(_currentStep < 2 ? 'Next' : 'Join Mission'),
            ),
          ),
        ],
      ),
    );
  }

  // Navigation methods
  void _nextStep() {
    if (_currentStep < 2) {
      if (_currentStep == 0 && !_validateRoleAndSkills()) return;
      if (_currentStep == 1 && !_validateRiskAcknowledgment()) return;

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

  // Validation methods
  bool _validateRoleAndSkills() {
    if (_emergencyNameController.text.trim().isEmpty ||
        _emergencyPhoneController.text.trim().isEmpty ||
        _emergencyRelationshipController.text.trim().isEmpty) {
      _showError('Please provide emergency contact information');
      return false;
    }
    return true;
  }

  bool _validateRiskAcknowledgment() {
    if (!_confirmedAdult ||
        !_confirmedPhysical ||
        !_confirmedInsurance ||
        !_confirmedEmergencyContact ||
        !_hasAcknowledgedRisks) {
      _showError('Please confirm all required acknowledgments');
      return false;
    }
    return true;
  }

  bool _canSubmit() {
    return _validateRoleAndSkills() &&
        _validateRiskAcknowledgment() &&
        _hasSignedWaiver;
  }

  // Form submission
  Future<void> _submitVolunteerRegistration() async {
    if (!_canSubmit()) return;

    setState(() => _isLoading = true);

    try {
      // Create emergency contact
      final emergencyContact = EmergencyContact(
        name: _emergencyNameController.text.trim(),
        phone: _emergencyPhoneController.text.trim(),
        relationship: _emergencyRelationshipController.text.trim(),
      );

      // Signature removed - using checkbox acceptance timestamp
      final acceptanceTimestamp = DateTime.now().toIso8601String();
      final signatureBase64 = base64Encode(acceptanceTimestamp.codeUnits);

      // Acknowledge risks first (with checkbox acceptance instead of signature)
      await _volunteerService.acknowledgeRisks(
        missionId: widget.missionId,
        digitalSignature: signatureBase64,
      );

      // Join the mission
      final participation = await _volunteerService.joinVolunteerMission(
        missionId: widget.missionId,
        role: _selectedRole,
        skills: _selectedSkills,
        equipment: _selectedEquipment,
        hasFirstAid: _hasFirstAid,
        hasTransportation: _hasTransportation,
        isLocalResident: _isLocalResident,
        emergencyContact: emergencyContact,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      _showSuccess('Successfully joined volunteer rescue mission!');

      // Navigate back after short delay
      // ignore: use_build_context_synchronously
      final navigator = Navigator.of(context);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        navigator.pop(participation);
      }
    } catch (e) {
      _showError('Failed to join mission: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Signature preview removed in Phase 1 APK optimization
  // Using checkbox acceptance instead of digital signature

  // Helper methods
  List<String> _getAvailableSkills() {
    return [
      'Basic First Aid',
      'CPR Certified',
      'Local Area Knowledge',
      'Outdoor Experience',
      'Communication Skills',
      'Physical Fitness',
      'Team Coordination',
      'Equipment Operation',
      'Navigation Skills',
      'Emergency Response',
      'Crowd Management',
      'Language Skills',
      'Technical Skills',
      'Medical Background',
      'Military/Police Experience',
    ];
  }

  List<String> _getAvailableEquipment() {
    return [
      'Vehicle (Car/Truck)',
      'ATV/Off-road Vehicle',
      'Boat/Watercraft',
      'First Aid Kit',
      'Flashlights/Headlamps',
      'Two-way Radios',
      'GPS Device',
      'Rope/Climbing Gear',
      'Tools (Shovels, etc.)',
      'Blankets/Tarps',
      'Food/Water Supplies',
      'Generator/Power Source',
      'Camping Equipment',
      'Photography Equipment',
      'Specialized Tools',
    ];
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
