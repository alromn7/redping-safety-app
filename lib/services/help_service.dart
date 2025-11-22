import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/help_request.dart';
import '../models/help_category.dart';
import '../models/help_response.dart';
import '../models/user_profile.dart';
import '../models/location_data.dart';
import '../services/location_service.dart';
import '../services/messaging_integration_service.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../config/google_cloud_config.dart';
import 'firebase_help_service.dart';

/// Service for managing REDP!NG Help and Support requests
///
/// This service handles the complete lifecycle of help requests:
/// - Creating and managing help requests
/// - Connecting with local services and community helpers
/// - Real-time communication and status updates
/// - Integration with REDP!NG SAR system
class HelpService {
  static final HelpService _instance = HelpService._internal();
  factory HelpService() => _instance;
  HelpService._internal();

  // Dependencies
  final LocationService _locationService = LocationService();
  final MessagingIntegrationService _messagingService =
      MessagingIntegrationService();
  final NotificationService _notificationService = NotificationService();
  final FirebaseHelpService _firebaseService = FirebaseHelpService();

  // State
  final List<HelpRequest> _activeRequests = [];
  final List<HelpRequest> _completedRequests = [];
  final Map<String, List<HelpResponse>> _responses = {};
  bool _isInitialized = false;

  // Streams
  final StreamController<List<HelpRequest>> _requestsStreamController =
      StreamController<List<HelpRequest>>.broadcast();
  final StreamController<HelpRequest> _requestUpdateStreamController =
      StreamController<HelpRequest>.broadcast();
  final StreamController<HelpResponse> _responseStreamController =
      StreamController<HelpResponse>.broadcast();

  // Getters
  Stream<List<HelpRequest>> get requestsStream =>
      _requestsStreamController.stream;
  Stream<HelpRequest> get requestUpdateStream =>
      _requestUpdateStreamController.stream;
  Stream<HelpResponse> get responseStream => _responseStreamController.stream;
  List<HelpRequest> get activeRequests => List.unmodifiable(_activeRequests);
  List<HelpRequest> get completedRequests =>
      List.unmodifiable(_completedRequests);
  bool get isInitialized => _isInitialized;

  /// Initialize the Help Service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize dependencies
      await _locationService.initialize();
      await _messagingService.initialize();
      await _notificationService.initialize();
      // Firebase service doesn't need initialization

      // Set up Firebase listeners
      _setupFirebaseListeners();

      // Load existing requests
      await _loadExistingRequests();

