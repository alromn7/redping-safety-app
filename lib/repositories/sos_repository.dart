import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../config/google_cloud_config.dart';
import '../models/sos_session.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/emergency_contacts_service.dart';
import '../services/location_service.dart';
import '../services/connectivity_monitor_service.dart';

/// Repository responsible for persisting SOS sessions to Firestore.
/// Centralizes create/update logic and ensures data is safe for Firestore.
class SosRepository {
  SosRepository();

  CollectionReference<Map<String, dynamic>> get _collection => FirebaseFirestore
      .instance
      .collection(GoogleCloudConfig.firestoreCollectionSosAlerts)
      .withConverter<Map<String, dynamic>>(
        fromFirestore: (snap, _) =>
            Map<String, dynamic>.from(snap.data() ?? {}),
        toFirestore: (data, _) => Map<String, dynamic>.from(data),
      );

  /// Create or update a session document using the session.id as document id.
  /// Returns the document id.
  Future<String> createOrUpdateFromSession(SOSSession session) async {
    final docId = session.id; // Use app-side id for correlation
    final ref = _collection.doc(docId);

    final data = await _buildSessionPayload(session);
    _cleanFirestoreData(data);

    await ref.set(data, SetOptions(merge: true));
    return docId;
  }

  /// Append a location ping to subcollection: sos_sessions/{id}/locations/{autoId}
  Future<void> addLocationPing(String sessionId, LocationInfo location) async {
    try {
      final ref = _collection.doc(sessionId).collection('locations');
      final data = {
        'lat': location.latitude,
        'lng': location.longitude,
        'accuracy': location.accuracy,
        if (location.altitude != null) 'altitude': location.altitude,
        if (location.speed != null) 'speed': location.speed,
        if (location.heading != null) 'heading': location.heading,
        'ts': FieldValue.serverTimestamp(),
        'source': 'gps',
        if (location.address != null && location.address!.isNotEmpty)
          'address': location.address,
      };
      _cleanFirestoreData(data);
      await ref.add(data);
    } catch (e) {
      _maybeLogOfflineError('add location ping', e);
    }
  }

