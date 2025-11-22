# REDP!NG Safety App - Complete Schema Documentation

## Table of Contents
1. [App Overview](#app-overview)
2. [Core Data Models](#core-data-models)
3. [Service Architecture](#service-architecture)
4. [Feature Modules](#feature-modules)
5. [UI Components](#ui-components)
6. [API Integration](#api-integration)
7. [Security & Privacy](#security--privacy)
8. [Performance & Optimization](#performance--optimization)

---

## App Overview

**REDP!NG Safety Ecosystem** is a comprehensive safety application that provides emergency response, location tracking, and community safety features. The app integrates with Search and Rescue (SAR) teams, emergency services, and provides real-time safety monitoring.

### Key Features
- **SOS Emergency System** - Real-time emergency alerts
- **SAR Integration** - Search and Rescue team coordination
- **Location Services** - GPS tracking and breadcrumb trails
- **Sensor Monitoring** - Crash and fall detection
- **Community Features** - Mesh networking and communication
- **Native Map Integration** - Device map applications
- **Firebase Backend** - Real-time data and messaging

---

## Core Data Models

### 1. SOS Session Model
```dart
class SOSSession {
  String id;                    // Unique session identifier
  String userId;                // User who initiated SOS
  SOSType type;                 // manual, automatic, crash, fall
  SOSStatus status;             // countdown, active, cancelled, completed
  DateTime startTime;           // Session start timestamp
  DateTime? endTime;            // Session end timestamp
  LocationInfo location;        // Current location data
  ImpactInfo? impactInfo;       // Crash/fall impact data
  List<String> contactedEmergencyContacts;
  List<SOSMessage> messages;    // Communication history
  List<MediaAttachment> mediaAttachments;
  List<RescueTeamResponse> rescueTeamResponses;
  List<EmergencyContactResponse> emergencyContactResponses;
  RescueStatus? rescueStatus;   // Current rescue status
  VoiceVerificationInfo? voiceVerification;
  String? userMessage;          // User's emergency message
  bool isTestMode;              // Test mode flag
  Map<String, dynamic> metadata;
}
```

### 2. Location Information
```dart
class LocationInfo {
  double latitude;              // GPS latitude
  double longitude;             // GPS longitude
  double? altitude;              // Elevation above sea level
  double accuracy;              // Location accuracy in meters
  double? speed;                // Current speed
  double? heading;              // Direction of movement
  DateTime timestamp;           // Location timestamp
  String? address;              // Human-readable address
  List<BreadcrumbPoint> breadcrumbTrail; // Location history
}
```

### 3. User Profile
```dart
class UserProfile {
  String id;                    // Unique user identifier
  String name;                  // User's full name
  String? email;                // Email address
  String? phoneNumber;          // Phone number
  DateTime? dateOfBirth;        // Date of birth
  String? bloodType;            // Blood type for medical emergencies
  List<String> medicalConditions; // Medical conditions
  List<String> allergies;       // Known allergies
  List<String> medications;     // Current medications
  List<EmergencyContact> emergencyContacts; // Emergency contacts
  UserPreferences preferences;  // User settings
  DateTime createdAt;           // Profile creation date
  DateTime updatedAt;           // Last update date
}
```

### 4. Emergency Contact
```dart
class EmergencyContact {
  String id;                    // Unique contact identifier
  String name;                  // Contact's name
  String phoneNumber;           // Phone number
  String? email;                // Email address
  ContactType type;             // family, friend, medical, emergency
  bool isEnabled;               // Contact is active
  int priority;                 // Priority level (1 = highest)
  String? relationship;         // Relationship to user
  String? notes;                // Additional notes
  DateTime createdAt;           // Contact creation date
  DateTime updatedAt;           // Last update date
}
```

### 5. SAR Identity
```dart
class SARIdentity {
  String id;                    // Unique SAR member identifier
  String userId;                // Associated user ID
  SARMemberType memberType;     // professional, volunteer, trainee
  SARVerificationStatus verificationStatus; // verified, pending, rejected
  PersonalInfo personalInfo;    // Personal details
  List<SARCredential> credentials; // Professional credentials
  List<SARCertification> certifications; // Certifications
  SARExperience experience;    // Experience details
  DateTime registrationDate;    // Registration date
  DateTime? verificationDate;   // Verification date
  String? verifiedBy;           // Who verified the member
  DateTime? expirationDate;     // Credential expiration
  List<String> photoIds;        // Photo attachments
  String? notes;                // Additional notes
}
```

### 6. Sensor Reading
```dart
class SensorReading {
  DateTime timestamp;           // Reading timestamp
  double x;                     // X-axis acceleration
  double y;                     // Y-axis acceleration
  double z;                     // Z-axis acceleration
  String sensorType;            // accelerometer, gyroscope, magnetometer
}
```

### 7. Impact Information
```dart
class ImpactInfo {
  double accelerationMagnitude; // Total acceleration magnitude
  double maxAcceleration;       // Maximum acceleration recorded
  DateTime detectionTime;       // When impact was detected
  List<SensorReading> sensorReadings; // Raw sensor data
  ImpactSeverity severity;      // low, medium, high, critical
  String? detectionAlgorithm;   // Algorithm used for detection
  bool isVerified;              // AI verification status
  double? verificationConfidence; // Verification confidence score
  String? verificationReason;   // Reason for verification result
}
```

---

## Service Architecture

### 1. App Service Manager
Central coordinator for all app services:
```dart
class AppServiceManager {
  // Core Services
  SOSService sosService;
  SensorService sensorService;
  LocationService locationService;
  EmergencyContactsService contactsService;
  UserProfileService profileService;
  NotificationService notificationService;
  
  // SAR Services
  SARService sarService;
  SARIdentityService sarIdentityService;
  SAROrganizationService organizationService;
  VolunteerRescueService volunteerService;
  RescueResponseService rescueResponseService;
  
  // Communication Services
  ChatService chatService;
  EmergencyMessagingService emergencyMessagingService;
  SARMessagingService sarMessagingService;
  MessagingIntegrationService messagingIntegrationService;
  
  // AI & Assistant Services
  AIAssistantService aiAssistantService;
  HelpAssistantService helpAssistantService;
  
  // Utility Services
  NativeMapService nativeMapService;
  SatelliteService satelliteService;
  HazardAlertService hazardService;
  ActivityService activityService;
  PrivacySecurityService privacySecurityService;
  LegalDocumentsService legalDocumentsService;
  
  // Authentication & Subscription
  AuthService authService;
  SubscriptionService subscriptionService;
  FeatureAccessService featureAccessService;
  
  // Performance Services
  BatteryOptimizationService batteryOptimizationService;
  PerformanceMonitoringService performanceMonitoringService;
  MemoryOptimizationService memoryOptimizationService;
  EmergencyModeService emergencyModeService;
  
  // Data Connect
  RedPingDataConnectService dataConnectService;
}
```

### 2. SOS Service
Manages emergency SOS sessions:
```dart
class SOSService {
  // Core Methods
  Future<void> initialize();
  Future<SOSSession> startSOSCountdown();
  void cancelSOS();
  void activateSOS();
  void deactivateSOS();
  
  // Callbacks
  Function(SOSSession)? onSessionStarted;
  Function(SOSSession)? onSessionUpdated;
  Function(SOSSession)? onSessionEnded;
  Function(int)? onCountdownTick;
  Function()? onVoiceVerificationRequested;
  
  // Properties
  SOSSession? currentSession;
  bool hasActiveSession;
  bool isCountdownActive;
}
```

### 3. Location Service
Handles GPS and location tracking:
```dart
class LocationService {
  // Core Methods
  Future<void> initialize();
  Future<LocationInfo?> getCurrentLocation();
  Future<void> startTracking();
  void stopTracking();
  
  // Callbacks
  Function(LocationInfo)? onLocationUpdate;
  
  // Properties
  bool isTracking;
  LocationInfo? currentLocation;
  List<LocationInfo> locationHistory;
}
```

### 4. Sensor Service
Monitors device sensors for crash/fall detection:
```dart
class SensorService {
  // Core Methods
  Future<void> startMonitoring();
  void stopMonitoring();
  Future<void> calibrateSensors();
  
  // Callbacks
  Function(ImpactInfo)? onCrashDetected;
  Function(ImpactInfo)? onFallDetected;
  Function(SensorReading)? onSensorUpdate;
  
  // Properties
  bool isMonitoring;
  double crashThreshold;
  double fallThreshold;
}
```

---

## Feature Modules

### 1. SOS Emergency System
**Location**: `lib/features/sos/`
- **SOSPage** - Main emergency interface
- **QuickActions** - Emergency action buttons
- **StatusIndicator** - System status display
- **SOSMessagingWidget** - Emergency communication
- **VerificationDialog** - Voice verification interface

### 2. Safety Dashboard
**Location**: `lib/features/safety/`
- **SafetyDashboardPage** - Main safety interface
- **SystemHealthCard** - System status monitoring
- **EmergencyInfoCard** - Emergency information display

### 3. Profile Management
**Location**: `lib/features/profile/`
- **ProfilePage** - User profile management
- **EmergencyContactsPage** - Emergency contacts management
- **ProfileTestPage** - Profile testing interface

### 4. Location & Maps
**Location**: `lib/features/location/`
- **MapPage** - Native map integration
- **LocationTracking** - GPS tracking interface
- **BreadcrumbTrail** - Location history display

### 5. SAR Integration
**Location**: `lib/features/sar/`
- **SARPage** - SAR operations interface
- **SARRegistrationPage** - SAR member registration
- **SARVerificationPage** - SAR member verification
- **SAROperationsPage** - SAR operations center

### 6. Communication
**Location**: `lib/features/communication/`
- **CommunityPage** - Community features
- **ChatPage** - Messaging interface
- **NearbyUsersPage** - Nearby users display

### 7. Settings
**Location**: `lib/features/settings/`
- **SettingsPage** - App configuration
- **PrivacySettings** - Privacy controls
- **NotificationSettings** - Notification preferences

---

## UI Components

### 1. Core Widgets
```dart
// Status Indicators
class StatusIndicator extends StatelessWidget
class SystemHealthCard extends StatelessWidget
class EmergencyInfoCard extends StatelessWidget

// Emergency Components
class SOSButton extends StatefulWidget
class QuickActions extends StatelessWidget
class VerificationDialog extends StatefulWidget

// Location Components
class LocationCard extends StatelessWidget
class BreadcrumbTrail extends StatelessWidget
class MapIntegration extends StatelessWidget

// Communication Components
class ChatWidget extends StatefulWidget
class MessageBubble extends StatelessWidget
class ContactCard extends StatelessWidget
```

### 2. Navigation Structure
```dart
// Main Navigation
class MainNavigationPage extends StatefulWidget
  - SOSPage (Emergency)
  - SafetyDashboardPage (Safety)
  - CommunityPage (Community)
  - ProfilePage (Profile)
  - SettingsPage (Settings)

// Routing
class AppRouter {
  static const String main = '/';
  static const String sos = '/sos';
  static const String safety = '/safety';
  static const String community = '/community';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String map = '/map';
  static const String sar = '/sar';
}
```

---

## API Integration

### 1. Firebase Services
```dart
// Firebase Core
- Firebase Core
- Firebase Auth
- Firebase Firestore
- Firebase Messaging
- Firebase Analytics

// Firebase Data Connect
class RedPingDataConnectService {
  Future<void> initialize();
  Future<List<SOSSession>> getSOSSessions();
  Future<void> createSOSSession(SOSSession session);
  Future<void> updateSOSSession(String id, Map<String, dynamic> updates);
  Stream<SOSSession> watchSOSSession(String id);
}
```

### 2. Native Map Integration
```dart
class NativeMapService {
  Future<bool> openCurrentLocation();
  Future<bool> openNavigation();
  Future<bool> openNearbySearch();
  Future<bool> openDirections();
  Future<bool> isMapAppAvailable();
  Future<List<String>> getAvailableMapApps();
}
```

### 3. Satellite Communication
```dart
class SatelliteService {
  Future<bool> sendEmergencySOS();
  Future<bool> sendLocationUpdate();
  Future<bool> sendStatusMessage();
  Future<bool> isSatelliteAvailable();
}
```

---

## Security & Privacy

### 1. Data Encryption
- **Local Storage**: Encrypted SharedPreferences
- **Network Communication**: HTTPS/TLS
- **Sensitive Data**: AES-256 encryption
- **API Keys**: Secure storage and rotation

### 2. Privacy Controls
```dart
class PrivacySecurityService {
  Future<void> enableLocationSharing();
  Future<void> disableLocationSharing();
  Future<void> enableDataCollection();
  Future<void> disableDataCollection();
  Future<void> clearUserData();
  Future<void> exportUserData();
}
```

### 3. Authentication
```dart
class AuthService {
  Future<AuthUser?> signIn(String email, String password);
  Future<AuthUser?> signUp(String email, String password);
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<AuthUser?> getCurrentUser();
}
```

---

## Performance & Optimization

### 1. Battery Optimization
```dart
class BatteryOptimizationService {
  Future<void> optimizeLocationTracking();
  Future<void> optimizeSensorMonitoring();
  Future<void> enablePowerSavingMode();
  Future<void> disablePowerSavingMode();
  Future<double> getBatteryLevel();
}
```

### 2. Memory Management
```dart
class MemoryOptimizationService {
  Future<void> clearCache();
  Future<void> optimizeImages();
  Future<void> compressData();
  Future<void> garbageCollect();
}
```

### 3. Performance Monitoring
```dart
class PerformanceMonitoringService {
  Future<void> startMonitoring();
  Future<void> stopMonitoring();
  Future<PerformanceMetrics> getMetrics();
  Future<void> logPerformanceEvent(String event);
}
```

---

## Database Schema

### 1. Firestore Collections
```
/sos_sessions
  - id: string
  - userId: string
  - type: string (manual, automatic, crash, fall)
  - status: string (countdown, active, cancelled, completed)
  - startTime: timestamp
  - endTime: timestamp
  - location: geopoint
  - impactInfo: object
  - messages: array
  - metadata: object

/users
  - id: string
  - name: string
  - email: string
  - phoneNumber: string
  - profile: object
  - preferences: object
  - createdAt: timestamp
  - updatedAt: timestamp

/emergency_contacts
  - id: string
  - userId: string
  - name: string
  - phoneNumber: string
  - type: string
  - priority: number
  - isEnabled: boolean

/sar_members
  - id: string
  - userId: string
  - memberType: string
  - verificationStatus: string
  - personalInfo: object
  - credentials: array
  - certifications: array
  - experience: object

/location_tracking
  - id: string
  - userId: string
  - location: geopoint
  - timestamp: timestamp
  - accuracy: number
  - speed: number
  - heading: number
```

### 2. Local Storage
```dart
// SharedPreferences Keys
class AppConstants {
  static const String userProfileKey = 'user_profile';
  static const String emergencyContactsKey = 'emergency_contacts';
  static const String settingsKey = 'app_settings';
  static const String lastKnownLocationKey = 'last_known_location';
}
```

---

## Configuration Files

### 1. App Configuration
```yaml
# pubspec.yaml
name: redping_14v
description: "REDP!NG Safety Ecosystem"
version: 1.0.0+1
dependencies:
  flutter: ^3.24.0
  firebase_core: ^3.15.2
  firebase_auth: ^5.7.0
  firebase_firestore: ^5.6.12
  firebase_messaging: ^15.2.10
  geolocator: ^12.0.0
  url_launcher: ^6.2.2
  # ... other dependencies
```

### 2. Android Configuration
```kotlin
// android/app/build.gradle.kts
android {
    namespace = "com.redping.redping"
    compileSdk = 36
    minSdk = 21
    targetSdk = 36
    
    signingConfigs {
        create("release") {
            // Release signing configuration
        }
    }
    
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

### 3. Firebase Configuration
```dart
// lib/firebase_options.dart
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Platform-specific Firebase configuration
  }
}
```

---

## Deployment Architecture

### 1. Build Configuration
- **Debug Build**: Development and testing
- **Release Build**: Production with release signing
- **App Bundle**: Optimized for Google Play Store
- **Code Signing**: Release keystore for production

### 2. Distribution
- **Google Play Store**: Primary distribution channel
- **App Bundle Format**: Optimized delivery
- **Language Splits**: Localized content
- **Density Splits**: Optimized for different screen densities
- **ABI Splits**: Architecture-specific optimizations

### 3. Monitoring & Analytics
- **Firebase Analytics**: User behavior tracking
- **Crash Reporting**: Error monitoring
- **Performance Monitoring**: App performance metrics
- **Custom Events**: Business logic tracking

---

## Security Considerations

### 1. Data Protection
- **Encryption**: All sensitive data encrypted
- **Secure Storage**: Keystore and credentials protected
- **Network Security**: HTTPS/TLS for all communications
- **API Security**: Rate limiting and authentication

### 2. Privacy Compliance
- **GDPR Compliance**: European data protection
- **CCPA Compliance**: California privacy rights
- **Data Minimization**: Only collect necessary data
- **User Consent**: Clear privacy controls

### 3. Emergency Data Handling
- **Emergency Override**: Privacy settings bypassed in emergencies
- **Data Retention**: Emergency data retention policies
- **Data Sharing**: Controlled sharing with emergency services
- **Audit Trail**: Complete logging of data access

---

This comprehensive schema documentation covers the complete architecture, data models, services, and implementation details of the REDP!NG Safety App ecosystem.
