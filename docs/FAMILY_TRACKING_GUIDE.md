# Family Member Tracking System - Complete Guide

## 📍 Overview

The Family Member Tracking System provides real-time location monitoring, safe zone management, and comprehensive family safety features within the RedPing app's Family Protection Mode.

**Status**: ✅ **IMPLEMENTED AND READY**

---

## 🎯 Features

### 1. Real-Time Location Tracking
- **Live Location Updates**: See family member locations in real-time
- **Online Status**: Know who's online and actively sharing location
- **Battery Monitoring**: Track battery levels to prevent disconnection
- **Speed Detection**: Monitor movement speed (ideal for teen drivers)
- **Location Accuracy**: View GPS accuracy for each member
- **Time Stamps**: See when each location was last updated

### 2. Geofence Safe Zones
- **Create Safe Zones**: Define areas like home, school, work
- **Entry/Exit Alerts**: Get notified when members enter or leave zones
- **Custom Radius**: Set zone size from 50m to 5km
- **Zone Colors**: Color-code zones for easy identification
- **Member Assignment**: Restrict zones to specific family members
- **Active/Inactive**: Enable or disable zones as needed

### 3. Family Dashboard
- **Overview Tab**: Summary of online members and safe zones
- **Map View**: Visual representation of all locations (coming soon)
- **Members Tab**: Detailed list of all family member locations
- **Safe Zones Tab**: Manage geofence zones
- **Quick Actions**: Access member details with one tap

---

## 🚀 Getting Started

### Prerequisites
1. **Family Subscription**: Required to access family tracking features
2. **Family Protection Mode**: Activate this RedPing mode
3. **Location Permissions**: All family members must grant location access
4. **Internet Connection**: Required for real-time updates

### Adding Family Members

#### Method 1: Via Family Dashboard (Subscription)
1. Navigate to **Settings** → **Subscription** → **Family Dashboard**
2. Tap **"Add Member"** button
3. Fill in member details:
   - Name
   - Email (optional)
   - Relationship (e.g., "Son", "Daughter", "Parent")
   - Assigned Tier (Essential, Pro, etc.)
4. Member receives invitation to join family circle

#### Method 2: Via Subscription Service (Programmatic)
```dart
final subscriptionService = SubscriptionService.instance;
await subscriptionService.addFamilyMember(
  familyId: 'family_id',
  userId: 'unique_user_id',
  name: 'John Doe',
  assignedTier: SubscriptionTier.essential,
  email: 'john@example.com',
  relationship: 'Son',
);
```

---

## 📱 Accessing the Family Mode Dashboard

### From SOS Page
1. Activate **Family Protection** mode
2. In the RedPing Mode card, tap **"Family Dashboard"** button
3. Dashboard opens with 3 tabs: Map, Members, Safe Zones

