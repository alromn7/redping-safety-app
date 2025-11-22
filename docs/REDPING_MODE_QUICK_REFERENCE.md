# RedPing Mode - Quick Reference Guide

## 🎯 Feature Overview

RedPing Mode is an **activity-based safety configuration system** with **17 specialized modes** across **5 categories** (Work, Travel, Family, Group, Extreme).

---

## 📱 User Guide

### Accessing RedPing Modes

1. **Open the RedPing app**
2. **Navigate to SOS Page** (homepage)
3. **Look at the top status bar** - You'll see "All Systems Active" and (if active) "[Mode Name] Active"
4. **Find the "RedPing Mode" card** (below the SOS button)
5. **Tap "Select Mode"** to browse modes

### Activating a Mode

1. **Browse modes** by category (All, Work, Travel, Family, Group, Extreme)
2. **Tap a mode card** to view details
3. **Review configuration** (sensor, location, hazard, emergency settings)
4. **Tap "Activate"** button
5. **Mode is now active** - You'll immediately see:
   - **Status indicator** at top shows "[Mode Name] Active" with mode icon
   - **Dashboard** appears automatically below the mode card
   - **Mode icon and color** displayed throughout

### Monitoring Active Mode

When a mode is active, you'll see:

**At the Top (Status Bar):**
- **✅ All Systems Active** (left side)
- **🏗️ [Mode Name] Active** (right side) - Shows mode icon and name in mode's color
  - Example: "Working at Height Active" in orange
  - Example: "Family Protection Active" in blue
  - Example: "Group Activity Active" in green

**In the Mode Card:**
- Mode icon, name, and duration
- Quick metrics: Crash/Fall/SOS thresholds
- "Manage" button (replaces "Select Mode")

**Active Mode Dashboard:**
- Real-time stats (sensor status, location tracking)
- Color-coded metrics (Crash 🔴, Fall 🟠, SOS 🔵, Power 🟢)
- Hazard monitoring chips
- "LIVE" badge

### Deactivating a Mode

1. **Tap "Manage"** on the RedPing Mode card
2. **Tap "Deactivate"** on the mode details sheet
3. **Mode session ends** and is saved to history
4. **Status indicator** at top disappears (only "All Systems Active" remains)

---

## 🏆 Mode Categories

### 🏢 Work Modes (3 modes)
**For professional/workplace safety**

1. **Remote Area** - Working in isolated locations with limited connectivity
2. **Working at Height** - Construction, towers, scaffolding work
3. **High Risk Task** - Electrical work, confined spaces, chemical handling

### ✈️ Travel Modes (1 mode)
**For journey safety**

4. **Travel Mode** - Road trips, business travel, commuting

### 👨‍👩‍👧‍👦 Family Modes (1 mode)
**For family member safety**

5. **Family Protection** - Children, teens, elderly monitoring with age-based thresholds

### 👥 Group Modes (1 mode)
**For multi-person activities**

6. **Group Activity** - Coordinate up to 50 members with rally points and separation alerts

### ⛰️ Extreme Modes (11 modes)
**For high-risk sports and activities**

7. **Skiing/Snowboarding** - Avalanche alerts, slope monitoring
8. **Rock Climbing** - Very low fall threshold, altitude tracking
9. **Hiking/Trekking** - Wilderness safety, offline maps
10. **Mountain Biking** - Speed tracking, trail monitoring
11. **Boating/Kayaking** - Man overboard, immediate SOS (0s)
12. **Scuba Diving** - Depth tracking, marine rescue
13. **Open Water Swimming** - Drowning prevention, immediate SOS (0s)
14. **4WD/Off-Roading** - Rollover detection, remote tracking
15. **Trail Running** - Pace tracking, performance monitoring
16. **Skydiving/Parachuting** - Freefall detection, altitude critical
17. **Flying (Private Pilot)** - Aircraft crash detection, flight tracking

---

## 🔧 Configuration Parameters

### Crash Threshold
**What it is**: Maximum acceleration before crash is detected  
**Range**: 120 m/s² (elderly) to 400 m/s² (flying)  
**Impact**: Lower = more sensitive, Higher = fewer false alarms

### Fall Threshold
**What it is**: Acceleration pattern indicating a fall  
**Range**: 50 m/s² (skydiving freefall) to 180 m/s² (4WD)  
**Impact**: Lower = detects gentler falls (elderly), Higher = only hard impacts

### SOS Countdown
**What it is**: Time before SOS auto-activates after detection  
**Range**: 0 seconds (water activities) to 15 seconds (remote/aircraft)  
**Impact**: Shorter = faster response, Longer = more time to cancel false alarms

### Power Mode
**Low**: 3-5 day battery, reduced monitoring  
**Balanced**: 1-2 day battery, standard monitoring (most modes)  
**High**: <1 day battery, maximum sensitivity (group, extreme activities)

---

## 👨‍👩‍👧 Family Mode Guide

### Age-Based Configurations

#### Children (0-12 years)
- **Sensitivity**: High (130/120 m/s²)
- **Geofencing**: ✅ Required (school, home, parks)
- **Check-Ins**: Every 2 hours
- **Alerts**: Parents notified on geofence exit
- **Best For**: School-age children, playground safety

#### Teens (13-17 years)
- **Sensitivity**: Medium (140/130 m/s²)
- **Driver Monitoring**: ✅ Enabled
- **Speed Alerts**: ✅ At 100 km/h
- **Check-Ins**: Every 4 hours
- **Privacy**: Location sharing mandatory
- **Best For**: Teen drivers, independence with oversight

