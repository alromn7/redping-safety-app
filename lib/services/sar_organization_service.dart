import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/sar_organization.dart';
import '../models/sar_identity.dart' as sar_identity;
import '../models/chat_message.dart';
import 'user_profile_service.dart';
import 'notification_service.dart';
import 'chat_service.dart';

/// Service for managing SAR organizations and operations
class SAROrganizationService {
  static final SAROrganizationService _instance =
      SAROrganizationService._internal();
  factory SAROrganizationService() => _instance;
  SAROrganizationService._internal();

  final UserProfileService _userProfileService = UserProfileService();
  final NotificationService _notificationService = NotificationService();
  final ChatService _chatService = ChatService();

  List<SAROrganization> _organizations = [];
  List<SAROrganizationMember> _members = [];
  List<SAROrganizationOperation> _operations = [];
  String? _currentUserOrganizationId;
  bool _isInitialized = false;

  // Callbacks
  Function(SAROrganization)? _onOrganizationRegistered;
  Function(SAROrganization)? _onOrganizationVerified;
  Function(SAROrganizationMember)? _onMemberAdded;
  Function(SAROrganizationOperation)? _onOperationStarted;
  Function(List<SAROrganization>)? _onOrganizationsUpdated;

  /// Initialize the organization service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadOrganizations();
      await _loadMembers();
      await _loadOperations();
      await _loadCurrentUserOrganization();