### Direct Navigation
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const FamilyModeDashboard(),
  ),
);
```

---

## 🗺️ Location Tracking Capabilities

### Real-Time Location Updates

Each family member's location includes:
- **GPS Coordinates**: Latitude and longitude
- **Accuracy**: ±15m typical accuracy
- **Speed**: Current movement speed in km/h
- **Heading**: Direction of travel (degrees)
- **Altitude**: Elevation above sea level
- **Battery Level**: Device battery percentage
- **Online Status**: Active or offline
- **Last Seen**: Time since last update

### Location Display Features

#### Member Location Card
```
┌─────────────────────────────────────┐
│ 👤 John Doe                   5m ago│
│ ● Online  🛡️ In Safe Zone           │
├─────────────────────────────────────┤
│ 📍 ±15m          🏃 12.5 km/h       │
│ 🔋 85%                              │
└─────────────────────────────────────┘
```

#### Status Indicators
- 🟢 **Online**: Location updated < 10 minutes ago
- 🟠 **Stale**: Location updated 10+ minutes ago
- ⚪ **Offline**: Member not sharing location
- 🛡️ **In Safe Zone**: Member inside a geofence

#### Battery Alerts
- 🔴 **≤20%**: Critical battery (red)
- 🟠 **21-40%**: Low battery (orange)
- 🟢 **41-100%**: Normal battery (green)

---

## 🏠 Safe Zone (Geofence) Management

### Creating a Safe Zone

1. Open **Family Mode Dashboard**
2. Navigate to **"Safe Zones"** tab
3. Tap **"Add Safe Zone"** button
4. Configure zone settings:
   - **Name**: e.g., "Home", "School", "Office"
   - **Location**: Center coordinates
   - **Radius**: 50m to 5000m
   - **Description**: Optional notes
   - **Color**: For visual identification
   - **Entry Alert**: Notify when member enters
   - **Exit Alert**: Notify when member leaves
   - **Allowed Members**: Restrict to specific members

### Example Zones

#### Home Zone
```dart
await geofenceService.createZone(
  name: 'Home',
  centerLat: 37.7749,
  centerLon: -122.4194,
  radiusMeters: 200,
  createdBy: 'admin_id',
  description: 'Family home safe zone',
  color: '#4CAF50', // Green
  alertOnEntry: false,
  alertOnExit: true,
);
```

#### School Zone
```dart
await geofenceService.createZone(
  name: 'School',
  centerLat: 37.7849,
  centerLon: -122.4094,
  radiusMeters: 150,
  createdBy: 'admin_id',
  description: 'Children\'s school',
  color: '#2196F3', // Blue
  alertOnEntry: true,
  alertOnExit: true,
  allowedMembers: ['child1_id', 'child2_id'],
);
```

### Geofence Alerts

When a family member crosses a geofence boundary:

#### Entry Alert
```
┌─────────────────────────────────────┐
│ 🚪 John Doe entered School          │
│ Time: 8:15 AM                       │
│ Location: 37.7849, -122.4094        │
└─────────────────────────────────────┘
```

#### Exit Alert
```
┌─────────────────────────────────────┐
│ 🚶 Jane Doe exited Home             │
│ Time: 3:45 PM                       │
│ Location: 37.7749, -122.4194        │
└─────────────────────────────────────┘
```

---

## 🔧 Technical Implementation

### Services

#### FamilyLocationService
```dart
// Initialize service
final locationService = FamilyLocationService.instance;
await locationService.initialize();

// Update member location
await locationService.updateMemberLocation(
  memberId: 'member_001',
  memberName: 'John Doe',
  latitude: 37.7749,
  longitude: -122.4194,
  accuracy: 15.0,
  speed: 5.5,
  batteryLevel: 85,
);

// Get all locations
List<FamilyMemberLocation> locations = locationService.allLocations;

// Get online members only
List<FamilyMemberLocation> onlineMembers = locationService.getOnlineMembers();

// Calculate distance between members
double? distance = locationService.getDistanceBetweenMembers(
  'member_001',
  'member_002',
);
```

#### GeofenceService
```dart
// Initialize service
final geofenceService = GeofenceService.instance;
await geofenceService.initialize();

// Check member location against zones
await geofenceService.checkMemberLocation(
  memberId: 'member_001',
  memberName: 'John Doe',
  lat: 37.7749,
  lon: -122.4194,
);

// Get zones for a member
List<GeofenceZone> zones = geofenceService.getZonesForMember('member_001');

// Check if in safe zone
bool isSafe = geofenceService.isMemberInSafeZone('member_001');

// Listen to alerts
geofenceService.alertStream.listen((alert) {
  print('${alert.memberName} ${alert.eventType.name} ${alert.zone.name}');
});
```

### Data Models

#### FamilyMemberLocation
```dart
class FamilyMemberLocation {
  final String memberId;
  final String memberName;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracy;
  final double? speed;       // m/s
  final double? heading;     // degrees
  final double? altitude;    // meters
  final int? batteryLevel;   // percentage
  final bool isOnline;
  final DateTime? lastSeen;
  
