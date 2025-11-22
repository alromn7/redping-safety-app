# Extreme Activities Management System - Complete Guide

## 📋 Table of Contents

1. [Overview](#overview)
2. [System Architecture](#system-architecture)
3. [Equipment Management](#equipment-management)
4. [Safety Checklist System](#safety-checklist-system)
5. [Activity Session Tracking](#activity-session-tracking)
6. [Performance Analytics](#performance-analytics)
7. [Integration Guide](#integration-guide)
8. [Test Data Setup](#test-data-setup)
9. [User Workflows](#user-workflows)

---

## Overview

The **Extreme Activities Management System** provides comprehensive management capabilities for 11 extreme sports integrated with RedPing's emergency detection:

### Supported Activities

1. **Skiing** - Winter sports with avalanche awareness
2. **Climbing** - Rock climbing with fall detection
3. **Hiking** - Trail safety and wilderness monitoring
4. **Mountain Biking** - Off-road cycling with crash detection
5. **Boating** - Water safety and man overboard
6. **Scuba Diving** - Underwater depth tracking
7. **Swimming** - Open water and drowning detection
8. **Off-road 4WD** - Vehicle recovery and rollover detection
9. **Trail Running** - Fast-paced trail with injury detection
10. **Skydiving** - Freefall monitoring and parachute tracking
11. **Flying** - General aviation emergency landing

### Core Features

- **Equipment Inventory** - Track gear with inspection schedules and expiry dates
- **Safety Checklists** - Pre-activity safety checks specific to each sport
- **Session Logging** - Record activities with performance metrics
- **Performance Stats** - Track progress across all your activities
- **Alert System** - Equipment inspection reminders and expiry warnings
- **Weather Integration** - Log conditions for each session
- **Buddy System** - Track who you're doing activities with
- **Incident Tracking** - Record safety incidents for analysis

---

## System Architecture

### Service Layer

**`ExtremeActivityService`** (Singleton pattern)
```
lib/services/extreme_activity_service.dart (733 lines)
```

**Key Methods:**
- Equipment: `addEquipment()`, `updateEquipment()`, `removeEquipment()`
- Sessions: `startSession()`, `updateSession()`, `endSession()`
- Safety: `completeSafetyCheck()`, `allRequiredChecksCompleted()`
- Analytics: `getActivityStats()`, `getSessionsForActivity()`

**State Management:**
- Real-time streams for equipment, sessions, checklists
- SharedPreferences persistence
- Automatic data loading on initialization

### Data Models

**`extreme_activity.dart`** (463 lines)

7 Model Classes:

1. **EquipmentItem** - Gear tracking
   - 21 properties including inspection dates, condition, manufacturer
   - Computed: `needsInspection`, `isExpired`
   - Lifespan: helmets 5yr, ropes 7yr, carabiners 10yr

2. **EquipmentCategory** (21 types)
   - helmet, harness, rope, carabiner, wetsuit, parachute, etc.

3. **EquipmentCondition** (5 states)
   - excellent, good, fair, poor, retired

4. **ExtremeActivitySession** - Activity logging
   - Distance, speed, altitude metrics
   - Weather conditions, equipment used, buddies
   - Photos, incidents, rating

5. **WeatherConditions** - Environmental data
   - Temperature, wind, visibility, precipitation

6. **SafetyChecklistItem** - Safety templates
   - Per-activity checks with categories
   - Required vs optional flags

7. **SafetyCheck** - Completed checks
   - Pass/fail tracking with timestamps

### UI Components

**Dashboard** (773 lines)
```
lib/features/redping_mode/presentation/pages/extreme_activity_dashboard.dart
```

4 Tabs:
- Equipment: Inventory with inspection alerts
- Safety: Pre-activity checklists
- Session: Active session tracking
- Stats: Performance analytics

**Widget Cards** (3 components)
- `equipment_item_card.dart` (274 lines) - Equipment display
- `safety_checklist_card.dart` (121 lines) - Checklist items
- `activity_session_card.dart` (439 lines) - Live session tracking

---

## Equipment Management

### Adding Equipment

```dart
// From dashboard or programmatically
final beacon = EquipmentItem(
  id: 'beacon_1',
  name: 'Mammut Barryvox S',
  category: EquipmentCategory.avalancheBeacon,
  activityTypes: ['skiing'],
  manufacturer: 'Mammut',
  purchaseDate: DateTime(2022, 10, 1),
  lastInspection: DateTime.now(),
  nextInspection: DateTime.now().add(Duration(days: 180)),
  condition: EquipmentCondition.excellent,
);

await ExtremeActivityService.instance.addEquipment(beacon);
```

### Equipment Categories (21 Types)

| Category | Used For | Typical Lifespan |
|----------|----------|------------------|
| **helmet** | Skiing, climbing, biking | 5 years |
| **harness** | Climbing | 5 years |
| **rope** | Climbing | 7 years |
| **carabiner** | Climbing | 10 years |
| **wetsuit** | Diving, swimming | Varies |
| **lifeJacket** | Boating | Check CO2 yearly |
| **avalancheBeacon** | Skiing | Check batteries monthly |
| **parachute** | Skydiving | Repack every 180 days |
| **gps** | All activities | N/A |
| **firstAid** | All activities | Check expiry dates |

### Inspection Tracking

**Automatic Expiry Calculation:**
- Helmets/Harnesses: 5 years from purchase
- Ropes: 7 years from purchase
- Carabiners: 10 years from purchase
- Other: Custom or N/A

**Inspection Alerts:**
```dart
// Get equipment needing inspection
final needsInspection = service.getEquipmentNeedingInspection();

// Get expired equipment
final expired = service.getExpiredEquipment();

// Mark as inspected
await service.updateEquipment(item.copyWith(
  lastInspection: DateTime.now(),
  nextInspection: DateTime.now().add(Duration(days: 180)),
));
```

**Visual Indicators:**
- 🔴 Red badge: EXPIRED (do not use)
- 🟠 Orange badge: Needs Inspection
- 🟡 Yellow badge: Poor Condition
- 🟢 Green: Good condition, current inspection

### Equipment Filtering

```dart
// Get equipment for specific activity
final skiEquipment = service.getEquipmentForActivity('skiing');

// Returns: helmet, avalanche beacon, probe, shovel, gps, radio, etc.
```

---

## Safety Checklist System

### Pre-configured Checklists

The service includes **default safety checks** for all activities:

#### Universal Checks (All Activities)
- ✅ Check weather forecast
- ✅ Inspect equipment condition
- ✅ Notify someone of plans
- ✅ Verify emergency contact info

#### Activity-Specific Checks

**Skiing:**
- ✅ Check avalanche forecast (REQUIRED)
- ✅ Test avalanche beacon (REQUIRED)

**Climbing:**
- ✅ Inspect harness (REQUIRED)
- ✅ Inspect climbing rope (REQUIRED)
- ✅ Verify partner check completed (REQUIRED)

**Water Sports (Boating, Swimming):**
- ✅ Life jacket/PFD check (REQUIRED)
- ✅ Check water conditions (REQUIRED)

**Scuba Diving:**
- ✅ Check dive computer (REQUIRED)
- ✅ Check air supply (REQUIRED)

**Skydiving:**
- ✅ Parachute inspection (REQUIRED)
- ✅ Check altimeter (REQUIRED)

### Checklist Categories

1. **Equipment** - Gear inspection
2. **Weather** - Conditions check
3. **Planning** - Route and timing
4. **Communication** - Emergency contacts
5. **Skills** - Ability verification
6. **General** - Other safety items

### Completing Checks

```dart
// Complete a safety check
await service.completeSafetyCheck(
  activityType: 'skiing',
  checklistItemId: 'avalanche_check',
  passed: true,
  notes: 'Avalanche danger: Low. Safe conditions.',
);

// Check if all required items completed
final allDone = service.allRequiredChecksCompleted('skiing');
// Returns: true if all required checks passed today

// Session start is BLOCKED until required checks are completed!
```

### Adding Custom Checks

```dart
final customCheck = SafetyChecklistItem(
  id: 'check_backup_battery',
  title: 'Check GPS backup battery',
  activityTypes: ['hiking', 'climbing'],
  description: 'Ensure GPS has charged backup battery',
  category: ChecklistCategory.equipment,
  isRequired: true,
  order: 100,
);

await service.addChecklistItem(customCheck);
```

---

## Activity Session Tracking

### Starting a Session

**Requirements:**
1. Activity type must be selected
2. All REQUIRED safety checks must be completed

```dart
// Start a session
final session = await service.startSession(
  activityType: 'skiing',
  location: 'Whistler Blackcomb, BC',
  description: 'Blue run practice',
  equipmentIds: ['helmet_ski_1', 'beacon_1', 'probe_1'],
  buddies: ['Sarah', 'Mike'],
  conditions: WeatherConditions(
    temperature: -5,
    windSpeed: 15,
    windDirection: 'NW',
    visibility: 8,
    conditions: 'Partly cloudy',
  ),
);
```

### Active Session Updates

**Real-time Metric Updates:**
```dart
// Update session with current metrics
await service.updateSession(
  distance: 5.3, // km
  maxSpeed: 52.3, // km/h
  maxAltitude: 2284, // meters
  altitudeGain: 450, // meters
  altitudeLoss: 2100, // meters
  averageSpeed: 28.5, // km/h
);
```

**Dashboard Auto-Updates:**
- ⏱️ Live elapsed time counter
- 📊 Real-time metrics display
- 🌤️ Weather conditions shown
- ⚠️ Incident reporting button

### Incident Reporting

```dart
// Add incident during active session
await service.addIncident(
  'Near miss with another skier on blue run #7'
);
```

### Ending a Session

```dart
// End session with rating
await service.endSession(
  rating: 5, // 1-5 stars
  notes: 'Perfect conditions! Fresh powder on upper runs.',
);

// Session automatically saved to history
// Active session cleared
```

### Session Data Structure

```dart
ExtremeActivitySession {
  id, activityType, startTime, endTime
  location, description
  
  // Performance
  distance, duration, maxSpeed, averageSpeed
  maxAltitude, altitudeGain, altitudeLoss
  
  // Safety
  equipmentUsed (IDs list)
  conditions (WeatherConditions)
  buddies (names list)
  incidents (descriptions list)
  
  // Media
  photos (URLs list)
  rating (1-5 stars)
  notes
}
```

---

## Performance Analytics

### Activity Statistics

```dart
// Get stats for an activity
final stats = service.getActivityStats('skiing');

// Returns:
{
  'totalSessions': 15,
  'totalDistance': 127.5, // km
  'totalDuration': Duration(hours: 45),
  'maxSpeed': 62.3, // km/h
  'maxAltitude': 2850, // m
  'averageRating': 4.2,
}
```

### Stats Dashboard Display

**Metric Cards:**
- 🏃 Total Sessions
- 📏 Total Distance (km)
- ⏱️ Total Time
- 🚀 Max Speed (km/h)
- ⛰️ Max Altitude (m)
- ⭐ Average Rating

### Session History

```dart
// Get all sessions for an activity
final sessions = service.getSessionsForActivity('skiing');

// Returns chronological list (newest first)
// Max 100 sessions stored per activity
```

---

## Integration Guide

### With RedPing Extreme Modes

The system integrates with **11 extreme modes** defined in `redping_mode_service.dart`:

Each mode has specialized sensor configs:
- **Crash Thresholds**: 180.0 - 400.0 (varies by activity)
- **Fall Thresholds**: 50.0 - 180.0
- **Hazard Types**: Activity-specific (avalanche, drowning, parachute fail, etc.)
- **Rescue Methods**: aerial, marine, ground

### Adding Dashboard Button to SOS Page

```dart
// In sos_page.dart (similar to Family/Group integration)

// Add button when extreme mode active
if (currentMode.category == ModeCategory.extreme) {
  ElevatedButton.icon(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExtremeActivityDashboard(
            activityType: currentMode.id, // Pass mode ID
          ),
        ),
      );
    },
    icon: Icon(Icons.fitness_center),
    label: Text('Activity Manager'),
  );
}
```

### Initialization

```dart
// In app startup or mode activation
await ExtremeActivityService.instance.initialize();

// Service auto-loads:
// - Equipment inventory
// - Active session (if any)
// - Safety checklist
// - Session history
```

---

## Test Data Setup

### Quick Setup (One Line)

```dart
import 'package:redping_14v/utils/extreme_activity_test_data.dart';

// Generate complete test data
await ExtremeActivityTestData.generateAll();

// Output:
// ✅ Extreme Activity Test Data Generated Successfully!
//    - 18 equipment items
//    - 16 safety checklist items
```

### What's Included

**Equipment (18 items):**

*Skiing:*
- Smith Vantage MIPS Helmet
- Mammut Barryvox S Avalanche Beacon
- BCA Stealth 270 Probe
- Black Diamond Transfer Shovel
- Giro Range MIPS Helmet (EXPIRED - for testing alerts)

*Climbing:*
- Petzl Corax Climbing Harness
- Mammut 9.5mm Infinity Dry Rope
- Black Diamond RockLock Carabiners (5x)

*Water Sports:*
- O'Neill Reactor Wetsuit
- Mustang Survival Elite Inflatable PFD

*Skydiving:*
- Icarus Safire 3 Main Parachute
- PD Optimum Reserve Parachute

*Universal:*
- Garmin inReach Mini 2 GPS
- Motorola T600 Two-Way Radios
- Adventure Medical Kits First Aid
- ARB 4WD Recovery Kit

**Safety Checks (16 items):**
- 4 universal checks (all activities)
- 12 activity-specific checks

### Clearing Test Data

```dart
await ExtremeActivityTestData.clearAll();
```

---

## User Workflows

### 📱 Typical User Journey

#### 1. **Equipment Setup** (One-time)
```
Open App → Extreme Mode → Activity Manager → Equipment Tab
→ "Add Equipment" → Fill details → Save
```

Repeat for all gear you own.

#### 2. **Pre-Activity Safety Check** (Every session)
```
Select Activity Type → Safety Tab
→ Complete all required checks → Mark as passed/failed
```

✅ **Cannot start session until required checks completed!**

#### 3. **Start Activity Session**
```
Safety Tab (all checks complete) → Session Tab
→ "Start Session" button enabled
→ Select equipment, add buddies, enter weather
→ "Start"
```

⏱️ Timer starts, metrics begin tracking.

#### 4. **During Activity**
```
Session Tab shows:
- Live elapsed time
- Current metrics (distance, speed, altitude)
- Equipment used, buddies
- "Report Incident" button (if needed)
```

#### 5. **End Session**
```
"End Session" → Rate 1-5 stars → Add notes → "End"
```

📊 Session saved to history, stats updated.

#### 6. **View Performance** (Anytime)
```
Stats Tab → See totals, records, ratings
```

#### 7. **Equipment Maintenance**
```
Equipment Tab → Alerts shown for:
- 🔴 Expired equipment
- 🟠 Needs inspection

→ Tap item → "Mark Inspected"
```

### 🎯 Example: Skiing Day

**Morning (Before leaving):**
1. Open RedPing → Set mode to "Skiing"
2. Activity Manager → Safety Tab
3. Complete checks:
   - ✅ Check avalanche forecast (REQUIRED)
   - ✅ Test avalanche beacon (REQUIRED)
   - ✅ Check weather forecast
   - ✅ Notify someone of plans
4. All required checks passed → Session Tab unlocked

**At Resort:**
1. Session Tab → "Start Session"
2. Location: "Whistler Blackcomb"
3. Equipment: Select helmet, beacon, probe, shovel
4. Buddies: Add Sarah, Mike
5. Weather: -5°C, 15km/h wind, partly cloudy
6. "Start Session" → Timer begins

**On Mountain:**
- App tracks GPS, speed, altitude automatically
- Dashboard shows live metrics
- If incident occurs → "Report Incident"

**End of Day:**
1. Back at car → "End Session"
2. Rate day: 5 stars ⭐
3. Notes: "Perfect powder!"
4. Session saved → Stats updated

**Later:**
1. Stats Tab shows:
   - Total sessions: 12
   - Total distance: 95km
   - Max speed: 62km/h
   - Average rating: 4.5 ⭐

---

## Advanced Features

### Activity Type Filtering

When dashboard opened with `activityType` parameter:
- Equipment tab shows only relevant gear
- Safety tab shows activity-specific checks
- Session uses that activity type
- Stats filtered to that activity

```dart
// From extreme mode context
ExtremeActivityDashboard(activityType: 'skiing')

// Shows ONLY skiing equipment, checks, sessions
```

### Weather Integration

Weather conditions logged with each session help track:
- Best conditions for performance
- Safety patterns (incidents in poor weather)
- Seasonal trends

### Buddy Tracking

Track who you do activities with:
- Safety accountability
- Social features potential
- Emergency contact info

### Incident Analysis

Over time, review incidents to:
- Identify risk patterns
- Improve safety procedures
- Share learnings with community

---

## API Reference

### ExtremeActivityService Methods

#### Equipment
```dart
Future<void> addEquipment(EquipmentItem item)
Future<void> updateEquipment(EquipmentItem item)
Future<void> removeEquipment(String id)
List<EquipmentItem> getEquipmentForActivity(String activityType)
List<EquipmentItem> getEquipmentNeedingInspection()
List<EquipmentItem> getExpiredEquipment()
```

#### Sessions
```dart
Future<ExtremeActivitySession> startSession({...})
Future<void> updateSession({...})
Future<void> endSession({int? rating, String? notes})
Future<void> addIncident(String incident)
List<ExtremeActivitySession> getSessionsForActivity(String activityType)
Map<String, dynamic> getActivityStats(String activityType)
```

#### Safety
```dart
Future<void> completeSafetyCheck({...})
List<SafetyChecklistItem> getChecklistForActivity(String activityType)
List<SafetyCheck> getTodaysSafetyChecks(String activityType)
bool allRequiredChecksCompleted(String activityType)
Future<void> addChecklistItem(SafetyChecklistItem item)
```

#### Streams
```dart
Stream<ExtremeActivitySession?> get activeSessionStream
Stream<List<EquipmentItem>> get equipmentStream
Stream<List<SafetyChecklistItem>> get checklistStream
```

---

## Summary

The Extreme Activities Management System provides:

✅ **Equipment Tracking** - 21 categories, inspection schedules, expiry alerts  
✅ **Safety Checklists** - Pre-activity checks prevent unsafe sessions  
✅ **Session Logging** - Detailed performance metrics for all activities  
✅ **Performance Stats** - Track progress, records, and ratings  
✅ **Real-time Alerts** - Equipment needing attention  
✅ **Test Data** - One-line setup for 18 equipment items  
✅ **11 Activities** - Full integration with RedPing extreme modes  
✅ **Zero Errors** - All components compile successfully  

**Total Implementation:**
- 1 Service (733 lines)
- 7 Data Models (463 lines)
- 1 Dashboard (773 lines)
- 3 Widget Cards (834 lines)
- 1 Test Data Generator (267 lines)
- **Total: 3,070+ lines of production code**

---

**Ready to use!** Initialize service and start tracking your extreme activities safely. 🏔️🚴🪂
