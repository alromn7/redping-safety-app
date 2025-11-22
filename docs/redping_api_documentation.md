# REDP!NG Safety App - API Documentation

## Overview

The REDP!NG Safety App provides a comprehensive API for emergency response, location tracking, and SAR (Search and Rescue) coordination. This documentation covers all internal APIs, external integrations, and data models.

## Table of Contents
1. [Core Services API](#core-services-api)
2. [SOS Emergency API](#sos-emergency-api)
3. [Location Services API](#location-services-api)
4. [SAR Integration API](#sar-integration-api)
5. [Communication API](#communication-api)
6. [Authentication API](#authentication-api)
7. [Data Models](#data-models)
8. [Error Handling](#error-handling)

---

## Core Services API

### AppServiceManager
Central service coordinator for all app functionality.

```dart
class AppServiceManager {
  // Initialization
  Future<void> initializeAllServices();
  Future<void> initializeEssentialServices();
  Future<void> initializeBackgroundServices();
  
  // Service Access
  SOSService get sosService;
  LocationService get locationService;
  SensorService get sensorService;
  EmergencyContactsService get contactsService;
  UserProfileService get profileService;
  NotificationService get notificationService;
  SARService get sarService;
  NativeMapService get nativeMapService;
  
  // Global State
  bool get isInitialized;
  bool get isAppInForeground;
  
  // Callbacks
  void setOnSOSActivated(Function(SOSSession) callback);
  void setOnSOSDeactivated(Function(SOSSession) callback);
  void setOnCriticalAlert(Function(String, String) callback);
  void setOnServicesReady(Function() callback);
  void setOnSettingsChanged(Function() callback);
}
```

---

## SOS Emergency API

### SOSService
Manages emergency SOS sessions and responses.

```dart
class SOSService {
  // Core SOS Operations
  Future<SOSSession> startSOSCountdown({
    SOSType type = SOSType.manual,
    String? userMessage,
  });
  
  void cancelSOS();
  void activateSOS();
  void deactivateSOS();
  
  // Session Management
  SOSSession? get currentSession;
  bool get hasActiveSession;
  bool get isCountdownActive;
  
  // Callbacks
  void setOnSessionStarted(Function(SOSSession) callback);
  void setOnSessionUpdated(Function(SOSSession) callback);
  void setOnSessionEnded(Function(SOSSession) callback);
  void setOnCountdownTick(Function(int) callback);
  void setOnVoiceVerificationRequested(Function() callback);
  
  // Voice Verification
  Future<void> startVoiceVerification();
  Future<void> completeVoiceVerification(bool isVerified);
  
  // Emergency Response
  Future<void> contactEmergencyServices();
  Future<void> notifyEmergencyContacts();
  Future<void> alertSARTeams();
}
```

### SOSSession Model
```dart
class SOSSession {
  final String id;
  final String userId;
  final SOSType type;
  final SOSStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final LocationInfo location;
  final ImpactInfo? impactInfo;
  final List<String> contactedEmergencyContacts;
  final List<SOSMessage> messages;
  final List<MediaAttachment> mediaAttachments;
  final List<RescueTeamResponse> rescueTeamResponses;
  final List<EmergencyContactResponse> emergencyContactResponses;
  final RescueStatus? rescueStatus;
  final VoiceVerificationInfo? voiceVerification;
  final String? userMessage;
  final bool isTestMode;
  final Map<String, dynamic> metadata;
}
```

### SOS Types and Status
```dart
enum SOSType {
  manual,      // User-initiated SOS
  automatic,   // System-triggered SOS
  crash,       // Crash detection
  fall,        // Fall detection
}

enum SOSStatus {
  countdown,   // Countdown phase
  active,      // Active emergency
  cancelled,   // User cancelled
  completed,   // Emergency resolved
}
```

---

## Location Services API

### LocationService
Handles GPS tracking and location management.

```dart
class LocationService {
  // Core Location Operations
  Future<void> initialize();
  Future<LocationInfo?> getCurrentLocation();
  Future<void> startTracking();
  void stopTracking();
  
  // Location Data
  LocationInfo? get currentLocation;
  List<LocationInfo> get locationHistory;
  bool get isTracking;
  
  // Callbacks
  void setLocationUpdateCallback(Function(LocationInfo) callback);
  
  // Location Utilities
  Future<String?> getAddressFromCoordinates(double lat, double lng);
  Future<LocationInfo?> getCoordinatesFromAddress(String address);
  double calculateDistance(LocationInfo from, LocationInfo to);
  List<LocationInfo> getBreadcrumbTrail();
}
```

### LocationInfo Model
```dart
class LocationInfo {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double accuracy;
  final double? speed;
  final double? heading;
  final DateTime timestamp;
  final String? address;
  final List<BreadcrumbPoint> breadcrumbTrail;
}
```

### BreadcrumbPoint Model
```dart
class BreadcrumbPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? speed;
}
```

---

## Sensor Services API

### SensorService
Monitors device sensors for crash and fall detection.

```dart
class SensorService {
  // Sensor Operations
  Future<void> startMonitoring();
  void stopMonitoring();
  Future<void> calibrateSensors();
  
  // Detection
  bool get isMonitoring;
  double get crashThreshold;
  double get fallThreshold;
  
  // Callbacks
  void setCrashDetectedCallback(Function(ImpactInfo) callback);
  void setFallDetectedCallback(Function(ImpactInfo) callback);
  void setSensorUpdateCallback(Function(SensorReading) callback);
  
  // Sensor Data
  List<SensorReading> getRecentReadings();
  ImpactInfo? getLastImpact();
}
```

### SensorReading Model
```dart
class SensorReading {
  final DateTime timestamp;
  final double x;
  final double y;
  final double z;
  final String sensorType;
  
  double get magnitude => (x * x + y * y + z * z).abs();
}
```

### ImpactInfo Model
```dart
class ImpactInfo {
  final double accelerationMagnitude;
  final double maxAcceleration;
  final DateTime detectionTime;
  final List<SensorReading> sensorReadings;
  final ImpactSeverity severity;
  final String? detectionAlgorithm;
  final bool isVerified;
  final double? verificationConfidence;
  final String? verificationReason;
}
```

---

## SAR Integration API

### SARService
Manages Search and Rescue team coordination.

```dart
class SARService {
  // SAR Operations
  Future<void> initialize();
  Future<void> registerSARMember(SARIdentity identity);
  Future<void> verifySARMember(String memberId, bool isVerified);
  Future<List<SARIdentity>> getSARMembers();
  Future<List<SARIdentity>> getNearbySARMembers(LocationInfo location);
  
  // Emergency Response
  Future<void> handleIncomingSOSAlert({
    required String sosSessionId,
    required String userId,
    required String userName,
    required LocationInfo location,
    required SOSType sosType,
    required String message,
    required List<String> emergencyContacts,
    required Map<String, dynamic> weatherConditions,
  });
  
  // SAR Coordination
  Future<void> assignSARTeam(String sosSessionId, String teamId);
  Future<void> updateRescueStatus(String sosSessionId, RescueStatus status);
  Future<List<RescueTeamResponse>> getRescueResponses(String sosSessionId);
}
```

### SARIdentity Model
```dart
class SARIdentity {
  final String id;
  final String userId;
  final SARMemberType memberType;
  final SARVerificationStatus verificationStatus;
  final PersonalInfo personalInfo;
  final List<SARCredential> credentials;
  final List<SARCertification> certifications;
  final SARExperience experience;
  final DateTime registrationDate;
  final DateTime? verificationDate;
  final String? verifiedBy;
  final DateTime? expirationDate;
  final List<String> photoIds;
  final String? notes;
}
```

### SAR Types
```dart
enum SARMemberType {
  professional,  // Professional SAR member
  volunteer,      // Volunteer SAR member
  trainee,       // SAR trainee
}

enum SARVerificationStatus {
  verified,      // Verified SAR member
  pending,       // Pending verification
  rejected,      // Verification rejected
}
```

---

## Communication API

### ChatService
Handles messaging and communication.

```dart
class ChatService {
  // Chat Operations
  Future<void> initialize();
  Future<void> sendMessage(String recipientId, String content);
  Future<List<ChatMessage>> getMessages(String chatId);
  Future<List<Chat>> getChats();
  
  // Real-time Updates
  Stream<ChatMessage> watchMessages(String chatId);
  Stream<Chat> watchChats();
}
```

### EmergencyMessagingService
Manages emergency communication.

```dart
class EmergencyMessagingService {
  // Emergency Messaging
  Future<void> sendEmergencyAlert({
    required String sosSessionId,
    required List<String> recipients,
    required String message,
    required EmergencyMessageType type,
    required EmergencyMessagePriority priority,
  });
  
  Future<void> sendLocationUpdate({
    required String sosSessionId,
    required LocationInfo location,
    required String message,
  });
  
  Future<void> sendStatusUpdate({
    required String sosSessionId,
    required String status,
    required String message,
  });
}
```

### SARMessagingService
Handles SAR team communication.

```dart
class SARMessagingService {
  // SAR Messaging
  Future<void> sendSARAlert({
    required String sosSessionId,
    required List<String> sarTeamIds,
    required String message,
    required SARMessageType type,
    required SARMessagePriority priority,
  });
  
  Future<void> sendRescueUpdate({
    required String sosSessionId,
    required String teamId,
    required String update,
    required RescueStatus status,
  });
}
```

---

## Authentication API

### AuthService
Manages user authentication and authorization.

```dart
class AuthService {
  // Authentication
  Future<AuthUser?> signIn(String email, String password);
  Future<AuthUser?> signUp(String email, String password);
  Future<void> signOut();
  Future<void> resetPassword(String email);
  
  // User Management
  AuthUser? get currentUser;
  bool get isSignedIn;
  Future<void> updateProfile(Map<String, dynamic> updates);
  
  // Session Management
  Future<void> refreshToken();
  Future<void> revokeToken();
}
```

### AuthUser Model
```dart
class AuthUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime lastSignIn;
  final bool isEmailVerified;
}
```

---

## Data Models

### UserProfile Model
```dart
class UserProfile {
  final String id;
  final String name;
  final String? email;
  final String? phoneNumber;
  final DateTime? dateOfBirth;
  final String? bloodType;
  final List<String> medicalConditions;
  final List<String> allergies;
  final List<String> medications;
  final List<EmergencyContact> emergencyContacts;
  final UserPreferences preferences;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### EmergencyContact Model
```dart
class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String? email;
  final ContactType type;
  final bool isEnabled;
  final int priority;
  final String? relationship;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### ContactType Enum
```dart
enum ContactType {
  family,     // Family member
  friend,     // Friend
  medical,    // Medical professional
  emergency,  // Emergency services
}
```

---

## Error Handling

### Error Types
```dart
class REDPINGError extends Exception {
  final String code;
  final String message;
  final String? details;
  
  const REDPINGError({
    required this.code,
    required this.message,
    this.details,
  });
}
```

### Common Error Codes
```dart
class ErrorCodes {
  static const String networkError = 'NETWORK_ERROR';
  static const String locationError = 'LOCATION_ERROR';
  static const String sensorError = 'SENSOR_ERROR';
  static const String authError = 'AUTH_ERROR';
  static const String permissionError = 'PERMISSION_ERROR';
  static const String serviceError = 'SERVICE_ERROR';
}
```

### Error Handling Example
```dart
try {
  await sosService.startSOSCountdown();
} on REDPINGError catch (e) {
  switch (e.code) {
    case ErrorCodes.locationError:
      // Handle location error
      break;
    case ErrorCodes.networkError:
      // Handle network error
      break;
    default:
      // Handle generic error
      break;
  }
}
```

---

## Firebase Integration

### Firestore Collections
```dart
// SOS Sessions Collection
const String sosSessionsCollection = 'sos_sessions';

// Users Collection
const String usersCollection = 'users';

// Emergency Contacts Collection
const String emergencyContactsCollection = 'emergency_contacts';

// SAR Members Collection
const String sarMembersCollection = 'sar_members';

// Messages Collection
const String messagesCollection = 'messages';
```

### Real-time Listeners
```dart
// Listen to SOS session updates
Stream<SOSSession> watchSOSSession(String sessionId) {
  return FirebaseFirestore.instance
      .collection(sosSessionsCollection)
      .doc(sessionId)
      .snapshots()
      .map((snapshot) => SOSSession.fromJson(snapshot.data()!));
}

// Listen to user profile updates
Stream<UserProfile> watchUserProfile(String userId) {
  return FirebaseFirestore.instance
      .collection(usersCollection)
      .doc(userId)
      .snapshots()
      .map((snapshot) => UserProfile.fromJson(snapshot.data()!));
}
```

---

## Native Map Integration

### NativeMapService
Integrates with device's native map applications.

```dart
class NativeMapService {
  // Map Operations
  Future<bool> openCurrentLocation({
    double? latitude,
    double? longitude,
    String? label,
  });
  
  Future<bool> openLocation({
    required double latitude,
    required double longitude,
    String? label,
    String? address,
  });
  
  Future<bool> openNavigation({
    required double latitude,
    required double longitude,
    String? label,
    String? address,
  });
  
  Future<bool> openDirections({
    required double destinationLatitude,
    required double destinationLongitude,
    String? destinationLabel,
    double? sourceLatitude,
    double? sourceLongitude,
    String? sourceLabel,
  });
  
  Future<bool> openNearbySearch({
    required String query,
    double? latitude,
    double? longitude,
  });
  
  // Map Availability
  Future<bool> isMapAppAvailable();
  Future<List<String>> getAvailableMapApps();
}
```

---

## Performance Monitoring

### PerformanceMetrics
Tracks app performance and user experience.

```dart
class PerformanceMetrics {
  // App Performance
  final double appStartupTime;
  final double memoryUsage;
  final double cpuUsage;
  final double batteryLevel;
  
  // Network Performance
  final double networkLatency;
  final double dataUsage;
  final int networkErrors;
  
  // User Experience
  final double sosResponseTime;
  final double locationAccuracy;
  final int crashDetections;
  final int falsePositives;
}
```

### PerformanceMonitoringService
Monitors and reports performance metrics.

```dart
class PerformanceMonitoringService {
  Future<void> startMonitoring();
  Future<void> stopMonitoring();
  Future<PerformanceMetrics> getMetrics();
  Future<void> logPerformanceEvent(String event);
  Future<void> logError(String error, StackTrace stackTrace);
}
```

---

This comprehensive API documentation provides detailed information about all the REDP!NG Safety App's internal APIs, data models, and integration points.