  // Computed properties
  String get speedKmh;           // "12.5 km/h"
  String get accuracyFormatted;  // "±15m"
  String get batteryFormatted;   // "85%"
  String get timeSinceUpdate;    // "5m ago"
  bool get isStale;              // true if > 10 min old
}
```

#### GeofenceZone
```dart
class GeofenceZone {
  final String id;
  final String name;
  final double centerLat;
  final double centerLon;
  final double radiusMeters;
  final String createdBy;
  final DateTime createdAt;
  final String? description;
  final String? color;           // Hex color
  final bool alertOnEntry;
  final bool alertOnExit;
  final bool isActive;
  final List<String> allowedMembers;
  
  // Computed properties
  String get radiusFormatted;    // "200m" or "1.5km"
}
```

---

## 🧪 Testing with Sample Data

### Quick Test Setup
```dart
import 'package:redping_14v/utils/family_tracking_test_data.dart';

// Initialize all test data (family, locations, geofences)
await FamilyTrackingTestData.initializeAllTestData();

// Clear all test data
await FamilyTrackingTestData.clearAllTestData();
```

### Test Data Includes
- **Test Family**: "Test Family" with 3 members
  - John Doe (Son, Essential)
  - Jane Doe (Daughter, Essential)
  - Mary Doe (Mother, Pro)
- **Test Locations**: San Francisco area coordinates
  - John: At home (37.7749, -122.4194)
  - Jane: At school (37.7849, -122.4094)
  - Mary: In transit (37.7949, -122.3994)
- **Test Geofences**:
  - Home (200m radius, green)
  - School (150m radius, blue)
  - Office (100m radius, orange)

---

## 📊 Dashboard Tabs

### 1. Map View Tab
**Status**: 🔜 Coming Soon

Will display:
- Interactive map with all family members
- Geofence zone boundaries
- Member clustering for dense areas
- Real-time location updates
- Tap markers for member details

### 2. Members Tab
**Status**: ✅ Active

Features:
- List of all family member locations
- Status indicators (online, offline, in safe zone)
- Battery levels and speed
- Tap card to view full details
- Summary card showing:
  - Online members count
  - Members in safe zones
  - Total safe zones

### 3. Safe Zones Tab
**Status**: ✅ Active

Features:
- List of all geofence zones
- Members currently in each zone
- Edit and delete zone actions
- Create new zones button
- Zone status (active/inactive)
- Alert configuration display

---

## 🔔 Alert Types

### Location Alerts
- **Member Offline**: When location hasn't updated in 10+ minutes
- **Low Battery**: When battery drops below 20%
- **High Speed**: When speed exceeds safe limits (configurable)
- **Location Stale**: When last update is older than threshold

### Geofence Alerts
- **Zone Entry**: Member enters a safe zone
- **Zone Exit**: Member exits a safe zone
- **Unauthorized Zone**: Member in zone they're not allowed in

### Safety Alerts (Family Protection Mode)
- **Fall Detection**: Combined with location data
- **Crash Detection**: With immediate location sharing
- **SOS Triggered**: Family-wide emergency notification
- **Wandering**: Elderly member outside safe zones for extended period

---

## 🔒 Privacy & Permissions

### Location Sharing Control
```dart
// Enable location sharing
await locationService.enableSharing();

// Disable location sharing
await locationService.disableSharing();

