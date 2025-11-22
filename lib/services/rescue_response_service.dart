import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/sos_session.dart';
import '../models/chat_message.dart' as chat;
import 'notification_service.dart';
import 'chat_service.dart';

/// Service for managing rescue team responses and emergency contact feedback
class RescueResponseService {
  static final RescueResponseService _instance =
      RescueResponseService._internal();
  factory RescueResponseService() => _instance;
  RescueResponseService._internal();

  final NotificationService _notificationService = NotificationService();
  final ChatService _chatService = ChatService();

  bool _isInitialized = false;

  // Active SOS sessions with response tracking
  final Map<String, SOSSession> _activeSessions = {};

  // Simulated rescue teams for demo purposes
  final List<RescueTeam> _availableRescueTeams = [
    RescueTeam(
      id: 'team_paramedic_01',
      name: 'City Paramedic Unit 1',
      type: RescueTeamType.paramedic,
      averageResponseTime: 8, // minutes
      isAvailable: true,
    ),
    RescueTeam(
      id: 'team_fire_01',
      name: 'Fire Department Station 5',
      type: RescueTeamType.fireDepartment,
      averageResponseTime: 12,
      isAvailable: true,
    ),
    RescueTeam(
      id: 'team_police_01',
      name: 'Police Unit 23',
      type: RescueTeamType.police,
      averageResponseTime: 6,
      isAvailable: true,
    ),
    RescueTeam(
      id: 'team_sar_01',
      name: 'Mountain Rescue Team',
      type: RescueTeamType.sarTeam,
      averageResponseTime: 25,
      isAvailable: true,
    ),
  ];

