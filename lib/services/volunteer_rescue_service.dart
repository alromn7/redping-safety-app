import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:redping_14v/utils/iterable_extensions.dart';
import '../models/volunteer_participation.dart';
import '../models/chat_message.dart';
import 'user_profile_service.dart';
import 'location_service.dart';
import 'notification_service.dart';
import 'chat_service.dart';

/// Service for managing volunteer rescue participation
class VolunteerRescueService {
  static final VolunteerRescueService _instance =
      VolunteerRescueService._internal();
  factory VolunteerRescueService() => _instance;
  VolunteerRescueService._internal();

  final UserProfileService _userProfileService = UserProfileService();
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();
  final ChatService _chatService = ChatService();

  List<VolunteerParticipation> _activeParticipations = [];
  List<RiskAcknowledgment> _riskAcknowledgments = [];
  bool _isInitialized = false;

  // Callbacks
  Function(VolunteerParticipation)? _onVolunteerJoined;
  Function(VolunteerParticipation)? _onVolunteerUpdated;
  Function(VolunteerParticipation)? _onVolunteerWithdrew;
  Function(List<VolunteerParticipation>)? _onVolunteersUpdated;

  /// Initialize the volunteer rescue service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadParticipations();
      await _loadRiskAcknowledgments();

      _isInitialized = true;
      debugPrint('VolunteerRescueService: Initialized successfully');
    } catch (e) {
      debugPrint('VolunteerRescueService: Initialization error - $e');
      throw Exception('Failed to initialize volunteer rescue service: $e');
    }
  }

  /// Join volunteer rescue mission
  Future<VolunteerParticipation> joinVolunteerMission({
    required String missionId,
    required VolunteerRole role,
    required List<String> skills,
    required List<String> equipment,
    required bool hasFirstAid,
    required bool hasTransportation,
    required bool isLocalResident,
    required EmergencyContact emergencyContact,
    String? notes,
  }) async {
    try {
      final userProfile = _userProfileService.currentProfile;
      if (userProfile == null) {
        throw Exception('User profile required to join volunteer mission');
      }

      // Check if user already participating in this mission
      final existingParticipation = _activeParticipations
          .where((p) => p.missionId == missionId && p.userId == userProfile.id)
          .firstOrNull;

      if (existingParticipation != null) {
        throw Exception('You are already participating in this mission');
      }

      // Get current location
      final location = await _locationService.getCurrentLocation();

      // Create volunteer participation
      final participation = VolunteerParticipation(
        id: _generateParticipationId(),
        userId: userProfile.id,
        userName: userProfile.name,
        userPhone: userProfile.phoneNumber,
        missionId: missionId,
        role: role,
        status: VolunteerStatus.pending,
        joinedAt: DateTime.now(),
        currentLocation: location,
        skills: skills,
        equipment: equipment,
        hasFirstAid: hasFirstAid,
        hasTransportation: hasTransportation,
        isLocalResident: isLocalResident,
        emergencyContact: emergencyContact,
        notes: notes,
      );

      // Add to active participations
      _activeParticipations.add(participation);
      await _saveParticipations();

      // Send notification to mission coordinators
      await _notifyMissionCoordinators(participation);

      // Add to volunteer chat room
      await _addToVolunteerChat(participation);

      // Notify callbacks
      _onVolunteerJoined?.call(participation);
      _onVolunteersUpdated?.call(_activeParticipations);

      debugPrint(
        'VolunteerRescueService: User joined mission - ${participation.id}',
      );
      return participation;
    } catch (e) {
      debugPrint('VolunteerRescueService: Error joining mission - $e');
      rethrow;
    }
  }

  /// Acknowledge risks and liability
  Future<RiskAcknowledgment> acknowledgeRisks({
    required String missionId,
    required String digitalSignature,
  }) async {
    try {
      final userProfile = _userProfileService.currentProfile;
      if (userProfile == null) {
        throw Exception('User profile required for risk acknowledgment');
      }

      // Get device information
      final deviceInfo = await _getDeviceInfo();
      final ipAddress = await _getIPAddress();

      // Create risk acknowledgment
      final acknowledgment = RiskAcknowledgment(
        id: _generateAcknowledgmentId(),
        userId: userProfile.id,
        missionId: missionId,
        acknowledgedAt: DateTime.now(),
        ipAddress: ipAddress,
        deviceInfo: deviceInfo,
        acknowledgedRisks: getStandardRisks(),
        confirmedAdult: true, // Assume user confirms they are adult
        confirmedPhysicalCapability: true,
        confirmedInsurance: true,
        confirmedEmergencyContact: true,
        digitalSignature: digitalSignature,
      );

      // Save acknowledgment
      _riskAcknowledgments.add(acknowledgment);
      await _saveRiskAcknowledgments();

      // Update participation status
      await _updateParticipationRiskAcknowledgment(missionId, userProfile.id);

      debugPrint(
        'VolunteerRescueService: Risk acknowledged - ${acknowledgment.id}',
      );
      return acknowledgment;
    } catch (e) {
      debugPrint('VolunteerRescueService: Error acknowledging risks - $e');
      rethrow;
    }
  }

  /// Activate volunteer for mission
  Future<void> activateVolunteer({
    required String participationId,
    String? coordinatorNotes,
  }) async {
    try {
      final participationIndex = _activeParticipations.indexWhere(
        (p) => p.id == participationId,
      );

      if (participationIndex == -1) {
        throw Exception('Volunteer participation not found');
      }

      final participation = _activeParticipations[participationIndex];
      final updatedParticipation = participation.copyWith(
        status: VolunteerStatus.active,
        notes: coordinatorNotes ?? participation.notes,
      );

      _activeParticipations[participationIndex] = updatedParticipation;
      await _saveParticipations();

      // Notify volunteer
      await _notificationService.showNotification(
        title: '✅ Volunteer Mission Activated',
        body:
            'You have been activated for rescue mission. Please follow safety protocols.',
        importance: NotificationImportance.high,
      );

      // Send activation message to volunteer chat
      await _sendVolunteerActivationMessage(updatedParticipation);

      _onVolunteerUpdated?.call(updatedParticipation);
      debugPrint(
        'VolunteerRescueService: Volunteer activated - $participationId',
      );
    } catch (e) {
      debugPrint('VolunteerRescueService: Error activating volunteer - $e');
      rethrow;
    }
  }

  /// Withdraw from volunteer mission
  Future<void> withdrawFromMission(
    String participationId, {
    String? reason,
  }) async {
    try {
      final participationIndex = _activeParticipations.indexWhere(
        (p) => p.id == participationId,
      );

      if (participationIndex == -1) {
        throw Exception('Volunteer participation not found');
      }

      final participation = _activeParticipations[participationIndex];
      final updatedParticipation = participation.copyWith(
        status: VolunteerStatus.withdrawn,
        notes: reason != null
            ? '${participation.notes ?? ''}\nWithdrawal reason: $reason'
            : participation.notes,
      );

      _activeParticipations[participationIndex] = updatedParticipation;
      await _saveParticipations();

      // Notify mission coordinators
      await _notifyVolunteerWithdrawal(updatedParticipation, reason);

      _onVolunteerWithdrew?.call(updatedParticipation);
      debugPrint(
        'VolunteerRescueService: Volunteer withdrew - $participationId',
      );
    } catch (e) {
      debugPrint('VolunteerRescueService: Error withdrawing volunteer - $e');
      rethrow;
    }
  }

  /// Get volunteers for mission
  List<VolunteerParticipation> getVolunteersForMission(String missionId) {
    return _activeParticipations
        .where((p) => p.missionId == missionId)
        .toList();
  }

  /// Get user's active participations
  List<VolunteerParticipation> getUserActiveParticipations([String? userId]) {
    final targetUserId = userId ?? _userProfileService.currentProfile?.id;
    if (targetUserId == null) return [];

    return _activeParticipations
        .where((p) => p.userId == targetUserId && p.isActive)
        .toList();
  }

  /// Check if user can join mission
  bool canUserJoinMission(String missionId, [String? userId]) {
    final targetUserId = userId ?? _userProfileService.currentProfile?.id;
    if (targetUserId == null) return false;

    // Check if already participating
    final isAlreadyParticipating = _activeParticipations.any(
      (p) =>
          p.missionId == missionId &&
          p.userId == targetUserId &&
          (p.status == VolunteerStatus.pending ||
              p.status == VolunteerStatus.active),
    );

    return !isAlreadyParticipating;
  }

  /// Get standard risks for acknowledgment
  List<String> getStandardRisks() {
    return [
      'Physical injury or death during rescue operations',
      'Exposure to hazardous conditions (weather, terrain, chemicals)',
      'Risk of getting lost or separated from rescue team',
      'Potential for equipment failure or malfunction',
      'Risk of secondary emergencies or accidents',
      'Exposure to infectious diseases or contamination',
      'Psychological trauma from rescue situations',
      'Legal liability for actions during rescue operations',
      'Risk of property damage or loss',
      'Potential for communication failures',
      'Risk of inadequate medical care in remote locations',
      'Possibility of mission cancellation or changes',
    ];
  }

  /// Update participation risk acknowledgment
  Future<void> _updateParticipationRiskAcknowledgment(
    String missionId,
    String userId,
  ) async {
    final participationIndex = _activeParticipations.indexWhere(
      (p) => p.missionId == missionId && p.userId == userId,
    );

    if (participationIndex != -1) {
      final participation = _activeParticipations[participationIndex];
      final updatedParticipation = participation.copyWith(
        acknowledgedRiskAt: DateTime.now(),
      );

      _activeParticipations[participationIndex] = updatedParticipation;
      await _saveParticipations();
    }
  }

  /// Notify mission coordinators of new volunteer
  Future<void> _notifyMissionCoordinators(
    VolunteerParticipation participation,
  ) async {
    try {
      await _notificationService.showNotification(
        title: '👥 New Volunteer Joined Mission',
        body:
            '${participation.userName} joined as ${getRoleDisplayName(participation.role)}',
        importance: NotificationImportance.high,
      );

      // Send message to mission chat
      final message =
          'New volunteer joined mission:\n'
          '👤 ${participation.userName}\n'
          '📞 ${participation.userPhone ?? 'No phone'}\n'
          '🎯 Role: ${getRoleDisplayName(participation.role)}\n'
          '🛠️ Equipment: ${participation.equipment.join(', ')}\n'
          '💊 First Aid: ${participation.hasFirstAid ? 'Yes' : 'No'}\n'
          '🚗 Transportation: ${participation.hasTransportation ? 'Yes' : 'No'}\n'
          '🏠 Local Resident: ${participation.isLocalResident ? 'Yes' : 'No'}';

      await _chatService.sendMessage(
        chatId: 'mission_${participation.missionId}',
        content: message,
        type: MessageType.volunteerUpdate,
        priority: MessagePriority.normal,
        location: participation.currentLocation,
      );
    } catch (e) {
      debugPrint('VolunteerRescueService: Error notifying coordinators - $e');
    }
  }

  /// Add volunteer to mission chat
  Future<void> _addToVolunteerChat(VolunteerParticipation participation) async {
    try {
      // Create or join volunteer coordination chat
      final chatId = 'volunteer_${participation.missionId}';

      await _chatService.sendMessage(
        chatId: chatId,
        content:
            '👋 ${participation.userName} joined as volunteer ${getRoleDisplayName(participation.role)}',
        type: MessageType.announcement,
        priority: MessagePriority.low,
      );
    } catch (e) {
      debugPrint('VolunteerRescueService: Error adding to volunteer chat - $e');
    }
  }

  /// Send volunteer activation message
  Future<void> _sendVolunteerActivationMessage(
    VolunteerParticipation participation,
  ) async {
    try {
      final message =
          '✅ VOLUNTEER ACTIVATED\n\n'
          '👤 ${participation.userName}\n'
          '🎯 Role: ${getRoleDisplayName(participation.role)}\n'
          '📍 Please report to designated location\n'
          '📞 Stay in radio contact\n'
          '⚠️ Follow all safety protocols\n'
          '🚨 Report any unsafe conditions immediately';

      await _chatService.sendMessage(
        chatId: 'volunteer_${participation.missionId}',
        content: message,
        type: MessageType.activation,
        priority: MessagePriority.high,
      );
    } catch (e) {
      debugPrint(
        'VolunteerRescueService: Error sending activation message - $e',
      );
    }
  }

  /// Notify volunteer withdrawal
  Future<void> _notifyVolunteerWithdrawal(
    VolunteerParticipation participation,
    String? reason,
  ) async {
    try {
      await _notificationService.showNotification(
        title: '👋 Volunteer Withdrew from Mission',
        body:
            '${participation.userName} withdrew from mission${reason != null ? ': $reason' : ''}',
        importance: NotificationImportance.defaultImportance,
      );

      // Send message to mission chat
      final message =
          '👋 ${participation.userName} withdrew from volunteer mission'
          '${reason != null ? '\nReason: $reason' : ''}';

      await _chatService.sendMessage(
        chatId: 'mission_${participation.missionId}',
        content: message,
        type: MessageType.withdrawal,
        priority: MessagePriority.normal,
      );
    } catch (e) {
      debugPrint('VolunteerRescueService: Error notifying withdrawal - $e');
    }
  }

  /// Get device information
  Future<String> _getDeviceInfo() async {
    try {
      final deviceInfoPlugin = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        return 'Android ${androidInfo.version.release} - ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        return 'iOS ${iosInfo.systemVersion} - ${iosInfo.model}';
      }

      return 'Unknown Device';
    } catch (e) {
      return 'Device Info Unavailable';
    }
  }

  /// Get IP address (simplified)
  Future<String> _getIPAddress() async {
    try {
      // In production, you would get the actual IP address
      return '192.168.1.${DateTime.now().millisecondsSinceEpoch % 255}';
    } catch (e) {
      return 'IP Unavailable';
    }
  }

  /// Load participations from storage
  Future<void> _loadParticipations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final participationsJson =
          prefs.getString('volunteer_participations') ?? '[]';
      final participationsList = jsonDecode(participationsJson) as List;

      _activeParticipations = participationsList
          .map((json) => VolunteerParticipation.fromJson(json))
          .toList();

      debugPrint(
        'VolunteerRescueService: Loaded ${_activeParticipations.length} participations',
      );
    } catch (e) {
      debugPrint('VolunteerRescueService: Error loading participations - $e');
      _activeParticipations = [];
    }
  }

  /// Save participations to storage
  Future<void> _saveParticipations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final participationsJson = jsonEncode(
        _activeParticipations.map((p) => p.toJson()).toList(),
      );
      await prefs.setString('volunteer_participations', participationsJson);
    } catch (e) {
      debugPrint('VolunteerRescueService: Error saving participations - $e');
    }
  }

  /// Load risk acknowledgments from storage
  Future<void> _loadRiskAcknowledgments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final acknowledgementsJson =
          prefs.getString('risk_acknowledgments') ?? '[]';
      final acknowledgmentsList = jsonDecode(acknowledgementsJson) as List;

      _riskAcknowledgments = acknowledgmentsList
          .map((json) => RiskAcknowledgment.fromJson(json))
          .toList();

      debugPrint(
        'VolunteerRescueService: Loaded ${_riskAcknowledgments.length} risk acknowledgments',
      );
    } catch (e) {
      debugPrint(
        'VolunteerRescueService: Error loading risk acknowledgments - $e',
      );
      _riskAcknowledgments = [];
    }
  }

  /// Save risk acknowledgments to storage
  Future<void> _saveRiskAcknowledgments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final acknowledgementsJson = jsonEncode(
        _riskAcknowledgments.map((a) => a.toJson()).toList(),
      );
      await prefs.setString('risk_acknowledgments', acknowledgementsJson);
    } catch (e) {
      debugPrint(
        'VolunteerRescueService: Error saving risk acknowledgments - $e',
      );
    }
  }

  /// Generate unique participation ID
  String _generateParticipationId() {
    return 'VOL_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(4)}';
  }

  /// Generate unique acknowledgment ID
  String _generateAcknowledgmentId() {
    return 'RISK_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(4)}';
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

  /// Get role display name
  String getRoleDisplayName(VolunteerRole role) {
    switch (role) {
      case VolunteerRole.generalSupport:
        return 'General Support';
      case VolunteerRole.searchAssistant:
        return 'Search Assistant';
      case VolunteerRole.logisticsSupport:
        return 'Logistics Support';
      case VolunteerRole.communicationRelay:
        return 'Communication Relay';
      case VolunteerRole.crowdControl:
        return 'Crowd Control';
      case VolunteerRole.supplyRunner:
        return 'Supply Runner';
      case VolunteerRole.localGuide:
        return 'Local Guide';
      case VolunteerRole.witness:
        return 'Witness';
      case VolunteerRole.familyLiaison:
        return 'Family Liaison';
    }
  }

  /// Get status display name
  String getStatusDisplayName(VolunteerStatus status) {
    switch (status) {
      case VolunteerStatus.pending:
        return 'Pending Approval';
      case VolunteerStatus.active:
        return 'Active';
      case VolunteerStatus.standby:
        return 'On Standby';
      case VolunteerStatus.completed:
        return 'Mission Completed';
      case VolunteerStatus.withdrawn:
        return 'Withdrawn';
      case VolunteerStatus.dismissed:
        return 'Dismissed';
    }
  }

  /// Get available volunteer roles
  List<VolunteerRole> getAvailableRoles() {
    return [
      VolunteerRole.generalSupport,
      VolunteerRole.searchAssistant,
      VolunteerRole.logisticsSupport,
      VolunteerRole.communicationRelay,
      VolunteerRole.localGuide,
      VolunteerRole.supplyRunner,
      VolunteerRole.witness,
    ];
  }

  /// Get role description
  String getRoleDescription(VolunteerRole role) {
    switch (role) {
      case VolunteerRole.generalSupport:
        return 'Assist with general tasks and provide support where needed';
      case VolunteerRole.searchAssistant:
        return 'Help with search operations under professional supervision';
      case VolunteerRole.logisticsSupport:
        return 'Assist with equipment, supplies, and coordination';
      case VolunteerRole.communicationRelay:
        return 'Help relay messages and maintain communication';
      case VolunteerRole.crowdControl:
        return 'Help manage crowds and maintain safety perimeter';
      case VolunteerRole.supplyRunner:
        return 'Transport supplies and equipment to teams';
      case VolunteerRole.localGuide:
        return 'Provide local knowledge and area guidance';
      case VolunteerRole.witness:
        return 'Provide witness information and assist investigators';
      case VolunteerRole.familyLiaison:
        return 'Support families and provide updates';
    }
  }

  // Getters
  List<VolunteerParticipation> get activeParticipations =>
      List.unmodifiable(_activeParticipations);
  List<RiskAcknowledgment> get riskAcknowledgments =>
      List.unmodifiable(_riskAcknowledgments);
  bool get isInitialized => _isInitialized;

  // Event handlers
  void setVolunteerJoinedCallback(Function(VolunteerParticipation) callback) {
    _onVolunteerJoined = callback;
  }

  void setVolunteerUpdatedCallback(Function(VolunteerParticipation) callback) {
    _onVolunteerUpdated = callback;
  }

  void setVolunteerWithdrewCallback(Function(VolunteerParticipation) callback) {
    _onVolunteerWithdrew = callback;
  }

  void setVolunteersUpdatedCallback(
    Function(List<VolunteerParticipation>) callback,
  ) {
    _onVolunteersUpdated = callback;
  }
}