// Check sharing status
bool isSharing = locationService.isSharing;
```

### Member Privacy Settings
- Members can disable location sharing
- Location history is not stored long-term
- Only active family members can view locations
- Geofence alerts sent only to family admins

---

## 📈 Usage Metrics

### Family Overview Card
```
┌─────────────────────────────────────┐
│ Family Overview                     │
├─────────────────────────────────────┤
│  📡 Online        🛡️ In Safe Zone   │
│     3/4               2              │
│                                     │
│  📍 Safe Zones                      │
│     5 total                         │
└─────────────────────────────────────┘
```

---

## 🛠️ Integration with Family Protection Mode

### Activation Flow
1. User activates **Family Protection** mode from RedPing Mode Selection
2. Mode card on SOS page shows **"Family Dashboard"** button
3. Dashboard provides access to all tracking features
4. Location updates automatically trigger geofence checks
5. Alerts sent in real-time via SnackBar notifications

### Age-Based Thresholds
Family Protection Mode applies different sensor thresholds based on age:
- **Children (0-12)**: crashThreshold = 130 m/s²
- **Teens (13-17)**: crashThreshold = 140 m/s²
- **Adults (18-64)**: crashThreshold = 140 m/s²
- **Elderly (65+)**: crashThreshold = 120 m/s², enhanced fall detection

---

## 📝 API Reference

### FamilyLocationService Methods
- `initialize()` - Initialize the service
- `updateMemberLocation()` - Update a member's location
- `getMemberLocation(memberId)` - Get specific member location
- `getOnlineMembers()` - Get list of online members
- `setMemberOffline(memberId)` - Mark member as offline
- `enableSharing()` - Enable location sharing
- `disableSharing()` - Disable location sharing
- `clearMemberLocation(memberId)` - Clear member's location
- `clearAllLocations()` - Clear all locations
- `getDistanceBetweenMembers(id1, id2)` - Calculate distance
- `getMembersInRadius(lat, lon, radius)` - Get nearby members

### GeofenceService Methods
- `initialize()` - Initialize the service
- `createZone()` - Create a new geofence zone
- `updateZone(zone)` - Update existing zone
- `deleteZone(zoneId)` - Delete a zone
- `getZone(zoneId)` - Get specific zone
- `isLocationInZone(lat, lon, zone)` - Check if point in zone
- `checkMemberLocation(memberId, name, lat, lon)` - Check against all zones
- `getZonesForMember(memberId)` - Get zones containing member
- `isMemberInSafeZone(memberId)` - Check if in any safe zone
- `clearAllZones()` - Delete all zones

---

## 🎨 UI Components

### FamilyMemberLocationCard
Displays member location with:
- Avatar with status color
- Name and online status
- Safe zone indicator
- Time since update
- Battery level with icon
- Accuracy and speed chips
- Tap to view full details

### GeofenceZoneCard
Displays geofence zone with:
- Zone name and description
- Active/inactive status badge
- Radius and member count
- Alert configuration chips
- List of members currently in zone
- Edit and delete actions

### FamilyModeDashboard
Full dashboard with:
- Tab navigation (Map, Members, Safe Zones)
- Summary statistics
- Real-time updates via streams
- Alert notifications
- Floating action button for adding zones

---

## 🔄 Real-Time Updates

### Stream Subscriptions
```dart
// Listen to location updates
locationService.locationsStream.listen((locations) {
  // Update UI with new locations
});

// Listen to geofence updates
geofenceService.zonesStream.listen((zones) {
  // Update zones list
});

// Listen to geofence alerts
geofenceService.alertStream.listen((alert) {
  // Show alert notification
});
```

---

## 📅 Future Enhancements

### Planned Features
- [ ] Interactive map with Google Maps/Mapbox
- [ ] Location history (breadcrumb trail)
- [ ] Heatmap of frequently visited locations
- [ ] Travel time estimates between members
- [ ] Route planning to member locations
- [ ] Offline map support for geofences
- [ ] Voice announcements for geofence events
- [ ] Multi-language support for alerts
- [ ] Custom alert sounds per zone
- [ ] Location sharing time limits
- [ ] Temporary location sharing links
- [ ] Integration with smart home devices

---

## 🐛 Troubleshooting

### Location Not Updating
1. Check location permissions
2. Verify location services enabled
3. Ensure internet connection active
4. Check if location sharing is enabled
5. Restart the app

### Geofence Alerts Not Working
1. Verify zone is set to active
2. Check alert configuration (entry/exit)
3. Ensure member is in allowedMembers list (if restricted)
4. Verify location accuracy is sufficient
5. Check if member location is being updated

### Members Not Showing
1. Confirm family subscription is active
2. Verify members added to family
3. Check if location sharing is enabled
4. Ensure members have granted permissions
5. Restart Family Dashboard

---

## 📞 Support

For issues or questions:
- Check the [RedPing Documentation](../docs/README.md)
- Review the [Family Protection Mode Guide](REDPING_MODE_PHASE3_COMPLETE.md)
- Contact support via the app's Help section

---

**Last Updated**: November 2, 2025
**Version**: 1.0.0
**Status**: ✅ Production Ready