      _isInitialized = true;
      debugPrint('SAROrganizationService: Initialized successfully');
    } catch (e) {
      debugPrint('SAROrganizationService: Initialization error - $e');
      throw Exception('Failed to initialize SAR organization service: $e');
    }
  }

  /// Register a new SAR organization
  Future<SAROrganization> registerOrganization({
    required String organizationName,
    required SAROrganizationType type,
    required SAROrganizationInfo organizationInfo,
    required SARLegalInfo legalInfo,
    required SARContactInfo contactInfo,
    required SARCapabilities capabilities,
    List<SAROrganizationCredential>? credentials,
    List<SAROrganizationCertification>? certifications,
    String? notes,
  }) async {
    try {
      final userProfile = _userProfileService.currentProfile;
      if (userProfile == null) {
        throw Exception('User profile required to register organization');
      }

      // Check if user already has an organization
      if (_currentUserOrganizationId != null) {
        throw Exception('User is already associated with an organization');
      }

      // Create organization
      final organization = SAROrganization(
        id: _generateOrganizationId(),
        organizationName: organizationName,
        type: type,
        organizationInfo: organizationInfo,
        legalInfo: legalInfo,
        contactInfo: contactInfo,
        capabilities: capabilities,
        credentials: credentials ?? [],
        certifications: certifications ?? [],
        registrationDate: DateTime.now(),
        adminIds: [userProfile.id],
        adminNotes: notes,
      );

      // Add to organizations list
      _organizations.add(organization);
      await _saveOrganizations();

      // Create admin member entry for the registering user
      final adminMember = SAROrganizationMember(
        id: _generateMemberId(),
        userId: userProfile.id,
        organizationId: organization.id,
        memberName: userProfile.name,
        memberEmail: userProfile.email,
        memberPhone: userProfile.phoneNumber,
        role: SARMemberRole.admin,
        status: SARMemberStatus.active,
        joinedDate: DateTime.now(),
        lastActiveDate: DateTime.now(),
        specializations: [],
        certifications: [],
      );

      _members.add(adminMember);
      await _saveMembers();

      // Set as current user's organization
      _currentUserOrganizationId = organization.id;
      await _saveCurrentUserOrganization();

      // Create organization chat room
      await _createOrganizationChatRoom(organization);

      // Send notification to admins for verification
      await _notifyAdminsForVerification(organization);

      // Notify callbacks
      _onOrganizationRegistered?.call(organization);
      _onOrganizationsUpdated?.call(_organizations);

      debugPrint(
        'SAROrganizationService: Organization registered - ${organization.id}',
      );
      return organization;
    } catch (e) {
      debugPrint('SAROrganizationService: Error registering organization - $e');
      rethrow;
    }
  }

  /// Verify an organization
  Future<void> verifyOrganization({
    required String organizationId,
    required bool approved,
    required String verifiedBy,
    String? notes,
    DateTime? expirationDate,
  }) async {
    try {
      final orgIndex = _organizations.indexWhere(
        (org) => org.id == organizationId,
      );
      if (orgIndex == -1) {
        throw Exception('Organization not found');
      }

      final organization = _organizations[orgIndex];
      final updatedOrganization = organization.copyWith(
        verificationStatus: approved
            ? sar_identity.SARVerificationStatus.verified
            : sar_identity.SARVerificationStatus.rejected,
        verificationDate: DateTime.now(),
        verifiedBy: verifiedBy,
        adminNotes: notes ?? organization.adminNotes,
        expirationDate: approved ? expirationDate : null,
        isActive: approved,
      );

      _organizations[orgIndex] = updatedOrganization;
      await _saveOrganizations();

      // Notify organization admins
      await _notifyOrganizationVerification(updatedOrganization, approved);

      _onOrganizationVerified?.call(updatedOrganization);
      debugPrint(
        'SAROrganizationService: Organization ${approved ? 'verified' : 'rejected'} - $organizationId',
      );
    } catch (e) {
      debugPrint('SAROrganizationService: Error verifying organization - $e');
      rethrow;
    }
  }

  /// Add member to organization
  Future<SAROrganizationMember> addMember({
    required String organizationId,
    required String userId,
    required String memberName,
    String? memberEmail,
    String? memberPhone,
    required SARMemberRole role,
    List<sar_identity.SARSpecialization>? specializations,
    List<String>? certifications,
    String? notes,
  }) async {
    try {
      // Check if user can add members to this organization
      if (!_canManageOrganization(organizationId)) {
        throw Exception('Insufficient permissions to add members');
      }

      // Check if user is already a member
      final existingMember = _members
          .where(
            (m) => m.userId == userId && m.organizationId == organizationId,
          )
          .firstOrNull;

      if (existingMember != null) {
        throw Exception('User is already a member of this organization');
      }

      // Create member
      final member = SAROrganizationMember(
        id: _generateMemberId(),
        userId: userId,
        organizationId: organizationId,
        memberName: memberName,
        memberEmail: memberEmail,
        memberPhone: memberPhone,
        role: role,
        status: SARMemberStatus.active,
        joinedDate: DateTime.now(),
        lastActiveDate: DateTime.now(),
        specializations: specializations ?? [],
        certifications: certifications ?? [],
        notes: notes,
      );

      _members.add(member);
      await _saveMembers();

      // Add member to organization chat
      await _addMemberToOrganizationChat(organizationId, member);

      // Notify member and organization
      await _notifyMemberAdded(member);

      _onMemberAdded?.call(member);
      debugPrint('SAROrganizationService: Member added - ${member.id}');
      return member;
    } catch (e) {
      debugPrint('SAROrganizationService: Error adding member - $e');
      rethrow;
    }
  }

  /// Start a rescue operation
  Future<SAROrganizationOperation> startOperation({
    required String organizationId,
    required String operationName,
    required SAROperationType type,
    required SAROperationPriority priority,
    required SAROperationLocation location,
    required String description,
    String? subjectInfo,
    List<String>? assignedMemberIds,
    List<String>? resourcesDeployed,
    SARWeatherConditions? weatherConditions,
    List<String>? coordinatingAgencies,
  }) async {
    try {
      // Check if user can start operations for this organization
      if (!_canManageOperations(organizationId)) {
        throw Exception('Insufficient permissions to start operations');
      }

      final userProfile = _userProfileService.currentProfile;
      if (userProfile == null) {
        throw Exception('User profile required');
      }

      // Create operation
      final operation = SAROrganizationOperation(
        id: _generateOperationId(),
        organizationId: organizationId,
        operationName: operationName,
        type: type,
        status: SAROperationStatus.active,
        priority: priority,
        startTime: DateTime.now(),
        location: location,
        description: description,
        subjectInfo: subjectInfo,
        assignedMemberIds: assignedMemberIds ?? [],
        resourcesDeployed: resourcesDeployed ?? [],
        weatherConditions: weatherConditions,
        updates: [
          SAROperationUpdate(
            id: _generateUpdateId(),
            timestamp: DateTime.now(),
            updatedBy: userProfile.name,
            update: 'Operation started',
            type: SARUpdateType.status,
          ),
        ],
        incidentCommanderId: userProfile.id,
        coordinatingAgencies: coordinatingAgencies ?? [],
      );

      _operations.add(operation);
      await _saveOperations();

      // Update organization status
      await _updateOrganizationStatus(
        organizationId,
        SAROperationalStatus.deployed,
      );

      // Notify assigned members and organization
      await _notifyOperationStarted(operation);

      // Create operation chat room
      await _createOperationChatRoom(operation);

      _onOperationStarted?.call(operation);
      debugPrint('SAROrganizationService: Operation started - ${operation.id}');
      return operation;
    } catch (e) {
      debugPrint('SAROrganizationService: Error starting operation - $e');
      rethrow;
    }
  }

  /// Update operation status
  Future<void> updateOperation({
    required String operationId,
    SAROperationStatus? status,
    String? update,
    SARUpdateType? updateType,
    List<String>? assignedMemberIds,
    List<String>? resourcesDeployed,
    SARWeatherConditions? weatherConditions,
    SAROperationOutcome? outcome,
  }) async {
    try {
      final opIndex = _operations.indexWhere((op) => op.id == operationId);
      if (opIndex == -1) {
        throw Exception('Operation not found');
      }

      final operation = _operations[opIndex];

      // Check permissions
      if (!_canManageOperations(operation.organizationId)) {
        throw Exception('Insufficient permissions to update operation');
      }

      final userProfile = _userProfileService.currentProfile;
      if (userProfile == null) {
        throw Exception('User profile required');
      }

      // Create update log entry
      final updates = List<SAROperationUpdate>.from(operation.updates);
      if (update != null) {
        updates.add(
          SAROperationUpdate(
            id: _generateUpdateId(),
            timestamp: DateTime.now(),
            updatedBy: userProfile.name,
            update: update,
            type: updateType ?? SARUpdateType.status,
          ),
        );
      }

      // Update operation
      final updatedOperation = operation.copyWith(
        status: status ?? operation.status,
        endTime:
            status == SAROperationStatus.completed ||
                status == SAROperationStatus.cancelled
            ? DateTime.now()
            : operation.endTime,
        assignedMemberIds: assignedMemberIds ?? operation.assignedMemberIds,
        resourcesDeployed: resourcesDeployed ?? operation.resourcesDeployed,
        weatherConditions: weatherConditions ?? operation.weatherConditions,
        updates: updates,
        outcome: outcome ?? operation.outcome,
      );

      _operations[opIndex] = updatedOperation;
      await _saveOperations();

      // Update organization status if operation completed
      if (status == SAROperationStatus.completed ||
          status == SAROperationStatus.cancelled) {
        final activeOps = getActiveOperations(operation.organizationId);
        if (activeOps.isEmpty) {
          await _updateOrganizationStatus(
            operation.organizationId,
            SAROperationalStatus.standby,
          );
        }
      }

      // Notify operation team
      await _notifyOperationUpdated(updatedOperation, update);

      debugPrint('SAROrganizationService: Operation updated - $operationId');
    } catch (e) {
      debugPrint('SAROrganizationService: Error updating operation - $e');
      rethrow;
    }
  }

  /// Upload organization credential document
  Future<String> uploadCredentialDocument({
    required SAROrganizationCredentialType credentialType,
    required XFile photoFile,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'ORG_CRED_${credentialType.name}_$timestamp.jpg';

      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final credentialsDir = Directory('${directory.path}/org_credentials');
      if (!await credentialsDir.exists()) {
        await credentialsDir.create(recursive: true);
      }

      // Save file
      final savedPath = '${credentialsDir.path}/$filename';
      await File(photoFile.path).copy(savedPath);

      debugPrint(
        'SAROrganizationService: Credential document uploaded - $savedPath',
      );
      return savedPath;
    } catch (e) {
      debugPrint(
        'SAROrganizationService: Error uploading credential document - $e',
      );
      rethrow;
    }
  }

  /// Upload organization certification document
  Future<String> uploadCertificationDocument({
    required SAROrganizationCertificationType certificationType,
    required XFile photoFile,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'ORG_CERT_${certificationType.name}_$timestamp.jpg';

      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final certificationsDir = Directory(
        '${directory.path}/org_certifications',
      );
      if (!await certificationsDir.exists()) {
        await certificationsDir.create(recursive: true);
      }

      // Save file
      final savedPath = '${certificationsDir.path}/$filename';
      await File(photoFile.path).copy(savedPath);

      debugPrint(
        'SAROrganizationService: Certification document uploaded - $savedPath',
      );
      return savedPath;
    } catch (e) {
      debugPrint(
        'SAROrganizationService: Error uploading certification document - $e',
      );
      rethrow;
    }
  }

  /// Get organizations by type
  List<SAROrganization> getOrganizationsByType(SAROrganizationType type) {
    return _organizations.where((org) => org.type == type).toList();
  }

  /// Get verified organizations
  List<SAROrganization> getVerifiedOrganizations() {
    return _organizations
        .where(
          (org) =>
              org.verificationStatus ==
              sar_identity.SARVerificationStatus.verified,
        )
        .toList();
  }

  /// Get organization members
  List<SAROrganizationMember> getOrganizationMembers(String organizationId) {
    return _members
        .where(
          (member) =>
              member.organizationId == organizationId && member.isActive,
        )
        .toList();
  }

  /// Get active operations for organization
  List<SAROrganizationOperation> getActiveOperations(String organizationId) {
    return _operations
        .where(
          (op) =>
              op.organizationId == organizationId &&
              op.status == SAROperationStatus.active,
        )
        .toList();
  }

  /// Get all operations for organization
  List<SAROrganizationOperation> getOrganizationOperations(
    String organizationId,
  ) {
    return _operations
        .where((op) => op.organizationId == organizationId)
        .toList();
  }

  /// Check if current user can manage organization
  bool _canManageOrganization(String organizationId) {
    final userProfile = _userProfileService.currentProfile;
    if (userProfile == null) return false;

    final organization = _organizations
        .where((org) => org.id == organizationId)
        .firstOrNull;
    if (organization == null) return false;

    // Check if user is admin
    if (organization.adminIds.contains(userProfile.id)) return true;

    // Check if user has admin role
    final member = _members
        .where(
          (m) =>
              m.organizationId == organizationId && m.userId == userProfile.id,
        )
        .firstOrNull;

    return member?.role == SARMemberRole.admin ||
        member?.role == SARMemberRole.incidentCommander;
  }

  /// Check if current user can manage operations
  bool _canManageOperations(String organizationId) {
    final userProfile = _userProfileService.currentProfile;
    if (userProfile == null) return false;

    final member = _members
        .where(
          (m) =>
              m.organizationId == organizationId && m.userId == userProfile.id,
        )
        .firstOrNull;

    return member?.role == SARMemberRole.admin ||
        member?.role == SARMemberRole.incidentCommander ||
        member?.role == SARMemberRole.teamLeader;
  }

  /// Update organization operational status
  Future<void> _updateOrganizationStatus(
    String organizationId,
    SAROperationalStatus status,
  ) async {
    final orgIndex = _organizations.indexWhere(
      (org) => org.id == organizationId,
    );
    if (orgIndex != -1) {
      final organization = _organizations[orgIndex];
      final updatedOrganization = organization.copyWith(
        operationalStatus: status,
      );
      _organizations[orgIndex] = updatedOrganization;
      await _saveOrganizations();
    }
  }

  /// Create organization chat room
  Future<void> _createOrganizationChatRoom(SAROrganization organization) async {
    try {
      await _chatService.sendMessage(
        chatId: 'org_${organization.id}',
        content: '🏢 ${organization.organizationName} chat room created',
        type: MessageType.announcement,
        priority: MessagePriority.low,
      );
    } catch (e) {
      debugPrint(
        'SAROrganizationService: Error creating organization chat - $e',
      );
    }
  }

  /// Create operation chat room
  Future<void> _createOperationChatRoom(
    SAROrganizationOperation operation,
  ) async {
    try {
      await _chatService.sendMessage(
        chatId: 'op_${operation.id}',
        content: '🚁 Operation "${operation.operationName}" started',
        type: MessageType.announcement,
        priority: MessagePriority.high,
      );
    } catch (e) {
      debugPrint('SAROrganizationService: Error creating operation chat - $e');
    }
  }

  /// Add member to organization chat
  Future<void> _addMemberToOrganizationChat(
    String organizationId,
    SAROrganizationMember member,
  ) async {
    try {
      await _chatService.sendMessage(
        chatId: 'org_$organizationId',
        content:
            '👋 ${member.memberName} joined as ${_getMemberRoleDisplayName(member.role)}',
        type: MessageType.announcement,
        priority: MessagePriority.low,
      );
    } catch (e) {
      debugPrint('SAROrganizationService: Error adding member to chat - $e');
    }
  }

  /// Notify admins for organization verification
  Future<void> _notifyAdminsForVerification(
    SAROrganization organization,
  ) async {
    try {
      await _notificationService.showNotification(
        title: '🏢 New SAR Organization Registered',
        body: '${organization.organizationName} registered for verification',
        importance: NotificationImportance.high,
      );
    } catch (e) {
      debugPrint('SAROrganizationService: Error notifying admins - $e');
    }
  }

  /// Notify organization verification result
  Future<void> _notifyOrganizationVerification(
    SAROrganization organization,
    bool approved,
  ) async {
    try {
      await _notificationService.showNotification(
        title: approved ? '✅ Organization Verified' : '❌ Organization Rejected',
        body: approved
            ? '${organization.organizationName} has been verified and can now manage rescue operations.'
            : '${organization.organizationName} verification was rejected. Please contact support.',
        importance: NotificationImportance.high,
      );
    } catch (e) {
      debugPrint('SAROrganizationService: Error notifying verification - $e');
    }
  }

  /// Notify member added
  Future<void> _notifyMemberAdded(SAROrganizationMember member) async {
    try {
      await _notificationService.showNotification(
        title: '👥 Added to SAR Organization',
        body:
            'You have been added to a SAR organization as ${_getMemberRoleDisplayName(member.role)}',
        importance: NotificationImportance.defaultImportance,
      );
    } catch (e) {
      debugPrint('SAROrganizationService: Error notifying member added - $e');
    }
  }

  /// Notify operation started
  Future<void> _notifyOperationStarted(
    SAROrganizationOperation operation,
  ) async {
    try {
      await _notificationService.showNotification(
        title: '🚁 Rescue Operation Started',
        body: 'Operation "${operation.operationName}" is now active',
        importance: NotificationImportance.high,
      );

      // Send to operation chat
      await _chatService.sendMessage(
        chatId: 'op_${operation.id}',
        content:
            '🚁 Operation "${operation.operationName}" started\n'
            '📍 Location: ${operation.location.locationName ?? 'Coordinates provided'}\n'
            '⚠️ Priority: ${_getPriorityDisplayName(operation.priority)}\n'
            '👥 Assigned: ${operation.assignedMemberIds.length} members',
        type: MessageType.sosUpdate,
        priority: MessagePriority.high,
      );
    } catch (e) {
      debugPrint(
        'SAROrganizationService: Error notifying operation started - $e',
      );
    }
  }

  /// Notify operation updated
  Future<void> _notifyOperationUpdated(
    SAROrganizationOperation operation,
    String? update,
  ) async {
    if (update == null) return;

    try {
      await _chatService.sendMessage(
        chatId: 'op_${operation.id}',
        content: '📝 Operation Update: $update',
        type: MessageType.sosUpdate,
        priority: MessagePriority.normal,
      );
    } catch (e) {
      debugPrint(
        'SAROrganizationService: Error notifying operation update - $e',
      );
    }
  }

  /// Get member role display name
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

  /// Get priority display name
  String _getPriorityDisplayName(SAROperationPriority priority) {
    switch (priority) {
      case SAROperationPriority.low:
        return 'Low';
      case SAROperationPriority.normal:
        return 'Normal';
      case SAROperationPriority.high:
        return 'High';
      case SAROperationPriority.critical:
        return 'Critical';
      case SAROperationPriority.emergency:
        return 'Emergency';
    }
  }

  /// Get organization type display name
  String getOrganizationTypeDisplayName(SAROrganizationType type) {
    switch (type) {
      case SAROrganizationType.volunteerNonprofit:
        return 'Volunteer Nonprofit';
      case SAROrganizationType.professionalRescue:
        return 'Professional Rescue';
      case SAROrganizationType.governmentAgency:
        return 'Government Agency';
      case SAROrganizationType.militaryUnit:
        return 'Military Unit';
      case SAROrganizationType.privateCompany:
        return 'Private Company';
      case SAROrganizationType.nationalTeam:
        return 'National Team';
      case SAROrganizationType.internationalTeam:
        return 'International Team';
    }
  }

  /// Storage methods
  Future<void> _loadOrganizations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final organizationsJson = prefs.getString('sar_organizations') ?? '[]';
      final organizationsList = jsonDecode(organizationsJson) as List;

      _organizations = organizationsList
          .map((json) => SAROrganization.fromJson(json))
          .toList();

      debugPrint(
        'SAROrganizationService: Loaded ${_organizations.length} organizations',
      );
    } catch (e) {
      debugPrint('SAROrganizationService: Error loading organizations - $e');
      _organizations = [];
    }
  }

  Future<void> _saveOrganizations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final organizationsJson = jsonEncode(
        _organizations.map((org) => org.toJson()).toList(),
      );
      await prefs.setString('sar_organizations', organizationsJson);
    } catch (e) {
      debugPrint('SAROrganizationService: Error saving organizations - $e');
    }
  }

  Future<void> _loadMembers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final membersJson = prefs.getString('sar_organization_members') ?? '[]';
      final membersList = jsonDecode(membersJson) as List;

      _members = membersList
          .map((json) => SAROrganizationMember.fromJson(json))
          .toList();

      debugPrint('SAROrganizationService: Loaded ${_members.length} members');
    } catch (e) {
      debugPrint('SAROrganizationService: Error loading members - $e');
      _members = [];
    }
  }

  Future<void> _saveMembers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final membersJson = jsonEncode(
        _members.map((member) => member.toJson()).toList(),
      );
      await prefs.setString('sar_organization_members', membersJson);
    } catch (e) {
      debugPrint('SAROrganizationService: Error saving members - $e');
    }
  }

  Future<void> _loadOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final operationsJson = prefs.getString('sar_operations') ?? '[]';
      final operationsList = jsonDecode(operationsJson) as List;

      _operations = operationsList
          .map((json) => SAROrganizationOperation.fromJson(json))
          .toList();

      debugPrint(
        'SAROrganizationService: Loaded ${_operations.length} operations',
      );
    } catch (e) {
      debugPrint('SAROrganizationService: Error loading operations - $e');
      _operations = [];
    }
  }

  Future<void> _saveOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final operationsJson = jsonEncode(
        _operations.map((op) => op.toJson()).toList(),
      );
      await prefs.setString('sar_operations', operationsJson);
    } catch (e) {
      debugPrint('SAROrganizationService: Error saving operations - $e');
    }
  }

  Future<void> _loadCurrentUserOrganization() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentUserOrganizationId = prefs.getString(
        'current_user_organization_id',
      );
    } catch (e) {
      debugPrint(
        'SAROrganizationService: Error loading current user organization - $e',
      );
    }
  }

  Future<void> _saveCurrentUserOrganization() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentUserOrganizationId != null) {
        await prefs.setString(
          'current_user_organization_id',
          _currentUserOrganizationId!,
        );
      } else {
        await prefs.remove('current_user_organization_id');
      }
    } catch (e) {
      debugPrint(
        'SAROrganizationService: Error saving current user organization - $e',
      );
    }
  }

  /// Generate unique IDs
  String _generateOrganizationId() {
    return 'ORG_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(4)}';
  }

  String _generateMemberId() {
    return 'MEM_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(4)}';
  }

  String _generateOperationId() {
    return 'OP_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(4)}';
  }

  String _generateUpdateId() {
    return 'UPD_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(4)}';
  }

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

  // Getters
  List<SAROrganization> get organizations => List.unmodifiable(_organizations);
  List<SAROrganizationMember> get members => List.unmodifiable(_members);
  List<SAROrganizationOperation> get operations =>
      List.unmodifiable(_operations);
  String? get currentUserOrganizationId => _currentUserOrganizationId;
  SAROrganization? get currentUserOrganization =>
      _currentUserOrganizationId != null
      ? _organizations
            .where((org) => org.id == _currentUserOrganizationId)
            .firstOrNull
      : null;
  bool get isInitialized => _isInitialized;

  // Event handlers
  void setOrganizationRegisteredCallback(Function(SAROrganization) callback) {
    _onOrganizationRegistered = callback;
  }

  void setOrganizationVerifiedCallback(Function(SAROrganization) callback) {
    _onOrganizationVerified = callback;
  }

  void setMemberAddedCallback(Function(SAROrganizationMember) callback) {
    _onMemberAdded = callback;
  }

  void setOperationStartedCallback(
    Function(SAROrganizationOperation) callback,
  ) {
    _onOperationStarted = callback;
  }

  void setOrganizationsUpdatedCallback(
    Function(List<SAROrganization>) callback,
  ) {
    _onOrganizationsUpdated = callback;
  }
}
