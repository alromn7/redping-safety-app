import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/logging/app_logger.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/google_cloud_config.dart';
import '../core/test_overrides.dart';
import '../models/sos_session.dart';
import '../security/request_signing.dart';

/// Firebase service for REDP!NG app
/// Connects to the same Firebase project as the website
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _isInitialized = false;
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  FirebaseMessaging? _messaging;

  // Subscriptions for Firestore real-time listeners
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sosSessionsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sarTeamsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersSub;

  // Stream controllers for real-time updates
  final StreamController<Map<String, dynamic>> _sosAlertsController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _sarUpdatesController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _locationUpdatesController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Callbacks
  Function(Map<String, dynamic>)? _onSosAlertReceived;
  Function(Map<String, dynamic>)? _onSarUpdateReceived;
  Function(Map<String, dynamic>)? _onLocationUpdateReceived;
  Function(Map<String, dynamic>)? _onHazardAlertReceived;
  Function(String)? _onAuthStateChanged;
  Function(String, dynamic)? _onError;

  /// Initialize Firebase service
  Future<void> initialize() async {
    if (_isInitialized) return;

    AppLogger.d('Initializing...', tag: 'FirebaseService');

    try {
      if (TestOverrides.isTest) {
        _isInitialized = true; // No-op in tests
        AppLogger.i('Skipped (test mode)', tag: 'FirebaseService');
        return;
      }
      // Initialize Firebase Core
      await Firebase.initializeApp();

      // Initialize Firebase services
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _messaging = FirebaseMessaging.instance;

      // Set up authentication state listener
      _auth!.authStateChanges().listen(_onAuthStateChange);

      // Set up Firestore listeners
      await _setupFirestoreListeners();

      // Set up Realtime Database listeners
      // Deprecated: listeners via RTDB are no longer required
      // await _setupRealtimeDatabaseListeners();

      // Set up Firebase Messaging
      await _setupFirebaseMessaging();

      _isInitialized = true;
      AppLogger.i('Initialized successfully', tag: 'FirebaseService');
    } catch (e) {
      AppLogger.e('Initialization failed', tag: 'FirebaseService', error: e);
      _onError?.call('FIREBASE_INIT_FAILED', e);
      rethrow;
    }
  }

  /// Set up Firestore listeners for real-time updates
  Future<void> _setupFirestoreListeners() async {
    try {
      // Listen to SOS sessions collection (single source of truth)
      _sosSessionsSub = _firestore!
          .collection(GoogleCloudConfig.firestoreCollectionSosAlerts)
          .snapshots()
          .listen((snapshot) {
            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added ||
                  change.type == DocumentChangeType.modified) {
                final data = change.doc.data() as Map<String, dynamic>;
                data['id'] = change.doc.id;
                _sosAlertsController.add(data);
                _onSosAlertReceived?.call(data);
              }
            }
          });

      // Listen to SAR teams collection
      _sarTeamsSub = _firestore!
          .collection(GoogleCloudConfig.firestoreCollectionSarTeams)
          .snapshots()
          .listen((snapshot) {
            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added ||
                  change.type == DocumentChangeType.modified) {
                final data = change.doc.data() as Map<String, dynamic>;
                data['id'] = change.doc.id;
                _sarUpdatesController.add(data);
                _onSarUpdateReceived?.call(data);
              }
            }
          });

      // Listen to users collection for location updates
      _usersSub = _firestore!
          .collection(GoogleCloudConfig.firestoreCollectionUsers)
          .snapshots()
          .listen((snapshot) {
            for (var change in snapshot.docChanges) {
              if (change.type == DocumentChangeType.added ||
                  change.type == DocumentChangeType.modified) {
                final data = change.doc.data() as Map<String, dynamic>;
                if (data.containsKey('location')) {
                  _locationUpdatesController.add(data);
                  _onLocationUpdateReceived?.call(data);
                }
              }
            }
          });

      debugPrint('FirebaseService: Firestore listeners set up successfully');
    } catch (e) {
      debugPrint('FirebaseService: Failed to set up Firestore listeners - $e');
      _onError?.call('FIRESTORE_LISTENERS_FAILED', e);
    }
  }

  // (removed: duplicate dispose and deprecated RTDB method)

  /// Set up Firebase Messaging for push notifications
  Future<void> _setupFirebaseMessaging() async {
    try {
      // Do NOT request notification permission here to avoid duplicate prompts.
      // NotificationService is responsible for requesting POST_NOTIFICATIONS on Android 13+.

      // Get FCM token
      final token = await _messaging!.getToken();
      debugPrint('FirebaseService: FCM Token - $token');

      // Listen to foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint(
          'FirebaseService: Received foreground message - ${message.messageId}',
        );
        _handleNotification(message);
      });

      // Listen to background messages
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      debugPrint('FirebaseService: Firebase Messaging set up successfully');
    } catch (e) {
      debugPrint('FirebaseService: Failed to set up Firebase Messaging - $e');
      _onError?.call('FCM_SETUP_FAILED', e);
    }
  }

  /// Handle authentication state changes
  void _onAuthStateChange(User? user) {
    if (user != null) {
      debugPrint('FirebaseService: User signed in - ${user.uid}');
      // Bootstrap request signing secret on sign-in (non-blocking)
      () async {
        try {
          final ok = await RequestSigner.ensureSigningSecret();
          if (!ok) {
            debugPrint(
              'FirebaseService: Signing secret bootstrap skipped or failed',
            );
          }
        } catch (e) {
          debugPrint('FirebaseService: Signing secret bootstrap error - $e');
        }
      }();
      _onAuthStateChanged?.call('signed_in');
    } else {
      debugPrint('FirebaseService: User signed out');
      _onAuthStateChanged?.call('signed_out');
    }
  }

  /// Handle incoming notifications
  void _handleNotification(RemoteMessage message) {
    final data = message.data;
    if (data.containsKey('type')) {
      switch (data['type']) {
        case 'sos_alert':
          _onSosAlertReceived?.call(data);
          break;
        case 'sar_update':
          _onSarUpdateReceived?.call(data);
          break;
        case 'location_update':
          _onLocationUpdateReceived?.call(data);
          break;
        case 'hazard_alert':
        case 'hazard':
          _onHazardAlertReceived?.call(data);
          break;
      }
    }
  }

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth!.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('FirebaseService: User signed in successfully');
      return credential;
    } catch (e) {
      debugPrint('FirebaseService: Sign in failed - $e');
      _onError?.call('SIGN_IN_FAILED', e);
      return null;
    }
  }

  /// Create user with email and password
  Future<UserCredential?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth!.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('FirebaseService: User created successfully');
      return credential;
    } catch (e) {
      debugPrint('FirebaseService: User creation failed - $e');
      _onError?.call('USER_CREATION_FAILED', e);
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth!.signOut();
      debugPrint('FirebaseService: User signed out successfully');
    } catch (e) {
      debugPrint('FirebaseService: Sign out failed - $e');
      _onError?.call('SIGN_OUT_FAILED', e);
    }
  }

  /// Send SOS alert to Firestore
  Future<bool> sendSosAlert(SOSSession session) async {
    try {
      // Map enums to canonical strings used by website
      String mapSosType(SOSType t) {
        switch (t) {
          case SOSType.manual:
            return 'manual';
          case SOSType.crashDetection:
            return 'crash_detection';
          case SOSType.fallDetection:
            return 'fall_detection';
          case SOSType.panicButton:
            return 'panic_button';
          case SOSType.voiceCommand:
            return 'voice_command';
          case SOSType.externalTrigger:
            return 'external_trigger';
        }
      }

      String mapSosStatus(SOSStatus s) {
        switch (s) {
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
          case SOSStatus.cancelled:
            return 'cancelled';
          case SOSStatus.resolved:
            return 'resolved';
          case SOSStatus.falseAlarm:
            return 'false_alarm';
        }
      }

      // Provide a cross-project emergencyType expected by website feed
      String mapEmergencyType(SOSType t) {
        switch (t) {
          case SOSType.crashDetection:
          case SOSType.fallDetection:
            return 'medical';
          case SOSType.panicButton:
          case SOSType.voiceCommand:
            return 'security';
          default:
            return 'other';
        }
      }

      final authUid = FirebaseAuth.instance.currentUser?.uid;

      final data = <String, dynamic>{
        'id': session.id,
        // Align with Firestore rules: owner must match request.auth.uid on create
        'userId': authUid ?? session.userId,
        'type': mapSosType(session.type),
        'status': mapSosStatus(session.status),
        'startTime': session.startTime, // DateTime -> Firestore Timestamp
        if (session.endTime != null) 'endTime': session.endTime,
        'location': {
          'latitude': session.location.latitude,
          'longitude': session.location.longitude,
          'accuracy': session.location.accuracy,
          'timestamp': session.location.timestamp, // DateTime
        },
        'userMessage': session.userMessage,
        'isTestMode': session.isTestMode,
        'metadata': session.metadata,
        'emergencyType': mapEmergencyType(session.type),
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore!
          .collection(GoogleCloudConfig.firestoreCollectionSosAlerts)
          .doc(session.id)
          .set(data, SetOptions(merge: true));

      debugPrint('FirebaseService: SOS alert sent successfully');
      return true;
    } catch (e) {
      debugPrint('FirebaseService: Failed to send SOS alert - $e');
      _onError?.call('SOS_ALERT_SEND_FAILED', e);
      return false;
    }
  }

  /// Update user location
  Future<bool> updateUserLocation(
    String userId,
    double latitude,
    double longitude,
    double accuracy,
  ) async {
    try {
      final locationData = {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'timestamp': DateTime.now(), // DateTime -> Firestore Timestamp
      };

      await _firestore!
          .collection(GoogleCloudConfig.firestoreCollectionUsers)
          .doc(userId)
          .update({'location': locationData});

      // Also update Realtime Database
      // Deprecated RTDB path removed

      AppLogger.i('Location updated successfully', tag: 'FirebaseService');
      return true;
    } catch (e) {
      AppLogger.w(
        'Failed to update location',
        tag: 'FirebaseService',
        error: e,
      );
      _onError?.call('LOCATION_UPDATE_FAILED', e);
      return false;
    }
  }

  /// Get SAR teams from Firestore
  Future<List<Map<String, dynamic>>> getSarTeams() async {
    try {
      final snapshot = await _firestore!
          .collection(GoogleCloudConfig.firestoreCollectionSarTeams)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      AppLogger.w('Failed to get SAR teams', tag: 'FirebaseService', error: e);
      _onError?.call('GET_SAR_TEAMS_FAILED', e);
      return [];
    }
  }

  /// Register gadget device
  Future<bool> registerGadget(Map<String, dynamic> device) async {
    try {
      await _firestore!
          .collection(GoogleCloudConfig.firestoreCollectionGadgets)
          .add(device);

      AppLogger.i('Gadget registered successfully', tag: 'FirebaseService');
      return true;
    } catch (e) {
      AppLogger.w(
        'Failed to register gadget',
        tag: 'FirebaseService',
        error: e,
      );
      _onError?.call('GADGET_REGISTRATION_FAILED', e);
      return false;
    }
  }

  /// Send push notification
  Future<bool> sendPushNotification(
    String token,
    String title,
    String body,
    Map<String, dynamic>? data,
  ) async {
    try {
      // This would typically be done through your backend
      // For now, we'll just log the notification
      AppLogger.d('Push notification sent to $token', tag: 'FirebaseService');
      AppLogger.d('Title: $title, Body: $body', tag: 'FirebaseService');
      return true;
    } catch (e) {
      AppLogger.w(
        'Failed to send push notification',
        tag: 'FirebaseService',
        error: e,
      );
      _onError?.call('PUSH_NOTIFICATION_FAILED', e);
      return false;
    }
  }

  /// Set callbacks
  void setSosAlertCallback(Function(Map<String, dynamic>) callback) {
    _onSosAlertReceived = callback;
  }

  void setSarUpdateCallback(Function(Map<String, dynamic>) callback) {
    _onSarUpdateReceived = callback;
  }

  void setLocationUpdateCallback(Function(Map<String, dynamic>) callback) {
    _onLocationUpdateReceived = callback;
  }

  void setHazardAlertCallback(Function(Map<String, dynamic>) callback) {
    _onHazardAlertReceived = callback;
  }

  void setAuthStateCallback(Function(String) callback) {
    _onAuthStateChanged = callback;
  }

  void setErrorCallback(Function(String, dynamic) callback) {
    _onError = callback;
  }

  /// Get streams
  Stream<Map<String, dynamic>> get sosAlertsStream =>
      _sosAlertsController.stream;
  Stream<Map<String, dynamic>> get sarUpdatesStream =>
      _sarUpdatesController.stream;
  Stream<Map<String, dynamic>> get locationUpdatesStream =>
      _locationUpdatesController.stream;

  /// Get current user
  User? get currentUser => _auth?.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _auth?.currentUser != null;

  /// Get service status
  Map<String, dynamic> getStatus() {
    return {'isInitialized': _isInitialized};
  }

  /// Clean up listeners and controllers
  void dispose() {
    try {
      _sosSessionsSub?.cancel();
      _sarTeamsSub?.cancel();
      _usersSub?.cancel();
      _sosAlertsController.close();
      _sarUpdatesController.close();
      _locationUpdatesController.close();
      _isInitialized = false;
    } catch (e) {
      AppLogger.w('dispose error', tag: 'FirebaseService', error: e);
    }
  }
}

/// Background message handler for Firebase Messaging
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  AppLogger.d(
    'Background message received - ${message.messageId}',
    tag: 'FirebaseService',
  );

  // Persist hazard alerts so they can appear in-app even when the push arrived
  // while the app was backgrounded/killed.
  try {
    final type = message.data['type']?.toString();
    if (type == 'hazard_alert' || type == 'hazard') {
      final prefs = await SharedPreferences.getInstance();
      final existing =
          prefs.getStringList('pending_hazard_alert_pushes') ?? <String>[];

      existing.add(jsonEncode(message.data));

      // Prevent unbounded growth.
      final capped =
          existing.length > 50 ? existing.sublist(existing.length - 50) : existing;
      await prefs.setStringList('pending_hazard_alert_pushes', capped);

      AppLogger.d(
        'Queued hazard push payload (count=${capped.length})',
        tag: 'FirebaseService',
      );
    }
  } catch (e) {
    AppLogger.w(
      'Failed to persist background message payload',
      tag: 'FirebaseService',
      error: e,
    );
  }
}