  /// Update the session header with the latest summarized location and updatedAt timestamp.
  Future<void> updateLatestLocation(
    String sessionId,
    LocationInfo location,
  ) async {
    try {
      final ref = _collection.doc(sessionId);
      final update = <String, dynamic>{
        'lastLocation': {
          'lat': location.latitude,
          'lng': location.longitude,
          'accuracy': location.accuracy,
          if (location.address != null && location.address!.isNotEmpty)
            'address': location.address,
          'ts': FieldValue.serverTimestamp(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      };
      _cleanFirestoreData(update);
      await ref.set(update, SetOptions(merge: true));
    } catch (e) {
      _maybeLogOfflineError('update latest location', e);
    }
  }

  /// Check if a session document exists
  Future<bool> sessionExists(String sessionId) async {
    try {
      final docSnapshot = await _collection.doc(sessionId).get();
      return docSnapshot.exists;
    } catch (e) {
      debugPrint('SosRepository: Error checking if session exists - $e');
      return false;
    }
  }

  /// Update session status and selected fields by id.
  Future<void> updateStatus(
    String sessionId, {
    required String status,
    DateTime? endTime,
    Map<String, dynamic>? extra,
  }) async {
    try {
      final ref = _collection.doc(sessionId);

      // Verify document exists first
      final docSnapshot = await ref.get();
      if (!docSnapshot.exists) {
        throw Exception('SOS session $sessionId not found in Firestore');
      }

      final update = <String, dynamic>{
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        if (endTime != null) 'endTime': endTime.toIso8601String(),
        ...?extra,
      };
      _cleanFirestoreData(update);

      // Use update instead of set to ensure document exists
      await ref.update(update);

      debugPrint('SosRepository: Updated session $sessionId to status $status');
    } on FirebaseException catch (e) {
      debugPrint(
        'SosRepository: Firebase error updating status - ${e.code}: ${e.message}',
      );
      if (e.code == 'permission-denied') {
        throw Exception('Permission denied: Check Firestore security rules');
      } else if (e.code == 'not-found') {
        throw Exception('SOS session not found');
      }
      rethrow;
    } catch (e) {
      debugPrint('SosRepository: Error updating status - $e');
      rethrow;
    }
  }

  /// Clear the user's active session pointer stored at users/{uid}/meta/state.
  /// This prevents the backend from auto-resolving newly created sessions
  /// as duplicates when a stale pointer remains.
  Future<void> clearActiveSessionPointer(String userId) async {
    try {
      final ref = FirebaseFirestore.instance.doc('users/$userId/meta/state');
      await ref.set({
        'activeSessionId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('SosRepository: Cleared activeSessionId pointer for $userId');
    } catch (e) {
      _maybeLogOfflineError('clear active session pointer', e);
    }
  }

  /// Set the user's active session pointer stored at users/{uid}/meta/state.
  /// The Cloud Function uses this to prevent duplicate active sessions.
  Future<void> setActiveSessionPointer(String userId, String sessionId) async {
    try {
      final ref = FirebaseFirestore.instance.doc('users/$userId/meta/state');
      await ref.set({
        'activeSessionId': sessionId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint(
        'SosRepository: Set activeSessionId pointer to $sessionId for $userId',
      );
    } catch (e) {
      _maybeLogOfflineError('set active session pointer', e);
    }
  }

  /// Get the active session for a user from Firestore
  /// Returns null if no active session exists
  Future<SOSSession?> getActiveSession(String userId) async {
    try {
      // First, get the active session ID from the state pointer
      final stateRef = FirebaseFirestore.instance.doc(
        'users/$userId/meta/state',
      );
      final stateDoc = await stateRef.get();

      if (!stateDoc.exists) {
        debugPrint('SosRepository: No state document found for user $userId');
        return null;
      }

      final stateData = stateDoc.data();
      final activeSessionId = stateData?['activeSessionId'] as String?;

      if (activeSessionId == null || activeSessionId.isEmpty) {
        debugPrint(
          'SosRepository: No active session ID in state for user $userId',
        );
        return null;
      }

      debugPrint('SosRepository: Found active session ID: $activeSessionId');

      // Now fetch the actual session document
      final sessionDoc = await _collection.doc(activeSessionId).get();

      if (!sessionDoc.exists) {
        debugPrint(
          'SosRepository: Active session document not found: $activeSessionId',
        );
        // Clear the stale pointer
        await clearActiveSessionPointer(userId);
        return null;
      }

      final sessionData = sessionDoc.data();
      if (sessionData == null) {
        debugPrint(
          'SosRepository: Active session has no data: $activeSessionId',
        );
        return null;
      }

      // Parse the session data into SOSSession model
      final session = _parseSessionFromFirestore(activeSessionId, sessionData);

      // Verify the session is actually active (not resolved/cancelled)
      if (session.status == SOSStatus.resolved ||
          session.status == SOSStatus.cancelled ||
          session.status == SOSStatus.falseAlarm) {
        debugPrint(
          'SosRepository: Session $activeSessionId is not active (status: ${session.status})',
        );
        // Clear the stale pointer
        await clearActiveSessionPointer(userId);
        return null;
      }

      debugPrint(
        'SosRepository: Restored active session: $activeSessionId (status: ${session.status})',
      );
      return session;
    } catch (e) {
      _maybeLogOfflineError('get active session', e);
      return null;
    }
  }

  /// Parse a Firestore document into a SOSSession model
  SOSSession _parseSessionFromFirestore(
    String sessionId,
    Map<String, dynamic> data,
  ) {
    // Parse status
    final statusStr = data['status'] as String? ?? 'active';
    final status = _parseStatus(statusStr);

    // Parse type
    final typeStr = data['type'] as String? ?? 'manual';
    final type = _parseType(typeStr);

    // Parse location
    final locationData = data['location'] as Map<String, dynamic>?;
    final location = LocationInfo(
      latitude: (locationData?['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (locationData?['longitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (locationData?['accuracy'] as num?)?.toDouble() ?? 0.0,
      timestamp: locationData?['timestamp'] != null
          ? DateTime.parse(locationData!['timestamp'] as String)
          : DateTime.now(),
      address: locationData?['address'] as String?,
      altitude: (locationData?['altitude'] as num?)?.toDouble(),
      speed: (locationData?['speed'] as num?)?.toDouble(),
      heading: (locationData?['heading'] as num?)?.toDouble(),
    );

    // Parse timestamps
    final startTime = data['startTime'] != null
        ? DateTime.parse(data['startTime'] as String)
        : DateTime.now();
    final endTime = data['endTime'] != null
        ? DateTime.parse(data['endTime'] as String)
        : null;

    // Parse impact info if present
    ImpactInfo? impactInfo;
    final impactData = data['impactInfo'] as Map<String, dynamic>?;
    if (impactData != null) {
      impactInfo = ImpactInfo(
        severity: _parseImpactSeverity(
          impactData['severity'] as String? ?? 'medium',
        ),
        accelerationMagnitude:
            (impactData['accelerationMagnitude'] as num?)?.toDouble() ?? 0.0,
        maxAcceleration:
            (impactData['maxAcceleration'] as num?)?.toDouble() ?? 0.0,
        detectionTime: impactData['detectionTime'] != null
            ? DateTime.parse(impactData['detectionTime'] as String)
            : DateTime.now(),
        isVerified: impactData['isVerified'] as bool? ?? false,
        verificationConfidence: (impactData['verificationConfidence'] as num?)
            ?.toDouble(),
        verificationReason: impactData['verificationReason'] as String?,
        detectionAlgorithm: impactData['detectionAlgorithm'] as String?,
      );
    }

    return SOSSession(
      id: sessionId,
      userId: data['userId'] as String? ?? '',
      type: type,
      status: status,
      startTime: startTime,
      endTime: endTime,
      location: location,
      userMessage: data['userMessage'] as String?,
      contactedEmergencyContacts:
          (data['emergencyContacts'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      impactInfo: impactInfo,
      isTestMode: false,
      metadata: data['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Parse status string to SOSStatus enum
  SOSStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'countdown':
        return SOSStatus.countdown;
      case 'active':
        return SOSStatus.active;
      case 'acknowledged':
        return SOSStatus.acknowledged;
      case 'assigned':
        return SOSStatus.assigned;
      case 'en_route':
      case 'enroute':
        return SOSStatus.enRoute;
      case 'on_scene':
      case 'onscene':
        return SOSStatus.onScene;
      case 'in_progress':
      case 'inprogress':
        return SOSStatus.inProgress;
      case 'resolved':
        return SOSStatus.resolved;
      case 'cancelled':
        return SOSStatus.cancelled;
      case 'false_alarm':
      case 'falsealarm':
        return SOSStatus.falseAlarm;
      default:
        return SOSStatus.active;
    }
  }

  /// Parse type string to SOSType enum
  SOSType _parseType(String type) {
    switch (type.toLowerCase()) {
      case 'manual':
        return SOSType.manual;
      case 'crash':
      case 'crash_detection':
        return SOSType.crashDetection;
      case 'fall':
      case 'fall_detection':
        return SOSType.fallDetection;
      case 'panic_button':
        return SOSType.panicButton;
      case 'voice_command':
        return SOSType.voiceCommand;
      case 'external_trigger':
        return SOSType.externalTrigger;
      default:
        return SOSType.manual;
    }
  }

  /// Parse impact severity string to ImpactSeverity enum
  ImpactSeverity _parseImpactSeverity(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return ImpactSeverity.low;
      case 'medium':
        return ImpactSeverity.medium;
      case 'high':
        return ImpactSeverity.high;
      case 'critical':
        return ImpactSeverity.critical;
      default:
        return ImpactSeverity.medium;
    }
  }

  /// Build a Firestore-safe payload from SOSSession
  Future<Map<String, dynamic>> _buildSessionPayload(SOSSession s) async {
    // Get user profile for additional information
    final userProfile = await _getUserProfile(s.userId);
    final authUser = AuthService.instance.currentUser;

    // Fallbacks from Auth if profile missing or incomplete
    final fallbackName = authUser.displayName.isNotEmpty
        ? authUser.displayName
        : null;
    final fallbackPhone = authUser.phoneNumber;
    final fallbackEmail = authUser.email.isNotEmpty ? authUser.email : null;

    // Get emergency contacts for SAR dashboard
    final emergencyContactsService = EmergencyContactsService();
    final emergencyContacts = emergencyContactsService.enabledContacts;

    // Get the primary/immediate family contact (highest priority)
    final primaryContact = emergencyContacts.isNotEmpty
        ? emergencyContacts.first
        : null;

    // Attach address if not present but we have coordinates
    String? address = s.location.address;
    if ((address == null || address.isEmpty) &&
        s.location.latitude != 0.0 &&
        s.location.longitude != 0.0) {
      try {
        address = await LocationService.reverseGeocode(
          s.location.latitude,
          s.location.longitude,
        );
      } catch (_) {}
    }

    final authUid = FirebaseAuth.instance.currentUser?.uid;

    // Build allowed viewer lists for Firestore rule checks
    final allowedViewerEmails = emergencyContacts
        .where((c) => c.isEnabled && (c.email != null && c.email!.isNotEmpty))
        .map((c) => c.email!)
        .toSet()
        .toList();

    // Placeholder for future expansion if contacts are mapped to user IDs
    final List<String> allowedViewerIds = <String>[];

    return {
      'id': s.id,
      // Align with Firestore rules: owner must match request.auth.uid
      'userId': authUid ?? s.userId,
      // Restrict visibility and allow specific contacts to view via email
      'visibility': 'restricted',
      if (allowedViewerEmails.isNotEmpty)
        'allowedViewerEmails': allowedViewerEmails,
      if (allowedViewerIds.isNotEmpty) 'allowedViewerIds': allowedViewerIds,
      // Add user profile information for SAR dashboard
      if (userProfile != null ||
          fallbackName != null ||
          fallbackPhone != null ||
          fallbackEmail != null) ...{
        'userName': (userProfile?.name.isNotEmpty == true)
            ? userProfile!.name
            : (fallbackName ?? 'User'),
        'userPhone':
            userProfile?.phoneNumber ?? userProfile?.phone ?? fallbackPhone,
        'phoneNumber':
            userProfile?.phoneNumber ?? userProfile?.phone ?? fallbackPhone,
        'phone':
            userProfile?.phoneNumber ?? userProfile?.phone ?? fallbackPhone,
        'userEmail': userProfile?.email ?? fallbackEmail,
      },
      // Add emergency contact information for SAR personnel
      if (primaryContact != null) ...{
        'emergencyContactName': primaryContact.name,
        'emergencyContactPhone': primaryContact.phoneNumber,
        'emergencyContactRelationship':
            primaryContact.relationship ?? 'Emergency Contact',
        'emergencyContactEmail': primaryContact.email,
      },
      // Add all emergency contacts for reference
      if (emergencyContacts.isNotEmpty)
        'emergencyContactsList': emergencyContacts
            .map(
              (contact) => {
                'name': contact.name,
                'phone': contact.phoneNumber,
                'relationship': contact.relationship ?? 'Emergency Contact',
                'email': contact.email,
                'priority': contact.priority,
                'type': contact.type
                    .toString()
                    .split('.')
                    .last, // family, friend, medical, work, emergencyServices, other
              },
            )
            .toList(),
      'status': _mapStatus(s.status),
      'type': _mapType(s.type),
      'startTime': s.startTime.toIso8601String(),
      if (s.endTime != null) 'endTime': s.endTime!.toIso8601String(),
      'location': {
        'latitude': s.location.latitude,
        'longitude': s.location.longitude,
        'accuracy': s.location.accuracy,
        'timestamp': s.location.timestamp.toIso8601String(),
        if (address != null && address.isNotEmpty) 'address': address,
      },
      if (s.userMessage != null) 'userMessage': s.userMessage,
      if (s.contactedEmergencyContacts.isNotEmpty)
        'emergencyContacts': s.contactedEmergencyContacts,
      if (s.impactInfo != null)
        'impactInfo': {
          'severity': _mapImpactSeverity(s.impactInfo!.severity),
          'accelerationMagnitude': s.impactInfo!.accelerationMagnitude,
          'maxAcceleration': s.impactInfo!.maxAcceleration,
          'detectionTime': s.impactInfo!.detectionTime.toIso8601String(),
          'isVerified': s.impactInfo!.isVerified,
          if (s.impactInfo!.verificationConfidence != null)
            'verificationConfidence': s.impactInfo!.verificationConfidence,
          if (s.impactInfo!.verificationReason != null)
            'verificationReason': s.impactInfo!.verificationReason,
          if (s.impactInfo!.detectionAlgorithm != null)
            'detectionAlgorithm': s.impactInfo!.detectionAlgorithm,
        },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (s.metadata.isNotEmpty) 'metadata': s.metadata,
    };
  }

  String _mapStatus(SOSStatus status) {
    switch (status) {
      case SOSStatus.countdown:
        return 'countdown';
      case SOSStatus.active:
        return 'active';
      case SOSStatus.acknowledged:
        return 'acknowledged';
      case SOSStatus.assigned:
        return 'assigned';
      case SOSStatus.enRoute:
        return 'en_route';
      case SOSStatus.onScene:
        return 'on_scene';
      case SOSStatus.inProgress:
        return 'in_progress';
      case SOSStatus.resolved:
        return 'resolved';
      case SOSStatus.cancelled:
        return 'cancelled';
      case SOSStatus.falseAlarm:
        return 'false_alarm';
    }
  }

  String _mapType(SOSType type) {
    switch (type) {
      case SOSType.manual:
        return 'manual';
      case SOSType.crashDetection:
        return 'crash';
      case SOSType.fallDetection:
        return 'fall';
      case SOSType.panicButton:
        return 'panic_button';
      case SOSType.voiceCommand:
        return 'voice_command';
      case SOSType.externalTrigger:
        return 'external_trigger';
    }
  }

  String _mapImpactSeverity(ImpactSeverity s) {
    switch (s) {
      case ImpactSeverity.low:
        return 'low';
      case ImpactSeverity.medium:
        return 'medium';
      case ImpactSeverity.high:
        return 'high';
      case ImpactSeverity.critical:
        return 'critical';
    }
  }

  /// Clean Firestore data to prevent serialization errors
  void _cleanFirestoreData(Map<String, dynamic> data) {
    data.forEach((key, value) {
      if (value is double) {
        if (value.isNaN || value.isInfinite) {
          data[key] = 0.0;
        }
      } else if (value is Map<String, dynamic>) {
        _cleanFirestoreData(value);
      } else if (value is List) {
        for (var i = 0; i < value.length; i++) {
          final v = value[i];
          if (v is Map<String, dynamic>) {
            _cleanFirestoreData(v);
          } else if (v is double) {
            if (v.isNaN || v.isInfinite) {
              value[i] = 0.0;
            }
          }
        }
      }
    });
  }

  /// Fetch user profile from Firestore
  Future<UserProfile?> _getUserProfile(String userId) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection(GoogleCloudConfig.firestoreCollectionUsers)
          .doc(userId);
      final snap = await docRef.get();

      if (snap.exists && snap.data() != null) {
        final data = Map<String, dynamic>.from(snap.data()!);
        // Ensure id field is present
        data['id'] = data['id'] ?? userId;
        return UserProfile.fromJson(data);
      }
      return null;
    } catch (e) {
      // If we can't fetch profile, return null and continue without it
      return null;
    }
  }

  // Offline error throttling to prevent log flood when network is down
  static DateTime _lastOfflineLog = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _offlineLogCooldown = Duration(seconds: 30);

  void _maybeLogOfflineError(String context, Object e) {
    final isOffline = ConnectivityMonitorService().isOffline;
    if (isOffline) {
      final now = DateTime.now();
      if (now.difference(_lastOfflineLog) >= _offlineLogCooldown) {
        _lastOfflineLog = now;
        debugPrint('SosRepository: Offline - suppressed repeated errors during "$context"');
      }
      return; // Suppress detailed error spam while offline
    }
    debugPrint('SosRepository: Failed to $context - $e');
  }
}