      _isInitialized = true;
      debugPrint('HelpService: Initialized successfully');
    } catch (e) {
      debugPrint('HelpService: Initialization failed - $e');
      rethrow;
    }
  }

  /// Create a new help request
  Future<HelpRequest> createHelpRequest({
    required String categoryId,
    String? subCategoryId,
    required String description,
    String? additionalInfo,
    List<String>? attachments,
    UserProfile? userProfile,
  }) async {
    if (!_isInitialized) {
      throw Exception('HelpService not initialized');
    }

    try {
      // Get current location
      final locationInfo = await _locationService.getCurrentLocation();
      final location = LocationData(
        latitude: locationInfo?.latitude ?? 0.0,
        longitude: locationInfo?.longitude ?? 0.0,
        address: locationInfo?.address ?? 'Unknown location',
        city: locationInfo?.address ?? 'Unknown',
        state: locationInfo?.address ?? 'Unknown',
        country: locationInfo?.address ?? 'Unknown',
        accuracy: locationInfo?.accuracy,
        timestamp: DateTime.now(),
      );

      // Get user profile from AuthService if not provided
      UserProfile? profile = userProfile;
      if (profile == null) {
        final authUser = AuthService.instance.currentUser;
        debugPrint(
          'HelpService: AuthUser ID: ${authUser.id}, Email: ${authUser.email}',
        );

        if (authUser.id.isNotEmpty) {
          // Try to load profile from Firestore using BOTH possible ID formats
          try {
            // Try with current auth ID first
            var docRef = FirebaseFirestore.instance
                .collection(GoogleCloudConfig.firestoreCollectionUsers)
                .doc(authUser.id);
            debugPrint(
              'HelpService: Looking for profile at users/${authUser.id}',
            );

            var snap = await docRef.get();
            debugPrint(
              'HelpService: Profile exists at ${authUser.id}: ${snap.exists}',
            );

            // If not found, try with redping_user_ prefix (legacy format)
            if (!snap.exists) {
              final legacyId = 'redping_${authUser.id}';
              docRef = FirebaseFirestore.instance
                  .collection(GoogleCloudConfig.firestoreCollectionUsers)
                  .doc(legacyId);
              debugPrint('HelpService: Trying legacy format: users/$legacyId');
              snap = await docRef.get();
              debugPrint(
                'HelpService: Profile exists at $legacyId: ${snap.exists}',
              );
            }

            if (snap.exists && snap.data() != null) {
              final data = Map<String, dynamic>.from(snap.data()!);
              data['id'] = data['id'] ?? authUser.id;
              profile = UserProfile.fromJson(data);
              debugPrint(
                'HelpService: Loaded profile - Name: ${profile.name}, Phone: ${profile.phoneNumber}',
              );
            } else {
              debugPrint(
                'HelpService: No profile found in Firestore, using AuthUser data',
              );
              // Create profile from AuthUser data
              profile = UserProfile(
                id: authUser.id,
                name: authUser.displayName.isNotEmpty
                    ? authUser.displayName
                    : 'User',
                email: authUser.email,
                phoneNumber: authUser.phoneNumber,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              debugPrint(
                'HelpService: Created profile from AuthUser - Name: ${profile.name}, Phone: ${profile.phoneNumber}',
              );
            }
          } catch (e) {
            debugPrint('HelpService: Could not load user profile - $e');
          }
        } else {
          debugPrint(
            'HelpService: AuthUser ID is empty, user not authenticated',
          );
        }
      } else {
        debugPrint(
          'HelpService: Using provided userProfile - Name: ${profile.name}, Phone: ${profile.phoneNumber}',
        );
      }

      // Prefer Firebase Auth UID for owner alignment with rules
      final authUid = FirebaseAuth.instance.currentUser?.uid;

      // Create help request
      final request = HelpRequest(
        id: _generateRequestId(),
        userId: authUid ?? profile?.id ?? 'anonymous',
        userName: profile?.name ?? 'Anonymous User',
        userPhone: profile?.phoneNumber ?? profile?.phone,
        userEmail: profile?.email,
        categoryId: categoryId,
        subCategoryId: subCategoryId,
        description: description,
        additionalInfo: additionalInfo,
        location: location,
        status: HelpRequestStatus.active,
        priority: _getCategoryPriority(categoryId),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        attachments: attachments ?? [],
        assignedHelpers: [],
        responses: [],
      );

      debugPrint('HelpService: Created help request:');
      debugPrint('  - ID: ${request.id}');
      debugPrint('  - User ID: ${request.userId}');
      debugPrint('  - User Name: ${request.userName}');
      debugPrint('  - User Phone: ${request.userPhone}');
      debugPrint('  - User Email: ${request.userEmail}');

      // Save to Firebase
      await _firebaseService.saveHelpRequest(request);

      // Add to local list
      _activeRequests.add(request);
      _requestsStreamController.add(_activeRequests);

      // Send notification to local services
      await _notifyLocalServices(request);

      // Send notification to local services (no messaging for now)
      // TODO: Implement proper help request messaging
      debugPrint('HelpService: Help request created - ${request.id}');

      debugPrint('HelpService: Created help request - ${request.id}');
      return request;
    } catch (e) {
      debugPrint('HelpService: Error creating help request - $e');
      rethrow;
    }
  }

  /// Get help request by ID
  HelpRequest? getHelpRequest(String requestId) {
    return _activeRequests.firstWhere(
      (request) => request.id == requestId,
      orElse: () => _completedRequests.firstWhere(
        (request) => request.id == requestId,
        orElse: () => throw Exception('Help request not found'),
      ),
    );
  }

  /// Update help request status
  Future<void> updateRequestStatus(
    String requestId,
    HelpRequestStatus status,
  ) async {
    try {
      final request = getHelpRequest(requestId);
      if (request == null) return;

      final updatedRequest = request.copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );

      // Update in Firebase
      await _firebaseService.updateHelpRequest(updatedRequest);

      // Update local list
      final index = _activeRequests.indexWhere((r) => r.id == requestId);
      if (index != -1) {
        _activeRequests[index] = updatedRequest;
      } else {
        final completedIndex = _completedRequests.indexWhere(
          (r) => r.id == requestId,
        );
        if (completedIndex != -1) {
          _completedRequests[completedIndex] = updatedRequest;
        }
      }

      // Move to completed if resolved
      if (status == HelpRequestStatus.resolved) {
        _activeRequests.removeWhere((r) => r.id == requestId);
        _completedRequests.add(updatedRequest);
      }

      _requestsStreamController.add(_activeRequests);
      _requestUpdateStreamController.add(updatedRequest);

      debugPrint('HelpService: Updated request status - $requestId: $status');
    } catch (e) {
      debugPrint('HelpService: Error updating request status - $e');
      rethrow;
    }
  }

  /// Add response to help request
  Future<void> addResponse({
    required String requestId,
    required String responderId,
    required String responderName,
    required String message,
    required HelpResponseType type,
    String? contactInfo,
    List<String>? attachments,
  }) async {
    try {
      final response = HelpResponse(
        id: _generateResponseId(),
        requestId: requestId,
        responderId: responderId,
        responderName: responderName,
        message: message,
        type: type,
        contactInfo: contactInfo,
        attachments: attachments ?? [],
        createdAt: DateTime.now(),
        isAccepted: false,
      );

      // Save to Firebase
      await _firebaseService.saveHelpResponse(response);

      // Add to local responses
      if (!_responses.containsKey(requestId)) {
        _responses[requestId] = [];
      }
      _responses[requestId]!.add(response);

      // Update request
      final request = getHelpRequest(requestId);
      if (request != null) {
        final updatedRequest = request.copyWith(
          responses: [...request.responses, response],
          updatedAt: DateTime.now(),
        );

        await _firebaseService.updateHelpRequest(updatedRequest);
        _requestUpdateStreamController.add(updatedRequest);
      }

      // Send notification to user
      await _notificationService.showNotification(
        title: 'New Response to Your Help Request',
        body: message,
      );

      _responseStreamController.add(response);
      debugPrint('HelpService: Added response to request - $requestId');
    } catch (e) {
      debugPrint('HelpService: Error adding response - $e');
      rethrow;
    }
  }

  /// Accept a help response
  Future<void> acceptResponse(String requestId, String responseId) async {
    try {
      final responses = _responses[requestId] ?? [];
      final responseIndex = responses.indexWhere((r) => r.id == responseId);

      if (responseIndex != -1) {
        final response = responses[responseIndex];
        final acceptedResponse = response.copyWith(isAccepted: true);

        responses[responseIndex] = acceptedResponse;
        _responses[requestId] = responses;

        // Update in Firebase
        await _firebaseService.updateHelpResponse(acceptedResponse);

        // Update request status
        await updateRequestStatus(requestId, HelpRequestStatus.assigned);

        // Notify responder
        await _notificationService.showNotification(
          title: 'Response Accepted',
          body: 'Your help response has been accepted',
        );

        _responseStreamController.add(acceptedResponse);
        debugPrint('HelpService: Accepted response - $responseId');
      }
    } catch (e) {
      debugPrint('HelpService: Error accepting response - $e');
      rethrow;
    }
  }

  /// Get responses for a help request
  List<HelpResponse> getResponses(String requestId) {
    return _responses[requestId] ?? [];
  }

  /// Get help categories
  List<HelpCategory> getHelpCategories() {
    return [
      // Emergency Services Categories
      HelpCategory(
        id: 'fire_emergency',
        name: 'Fire Emergency',
        description: 'Fire-related emergencies and hazards',
        icon: 'local_fire_department',
        priority: HelpPriority.critical,
        requiredServices: ['Fire Department', 'Emergency Services'],
        subCategories: [
          HelpSubCategory(
            id: 'structure_fire',
            name: 'Building Fire',
            description: 'Fire in building, house, or structure',
            icon: 'home',
            requiredEquipment: ['Fire Extinguisher', 'Fire Blanket'],
            requiredSkills: ['Emergency Evacuation'],
          ),
          HelpSubCategory(
            id: 'vehicle_fire',
            name: 'Vehicle Fire',
            description: 'Car, truck, or vehicle on fire',
            icon: 'local_fire_department',
            requiredEquipment: ['Fire Extinguisher'],
            requiredSkills: ['Safe Distance', 'Emergency Response'],
          ),
          HelpSubCategory(
            id: 'wildfire',
            name: 'Wildfire/Bush Fire',
            description: 'Forest or grassland fire',
            icon: 'nature',
            requiredEquipment: ['Evacuation Kit'],
            requiredSkills: ['Evacuation Planning'],
          ),
          HelpSubCategory(
            id: 'smoke_hazard',
            name: 'Smoke/Gas Leak',
            description: 'Smoke or gas leak detected',
            icon: 'cloud',
            requiredEquipment: ['Gas Detector'],
            requiredSkills: ['Ventilation', 'Evacuation'],
          ),
        ],
      ),
      HelpCategory(
        id: 'police_emergency',
        name: 'Police Emergency',
        description: 'Crime, safety threats, or police assistance needed',
        icon: 'local_police',
        priority: HelpPriority.critical,
        requiredServices: ['Police', 'Law Enforcement', 'Security'],
        subCategories: [
          HelpSubCategory(
            id: 'assault_violence',
            name: 'Assault/Violence',
            description: 'Physical attack or violence in progress',
            icon: 'priority_high',
            requiredEquipment: ['Phone'],
            requiredSkills: ['Emergency Response', 'Safety'],
          ),
          HelpSubCategory(
            id: 'robbery_theft',
            name: 'Robbery/Theft',
            description: 'Theft or robbery in progress',
            icon: 'warning',
            requiredEquipment: ['Phone', 'Camera'],
            requiredSkills: ['Observation', 'Reporting'],
          ),
          HelpSubCategory(
            id: 'domestic_violence',
            name: 'Domestic Violence',
            description: 'Domestic abuse or family violence',
            icon: 'home',
            requiredEquipment: ['Safe Location'],
            requiredSkills: ['Crisis Support'],
          ),
          HelpSubCategory(
            id: 'suspicious_activity',
            name: 'Suspicious Activity',
            description: 'Suspicious person or behavior',
            icon: 'visibility',
            requiredEquipment: ['Camera'],
            requiredSkills: ['Observation', 'Reporting'],
          ),
        ],
      ),
      HelpCategory(
        id: 'medical_emergency',
        name: 'Medical Emergency',
        description: 'Medical emergencies requiring immediate attention',
        icon: 'medical_services',
        priority: HelpPriority.critical,
        requiredServices: ['Ambulance', 'Paramedics', 'Hospital'],
        subCategories: [
          HelpSubCategory(
            id: 'heart_attack',
            name: 'Heart Attack/Chest Pain',
            description: 'Severe chest pain or suspected heart attack',
            icon: 'favorite',
            requiredEquipment: ['AED', 'First Aid Kit'],
            requiredSkills: ['CPR', 'First Aid'],
          ),
          HelpSubCategory(
            id: 'difficulty_breathing',
            name: 'Difficulty Breathing',
            description: 'Severe breathing problems or choking',
            icon: 'air',
            requiredEquipment: ['Oxygen', 'Inhaler'],
            requiredSkills: ['Heimlich Maneuver', 'CPR'],
          ),
          HelpSubCategory(
            id: 'severe_bleeding',
            name: 'Severe Bleeding',
            description: 'Uncontrolled bleeding or major injury',
            icon: 'bloodtype',
            requiredEquipment: ['Bandages', 'Tourniquet'],
            requiredSkills: ['Wound Care', 'Pressure Application'],
          ),
          HelpSubCategory(
            id: 'unconscious',
            name: 'Unconscious Person',
            description: 'Person unconscious or unresponsive',
            icon: 'personal_injury',
            requiredEquipment: ['First Aid Kit'],
            requiredSkills: ['Recovery Position', 'CPR'],
          ),
          HelpSubCategory(
            id: 'overdose',
            name: 'Drug Overdose',
            description: 'Drug or alcohol overdose',
            icon: 'medication',
            requiredEquipment: ['Naloxone/Narcan'],
            requiredSkills: ['First Aid', 'Recovery Position'],
          ),
        ],
      ),
      HelpCategory(
        id: 'hazard_report',
        name: 'Hazard Report',
        description: 'Environmental hazards and public safety threats',
        icon: 'warning',
        priority: HelpPriority.high,
        requiredServices: ['Emergency Services', 'Utilities', 'Public Safety'],
        subCategories: [
          HelpSubCategory(
            id: 'power_lines_down',
            name: 'Downed Power Lines',
            description: 'Electrical lines down or sparking',
            icon: 'power',
            requiredEquipment: ['Warning Signs'],
            requiredSkills: ['Safety Distance', 'Area Cordoning'],
          ),
          HelpSubCategory(
            id: 'gas_leak',
            name: 'Gas Leak',
            description: 'Natural gas or propane leak',
            icon: 'gas_meter',
            requiredEquipment: ['Gas Detector'],
            requiredSkills: ['Evacuation', 'Ventilation'],
          ),
          HelpSubCategory(
            id: 'chemical_spill',
            name: 'Chemical Spill',
            description: 'Hazardous chemical spill or contamination',
            icon: 'science',
            requiredEquipment: ['Protective Gear', 'Containment'],
            requiredSkills: ['Hazmat Response', 'Evacuation'],
          ),
          HelpSubCategory(
            id: 'flooding',
            name: 'Flooding/Water Hazard',
            description: 'Flood, water main break, or water hazard',
            icon: 'water',
            requiredEquipment: ['Sandbags', 'Pumps'],
            requiredSkills: ['Water Damage Control'],
          ),
          HelpSubCategory(
            id: 'road_hazard',
            name: 'Road Hazard',
            description: 'Dangerous road condition or obstruction',
            icon: 'warning_amber',
            requiredEquipment: ['Warning Signs', 'Flares'],
            requiredSkills: ['Traffic Management'],
          ),
        ],
      ),

      // Existing Categories
      HelpCategory(
        id: 'vehicle_breakdown',
        name: 'Vehicle Breakdown',
        description: 'Car, truck, or motorcycle mechanical issues',
        icon: 'car_repair',
        priority: HelpPriority.low,
        requiredServices: ['Mechanic', 'Tow Service', 'Roadside Assistance'],
        subCategories: [
          HelpSubCategory(
            id: 'tire_issues',
            name: 'Tire Issues',
            description: 'Flat tire, tire damage, or tire replacement',
            icon: 'tire_repair',
            requiredEquipment: [
              'Spare Tire',
              'Jack',
              'Lug Wrench',
              'Tire Pressure Gauge',
            ],
            requiredSkills: ['Tire Changing', 'Basic Mechanics'],
          ),
          HelpSubCategory(
            id: 'battery_problems',
            name: 'Battery Problems',
            description:
                'Dead battery, battery replacement, or charging issues',
            icon: 'battery_charging_full',
            requiredEquipment: [
              'Jump Starter',
              'Battery Charger',
              'Multimeter',
              'Battery Cables',
            ],
            requiredSkills: ['Electrical Diagnostics', 'Battery Replacement'],
          ),
          HelpSubCategory(
            id: 'fuel_issues',
            name: 'Fuel Issues',
            description: 'Out of fuel, fuel system problems, or fuel delivery',
            icon: 'local_gas_station',
            requiredEquipment: [
              'Fuel Container',
              'Fuel Pump',
              'Fuel Line Tools',
            ],
            requiredSkills: [
              'Fuel System Diagnostics',
              'Emergency Fuel Delivery',
            ],
          ),
          HelpSubCategory(
            id: 'accident_damage',
            name: 'Accident Damage',
            description: 'Vehicle damage from collision or accident',
            icon: 'car_crash',
            requiredEquipment: [
              'Tow Truck',
              'Safety Equipment',
              'Damage Assessment Tools',
            ],
            requiredSkills: [
              'Accident Assessment',
              'Towing',
              'Insurance Documentation',
            ],
          ),
          HelpSubCategory(
            id: 'engine_problems',
            name: 'Engine Problems',
            description:
                'Engine won\'t start, overheating, or mechanical failure',
            icon: 'build',
            requiredEquipment: [
              'Diagnostic Tools',
              'Engine Parts',
              'Cooling System Tools',
            ],
            requiredSkills: ['Engine Diagnostics', 'Mechanical Repair'],
          ),
          HelpSubCategory(
            id: 'towing_needed',
            name: 'Towing Required',
            description: 'Vehicle needs to be towed to repair shop',
            icon: 'local_shipping',
            requiredEquipment: ['Tow Truck', 'Towing Equipment', 'Safety Gear'],
            requiredSkills: ['Towing Operations', 'Vehicle Securing'],
          ),
        ],
      ),
      HelpCategory(
        id: 'boat_breakdown',
        name: 'Boat Breakdown',
        description: 'Marine vessel mechanical issues',
        icon: 'directions_boat',
        priority: HelpPriority.medium,
        requiredServices: ['Marine Mechanic', 'Coast Guard', 'Marine Rescue'],
        subCategories: [
          HelpSubCategory(
            id: 'engine_failure',
            name: 'Engine Failure',
            description: 'Boat engine won\'t start or has mechanical issues',
            icon: 'build',
            requiredEquipment: [
              'Marine Engine Parts',
              'Diagnostic Tools',
              'Fuel System Tools',
            ],
            requiredSkills: ['Marine Engine Repair', 'Engine Diagnostics'],
          ),
          HelpSubCategory(
            id: 'fuel_problems',
            name: 'Fuel Problems',
            description: 'Out of fuel or fuel system issues on water',
            icon: 'local_gas_station',
            requiredEquipment: [
              'Marine Fuel Container',
              'Fuel Transfer Pump',
              'Safety Equipment',
            ],
            requiredSkills: ['Marine Fuel Delivery', 'Water Safety'],
          ),
          HelpSubCategory(
            id: 'electrical_issues',
            name: 'Electrical Issues',
            description: 'Boat electrical system problems or dead battery',
            icon: 'electrical_services',
            requiredEquipment: [
              'Marine Battery',
              'Electrical Tools',
              'Multimeter',
            ],
            requiredSkills: [
              'Marine Electrical Systems',
              'Battery Replacement',
            ],
          ),
          HelpSubCategory(
            id: 'propeller_damage',
            name: 'Propeller Damage',
            description: 'Propeller damage or propeller-related issues',
            icon: 'propeller',
            requiredEquipment: [
              'Propeller Tools',
              'Replacement Propeller',
              'Diving Equipment',
            ],
            requiredSkills: ['Propeller Repair', 'Underwater Work'],
          ),
          HelpSubCategory(
            id: 'stranded_boat',
            name: 'Stranded Boat',
            description: 'Boat stranded and needs towing or rescue',
            icon: 'local_shipping',
            requiredEquipment: ['Tow Rope', 'Rescue Equipment', 'Safety Gear'],
            requiredSkills: ['Marine Towing', 'Water Rescue'],
          ),
        ],
      ),
      HelpCategory(
        id: 'domestic_violence',
        name: 'Domestic Violence',
        description: 'Domestic abuse or violence situations',
        icon: 'security',
        priority: HelpPriority.critical,
        requiredServices: [
          'Police',
          'Domestic Violence Hotline',
          'Social Services',
        ],
        subCategories: [
          HelpSubCategory(
            id: 'immediate_danger',
            name: 'Immediate Danger',
            description: 'Threat is present now; need urgent assistance',
            icon: 'warning',
            requiredEquipment: ['Phone', 'Safe Location Info'],
            requiredSkills: ['De-escalation', 'Emergency Response'],
          ),
          HelpSubCategory(
            id: 'safe_shelter',
            name: 'Find Safe Shelter',
            description: 'Need a safe place or shelter',
            icon: 'home',
            requiredEquipment: ['Shelter Contacts'],
            requiredSkills: ['Resource Coordination'],
          ),
          HelpSubCategory(
            id: 'legal_support',
            name: 'Legal Support',
            description: 'Restraining orders, legal guidance',
            icon: 'gavel',
            requiredEquipment: ['Legal Aid Contacts'],
            requiredSkills: ['Legal Guidance'],
          ),
        ],
      ),
      HelpCategory(
        id: 'lost_pet',
        name: 'Lost Pet',
        description: 'Missing pet or animal rescue',
        icon: 'pets',
        priority: HelpPriority.low,
        requiredServices: ['Animal Control', 'Pet Rescue', 'Veterinarian'],
        subCategories: [
          HelpSubCategory(
            id: 'lost_dog',
            name: 'Lost Dog',
            description: 'Missing dog - help with search and identification',
            icon: 'pets',
            requiredEquipment: ['Pet Tracker', 'Leash', 'Treats', 'Pet Photo'],
            requiredSkills: ['Animal Handling', 'Search Techniques'],
          ),
          HelpSubCategory(
            id: 'lost_cat',
            name: 'Lost Cat',
            description: 'Missing cat - help with search and recovery',
            icon: 'pets',
            requiredEquipment: ['Carrier', 'Food', 'Pet Photo', 'Flashlight'],
            requiredSkills: ['Cat Behavior', 'Search Techniques'],
          ),
          HelpSubCategory(
            id: 'lost_bird',
            name: 'Lost Bird',
            description: 'Missing bird or exotic pet',
            icon: 'flutter_dash',
            requiredEquipment: ['Bird Cage', 'Bird Food', 'Net', 'Pet Photo'],
            requiredSkills: ['Bird Handling', 'Capture Techniques'],
          ),
          HelpSubCategory(
            id: 'injured_pet',
            name: 'Injured Pet Found',
            description: 'Found an injured animal needing help',
            icon: 'medical_services',
            requiredEquipment: [
              'First Aid Kit',
              'Carrier',
              'Gloves',
              'Blanket',
            ],
            requiredSkills: ['Animal First Aid', 'Emergency Transport'],
          ),
          HelpSubCategory(
            id: 'stray_animal',
            name: 'Stray Animal',
            description: 'Found a stray animal that needs assistance',
            icon: 'home',
            requiredEquipment: ['Carrier', 'Food', 'Water', 'Leash'],
            requiredSkills: ['Animal Handling', 'Temporary Care'],
          ),
        ],
      ),
      HelpCategory(
        id: 'home_break_in',
        name: 'Home Break-In',
        description: 'Burglary or home security breach',
        icon: 'home_work',
        priority: HelpPriority.high,
        requiredServices: ['Police', 'Security Company', 'Insurance'],
        subCategories: [
          HelpSubCategory(
            id: 'ongoing_break_in',
            name: 'Ongoing Break-In',
            description: 'Intruder present or suspected right now',
            icon: 'priority_high',
            requiredEquipment: ['Phone'],
            requiredSkills: ['Emergency Response'],
          ),
          HelpSubCategory(
            id: 'after_theft',
            name: 'After Theft - Report & Secure',
            description: 'Property stolen; need to report and secure home',
            icon: 'report',
            requiredEquipment: ['Locksmith Contact'],
            requiredSkills: ['Documentation', 'Security'],
          ),
        ],
      ),
      HelpCategory(
        id: 'drug_abuse',
        name: 'Drug Abuse',
        description: 'Substance abuse or overdose situations',
        icon: 'medical_services',
        priority: HelpPriority.high,
        requiredServices: ['Medical Emergency', 'Addiction Services', 'Police'],
        subCategories: [
          HelpSubCategory(
            id: 'overdose',
            name: 'Overdose - Medical Emergency',
            description: 'Possible overdose; need urgent medical help',
            icon: 'medical_services',
            requiredEquipment: ['First Aid'],
            requiredSkills: ['Emergency Response'],
          ),
          HelpSubCategory(
            id: 'support_services',
            name: 'Find Support Services',
            description: 'Rehab, counseling, addiction support',
            icon: 'support',
            requiredEquipment: ['Support Contacts'],
            requiredSkills: ['Resource Coordination'],
          ),
        ],
      ),
      HelpCategory(
        id: 'criminal_activity',
        name: 'Criminal Activity',
        description: 'Suspected or witnessed criminal behavior',
        icon: 'warning',
        priority: HelpPriority.high,
        requiredServices: ['Police', 'Security', 'Legal Services'],
        subCategories: [
          HelpSubCategory(
            id: 'violence',
            name: 'Violence / Assault',
            description: 'Physical threat or assault',
            icon: 'priority_high',
            requiredEquipment: ['Phone'],
            requiredSkills: ['Emergency Response'],
          ),
          HelpSubCategory(
            id: 'suspicious_activity',
            name: 'Suspicious Activity',
            description: 'Suspicious persons or behavior',
            icon: 'visibility',
            requiredEquipment: ['Camera'],
            requiredSkills: ['Observation', 'Reporting'],
          ),
        ],
      ),
      HelpCategory(
        id: 'kidnapping',
        name: 'Kidnapping',
        description: 'Abduction or kidnapping situations',
        icon: 'person_search',
        priority: HelpPriority.critical,
        requiredServices: ['Police', 'FBI', 'Emergency Services'],
      ),
      HelpCategory(
        id: 'car_theft',
        name: 'Car Theft',
        description: 'Vehicle theft or carjacking',
        icon: 'car_crash',
        priority: HelpPriority.high,
        requiredServices: ['Police', 'Insurance', 'Security'],
      ),
      HelpCategory(
        id: 'lost_item',
        name: 'Lost Item',
        description: 'Missing personal belongings',
        icon: 'search',
        priority: HelpPriority.low,
        requiredServices: ['Lost & Found', 'Security', 'Community Services'],
        subCategories: [
          HelpSubCategory(
            id: 'lost_id_wallet',
            name: 'ID / Wallet',
            description: 'IDs, wallet, bank cards, licenses',
            icon: 'wallet',
            requiredEquipment: ['ID Numbers'],
            requiredSkills: ['Report & Block Cards'],
          ),
          HelpSubCategory(
            id: 'lost_electronics',
            name: 'Electronics',
            description: 'Phone, laptop, tablet, headphones',
            icon: 'devices',
            requiredEquipment: ['Serial Numbers'],
            requiredSkills: ['Device Tracking'],
          ),
          HelpSubCategory(
            id: 'lost_documents',
            name: 'Documents',
            description: 'Passport, certificates, important papers',
            icon: 'description',
            requiredEquipment: ['Document Details'],
            requiredSkills: ['Replacement Process'],
          ),
        ],
      ),
      HelpCategory(
        id: 'theft_report',
        name: 'Theft Report',
        description: 'Stolen property or theft incidents',
        icon: 'report',
        priority: HelpPriority.medium,
        requiredServices: ['Police', 'Insurance', 'Security'],
        subCategories: [
          HelpSubCategory(
            id: 'theft_in_progress',
            name: 'Theft In Progress',
            description: 'Suspect on site or close by - urgent response',
            icon: 'priority_high',
            requiredEquipment: ['Phone', 'Camera'],
            requiredSkills: ['Emergency Response', 'Observation'],
          ),
          HelpSubCategory(
            id: 'post_theft_report',
            name: 'After Incident - File Report',
            description: 'Document and report the theft after it happened',
            icon: 'report',
            requiredEquipment: ['Photos', 'Serial Numbers', 'Receipts'],
            requiredSkills: ['Documentation'],
          ),
          HelpSubCategory(
            id: 'insurance_support',
            name: 'Insurance Support',
            description: 'Guidance on claim filing and documentation',
            icon: 'assignment',
            requiredEquipment: ['Policy Details'],
            requiredSkills: ['Claims Guidance'],
          ),
        ],
      ),
      HelpCategory(
        id: 'community_support',
        name: 'Community Support',
        description: 'General community assistance needs',
        icon: 'people',
        priority: HelpPriority.low,
        requiredServices: [
          'Community Services',
          'Social Services',
          'Volunteers',
        ],
      ),
    ];
  }

  /// Setup Firebase listeners
  void _setupFirebaseListeners() {
    // Listen for new help requests
    _firebaseService.helpRequestsStream.listen((requests) {
      _activeRequests.clear();
      _activeRequests.addAll(
        requests.where((r) => r.status != HelpRequestStatus.resolved),
      );
      _completedRequests.clear();
      _completedRequests.addAll(
        requests.where((r) => r.status == HelpRequestStatus.resolved),
      );
      _requestsStreamController.add(_activeRequests);
    });

    // Listen for help responses
    _firebaseService.helpResponsesStream.listen((responses) {
      for (final response in responses) {
        if (!_responses.containsKey(response.requestId)) {
          _responses[response.requestId] = [];
        }
        _responses[response.requestId]!.add(response);
        _responseStreamController.add(response);
      }
    });
  }

  /// Load existing requests from Firebase
  Future<void> _loadExistingRequests() async {
    try {
      final requests = await _firebaseService.getHelpRequests();
      _activeRequests.clear();
      _completedRequests.clear();

      for (final request in requests) {
        if (request.status == HelpRequestStatus.resolved) {
          _completedRequests.add(request);
        } else {
          _activeRequests.add(request);
        }
      }

      _requestsStreamController.add(_activeRequests);
    } catch (e) {
      debugPrint('HelpService: Error loading existing requests - $e');
    }
  }

  /// Notify local services about new help request
  Future<void> _notifyLocalServices(HelpRequest request) async {
    try {
      // Send notification to local services
      await _notificationService.showNotification(
        title: 'Help Request Created',
        body:
            'Your help request has been submitted successfully. Response depends on local service availability.',
      );

      debugPrint(
        'HelpService: Local services notified for request ${request.id}',
      );
    } catch (e) {
      debugPrint('HelpService: Error notifying local services - $e');
    }
  }

  /// Get category priority
  HelpPriority _getCategoryPriority(String categoryId) {
    final category = getHelpCategories().firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => throw Exception('Category not found'),
    );
    return category.priority;
  }

  /// Generate unique request ID
  String _generateRequestId() {
    return 'help_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// Generate unique response ID
  String _generateResponseId() {
    return 'response_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecond}';
  }

  /// Dispose resources
  void dispose() {
    _requestsStreamController.close();
    _requestUpdateStreamController.close();
    _responseStreamController.close();
  }
}