  // Callbacks
  Function(SOSSession)? _onSessionUpdated;
  Function(RescueTeamResponse)? _onRescueTeamResponse;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _isInitialized = true;
      debugPrint('RescueResponseService: Initialized successfully');
    } catch (e) {
      debugPrint('RescueResponseService: Initialization error - $e');
      throw Exception('Failed to initialize rescue response service: $e');
    }
  }

  /// Start tracking responses for an SOS session
  Future<void> startTrackingSession(SOSSession session) async {
    _activeSessions[session.id] = session;

    // NOTE: Rescue team dispatch is controlled by SAR admin through dashboard
    // NOT automatically dispatched by the app - removed automatic simulation
    // SAR admin will manually dispatch teams after reviewing the SOS alert

    debugPrint(
      'RescueResponseService: Started tracking session ${session.id} - Awaiting SAR admin dispatch',
    );
  }

  /// Stop tracking responses for an SOS session
  void stopTrackingSession(String sessionId) {
    _activeSessions.remove(sessionId);
    debugPrint('RescueResponseService: Stopped tracking session $sessionId');
  }

  /// PUBLIC METHOD: SAR admin manually dispatches rescue team
  /// Called from SAR dashboard when admin assigns a team to an SOS
  Future<void> dispatchRescueTeamManually({
    required String sessionId,
    required RescueTeam team,
    String? notes,
  }) async {
    final session = _activeSessions[sessionId];
    if (session == null) {
      debugPrint('⚠️ Cannot dispatch team - session $sessionId not found');
      return;
    }

    debugPrint(
      '👨‍💼 SAR Admin dispatching ${team.name} to session $sessionId',
    );

    await _dispatchRescueTeam(
      team,
      session,
      dispatchedBy: 'SAR Admin',
      notes: notes,
    );
  }

  /// Get available rescue teams for SAR admin to choose from
  List<RescueTeam> getAvailableRescueTeams() {
    return _availableRescueTeams.where((t) => t.isAvailable).toList();
  }

  /// Get recommended teams for a specific SOS session
  List<RescueTeam> getRecommendedTeams(String sessionId) {
    final session = _activeSessions[sessionId];
    if (session == null) return [];

    return _selectRescueTeams(session);
  }

  /// Select appropriate rescue teams based on SOS type and severity
  /// Used by SAR admin to see recommended teams for dispatch
  List<RescueTeam> _selectRescueTeams(SOSSession session) {
    final teams = <RescueTeam>[];

    // Always dispatch paramedics for medical emergencies
    final paramedics = _availableRescueTeams
        .where((t) => t.type == RescueTeamType.paramedic && t.isAvailable)
        .take(1);
    teams.addAll(paramedics);

    // Dispatch police for all emergencies
    final police = _availableRescueTeams
        .where((t) => t.type == RescueTeamType.police && t.isAvailable)
        .take(1);
    teams.addAll(police);

    // Dispatch fire department for crash detection
    if (session.type == SOSType.crashDetection) {
      final fire = _availableRescueTeams
          .where(
            (t) => t.type == RescueTeamType.fireDepartment && t.isAvailable,
          )
          .take(1);
      teams.addAll(fire);
    }

    // Dispatch SAR team for outdoor/remote locations (simulated)
    if (session.type == SOSType.fallDetection ||
        session.type == SOSType.manual) {
      final sar = _availableRescueTeams
          .where((t) => t.type == RescueTeamType.sarTeam && t.isAvailable)
          .take(1);
      teams.addAll(sar);
    }

    return teams;
  }

  /// Dispatch a rescue team and simulate their response
  /// Can be called automatically (testing) or manually by SAR admin
  Future<void> _dispatchRescueTeam(
    RescueTeam team,
    SOSSession session, {
    String? dispatchedBy,
    String? notes,
  }) async {
    final dispatchInfo = dispatchedBy != null
        ? 'Dispatched by: $dispatchedBy${notes != null ? " - Notes: $notes" : ""}'
        : 'Team dispatched and en route to your location';

    // Create initial response (acknowledged)
    final response = RescueTeamResponse(
      id: _generateId(),
      teamId: team.id,
      teamName: team.name,
      teamType: team.type,
      status: ResponseStatus.acknowledged,
      responseTime: DateTime.now(),
      estimatedArrival: DateTime.now().add(
        Duration(minutes: team.averageResponseTime),
      ),
      message: dispatchInfo,
      assignedMembers: _generateTeamMembers(team),
      equipment: _generateTeamEquipment(team),
    );

    // Update session with response
    await _addRescueTeamResponse(session.id, response);

    // Notify SOS sender
    await _notifySOSSender(session, response);

    // Production mode - real status updates from Firebase only
  }

  /// Add rescue team response to session
  Future<void> _addRescueTeamResponse(
    String sessionId,
    RescueTeamResponse response,
  ) async {
    final session = _activeSessions[sessionId];
    if (session == null) return;

    final updatedResponses = List<RescueTeamResponse>.from(
      session.rescueTeamResponses,
    );
    final existingIndex = updatedResponses.indexWhere(
      (r) => r.teamId == response.teamId,
    );

    if (existingIndex >= 0) {
      updatedResponses[existingIndex] = response;
    } else {
      updatedResponses.add(response);
    }

    final updatedSession = session.copyWith(
      rescueTeamResponses: updatedResponses,
    );
    _activeSessions[sessionId] = updatedSession;

    _onSessionUpdated?.call(updatedSession);
    _onRescueTeamResponse?.call(response);
  }

  // Removed unused _addEmergencyContactResponse method (not invoked)

  /// Notify SOS sender about responses
  Future<void> _notifySOSSender(
    SOSSession session,
    RescueTeamResponse? rescueResponse, {
    EmergencyContactResponse? emergencyContactResponse,
  }) async {
    try {
      if (rescueResponse != null) {
        await _notifyRescueTeamResponse(session, rescueResponse);
      }

      if (emergencyContactResponse != null) {
        await _notifyEmergencyContactResponse(
          session,
          emergencyContactResponse,
        );
      }
    } catch (e) {
      debugPrint('RescueResponseService: Error sending notification - $e');
    }
  }

  /// Notify about rescue team response
  Future<void> _notifyRescueTeamResponse(
    SOSSession session,
    RescueTeamResponse response,
  ) async {
    String title;
    String body;

    switch (response.status) {
      case ResponseStatus.acknowledged:
        title = '🚑 Rescue Team Dispatched';
        body = '${response.teamName} is responding to your emergency';
        break;
      case ResponseStatus.enRoute:
        title = '🚨 Rescue Team En Route';
        final eta = response.estimatedArrival;
        body = eta != null
            ? '${response.teamName} will arrive in ${_formatETA(eta)}'
            : '${response.teamName} is on the way to your location';
        break;
      case ResponseStatus.onScene:
        title = '✅ Rescue Team On Scene';
        body = '${response.teamName} has arrived at your location';
        break;
      case ResponseStatus.unableToRespond:
        title = '⚠️ Team Unable to Respond';
        body =
            '${response.teamName} is unavailable. Alternative help is being dispatched.';
        break;
      case ResponseStatus.completed:
        title = '✅ Rescue Operation Complete';
        body = 'Emergency response by ${response.teamName} has been completed';
        break;
      case ResponseStatus.cancelled:
        title = '❌ Response Cancelled';
        body = '${response.teamName} response has been cancelled';
        break;
    }

    // Use specific rescue team notification method
    if (response.status == ResponseStatus.acknowledged) {
      await _notificationService.showRescueTeamAcknowledgment(
        response.teamName,
        response.estimatedArrival != null
            ? _formatETA(response.estimatedArrival!)
            : null,
      );
    } else {
      await _notificationService.showRescueStatusUpdate(title, body);
    }

    // Send to chat as well
    await _chatService.sendMessage(
      chatId: 'sos_${session.id}',
      content:
          '$title\n$body${response.message != null ? '\n\n"${response.message}"' : ''}',
      type: chat.MessageType.emergency,
      priority: chat.MessagePriority.high,
    );
  }

  /// Notify about emergency contact response
  Future<void> _notifyEmergencyContactResponse(
    SOSSession session,
    EmergencyContactResponse response,
  ) async {
    final title = '👤 ${response.contactName} Responded';
    final body =
        response.message ??
        'Your emergency contact has acknowledged your SOS alert';

    await _notificationService.showEmergencyContactResponse(
      response.contactName,
      body,
    );

    // Send to chat as well
    await _chatService.sendMessage(
      chatId: 'sos_${session.id}',
      content: '$title\n$body',
      type: chat.MessageType.system,
      priority: chat.MessagePriority.normal,
    );
  }

  // Simulation methods REMOVED - production uses real Firebase updates only

  /// Generate team members for a rescue team
  List<RescueTeamMember> _generateTeamMembers(RescueTeam team) {
    switch (team.type) {
      case RescueTeamType.paramedic:
        return [
          const RescueTeamMember(
            id: 'medic_01',
            name: 'Sarah Johnson',
            role: 'Paramedic',
            specialization: 'Advanced Life Support',
          ),
          const RescueTeamMember(
            id: 'medic_02',
            name: 'Mike Chen',
            role: 'EMT',
            specialization: 'Basic Life Support',
          ),
        ];
      case RescueTeamType.police:
        return [
          const RescueTeamMember(
            id: 'officer_01',
            name: 'Officer Martinez',
            role: 'Police Officer',
          ),
        ];
      case RescueTeamType.fireDepartment:
        return [
          const RescueTeamMember(
            id: 'fire_01',
            name: 'Captain Williams',
            role: 'Fire Captain',
          ),
          const RescueTeamMember(
            id: 'fire_02',
            name: 'Firefighter Davis',
            role: 'Firefighter',
          ),
        ];
      case RescueTeamType.sarTeam:
        return [
          const RescueTeamMember(
            id: 'sar_01',
            name: 'John Smith',
            role: 'SAR Leader',
            specialization: 'Mountain Rescue',
          ),
          const RescueTeamMember(
            id: 'sar_02',
            name: 'Lisa Brown',
            role: 'SAR Medic',
            specialization: 'Wilderness Medicine',
          ),
        ];
      default:
        return [];
    }
  }

  /// Generate equipment for a rescue team
  Map<String, dynamic> _generateTeamEquipment(RescueTeam team) {
    switch (team.type) {
      case RescueTeamType.paramedic:
        return {
          'vehicle': 'Ambulance',
          'medical_equipment': [
            'Defibrillator',
            'Oxygen',
            'IV Supplies',
            'Medications',
          ],
          'communication': ['Radio', 'Mobile Phone'],
        };
      case RescueTeamType.police:
        return {
          'vehicle': 'Police Cruiser',
          'equipment': ['First Aid Kit', 'Traffic Control'],
          'communication': ['Radio', 'Mobile Phone'],
        };
      case RescueTeamType.fireDepartment:
        return {
          'vehicle': 'Fire Engine',
          'equipment': ['Jaws of Life', 'Fire Suppression', 'Rescue Tools'],
          'communication': ['Radio', 'Mobile Phone'],
        };
      case RescueTeamType.sarTeam:
        return {
          'vehicle': '4WD Rescue Vehicle',
          'equipment': [
            'Rope Rescue Gear',
            'Medical Kit',
            'GPS',
            'Helicopter Support',
          ],
          'communication': ['Satellite Radio', 'Mobile Phone'],
        };
      default:
        return {};
    }
  }

  /// Format ETA for display
  String _formatETA(DateTime eta) {
    final now = DateTime.now();
    final difference = eta.difference(now);

    if (difference.inMinutes < 1) {
      return 'less than 1 minute';
    } else if (difference.inMinutes == 1) {
      return '1 minute';
    } else {
      return '${difference.inMinutes} minutes';
    }
  }

  /// Generate unique ID
  String _generateId() {
    return 'resp_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  // Getters
  SOSSession? getSession(String sessionId) => _activeSessions[sessionId];
  List<SOSSession> get activeSessions => _activeSessions.values.toList();

  // Callback setters
  void setSessionUpdatedCallback(Function(SOSSession) callback) {
    _onSessionUpdated = callback;
  }

  void setRescueTeamResponseCallback(Function(RescueTeamResponse) callback) {
    _onRescueTeamResponse = callback;
  }

  // Removed unused emergency contact response callback setter and field

  /// Dispose resources
  void dispose() {
    _activeSessions.clear();
  }
}

/// Rescue team information (for simulation)
class RescueTeam {
  final String id;
  final String name;
  final RescueTeamType type;
  final int averageResponseTime; // minutes
  final bool isAvailable;

  const RescueTeam({
    required this.id,
    required this.name,
    required this.type,
    required this.averageResponseTime,
    required this.isAvailable,
  });
}