#### Elderly (65+ years)
- **Sensitivity**: Very High (120/100 m/s²)
- **Fall Detection**: ✅ Most sensitive
- **Wandering Alerts**: ✅ Enabled
- **Check-Ins**: Every 6 hours
- **Auto-Alert**: Immediate on fall
- **Best For**: Elderly care, fall prevention, dementia support

### Geofencing Setup
1. **Home Zone**: 300m radius, exit alerts on
2. **School Zone**: 500m radius, exit alerts on
3. **Park Zone**: 200m radius, exit alerts optional

---

## 👥 Group Mode Guide

### Group Sizes
- **Small Groups**: 2-10 members (hiking, camping)
- **Medium Groups**: 11-25 members (cycling clubs)
- **Large Groups**: 26-50 members (organized events)

### Activity Types

#### Hiking Groups
- **Separation**: 500 meters
- **Rally Points**: Every 2 km
- **Best For**: Day hikes, wilderness treks

#### Cycling Clubs
- **Separation**: 1000 meters (higher speed)
- **Speed Monitoring**: ✅ Enabled
- **Best For**: Road cycling tours, group rides

#### Running Groups
- **Separation**: 300 meters
- **Pace Tracking**: ✅ Enabled
- **Best For**: Trail runs, marathons

#### Boating Expeditions
- **Separation**: 1000 meters (water)
- **Water Safety**: ✅ Enabled
- **Best For**: Kayaking, sailing groups

#### Events (50 members)
- **Separation**: 300 meters
- **Venue Geofence**: ✅ Enabled
- **Best For**: Corporate team building, large gatherings

### Rally Points
- **Purpose**: Designated checkpoints for headcount and regrouping
- **Auto-Suggest**: AI recommends optimal points based on route
- **Check-In**: Mandatory arrival confirmation
- **Late Alert**: Notification if member doesn't arrive within 10 minutes
- **Max Points**: 10 per activity

### Separation Alerts
- **Trigger**: Member exceeds separation distance from group
- **Notification**: Both member and leader alerted
- **Action**: Auto-guide back to group
- **Delay**: 30 seconds (prevents false alarms)

---

## 📊 Dashboard Metrics Explained

### Color Coding
- 🔴 **Red (Crash)**: High-impact detection threshold
- 🟠 **Orange (Fall)**: Fall pattern detection threshold
- 🔵 **Blue (SOS)**: SOS countdown time
- 🟢 **Green (Power)**: Battery optimization mode

### Real-Time Stats
- **Sensor Status**: ✅ Monitoring / ❌ Stopped
- **Location Tracking**: ✅ Active / ❌ Inactive
- **Sensors**: ✅ On / ❌ Off

### Hazard Chips
Shows active hazard monitoring types:
- Weather (storms, extreme temps)
- Environmental (air quality, altitude)
- Proximity (nearby hazards)
- Traffic (vehicle alerts)
- Water (marine conditions)
- Crash (impact detection)
- Fall (fall pattern detection)
- Freefall (skydiving, aircraft)

---

## ⚡ Quick Tips

### Choosing the Right Mode
1. **Match activity to mode** - Use specific modes for best safety
2. **Consider environment** - Remote areas need higher sensitivity
3. **Check battery impact** - High power modes drain faster
4. **Review thresholds** - Understand when alerts trigger

### Optimizing Battery Life
- Use **Balanced** power mode for most activities
- Switch to **Low** for multi-day wilderness trips
- Reserve **High** for critical safety situations
- Deactivate mode when activity ends

### False Alarm Prevention
- Choose appropriate crash/fall thresholds for activity
- Use longer SOS countdowns if activity is rough (4WD, skiing)
- Use immediate SOS (0s) only for water activities
- Cancel false alarms during countdown period

### Emergency Response
- **During Countdown**: Tap anywhere to cancel false alarm
- **SOS Activated**: Contacts notified, location shared
- **Auto-Call**: Emergency services called (if enabled)
- **Video Evidence**: Recording starts (if enabled)

---

## 🔍 Mode Comparison Table

| Mode | Crash | Fall | SOS | Power | Best For |
|------|-------|------|-----|-------|----------|
| Remote Area | 180 | 150 | 15s | Balanced | Mining, forestry |
| Working at Height | 160 | 120 | 5s | Balanced | Construction towers |
| High Risk Task | 150 | 130 | 5s | Balanced | Electrical, chemicals |
| Travel Mode | 200 | 150 | 10s | Balanced | Road trips |
| Family Protection | 140 | 130 | 8s | Balanced | Children, elderly |
| Group Activity | 180 | 140 | 5s | High | Hiking, events |
| Skiing | 220 | 140 | 10s | Balanced | Snow sports |
| Climbing | 180 | 100 | 5s | Balanced | Rock climbing |
| Hiking | 180 | 150 | 10s | Balanced | Wilderness |
| Biking | 200 | 140 | 10s | Balanced | Trail riding |
| Boating | 180 | 130 | 0s | Balanced | Water sports |
| Scuba | 180 | 150 | 0s | Balanced | Diving |
| Swimming | 180 | 120 | 0s | Balanced | Open water |
| 4WD | 250 | 180 | 8s | High | Off-roading |
| Trail Running | 180 | 140 | 10s | Balanced | Running |
| Skydiving | 300 | 50 | 3s | High | Parachuting |
| Flying | 400 | 100 | 15s | High | Private aircraft |

---

## 📞 Support & Feedback

### Need Help?
- Review mode details before activation
- Check dashboard for real-time status
- Deactivate mode if experiencing issues
- Contact support for assistance

### Report Issues
- False alarms too frequent? Try higher threshold mode
- Battery draining fast? Switch to Balanced or Low power
- Missing features? Request in feedback

---

**RedPing Mode: Adaptive Safety for Every Activity** 🛡️
