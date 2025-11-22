# RedPing Mode Feature Plan
**Version:** 1.0  
**Date:** November 2, 2025  
**Status:** Feature Specification

---

## 📋 Table of Contents
1. [Overview](#overview)
2. [Core Concept](#core-concept)
3. [Default Base Features](#default-base-features)
4. [Activity Modes](#activity-modes)
5. [Technical Architecture](#technical-architecture)
6. [UI/UX Design](#uiux-design)
7. [Implementation Phases](#implementation-phases)
8. [Safety & Compliance](#safety--compliance)

---

## 🎯 Overview

**RedPing Mode** is an intelligent activity-based safety system that automatically or manually configures the app's sensors, monitoring intensity, location tracking, hazard detection, and emergency response protocols based on the user's current activity or work environment.

### Goals
- **Adaptive Safety**: Tailor safety features to specific risk profiles
- **Battery Optimization**: Adjust monitoring intensity based on activity needs
- **Contextual Awareness**: Provide relevant hazard alerts for each activity
- **Faster Emergency Response**: Pre-configure emergency protocols for high-risk activities

---

## 🔧 Core Concept

### Activity-Based Configuration
Each mode automatically adjusts:
- **Sensor Sensitivity** (crash/fall thresholds)
- **Monitoring Frequency** (low/medium/high power)
- **Location Tracking** (breadcrumb interval & accuracy)
- **Hazard Alert Types** (contextual warnings)
- **Emergency Contact Priority** (activity-specific contacts)
- **Auto-Detection Triggers** (mode-specific patterns)

### Mode Selection
- **Manual Activation**: User selects mode before starting activity
- **Smart Suggestions**: App suggests mode based on location/time/calendar
- **Auto-Detection**: AI learns patterns and auto-activates (future)
- **Quick Switch**: Swipe gesture or widget for instant mode change

---

## 🛡️ Default Base Features
**Available in ALL modes (Minimum Safety Baseline)**

### 1. Core Monitoring
- ✅ Continuous sensor monitoring (adjustable intensity)
- ✅ Real-world acceleration calibration
- ✅ Background operation capability
- ✅ Battery optimization (adaptive power modes)

### 2. Location Services
- ✅ Location breadcrumbs (every 30 sec - 5 min based on mode)
- ✅ GPS accuracy monitoring (< 100m preferred)
- ✅ Last known location caching (offline capability)
- ✅ Location sharing with emergency contacts

### 3. Hazard Reporting
- ✅ Comprehensive environmental hazard alerts
- ✅ Weather condition monitoring
- ✅ Air quality index tracking
- ✅ UV radiation warnings
- ✅ Temperature extremes alerts
- ✅ Storm/lightning detection (where available)

### 4. Emergency Response
- ✅ SOS button (10-sec hold activation)
- ✅ Auto crash detection (180+ m/s²)
- ✅ Auto fall detection (150 m/s²)
- ✅ Emergency contact notification
- ✅ SAR team integration
- ✅ Offline SOS queue (retry when online)

### 5. Communication
- ✅ Emergency chat with responders
- ✅ Voice message capability
- ✅ Photo/video evidence upload
- ✅ Real-time status updates to contacts

---

## 🏗️ Activity Modes

---

### 1️⃣ **REMOTE AREA MODE**
**Scenario**: Working in isolated locations (mining, forestry, rural construction, farming)

#### Enhanced Features
- 🔋 **Extended Battery Mode**: Low-power monitoring (3-5 day battery life)
- 📍 **Aggressive Location Tracking**: Breadcrumbs every 2 minutes
- 📡 **Satellite Fallback**: Auto-switch to satellite messaging if cellular lost
- ⏰ **Check-in Timers**: Mandatory check-ins every 2-4 hours
- 🚨 **No-Movement Alerts**: Trigger SOS if stationary >30 min (configurable)
- 📞 **Priority Contacts**: Work supervisor + emergency services
- 🗺️ **Offline Maps**: Pre-cache maps for area (10km radius)

#### Hazard Monitoring
- ⚠️ **Wildlife Alerts**: Bear/snake sightings in area (community-sourced)
- 🌡️ **Extreme Temperature**: Heat stroke / hypothermia warnings
- ⛈️ **Severe Weather**: Storm tracking with 2-hour advance warning
- 🔥 **Bushfire Alerts**: Fire proximity and wind direction
- 💧 **Flood Risk**: River level and flash flood warnings
- 📶 **Signal Loss Warning**: Alert before entering no-coverage zone

#### Sensor Configuration
- Crash Threshold: 180 m/s² (vehicle accidents)
- Fall Threshold: 150 m/s² (trips, equipment falls)
- Violent Handling: 100-180 m/s² (machinery vibration filter)
- Motion Monitoring: Continuous (detects immobility)

#### Auto-Triggers
- 30 min stationary → Check-in prompt
- 60 min stationary → Auto-alert supervisor
- 90 min stationary → Auto-SOS activation
- Signal lost >20 min → Queue emergency beacon

---

### 2️⃣ **WORKING AT HEIGHT MODE**
**Scenario**: Construction, tower work, roofing, window cleaning, tree surgery

#### Enhanced Features
- 🎯 **Ultra-Sensitive Fall Detection**: Lowered threshold to 120 m/s²
- 📏 **Altitude Tracking**: Monitor height changes via barometer
- ⏱️ **Rapid Response**: Instant SOS on fall (no countdown)
- 🚁 **Helicopter Evacuation**: Pre-configure aerial rescue contacts
- 📹 **Video Evidence**: Auto-record 30 sec before/after fall
- 👷 **Harness Integration**: Bluetooth smart harness connectivity (future)
- ⚡ **Lightning Warning**: Stop work alerts for electrical storms

#### Hazard Monitoring
- 💨 **Wind Speed Alerts**: Work stoppage at >40 km/h gusts
- 🌧️ **Rain/Ice Warnings**: Slippery surface hazard alerts
- ⚡ **Electrical Storm**: 20km radius lightning tracking
- 🌡️ **Heat Index**: Dehydration and fatigue warnings at height
- 🌫️ **Visibility Alerts**: Fog/low visibility warnings
- 🏗️ **Structural Integrity**: Earthquake/tremor detection

#### Sensor Configuration
- Crash Threshold: 180 m/s² (falling objects, collisions)
- Fall Threshold: **120 m/s²** (lower for height-related falls)
- Free-fall Detection: <2.0 m/s² for >0.5 sec → Immediate SOS
- Impact Detection: >150 m/s² after free-fall → Auto-SOS
- Altitude Change: >3m sudden drop → Fall alert

#### Auto-Triggers
- Free-fall >0.5 sec → Instant SOS (no 10s countdown)
- Fall detected → Auto-call emergency services
- Barometer drop >5m in 2 sec → Fall verification
- Post-fall immobility >10 sec → Escalate to SAR

#### Safety Protocols
- Pre-shift checklist (equipment verification)
- Buddy system check-ins (every 30 min)
- Weather clearance verification
- Emergency evacuation route mapping

---

### 3️⃣ **HIGH RISK TASK MODE**
**Scenario**: Confined spaces, hazardous materials, electrical work, underwater welding

#### Enhanced Features
- ☠️ **Gas Detection Integration**: CO, H2S, O2 level monitoring (via Bluetooth sensor)
- 🔒 **Permit-to-Work**: Digital safety permit system
- 👥 **Buddy Monitoring**: Two-way check-ins with partner
- ⏰ **Countdown Timer**: Task duration limits with alerts
- 📹 **Continuous Recording**: Black box mode (audio/video log)
- 🚪 **Entry/Exit Logging**: Geofence-based confined space tracking
- 🆘 **Panic Button**: One-tap instant SOS (no hold required)

#### Hazard Monitoring
- ☢️ **Radiation Levels**: Ionizing radiation detection (with compatible sensor)
- 🧪 **Chemical Exposure**: Toxic gas proximity alerts
- 🔥 **Fire/Explosion Risk**: Temperature and pressure anomalies
- ⚡ **Electrical Hazard**: High voltage proximity warnings
- 💨 **Ventilation Failure**: O2 level drop alerts
- 🌡️ **Extreme Temps**: Heat stress in protective gear

#### Sensor Configuration
- Crash Threshold: 150 m/s² (equipment impact, explosion)
- Fall Threshold: 130 m/s² (confined space collapse)
- Violent Handling: 100-180 m/s² (explosion shockwave detection)
- Environmental: Gas sensors, temperature, pressure
- Heart Rate: Optional wearable integration (fatigue detection)

#### Auto-Triggers
- Gas level >threshold → Immediate evacuation alert
- No movement >5 min → Buddy alert + supervisor notification
- Exit geofence timeout → Auto-SOS (stuck in confined space)
- Heart rate >140 bpm sustained → Medical alert
- Temperature >60°C → Heat emergency

#### Safety Protocols
- Pre-task hazard assessment checklist
- Mandatory atmospheric testing log
- Rescue plan verification
- Emergency escape route confirmation
- Post-task safety sign-off

---

### 4️⃣ **TRAVEL MODE**
**Scenario**: Long-distance driving, road trips, international travel, commuting

#### Enhanced Features
- 🚗 **Journey Sharing**: Real-time location sharing with family/friends
- 🛣️ **Route Deviation Alerts**: Notify contacts if off planned route
- ⏰ **Expected Arrival Time**: Auto-notify if delayed >30 min
- ⛽ **Fuel Stop Reminders**: Smart break suggestions every 2 hours
- 😴 **Fatigue Detection**: Drowsy driving pattern recognition
- 🚦 **Traffic Hazards**: Accident/roadwork/congestion alerts
- 🏨 **Safe Zone Check-ins**: Auto-check-in at destinations
- 🌍 **International SOS**: Country-specific emergency numbers

#### Hazard Monitoring
- ⛈️ **Weather Route Analysis**: Storm avoidance suggestions
- 🌪️ **Severe Weather**: Tornado/hurricane tracking
- 🌫️ **Visibility Warnings**: Fog, dust storm, smoke alerts
- ❄️ **Ice/Snow Conditions**: Winter driving hazards
- 🦌 **Wildlife Crossings**: Animal strike risk areas
- 🚧 **Road Closures**: Real-time road condition updates
- 🌋 **Natural Disasters**: Earthquake, tsunami, volcanic activity

#### Sensor Configuration
- Crash Threshold: **200 m/s²** (vehicle collision detection)
- Sustained Pattern: >180 m/s² for >200ms = crash
- Rapid Deceleration: 60+ km/h to 0 in <2 sec = crash
- Motion Resume: If movement continues after impact = false alarm cancel
- Driving Pattern: Recognize highway vs city driving
- Sudden Swerve: >50° direction change at speed

#### Auto-Triggers
- Crash detected → 30 sec countdown with auto-call
- Airbag deployment (if phone detects) → Instant SOS
- Rollover pattern → Immediate emergency response
- 3+ hours no movement on highway → Check-in prompt
- Deviation >20km from route → Notify emergency contacts
- Speed >200 km/h sustained → Reckless driving alert to contacts

#### Smart Features
- **Fuel Price Alerts**: Cheapest stations on route
- **Rest Stop Locator**: Safe parking areas every 2 hours
- **Points of Interest**: Emergency services, hospitals on route
- **Border Crossing Alerts**: International travel notifications
- **Insurance Integration**: Auto-claim filing if crash detected

---

### 5️⃣ **FAMILY MODE**
**Scenario**: Family outings, children supervision, elderly care, group activities with loved ones

#### Enhanced Features
- 👨‍👩‍👧‍👦 **Family Circle Management**: Add/remove family members with roles (parent, child, elderly)
- 📍 **Real-Time Family Map**: Live location view of all family members
- 🚸 **Child Safety Zones**: Geofence alerts when children enter/exit safe zones
- 👵 **Elderly Monitoring**: Fall detection + medication reminders + wandering alerts
- 🏫 **School/Activity Check-ins**: Auto-confirm arrival at school, sports, activities
- 🚗 **Driving Safety**: Teen driver monitoring (speed, harsh braking, location)
- 📱 **Device Pairing**: Link children's devices to parent account
- 🔔 **Smart Notifications**: Customizable alerts per family member
- 🗓️ **Family Calendar Integration**: Auto-activate mode based on family events
- 🆘 **Family Emergency Protocol**: One member's SOS alerts entire family
- 💬 **Family Chat**: Dedicated communication channel with location sharing
- 📊 **Activity Dashboard**: Overview of all family members' status
- 🔋 **Battery Alerts**: Low battery warnings for family devices
- 🌙 **Night Mode**: Quiet hours with reduced notifications

#### Hazard Monitoring
- 🚸 **School Zone Alerts**: Speed limit reminders in school areas
- 🏊 **Pool/Water Safety**: Drowning prevention alerts near water bodies
- 🚗 **Traffic Hazards**: Child pedestrian safety in high-traffic areas
- 🌡️ **Temperature Extremes**: Heat stroke/hypothermia for children/elderly
- 🏥 **Medical Facilities**: Nearest hospital/clinic locations
- 🚨 **Amber Alerts**: Child abduction alerts in local area
- 👮 **Safety Zones**: Police/fire station proximity
- 🌳 **Park Safety**: Playground equipment, trail conditions

#### Sensor Configuration (Per Family Member)
- **Children (<12)**:
  - Fall Threshold: 130 m/s² (playground falls, running)
  - Crash Threshold: 160 m/s² (bicycle accidents, car crashes)
  - Geofencing: Strict (100m radius from approved zones)
  - Check-in: Required every 2-4 hours
  
- **Teens (13-17)**:
  - Fall Threshold: 140 m/s²
  - Crash Threshold: 180 m/s² (driving accidents)
  - Driving Monitor: Speed, location, harsh events
  - Check-in: Required every 4-6 hours
  
- **Adults**:
  - Standard thresholds (150 m/s² fall, 180 m/s² crash)
  - Optional monitoring
  
- **Elderly (65+)**:
  - Fall Threshold: 120 m/s² (more sensitive for fragile bones)
  - Immobility Detection: Alert if stationary >20 min (fall risk)
  - Wandering Detection: Geofence alerts (dementia care)
  - Medication Reminders: Scheduled alerts

#### Auto-Triggers
- **Children**:
  - Exit safe zone (school, home) → Parent notification
  - Fall detected → Immediate parent alert + 60 sec SOS countdown
  - No movement >15 min → Parent check-in request
  - Battery <20% → Parent low battery warning
  
- **Teens**:
  - Speeding >20 km/h over limit → Parent warning
  - Harsh braking/crash → Immediate parent + emergency alert
  - Late arrival at destination → Parent notification
  - Out past curfew → Parent alert
  
- **Elderly**:
  - Fall detected → Immediate family alert + 30 sec SOS
  - Wandering outside safe zone → Family notification
  - Medication missed → Reminder + family alert
  - No activity detected >3 hours → Wellness check

#### Family Dashboard Metrics
- 📍 Current location of each member
- 🔋 Battery levels for all devices
- ✅ Last check-in time
- 🚶 Activity status (stationary, moving, driving)
- ⚠️ Active alerts/warnings
- 📊 Weekly safety summary
- 🏆 Safety streak (days without incidents)

#### Privacy Controls
- **Teen Privacy Options**: Balance between safety and independence
- **Location History**: Automatic deletion after 7/30 days (configurable)
- **Sharing Permissions**: Granular control over what data is shared
- **Emergency Override**: Full tracking enabled during SOS events
- **Opt-out Ages**: Automatic transition to adult mode at 18

---

### 6️⃣ **GROUP MODE**
**Scenario**: Friends outings, hiking groups, sports teams, tour groups, event coordination

#### Enhanced Features
- 👥 **Dynamic Group Creation**: Create temporary or permanent groups (max 50 members)
- 📍 **Live Group Map**: Real-time location of all group members with clustering
- 🎯 **Rally Point**: Set meeting points with navigation for all members
- 📊 **Group Statistics**: Distance covered, elevation, average speed, spread
- 💬 **Group Chat**: Built-in messaging with location sharing
- 🔔 **Group Announcements**: Broadcast alerts to all members
- 📸 **Photo Sharing**: Geotagged photos shared with group
- 🏁 **Waypoint Navigation**: Shared route with turn-by-turn guidance
- ⏱️ **Group Pacing**: Monitor stragglers and leaders
- 🆘 **Group Emergency**: One member's SOS alerts entire group + coordinates
- 📱 **Invite System**: QR code or link to join group
- 👑 **Group Leader**: Designated coordinator with admin privileges
- 🔄 **Buddy System**: Pair members for mutual safety checks
- 📋 **Group Checklist**: Pre-activity safety verification for all

#### Hazard Monitoring
- ⚠️ **Group Separation Alerts**: Member >500m from group center
- 🌡️ **Environmental Conditions**: Shared weather/hazard updates
- 🚶 **Pace Warnings**: Slowest member falling behind
- 🔋 **Battery Monitoring**: Low battery alerts for any member
- 📶 **Signal Loss**: Alert when member enters no-coverage area
- ⏰ **Time Management**: Expected arrival time vs actual
- 🌙 **Sunset Warnings**: Nightfall approaching alerts
- 🗺️ **Off-Route Alerts**: Member deviating from planned path

#### Group Types & Configurations

##### 🥾 **Hiking/Trekking Group**
- Breadcrumb interval: 1 min (detailed trail tracking)
- Separation threshold: 200m (visual contact)
- Check-in: Every 30 min at waypoints
- Leader can mark hazards (steep section, wildlife, etc.)
- Auto-alerts for stragglers >500m behind
- Summit countdown timer (turnaround time)

##### 🚴 **Cycling Group**
- Breadcrumb interval: 30 sec (high speed)
- Separation threshold: 500m (group riding)
- Speed monitoring: Alert if member <50% average speed
- Mechanical breakdown signal
- Regrouping waypoints at intersections
- Traffic hazard sharing

##### 🏃 **Running/Jogging Group**
- Breadcrumb interval: 1 min
- Pace groups (fast, medium, slow)
- Heart rate sharing (optional)
- Water station waypoints
- Injury/cramp signals
- Finish line notifications

##### ⛵ **Boating/Sailing Group**
- Marine navigation integration
- Man overboard alerts entire fleet
- Weather updates broadcasted
- Anchor point monitoring
- VHF channel coordination
- Distress signals relay

##### 🎿 **Ski/Snowboard Group**
- Lift queue coordination
- Slope difficulty matching
- Avalanche alerts shared
- Lost member search pattern
- Après-ski meetup points
- Equipment issues flagging

##### 🏕️ **Camping Group**
- Campsite location marking
- Firewood/water source sharing
- Wildlife sighting alerts
- Quiet hours enforcement
- Morning wake-up coordination
- Departure time synchronization

##### 🎉 **Event/Festival Group**
- Venue map with member locations
- Stage schedule coordination
- Lost & found meetup points
- Battery charging station locations
- Exit coordination
- Ride-share pairing

#### Sensor Configuration (Group Default)
- Crash Threshold: 180 m/s² (adjusts to activity type)
- Fall Threshold: 150 m/s² (adjusts to activity type)
- Separation Alert: 200-1000m (activity dependent)
- Location Update: 30 sec - 5 min (based on activity)
- Battery Conservation: Shared monitoring reduces individual load

#### Auto-Triggers
- Member separation >threshold → Group alert + navigation to member
- Member fall/crash → Instant group notification + nearest member dispatch
- Member SOS → Alert all + coordinate response
- Member battery <10% → Group notification + buddy assignment
- Weather hazard → Broadcast to all members
- Time checkpoint missed → Group reminder
- Member stationary >20 min → Buddy check-in
- Group leader marks waypoint → Auto-navigate all members

#### Group Coordination Features
- **Headcount System**: Automatic member accounting at checkpoints
- **Role Assignment**: Leader, navigator, sweep (last person), first aider
- **Skill Levels**: Beginner, intermediate, advanced (pace matching)
- **Equipment Sharing**: Who has what (first aid, tools, water filter)
- **Emergency Contacts**: Consolidated list for entire group
- **Group Insurance**: Optional group activity insurance integration
- **Post-Activity Report**: Summary of distance, time, incidents, photos

#### Privacy & Permissions
- **Temporary Sharing**: Location sharing ends when group disbands
- **Anonymous Mode**: Hide name, show as "Member 7" (festivals/events)
- **Opt-out Tracking**: Members can disable tracking (with group leader approval)
- **Data Retention**: Group data deleted after 30 days (configurable)
- **Join Approval**: Leader can require approval for new members
- **Kick/Block**: Leader can remove disruptive members

#### Group Dashboard Metrics
- 🗺️ Live map with all member locations
- 📊 Group statistics (distance, speed, elevation)
- 👥 Member count and status
- ⚠️ Active alerts/warnings
- 🔋 Battery levels for all members
- 📍 Distance to rally point
- ⏱️ Elapsed time / ETA
- 🏆 Group achievements (summit reached, distance record)

---

### 7️⃣ **EXTREME ACTIVITIES MODE**
**Parent Category with Specialized Sub-Modes**

#### General Extreme Features (All Sub-Categories)
- 🏔️ **Activity-Specific Thresholds**: Customized detection per sport
- 📸 **Action Cam Integration**: GoPro/360 camera sync for evidence
- 🏥 **Medical Info Quick Access**: Blood type, allergies, conditions
- 🚁 **Aerial Rescue Coordination**: Helicopter LZ identification
- 🌐 **Gear Tracking**: Equipment checklist and maintenance logs
- 👥 **Group Coordination**: Multi-user location sharing
- 📡 **Satellite Messaging**: Backup communication (Garmin inReach, etc.)
- 🏆 **Performance Tracking**: Activity stats and personal records

---

#### 7.1 🎿 **SKIING / SNOWBOARDING**

**Features**
- 🗺️ **Piste Mapping**: Trail difficulty and avalanche zones
- ❄️ **Avalanche Alerts**: Real-time risk assessment
- 🌡️ **Temperature & Wind Chill**: Frostbite warnings
- 🏂 **Fall Detection**: High-speed tumble vs controlled fall
- 📍 **Lift Location**: Auto-check-in at each lift
- 🚑 **Ski Patrol Integration**: Resort emergency services

**Hazards**
- Avalanche risk levels (1-5 scale)
- Tree well proximity warnings
- Cliff/drop-off alerts
- Whiteout/visibility conditions
- Hypothermia risk assessment
- Altitude sickness (high elevations)

**Sensors**
- Crash: 250 m/s² (high-speed collisions)
- Fall: 180 m/s² (tumbling differentiation)
- Altitude: Barometer tracking (rescue elevation)
- Speed: GPS-based (>80 km/h = high risk)
- Freefall: >1 sec + impact = cliff fall

**Auto-Triggers**
- High-speed crash >60 km/h → 60 sec countdown
- Tree collision detected → Immediate alert
- Stationary in avalanche zone >10 min → Check-in
- Temperature <-25°C + no movement → Hypothermia alert

---

#### 7.2 🪂 **SKYDIVING / BASE JUMPING**

**Features**
- ✈️ **Jump Altitude Tracking**: Exit altitude logging
- 🪂 **Parachute Deployment Detection**: Barometer + accelerometer
- 🎯 **Landing Zone Mapping**: Approved LZ coordinates
- 📡 **Freefall Timer**: Auto-start at exit
- 🚁 **Air Rescue Coordination**: Helicopter emergency pickup
- 📋 **Jump Log**: Automatic jump counting and stats

**Hazards**
- Wind speed at altitude (>25 knots = no jump)
- Cloud cover / visibility
- Air traffic proximity
- Landing zone obstacles
- Weather window (pressure changes)
- Oxygen level warnings (HALO jumps)

**Sensors**
- Altitude: Precise barometer (3000m+ tracking)
- Freefall: Sustained <2 m/s² acceleration
- Deployment: Sudden deceleration (chute opening)
- Landing: Impact detection (150-200 m/s²)
- Speed: Terminal velocity monitoring (200+ km/h)

**Auto-Triggers**
- Freefall >20 sec without chute → Emergency (malfunction)
- Hard landing >200 m/s² → Medical check
- Water landing detected → Immediate water rescue
- Altitude <300m without chute → Catastrophic emergency
- No movement post-landing → Auto-SOS in 60 sec

---

#### 7.3 🤿 **SEA DIVING / SCUBA**

**Features**
- 🌊 **Dive Computer Sync**: Bluetooth dive computer integration
- ⏱️ **Dive Timer**: Automatic dive start/end logging
- 🚢 **Boat Return Navigation**: Compass bearing to vessel
- 🆘 **Surface Marker Buoy**: GPS coordinates broadcasting
- 🏥 **Decompression Alerts**: Bends prevention (via dive computer)
- 🌡️ **Water Temperature**: Hypothermia risk in cold water
- 🌙 **Night Dive Mode**: Low-light interface + flashlight

**Hazards**
- Strong currents (>2 knots)
- Low visibility (<5m)
- Marine life warnings (shark/jellyfish sightings)
- Boat traffic proximity
- Weather deterioration (surface conditions)
- Water temperature <15°C (drysuit required)
- Tidal changes and rip currents

**Sensors**
- Depth: Pressure sensor (dive depth logging)
- Time: Dive duration tracking
- Temperature: Water temp monitoring
- Motion: Panic swimming detection
- Surface: GPS reacquisition after dive
- O2: Dive computer integration (tank pressure)

**Auto-Triggers**
- Dive time >max (from dive computer) → Surface warning
- Rapid ascent detected → Decompression alert
- Surface >500m from boat → Lost diver protocol
- No GPS signal 10 min post-surface → Missing diver SOS
- Panic motion detected underwater → Buddy alert
- Emergency ascent pattern → Auto-alert boat + emergency

---

#### 7.4 🧗 **MOUNTAIN CLIMBING / MOUNTAINEERING**

**Features**
- 🏔️ **Summit Tracking**: Elevation progress logging
- 🧭 **Route Navigation**: Waypoint-based path guidance
- ⛺ **Camp Check-ins**: Altitude-based camp confirmation
- 🌡️ **Acclimatization Monitor**: Altitude sickness risk
- 🧗 **Rope Team Sync**: Multi-climber location sharing
- 📡 **Mountain Rescue**: Dedicated alpine rescue integration
- ❄️ **Weather Window**: Multi-day summit forecast

**Hazards**
- Avalanche risk (slope angle, recent snow)
- Altitude sickness (>2500m elevation)
- Crevasse locations (glacier travel)
- Rockfall zones
- Electrical storms at elevation
- Wind speed (>60 km/h = descent required)
- Temperature + wind chill (frostbite risk)
- Oxygen saturation <90% (supplemental O2 needed)

**Sensors**
- Altitude: Precise barometer (up to 9000m)
- Temperature: Ambient + wind chill calculation
- Fall: Crevasse fall detection (sudden drop)
- Crash: Rockfall/avalanche impact
- Heart Rate: Altitude sickness early warning
- SpO2: Blood oxygen saturation (with wearable)

**Auto-Triggers**
- Fall >10m (barometer) → Crevasse fall SOS
- Altitude sickness symptoms detected → Descent alert
- Temperature <-40°C → Extreme cold emergency
- No movement >30 min above 6000m → Medical emergency
- Avalanche burial detected (motion + no signal) → Beacon activation
- Summit timeout (>18 hours from basecamp) → Overdue climber alert

---

#### 7.5 🚤 **BOATING / SAILING**

**Features**
- ⚓ **Marine Navigation**: AIS integration, chart plotting
- 🧭 **Compass Heading**: Course deviation alerts
- 🌊 **Man Overboard (MOB)**: Instant GPS marker + return heading
- 🚢 **Vessel Check-ins**: Marina/harbor auto-logging
- ⛽ **Fuel Range**: Distance to shore calculator
- 📡 **VHF Radio Integration**: Emergency channel monitoring
- 🌅 **Sunset Alerts**: Return to port reminders

**Hazards**
- Wave height >2m (small craft advisory)
- Wind speed >25 knots
- Severe weather (storms, waterspouts)
- Fog / low visibility
- Shipping lane traffic
- Shallow water / reef proximity
- Marine hazards (debris, buoys)
- Rip currents and undertows

**Sensors**
- GPS: Precise maritime navigation
- Compass: Heading tracking
- Barometer: Pressure drop (storm warning)
- Accelerometer: Man overboard detection
- Speed: Boat speed monitoring
- Distance: Shore proximity

**Auto-Triggers**
- Man overboard (sudden acceleration + GPS separation) → Instant MOB alert
- Vessel adrift (no movement + away from anchor point) → Drift alert
- Storm approaching (pressure drop >5 hPa/hour) → Return to port
- Fuel range <10km to shore → Low fuel warning
- No check-in at expected time → Overdue vessel alert
- Capsize detected (90° tilt sustained) → MAYDAY SOS

---

#### 7.6 🏊 **OPEN WATER SWIMMING**

**Features**
- 🏊 **Swim Tracking**: Distance, pace, stroke count
- 🌊 **Waterproof Mode**: IP68 device protection required
- 🛟 **Safety Buoy GPS**: Tow-float mounted phone tracking
- 👥 **Buddy Location**: Multi-swimmer tracking
- 🚤 **Support Boat Sync**: Return bearing to boat/kayaker
- 🌡️ **Water Temperature**: Hypothermia risk monitoring
- 🆘 **Panic Signal**: Waving arm detection (SOS pattern)

**Hazards**
- Water temperature <18°C (wetsuit required)
- Strong currents (>1 knot)
- Rip currents and undertows
- Marine life (jellyfish, sharks)
- Boat traffic proximity
- Visibility / fog
- Sudden weather change
- Fatigue and cramps

**Sensors**
- GPS: Swimming route tracking (in tow float)
- Temperature: Water temp monitoring
- Motion: Stroke pattern recognition
- Accelerometer: Panic swimming detection
- Heart Rate: Wearable integration (fatigue)
- Distance: Shore/boat separation

**Auto-Triggers**
- Distance from shore >500m solo → Risk warning
- Panic swimming detected → Buddy alert + support boat
- Heart rate >160 sustained → Fatigue warning
- No forward progress >2 min → Distress check-in
- Separation from group >100m → Reunion alert
- Temperature <15°C + swim time >20 min → Hypothermia risk

---

#### 7.7 🚴 **MOUNTAIN BIKING / BMX**

**Features**
- 🚵 **Trail Mapping**: MTB trail difficulty ratings
- 🏁 **Ride Tracking**: Distance, elevation, speed stats
- 🛠️ **Mechanical Breakdown**: Nearest bike shop locator
- 👥 **Group Rides**: Multi-rider location sharing
- 📹 **Crash Cam**: Auto-record 30 sec before/after crash
- 🏥 **Trail Emergency**: Evacuation point mapping
- 🌲 **Trail Conditions**: Recent user reports (mud, hazards)

**Hazards**
- Trail obstacles (rocks, roots, jumps)
- Wildlife encounters (bears, snakes)
- Mechanical failure (brake, tire, chain)
- Weather changes (rain = slippery)
- Remote location (no cell signal)
- Heat exhaustion on climbs
- Low visibility (dusk riding)

**Sensors**
- Crash: 200 m/s² (high-speed MTB crashes)
- Fall: 150 m/s² (over-the-bars, side falls)
- Speed: GPS tracking (downhill >40 km/h)
- Altitude: Climb/descent tracking
- Motion: Stationary = mechanical issue or injury

**Auto-Triggers**
- High-speed crash >30 km/h → 60 sec countdown
- Crash + no movement >2 min → Auto-SOS
- Stationary in remote area >20 min → Check-in prompt
- Multiple crashes in short time → Concussion protocol
- Separation from group >2 km → Reunion waypoint
- Emergency brake pattern → Pre-crash alert

---

#### 7.8 🚙 **4WD / OFF-ROADING**

**Features**
- 🗺️ **Track Mapping**: 4WD trail recording and sharing
- 🧭 **Recovery Points**: Winch anchor and camp locations
- 🛞 **Vehicle Tilt**: Rollover warning system
- ⛽ **Fuel Consumption**: Range to next fuel station
- 📡 **Convoy Tracking**: Multi-vehicle coordination
- 🔧 **Breakdown Assistance**: Remote mechanic diagnosis
- 🚗 **Vehicle Recovery**: Tow truck coordination

**Hazards**
- Steep inclines/declines (>30° rollover risk)
- Water crossings (depth, current)
- Soft sand / mud (bogging)
- Remote location (no rescue access)
- Extreme weather (dust storms, flash floods)
- Wildlife on tracks
- Equipment failure (suspension, diff, transmission)

**Sensors**
- Tilt: Gyroscope (rollover detection)
- Crash: 180 m/s² (impact, rollover)
- GPS: Off-road navigation
- Altitude: Elevation tracking
- Speed: Terrain-appropriate speed monitoring
- Barometer: Weather pressure changes

**Auto-Triggers**
- Vehicle rollover (>45° tilt) → Immediate SOS
- Crash detected → 30 sec countdown
- Stationary in remote area >2 hours → Check-in
- Water crossing depth >50cm → Caution alert
- Fuel range <50km + no station → Low fuel warning
- Multiple vehicle stops (bogged) → Recovery request

---

#### 7.9 🥾 **BUSH WALKING / HIKING**

**Features**
- 🥾 **Trail Navigation**: Turn-by-turn hiking directions
- 🏕️ **Camp Locations**: Designated camping area database
- 💧 **Water Sources**: Creek, spring, tank locations
- 🌳 **Flora/Fauna Database**: Plant ID and wildlife info
- 📸 **Photo Waypoints**: Geotagged trail markers
- 🆘 **Trail Emergency**: Rescue helicopter LZ points
- 🗺️ **Offline Maps**: Pre-cached topographic maps

**Hazards**
- Bushfire risk (fire danger rating)
- Snake/spider encounters
- Dehydration (heat, lack of water)
- Getting lost (trail deviation)
- Weather changes (storms, cold fronts)
- River crossings (flash flooding)
- Cliff edges and drop-offs
- Heat exhaustion / hypothermia

**Sensors**
- GPS: Trail navigation and breadcrumbs
- Fall: 140 m/s² (trip, cliff fall)
- Temperature: Heat/cold stress monitoring
- Altitude: Elevation gain tracking
- Motion: Walking pace and rest detection
- Compass: Heading tracking

**Auto-Triggers**
- Off-trail >200m → Lost hiker alert
- Fall detected → 90 sec countdown
- Stationary >1 hour not at camp → Check-in
- Temperature >35°C + low movement → Heat stress
- No progress toward destination → Navigation assist
- Sunset approaching + >2 hours from camp → Night warning

---

#### 7.10 🏃 **RUNNING / JOGGING**

**Features**
- 🏃 **Run Tracking**: Pace, distance, route mapping
- 💓 **Heart Rate Zones**: Training zone monitoring
- 🏅 **Personal Records**: PB tracking and achievements
- 👟 **Shoe Mileage**: Wear tracking (replace at 800km)
- 🌙 **Night Running Mode**: Reflective gear reminder
- 🚶 **Cool Down Timer**: Post-run stretch prompts
- 📊 **Performance Analytics**: VO2 max estimation

**Hazards**
- Traffic (cars, bikes)
- Uneven surfaces (trips, sprains)
- Dehydration
- Heat exhaustion
- Cardiac events (heart attack)
- Assault (solo running)
- Wildlife (dogs, snakes)
- Poor visibility (night, fog)

**Sensors**
- Heart Rate: Wearable integration (cardiac monitoring)
- Fall: 140 m/s² (trip, collapse)
- Speed: Pace tracking
- GPS: Route and distance
- Cadence: Steps per minute (via accelerometer)
- Impact: Repetitive stress monitoring

**Auto-Triggers**
- Heart rate >85% max sustained >10 min → Cardiac warning
- Sudden stop + fall → Medical emergency (60 sec countdown)
- Heart rate spike >200 bpm → Heart attack protocol
- Stationary >5 min mid-run → Injury/collapse check
- Off usual route + night → Safety check-in
- Temperature >30°C + HR elevated → Heat stress warning

---

#### 7.11 ✈️ **FLYING (Paragliding, Hang Gliding, Light Aircraft)**

**Features**
- ✈️ **Flight Logging**: Auto-start flight timer
- 🌤️ **Weather Layers**: Wind, thermals, cloud base
- 🧭 **Navigation**: Airspace restrictions, waypoints
- 📡 **FLARM Integration**: Collision avoidance system
- 🪂 **Emergency Landing**: Suitable field identification
- 🚁 **Air Rescue**: Helicopter coordination
- 📋 **Pre-flight Checklist**: Equipment verification

**Hazards**
- Wind shear and gusts (>30 knots)
- Thermals and downdrafts
- Controlled airspace violations
- Weather deterioration
- Collision with terrain/obstacles
- Parachute malfunction (paragliding)
- Engine failure (powered flight)
- Hypoxia (high altitude)

**Sensors**
- Altitude: Precise barometer (3000m+ flying)
- GPS: 3D flight path tracking
- Vario: Climb/sink rate
- Airspeed: GPS-derived speed
- Wind: Ground speed vs airspeed
- G-Force: Maneuver stress monitoring

**Auto-Triggers**
- Rapid descent >5 m/s sustained → Emergency landing
- Impact detected → Crash SOS (60 sec countdown)
- Altitude loss >500m in 1 min → Malfunction check
- No landing within flight plan time → Overdue aircraft
- Controlled flight into terrain → Immediate SOS
- Parachute deployment (paragliding) → Emergency rescue

---

## 🏗️ Technical Architecture

### Data Structure
```dart
class RedPingMode {
  final String id;
  final String name;
  final String category; // work, travel, extreme
  final IconData icon;
  final Color themeColor;
  
  // Sensor Configuration
  final SensorConfig sensorConfig;
  final LocationConfig locationConfig;
  final HazardConfig hazardConfig;
  final EmergencyConfig emergencyConfig;
  
  // Auto-Trigger Rules
  final List<AutoTriggerRule> autoTriggers;
  final List<HazardType> activeHazards;
  final List<String> priorityContacts;
  
  // UI Customization
  final String quickAccessWidget;
  final List<String> dashboardMetrics;
  final bool showPerformanceStats;
}

class SensorConfig {
  final double crashThreshold; // m/s²
  final double fallThreshold; // m/s²
  final double violentHandlingMin; // m/s²
  final double violentHandlingMax; // m/s²
  final Duration monitoringInterval;
  final bool enableFreefallDetection;
  final bool enableMotionTracking;
  final bool enableAltitudeTracking;
  final PowerMode powerMode; // low, medium, high
}

class LocationConfig {
  final Duration breadcrumbInterval; // 30 sec - 5 min
  final int accuracyTarget; // meters
  final bool enableOfflineMaps;
  final bool enableRouteTracking;
  final bool enableGeofencing;
  final int mapCacheRadius; // km
}

class HazardConfig {
  final List<HazardType> enabledHazards;
  final Map<HazardType, AlertLevel> hazardThresholds;
  final bool enableWeatherAlerts;
  final bool enableEnvironmentalAlerts;
  final bool enableProximityAlerts;
}

class EmergencyConfig {
  final Duration sosCountdown; // 0-90 sec
  final bool autoCallEmergency;
  final List<String> priorityContactIds;
  final String emergencyMessage;
  final bool enableVideoEvidence;
  final bool enableVoiceMessage;
  final RescueType preferredRescue; // ground, aerial, marine
}

class AutoTriggerRule {
  final String condition; // e.g., "stationary > 30 min"
  final TriggerAction action; // alert, sos, check-in
  final Duration delay;
  final String message;
  final bool requiresConfirmation;
}
```

### Mode Selection UI
```
┌─────────────────────────────────┐
│   🎯 Select RedPing Mode        │
├─────────────────────────────────┤
│                                 │
│ 🏢 WORK MODES                   │
│  ├─ 🏔️ Remote Area              │
│  ├─ 🏗️ Working at Height        │
│  └─ ⚠️ High Risk Task           │
│                                 │
│ 🚗 TRAVEL                       │
│  └─ 🗺️ Journey Mode             │
│                                 │
│ 👨‍👩‍👧‍👦 FAMILY & GROUPS              │
│  ├─ 👨‍👩‍👧 Family Mode              │
│  └─ 👥 Group Mode               │
│                                 │
│ 🏔️ EXTREME ACTIVITIES           │
│  ├─ 🎿 Skiing/Snowboarding      │
│  ├─ 🪂 Skydiving                │
│  ├─ 🤿 Sea Diving               │
│  ├─ 🧗 Mountain Climbing        │
│  ├─ 🚤 Boating                  │
│  ├─ 🏊 Open Water Swimming      │
│  ├─ 🚴 Mountain Biking          │
│  ├─ 🚙 4WD Off-Roading          │
│  ├─ 🥾 Bush Walking             │
│  ├─ 🏃 Running/Jogging          │
│  └─ ✈️ Flying                   │
│                                 │
│ [Quick Start Last Mode]         │
│ [Create Custom Mode]            │
└─────────────────────────────────┘
```

### Active Mode Dashboard
```
┌─────────────────────────────────┐
│ 🎿 SKIING MODE ACTIVE           │
│ ────────────────────────────────│
│ Duration: 2h 34m                │
│ Altitude: 2,847m                │
│ Max Speed: 68 km/h              │
│ Falls Detected: 0               │
│                                 │
│ 📊 CONDITIONS                   │
│ ├─ Temp: -8°C (Feels -15°C)    │
│ ├─ Visibility: Good (>500m)    │
│ ├─ Avalanche Risk: 2/5 (Low)   │
│ └─ Lifts Open: 12/15            │
│                                 │
│ 📍 LOCATION                     │
│ └─ Last breadcrumb: 2 min ago   │
│                                 │
│ 👥 GROUP (3)                    │
│ ├─ John: 156m away ↗️           │
│ ├─ Sarah: 89m away ↙️           │
│ └─ Mike: 412m away ⬇️           │
│                                 │
│ [End Session] [⚙️ Settings]     │
└─────────────────────────────────┘
```

---

## 🎨 UI/UX Design

### Mode Activation Flow
1. **Selection Screen**: Grid of activity modes with icons
2. **Quick Config**: Pre-configured settings with one-tap start
3. **Custom Adjustments**: Optional fine-tuning (thresholds, contacts)
4. **Safety Brief**: Quick hazard overview and emergency procedures
5. **Start Confirmation**: "Start [Activity] Mode" button
6. **Active Mode UI**: Specialized dashboard with relevant metrics

### Visual Indicators
- **Status Bar Color**: Changes based on active mode
  - 🔵 Blue = Remote Area
  - 🟠 Orange = Height/High Risk
  - 🟢 Green = Travel
  - 🔴 Red = Extreme Activities
- **Mode Badge**: Persistent icon showing active mode
- **Quick Toggle**: Swipe gesture to end/switch modes
- **Widget**: Home screen widget for instant mode activation

### Notifications
- **Mode Start**: "🎿 Skiing Mode Active - Stay safe!"
- **Hazard Alert**: "⚠️ High wind warning - 45 km/h gusts"
- **Check-in Reminder**: "👋 30 min check-in due in 5 minutes"
- **Auto-trigger**: "⏰ You've been stationary for 25 min - Are you OK?"
- **Mode End**: "✅ Skiing session complete - 3h 12m, 0 incidents"

---

## 🚀 Implementation Phases

### Phase 1: Foundation (Weeks 1-3)
- [ ] Create RedPingMode data model
- [ ] Implement mode selection UI
- [ ] Build mode persistence (save active mode)
- [ ] Integrate with existing sensor service
- [ ] Add basic location config per mode
- [ ] Implement 3 core work modes (Remote, Height, High Risk)

### Phase 2: Travel & Social Modes (Weeks 4-6)
- [ ] Implement Travel Mode
- [ ] Implement Family Mode (family circle, child safety, elderly monitoring)
- [ ] Implement Group Mode (dynamic groups, live map, coordination)
- [ ] Build auto-trigger rule engine
- [ ] Create mode-specific dashboards
- [ ] Add hazard configuration per mode
- [ ] Implement check-in system

### Phase 3: Core Extreme Activities (Weeks 7-9)
- [ ] Add 4 extreme modes (Skiing, Diving, Climbing, Running)
- [ ] Implement group coordination features (for extreme modes)
- [ ] Build activity tracking and stats
- [ ] Add performance analytics
- [ ] Create mode-specific widgets
- [ ] Implement mode suggestions (AI)

### Phase 4: Extended Extreme Activities (Weeks 10-12)
- [ ] Add remaining 7 extreme modes (Skydiving, Boating, Swimming, Biking, 4WD, Hiking, Flying)
- [ ] Implement activity-specific features (parachute detection, man overboard, etc.)
- [ ] Build advanced tracking (altitude, depth, speed variations)
- [ ] Add sport-specific hazard monitoring
- [ ] Implement performance leaderboards
- [ ] Create activity sharing features

### Phase 5: Advanced Features (Weeks 13-15)
- [ ] Bluetooth sensor integration (gas, heart rate, dive computer)
- [ ] Satellite messaging integration (Garmin inReach)
- [ ] Video evidence recording
- [ ] Custom mode creation
- [ ] Mode sharing (export/import configs)
- [ ] Wearable device integration
- [ ] Family dashboard (web portal for parents)
- [ ] Group analytics and reports

### Phase 6: Polish & Launch (Weeks 16-17)
- [ ] User testing and feedback
- [ ] Performance optimization
- [ ] Battery life testing (all modes)
- [ ] Privacy and data protection audit
- [ ] Documentation and tutorials
- [ ] App store submission
- [ ] Marketing materials
- [ ] Launch Family Mode beta program
- [ ] Launch Group Mode for sports teams/clubs

---

## 🛡️ Safety & Compliance

### Legal Disclaimers
- **Not a Substitute**: RedPing Mode is a supplementary safety tool, not a replacement for proper safety equipment, training, or professional rescue services
- **Battery Dependency**: Features require device battery; users must carry backup power
- **Coverage Limitations**: Cellular/GPS coverage required for full functionality
- **User Responsibility**: Users must verify settings and ensure appropriate emergency contacts

### Certifications (Future)
- **ISO 22301**: Business continuity management
- **ISO 45001**: Occupational health and safety
- **CE Marking**: European safety compliance
- **FCC/IC**: Radio communication compliance
- **Medical Device**: Consideration for heart rate/health monitoring features

### Data Privacy
- **Location Data**: Encrypted and stored locally unless shared with emergency contacts
- **Activity Logs**: User-owned data, exportable and deletable
- **Emergency Sharing**: Explicit consent required for location sharing
- **Third-party Integration**: Optional, opt-in only

### Emergency Services
- **Official Integration**: Partner with local emergency services (ambulance, police, fire, SAR)
- **False Alarm Prevention**: Multi-stage verification to reduce unnecessary dispatches
- **Accountability**: Activity logs preserved for incident investigation

---

## 📊 Success Metrics

### User Engagement
- Mode activation frequency (target: 3x/week for active users)
- Average session duration per mode
- Feature utilization rate
- User retention after mode adoption

### Safety Effectiveness
- True emergency detection rate (>95% accuracy)
- False positive rate (<2% per month)
- Response time improvement (vs manual SOS)
- Lives saved / emergencies resolved

### Technical Performance
- Battery life in active mode (target: 8+ hours)
- GPS accuracy (target: <50m 95% of time)
- Sensor calibration accuracy
- App crash rate (<0.1%)

---

## 🔮 Future Enhancements

### AI & Machine Learning
- **Auto Mode Detection**: Learn user patterns and auto-activate modes
- **Risk Prediction**: Predict high-risk scenarios before they occur
- **Anomaly Detection**: Identify unusual behavior patterns
- **Performance Coaching**: AI-driven activity improvement suggestions

### Social Features
- **Activity Sharing**: Share routes and experiences with community
- **Safety Ratings**: User-sourced trail/activity safety ratings
- **Group Challenges**: Competitive events with safety monitoring
- **Emergency Network**: Community-based rescue assistance

### Hardware Integration
- **Smart Helmets**: Impact detection via helmet sensors
- **Smart Watches**: Comprehensive health monitoring
- **Avalanche Beacons**: Direct integration with rescue beacons
- **Drone Coordination**: Autonomous drone emergency response

### Enterprise Features
- **Fleet Management**: Corporate safety monitoring for field workers
- **Compliance Reporting**: OSHA/WorkSafe reporting automation
- **Incident Analytics**: Workplace safety trend analysis
- **Training Integration**: Safety certification tracking

---

## 📝 Conclusion

**RedPing Mode** transforms the app from a reactive emergency tool into a **proactive, intelligent safety companion** that adapts to users' activities and environments. By providing context-aware monitoring, hazard alerts, and emergency response protocols, RedPing Mode empowers users to pursue their work and passions with confidence, knowing they have a comprehensive safety net.

The phased implementation approach ensures core safety features are delivered first, with advanced capabilities added iteratively based on user feedback and demand.

---

**Next Steps:**
1. Review and approve feature plan
2. Prioritize modes for Phase 1 development
3. Begin UI/UX design mockups
4. Set up development environment for mode system
5. Create detailed technical specifications for sensor integration

---

*Document prepared by: AI Assistant*  
*Review required by: Product Team, Safety Officer, Development Lead*  
*Target Launch: Q2 2026*
