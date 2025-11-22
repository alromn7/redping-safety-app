import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/sar_identity.dart';
import 'user_profile_service.dart';
import 'notification_service.dart';

/// Service for managing SAR member identity and credentials
class SARIdentityService {
  static final SARIdentityService _instance = SARIdentityService._internal();
  factory SARIdentityService() => _instance;
  SARIdentityService._internal();

  final UserProfileService _userProfileService = UserProfileService();
  final NotificationService _notificationService = NotificationService();
  final ImagePicker _imagePicker = ImagePicker();

  List<SARIdentity> _registeredMembers = [];
  SARIdentity? _currentUserIdentity;
  bool _isInitialized = false;

  // Callbacks
  Function(SARIdentity)? _onIdentityRegistered;
  Function(SARIdentity)? _onIdentityVerified;
  Function(SARIdentity)? _onIdentityUpdated;
  Function(List<SARIdentity>)? _onMembersUpdated;

  /// Initialize the SAR identity service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadRegisteredMembers();
      await _loadCurrentUserIdentity();

      // Create demo SAR member for testing if none exists
      await _createDemoSARMemberIfNeeded();

      _isInitialized = true;
      debugPrint('SARIdentityService: Initialized successfully');
    } catch (e) {
      debugPrint('SARIdentityService: Initialization error - $e');
      throw Exception('Failed to initialize SAR identity service: $e');
    }
  }

  /// Create demo SAR member for testing purposes
  Future<void> _createDemoSARMemberIfNeeded() async {
    // For production release, do not create demo SAR members
    // All SAR members must register through proper verification process
    // Demo SAR member creation disabled for production
  }

  /// Register new SAR member
  Future<SARIdentity> registerSARMember({
    required SARMemberType memberType,
    required PersonalInfo personalInfo,
    required List<SARCredential> credentials,
    required List<SARCertification> certifications,
    required SARExperience experience,
    String? notes,
  }) async {
    try {
      final userProfile = _userProfileService.currentProfile;
      if (userProfile == null) {
        throw Exception('User profile required for SAR registration');
      }

      // Create new SAR identity
      final identity = SARIdentity(
        id: _generateIdentityId(),
        userId: userProfile.id,
        memberType: memberType,
        verificationStatus: SARVerificationStatus.pending,
        personalInfo: personalInfo,
        credentials: credentials,
        certifications: certifications,
        experience: experience,
        registrationDate: DateTime.now(),
        photoIds: [],
        notes: notes,
      );

      // Add to registered members
      _registeredMembers.add(identity);
      _currentUserIdentity = identity;

      // Save to storage
      await _saveRegisteredMembers();
      await _saveCurrentUserIdentity();

      // Notify callbacks
      _onIdentityRegistered?.call(identity);
      _onMembersUpdated?.call(_registeredMembers);

      // Show notification
      await _notificationService.showNotification(
        title: '✅ SAR Registration Submitted',
        body: 'Your SAR member registration is pending verification.',
        importance: NotificationImportance.high,
      );

      debugPrint('SARIdentityService: Member registered - ${identity.id}');
      return identity;
    } catch (e) {
      debugPrint('SARIdentityService: Error registering member - $e');
      rethrow;
    }
  }

  /// Upload credential photo
  Future<String> uploadCredentialPhoto({
    required SARCredentialType credentialType,
    required ImageSource source,
  }) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image == null) {
        throw Exception('No image selected');
      }

      // Create unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'SAR_${credentialType.name}_$timestamp.jpg';

      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final credentialsDir = Directory('${directory.path}/sar_credentials');
      if (!await credentialsDir.exists()) {
        await credentialsDir.create(recursive: true);
      }

      // Save image
      final savedPath = '${credentialsDir.path}/$filename';
      await File(image.path).copy(savedPath);

      debugPrint('SARIdentityService: Credential photo saved - $savedPath');
      return savedPath;
    } catch (e) {
      debugPrint('SARIdentityService: Error uploading credential photo - $e');
      rethrow;
    }
  }

  /// Upload certification photo
  Future<String> uploadCertificationPhoto({
    required SARCertificationType certificationType,
    required ImageSource source,
  }) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image == null) {
        throw Exception('No image selected');
      }

      // Create unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'SAR_CERT_${certificationType.name}_$timestamp.jpg';

      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final certificationsDir = Directory(
        '${directory.path}/sar_certifications',
      );
      if (!await certificationsDir.exists()) {
        await certificationsDir.create(recursive: true);
      }

      // Save image
      final savedPath = '${certificationsDir.path}/$filename';
      await File(image.path).copy(savedPath);

      debugPrint('SARIdentityService: Certification photo saved - $savedPath');
      return savedPath;
    } catch (e) {
      debugPrint(
        'SARIdentityService: Error uploading certification photo - $e',
      );
      rethrow;
    }
  }

  /// Verify SAR member identity
  Future<void> verifyMemberIdentity({
    required String identityId,
    required String verifiedBy,
    bool approved = true,
    String? notes,
  }) async {
    try {
      final memberIndex = _registeredMembers.indexWhere(
        (m) => m.id == identityId,
      );
      if (memberIndex == -1) {
        throw Exception('SAR member not found');
      }

      final member = _registeredMembers[memberIndex];
      final updatedMember = member.copyWith(
        verificationStatus: approved
            ? SARVerificationStatus.verified
            : SARVerificationStatus.rejected,
        verificationDate: DateTime.now(),
        verifiedBy: verifiedBy,
        notes: notes,
        expirationDate: approved
            ? DateTime.now().add(const Duration(days: 365)) // 1 year validity
            : null,
      );

      _registeredMembers[memberIndex] = updatedMember;

      // Update current user identity if it's their registration
      if (_currentUserIdentity?.id == identityId) {
        _currentUserIdentity = updatedMember;
        await _saveCurrentUserIdentity();
      }

      await _saveRegisteredMembers();

      // Notify callbacks
      _onIdentityVerified?.call(updatedMember);
      _onMembersUpdated?.call(_registeredMembers);

      // Show notification
      await _notificationService.showNotification(
        title: approved ? '✅ SAR Identity Verified' : '❌ SAR Identity Rejected',
        body: approved
            ? 'Your SAR member identity has been verified. You can now participate in rescue operations.'
            : 'Your SAR registration was rejected. Please contact support for details.',
        importance: NotificationImportance.high,
      );

      debugPrint(
        'SARIdentityService: Member ${approved ? 'verified' : 'rejected'} - $identityId',
      );
    } catch (e) {
      debugPrint('SARIdentityService: Error verifying member - $e');
      rethrow;
    }
  }

  /// Update SAR member credentials
  Future<void> updateMemberCredentials({
    required String identityId,
    List<SARCredential>? credentials,
    List<SARCertification>? certifications,
    SARExperience? experience,
  }) async {
    try {
      final memberIndex = _registeredMembers.indexWhere(
        (m) => m.id == identityId,
      );
      if (memberIndex == -1) {
        throw Exception('SAR member not found');
      }

      final member = _registeredMembers[memberIndex];
      final updatedMember = member.copyWith(
        credentials: credentials ?? member.credentials,
        certifications: certifications ?? member.certifications,
        experience: experience ?? member.experience,
        verificationStatus:
            SARVerificationStatus.underReview, // Re-review after updates
      );

      _registeredMembers[memberIndex] = updatedMember;

      // Update current user identity if it's their registration
      if (_currentUserIdentity?.id == identityId) {
        _currentUserIdentity = updatedMember;
        await _saveCurrentUserIdentity();
      }

      await _saveRegisteredMembers();

      // Notify callbacks
      _onIdentityUpdated?.call(updatedMember);
      _onMembersUpdated?.call(_registeredMembers);

      debugPrint(
        'SARIdentityService: Member credentials updated - $identityId',
      );
    } catch (e) {
      debugPrint('SARIdentityService: Error updating credentials - $e');
      rethrow;
    }
  }

  /// Get verified SAR members
  List<SARIdentity> getVerifiedMembers() {
    return _registeredMembers
        .where(
          (member) =>
              member.verificationStatus == SARVerificationStatus.verified,
        )
        .toList();
  }

  /// Get SAR members by type
  List<SARIdentity> getMembersByType(SARMemberType type) {
    return _registeredMembers
        .where((member) => member.memberType == type)
        .toList();
  }

  /// Get SAR members by specialization
  List<SARIdentity> getMembersBySpecialization(
    SARSpecialization specialization,
  ) {
    return _registeredMembers
        .where(
          (member) =>
              member.experience.specializations.contains(specialization),
        )
        .toList();
  }

  /// Check if user is verified SAR member
  bool isVerifiedSARMember([String? userId]) {
    final targetUserId = userId ?? _userProfileService.currentProfile?.id;
    if (targetUserId == null) return false;

    return _registeredMembers.any(
      (member) =>
          member.userId == targetUserId &&
          member.verificationStatus == SARVerificationStatus.verified &&
          member.isActive,
    );
  }

  /// Get SAR member by user ID
  SARIdentity? getSARMemberByUserId(String userId) {
    try {
      return _registeredMembers.firstWhere((member) => member.userId == userId);
    } catch (e) {
      return null;
    }
  }

  /// Validate credential requirements
  bool validateCredentialRequirements(
    SARMemberType memberType,
    List<SARCredential> credentials,
  ) {
    final requiredCredentials = _getRequiredCredentials(memberType);

    for (final required in requiredCredentials) {
      final hasCredential = credentials.any((cred) => cred.type == required);
      if (!hasCredential) return false;
    }

    return true;
  }

  /// Get required credentials for member type
  List<SARCredentialType> _getRequiredCredentials(SARMemberType memberType) {
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

  /// Get required certifications for member type
  List<SARCertificationType> getRequiredCertifications(
    SARMemberType memberType,
  ) {
    switch (memberType) {
      case SARMemberType.volunteer:
        return [
          SARCertificationType.wildernessFirstAid,
          SARCertificationType.cprCertification,
        ];
      case SARMemberType.professional:
        return [
          SARCertificationType.rescueTechnician,
          SARCertificationType.wildernessFirstAid,
          SARCertificationType.cprCertification,
        ];
      case SARMemberType.emergencyServices:
        return [
          SARCertificationType.rescueTechnician,
          SARCertificationType.medicalTraining,
        ];
      case SARMemberType.medicalPersonnel:
        return [
          SARCertificationType.medicalTraining,
          SARCertificationType.wildernessFirstAid,
          SARCertificationType.cprCertification,
        ];
      case SARMemberType.teamLeader:
        return [
          SARCertificationType.incidentCommand,
          SARCertificationType.searchManagement,
          SARCertificationType.rescueTechnician,
        ];
      case SARMemberType.coordinator:
        return [
          SARCertificationType.incidentCommand,
          SARCertificationType.searchManagement,
        ];
    }
  }

  /// Delete credential photo
  Future<void> deleteCredentialPhoto(String photoPath) async {
    try {
      final file = File(photoPath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('SARIdentityService: Credential photo deleted - $photoPath');
      }
    } catch (e) {
      debugPrint('SARIdentityService: Error deleting credential photo - $e');
    }
  }

  /// Load registered members from storage
  Future<void> _loadRegisteredMembers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final membersJson = prefs.getString('sar_registered_members') ?? '[]';
      final membersList = jsonDecode(membersJson) as List;

      _registeredMembers = membersList
          .map((json) => SARIdentity.fromJson(json))
          .toList();

      debugPrint(
        'SARIdentityService: Loaded ${_registeredMembers.length} registered members',
      );
    } catch (e) {
      debugPrint('SARIdentityService: Error loading registered members - $e');
      _registeredMembers = [];
    }
  }

  /// Save registered members to storage
  Future<void> _saveRegisteredMembers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final membersJson = jsonEncode(
        _registeredMembers.map((member) => member.toJson()).toList(),
      );
      await prefs.setString('sar_registered_members', membersJson);
    } catch (e) {
      debugPrint('SARIdentityService: Error saving registered members - $e');
    }
  }

  /// Load current user identity from storage
  Future<void> _loadCurrentUserIdentity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final identityJson = prefs.getString('sar_current_user_identity');

      if (identityJson != null) {
        _currentUserIdentity = SARIdentity.fromJson(jsonDecode(identityJson));
        debugPrint('SARIdentityService: Current user identity loaded');
      }
    } catch (e) {
      debugPrint(
        'SARIdentityService: Error loading current user identity - $e',
      );
      _currentUserIdentity = null;
    }
  }

  /// Save current user identity to storage
  Future<void> _saveCurrentUserIdentity() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_currentUserIdentity != null) {
        await prefs.setString(
          'sar_current_user_identity',
          jsonEncode(_currentUserIdentity!.toJson()),
        );
      } else {
        await prefs.remove('sar_current_user_identity');
      }
    } catch (e) {
      debugPrint('SARIdentityService: Error saving current user identity - $e');
    }
  }

  /// Generate unique identity ID
  String _generateIdentityId() {
    return 'SAR_ID_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(6)}';
  }

  /// Generate random string
  String _generateRandomString(int length) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  /// Get credential type display name
  String getCredentialTypeDisplayName(SARCredentialType type) {
    switch (type) {
      case SARCredentialType.driversLicense:
        return "Driver's License";
      case SARCredentialType.passport:
        return 'Passport';
      case SARCredentialType.stateId:
        return 'State ID';
      case SARCredentialType.governmentId:
        return 'Government ID';
      case SARCredentialType.professionalLicense:
        return 'Professional License';
      case SARCredentialType.backgroundCheck:
        return 'Background Check';
    }
  }

  /// Get certification type display name
  String getCertificationTypeDisplayName(SARCertificationType type) {
    switch (type) {
      case SARCertificationType.wildernessFirstAid:
        return 'Wilderness First Aid';
      case SARCertificationType.cprCertification:
        return 'CPR Certification';
      case SARCertificationType.rescueTechnician:
        return 'Rescue Technician';
      case SARCertificationType.mountainRescue:
        return 'Mountain Rescue';
      case SARCertificationType.waterRescue:
        return 'Water Rescue';
      case SARCertificationType.technicalRescue:
        return 'Technical Rescue';
      case SARCertificationType.medicalTraining:
        return 'Medical Training';
      case SARCertificationType.incidentCommand:
        return 'Incident Command';
      case SARCertificationType.radioOperator:
        return 'Radio Operator';
      case SARCertificationType.searchManagement:
        return 'Search Management';
      case SARCertificationType.k9Handler:
        return 'K9 Handler';
      case SARCertificationType.aviationRescue:
        return 'Aviation Rescue';
    }
  }

  /// Get member type display name
  String getMemberTypeDisplayName(SARMemberType type) {
    switch (type) {
      case SARMemberType.volunteer:
        return 'Volunteer';
      case SARMemberType.professional:
        return 'Professional Rescuer';
      case SARMemberType.emergencyServices:
        return 'Emergency Services';
      case SARMemberType.medicalPersonnel:
        return 'Medical Personnel';
      case SARMemberType.teamLeader:
        return 'Team Leader';
      case SARMemberType.coordinator:
        return 'SAR Coordinator';
    }
  }

  /// Get verification status display name
  String getVerificationStatusDisplayName(SARVerificationStatus status) {
    switch (status) {
      case SARVerificationStatus.pending:
        return 'Pending Review';
      case SARVerificationStatus.underReview:
        return 'Under Review';
      case SARVerificationStatus.verified:
        return 'Verified';
      case SARVerificationStatus.rejected:
        return 'Rejected';
      case SARVerificationStatus.expired:
        return 'Expired';
      case SARVerificationStatus.suspended:
        return 'Suspended';
    }
  }

  // Getters
  List<SARIdentity> get registeredMembers =>
      List.unmodifiable(_registeredMembers);
  SARIdentity? get currentUserIdentity => _currentUserIdentity;
  bool get isInitialized => _isInitialized;
  bool get isCurrentUserVerified =>
      _currentUserIdentity?.verificationStatus ==
      SARVerificationStatus.verified;

  // Event handlers
  void setIdentityRegisteredCallback(Function(SARIdentity) callback) {
    _onIdentityRegistered = callback;
  }

  void setIdentityVerifiedCallback(Function(SARIdentity) callback) {
    _onIdentityVerified = callback;
  }

  void setIdentityUpdatedCallback(Function(SARIdentity) callback) {
    _onIdentityUpdated = callback;
  }

  void setMembersUpdatedCallback(Function(List<SARIdentity>) callback) {
    _onMembersUpdated = callback;
  }

  // Helper methods for generating IDs (removed unused methods for production)
}
