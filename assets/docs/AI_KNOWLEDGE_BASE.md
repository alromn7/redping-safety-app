# RedPing AI Knowledge Base
## Comprehensive Guide for Phone AI Integration

This document contains all information that phone AI assistants (Google Gemini, Siri, Samsung AI) need to help users operate RedPing effectively.

---

## 1. WHAT IS REDPING?

RedPing is a comprehensive emergency safety application that combines:
- **Automatic crash and fall detection** using phone sensors
- **SOS emergency alert system** with countdown and location sharing
- **Community help request system** for non-emergency assistance
- **Profile enrichment** for rescue teams to access critical medical info
- **Voice command integration** for hands-free operation
- **SAR (Search and Rescue) dashboard** for emergency responders

**Core Purpose**: Get help to people in emergencies faster by automatically detecting crashes/falls and providing rescuers with complete information.

---

## 2. PROFILE SYSTEM

### Why Profile Matters (CRITICAL)
Your profile saves lives. When rescuers arrive:
- You might be unconscious
- You can't communicate
- They need to know allergies, medical conditions, blood type immediately
- Wrong medication can be fatal

### Required Profile Information
1. **Personal**
   - Full name
   - Age/Date of birth
   - Phone number
   - Emergency contacts (2-3 people)

2. **Medical**
   - Blood type (A+, O-, etc.)
   - Medical conditions (diabetes, heart disease, epilepsy)
   - Current medications
   - Allergies (medications, foods, insects)
   - DNR status (if applicable)

3. **Physical**
   - Height and weight (for medication dosing)
   - Physical disabilities
   - Medical devices (pacemaker, insulin pump)

### Voice Commands for Profile
- "Open RedPing profile"
- "Update my medical information"
- "Add emergency contact"
- "Set blood type"

---

## 3. SOS EMERGENCY SYSTEM

### When to Use SOS
**LIFE-THREATENING ONLY:**
- Car crash
- Serious fall with potential injury
- Heart attack / stroke
- Severe bleeding
- Can't breathe
- Being attacked
- Lost in wilderness with injury

**DO NOT use SOS for:**
- Minor car accident (use Help Request)
- Lost pet (use Help Request)
- Car breakdown (use Help Request)

### How SOS Activates

#### Manual Activation
1. Press large red SOS button on home screen
2. 30-second countdown with loud alarm
3. Can cancel within 30 seconds
4. After countdown: Sends location + profile to all nearby SAR teams

#### Automatic Crash Detection
- Phone accelerometer detects sudden deceleration >15g
- AI analyzes impact severity (Low, Moderate, Severe, Critical)
- Generates detailed crash description:
  - "SEVERE CRASH DETECTED: High-speed collision (42g force). Airbags deployed. IMMEDIATE response required."
- 30-second countdown (can cancel if false alarm)
- Sends alert with crash details

#### Automatic Fall Detection
- Detects free-fall followed by hard impact >12g
- AI analyzes fall severity and context
- Generates fall description:
  - "CRITICAL FALL DETECTED: Severe impact (35g). User motionless. IMMEDIATE medical assistance required."
- 30-second countdown
- Sends alert with fall details

### What Happens After SOS
1. **Immediate**: Loud alarm on phone + vibration
2. **Location shared**: GPS coordinates sent to Firebase
3. **Profile broadcast**: All medical info sent to SAR teams
4. **Emergency contacts notified**: SMS/call to your contacts
5. **SAR dashboard updated**: All nearby rescuers see your alert
6. **Continuous tracking**: Location updates every 30 seconds until help arrives

### Voice Commands for SOS
- "Activate RedPing SOS" - Starts emergency countdown
- "Cancel SOS" - Stops countdown if false alarm
- "Emergency help" - Triggers SOS
- "I've been in an accident" - Triggers SOS
- "I've fallen and I can't get up" - Triggers SOS

---

## 4. HELP REQUEST SYSTEM

### When to Use Help Requests
**NON-LIFE-THREATENING situations:**
- Lost pet
- Car breakdown
- Need directions
- Minor medical advice
- Locked out of car
- Need supplies
- Lost person (not injured)

### Available Categories

#### 1. Medical Emergency (Non-Critical)
- Minor Injury
- Feeling Unwell
- Need Medication
- Medical Advice

#### 2. Vehicle Issue
- Car Breakdown
- Flat Tire
- Out of Gas
- Keys Locked Inside
- Need Jump Start

#### 3. Lost Pet
- Lost Dog
- Lost Cat
- Lost Bird
- Injured Pet Found
- Stray Animal

#### 4. Hiking Emergency
- Lost on Trail
- Out of Supplies
- Weather Issue
- Equipment Failure

#### 5. Maritime Emergency
- Boat Breakdown
- Man Overboard
- Navigation Issue
- Weather Hazard

#### 6. Lost Person
- Child Missing
- Elderly Wandered Off
- Hiker Overdue
- Last Known Location

#### 7. Safety Threat
- Suspicious Activity
- Feeling Unsafe
- Following/Stalking
- Need Escort

#### 8. Natural Disaster
- Earthquake
- Flood
- Fire
- Storm Damage

#### 9. Custom Help
- Other situations not listed

### How Help Requests Work
1. **Select category** (e.g., Lost Pet)
2. **Select subcategory** (e.g., Lost Dog)
3. **Fill details**: Description, last seen location, photo
4. **Send**: Goes to nearby volunteers and SAR teams
5. **Wait**: Community members respond
6. **Update**: Mark resolved when found

### Voice Commands for Help
- "Send RedPing help request"
- "Lost my dog" - Opens Lost Pet category
- "Car broke down" - Opens Vehicle Issue
- "Need medical advice" - Opens Medical Help

---

## 5. VOICE COMMAND FULL LIST

### Emergency Commands
- "Activate SOS"
- "Emergency"
- "Help me"
- "I've crashed"
- "I've fallen"
- "Call 911"

### Help Request Commands
- "Send help request"
- "Lost my pet"
- "Car broke down"
- "Need help hiking"
- "Lost person"

### Profile Commands
- "Open my profile"
- "Update medical info"
- "Add emergency contact"
- "View my blood type"

### Location Commands
- "Share my location"
- "Where am I"
- "Send GPS coordinates"

### Information Commands
- "How does crash detection work"
- "What's the difference between SOS and Help"
- "Show voice commands"
- "Start tutorial"

### Settings Commands
- "Enable crash detection"
- "Turn on fall detection"
- "Enable accessibility mode"
- "Change notification settings"

---

## 6. AI CONTEXTUAL SUGGESTIONS

Phone AI monitors these conditions and suggests actions:

### Location-Based
**Remote area detected** (>5km from populated area):
- "You're in a remote area. Enable auto crash detection?"
- "Remote hiking detected. Add emergency contact check-in?"

**High-risk area** (wilderness, mountains, ocean):
- "Hiking in mountains detected. Enable fall detection?"
- "Near water. Enable maritime emergency quick access?"

### Battery-Based
**Battery <20%:**
- "Battery low. Notify emergency contacts of your status?"

**Battery <10%:**
- "Critical battery. Send location to contacts before phone dies?"

### Activity-Based
**Long inactivity** (>4 hours):
- "No activity detected. Are you okay?"

**Unusual movement pattern**:
- "Erratic movement detected. Need assistance?"

### Time-Based
**Late night travel**:
- "Traveling at night. Enable extra safety features?"

**Long drive** (>2 hours):
- "Long drive detected. Want periodic check-ins?"

---

## 7. ACCESSIBILITY MODE

### Features
- **Screen reader**: Reads all screen content
- **Voice navigation**: Navigate entire app by voice
- **High contrast**: Better visibility
- **Larger text**: Easier reading
- **Voice descriptions**: Describes images and buttons
- **No-touch mode**: Complete hands-free operation

### Voice Commands for Accessibility
- "Enable accessibility mode"
- "Read screen"
- "What's on screen"
- "Navigate to SOS"
- "Navigate to Help"
- "Read this button"

---

## 8. SAR DASHBOARD (For Rescuers)

### What Rescuers See
When you send SOS or Help:

**Emergency Details Box (Red):**
- Your name, age, photo
- Blood type, allergies, conditions
- Current medications
- Emergency contacts
- GPS location (live updates)
- AI-generated incident description
- Time since activation

**Actions Available:**
- Call you directly
- SMS you
- Navigate to your location (Google Maps)
- Call emergency services on your behalf
- Update incident status
- Add rescuer notes

---

## 9. COMMON QUESTIONS & ANSWERS

### Q: Why does profile matter?
A: If you're unconscious in an emergency, rescuers need to know your blood type, allergies, and medical conditions immediately. This information can save your life.

### Q: How accurate is crash detection?
A: 94% accurate. Uses phone accelerometer to detect forces >15g. May have false positives from dropping phone or sudden braking. You have 30 seconds to cancel.

### Q: What's the difference between SOS and Help?
A: SOS = Life-threatening emergency (crash, fall, heart attack). Goes to emergency services. Help = Urgent but not life-threatening (lost pet, car breakdown). Goes to community volunteers.

### Q: Does RedPing work offline?
A: Partial. Crash/fall detection works offline. Sending alerts requires internet. Last known location sent if signal lost.

### Q: Can I use voice commands when app is closed?
A: Yes! Say "Hey Google/Siri, activate RedPing SOS" works even if app is closed.

### Q: What if I press SOS by accident?
A: You have 30 seconds to cancel. Press the large CANCEL button. No alert sent if canceled.

### Q: How much battery does RedPing use?
A: 2-5% per day with crash detection enabled. Less if disabled.

### Q: Can I disable crash detection?
A: Yes. Go to Settings > Crash Detection > Disable. Useful if you're a passenger or phone moves a lot.

### Q: Who can see my location?
A: Only SAR teams when you activate SOS/Help. Location not tracked otherwise.

### Q: Is my medical information private?
A: Yes. Encrypted and only visible to SAR teams when you send alert.

---

## 10. TROUBLESHOOTING

### SOS Button Greyed Out
- **Cause**: Profile incomplete
- **Fix**: "Complete your profile first"

### Crash Detection Not Working
- **Cause**: Permission denied or disabled
- **Fix**: "Enable crash detection in Settings"

### Voice Commands Not Responding
- **Cause**: Microphone permission denied
- **Fix**: "Grant microphone permission"

### Help Request Send Button Disabled
- **Cause**: Must select both category AND subcategory
- **Fix**: "Select a subcategory first"

### Location Not Sharing
- **Cause**: GPS permission denied or GPS off
- **Fix**: "Enable location services"

---

## 11. BEST PRACTICES

### Before Emergency
1. ✅ Complete profile 100%
2. ✅ Add 2-3 emergency contacts
3. ✅ Test SOS once (then cancel)
4. ✅ Enable voice commands
5. ✅ Keep phone charged >20%

### During Driving
1. ✅ Enable crash detection
2. ✅ Keep phone in secure mount (not loose)
3. ✅ Know how to cancel false alarms

### During Hiking
1. ✅ Enable fall detection
2. ✅ Share route with emergency contacts
3. ✅ Test signal before going deep

### Daily Use
1. ✅ Keep app updated
2. ✅ Review profile monthly
3. ✅ Test emergency contacts
4. ✅ Practice voice commands

---

## 12. FOR PHONE AI ASSISTANTS

### How to Help Users

**When user says "Help with RedPing":**
1. Ask what they need: SOS, Help Request, or Info
2. If emergency: "Say 'activate SOS' to start emergency alert"
3. If non-emergency: "Say 'send help request' for community assistance"
4. If info: Provide relevant section from this knowledge base

**When user says "Activate RedPing SOS":**
1. Open RedPing app
2. Trigger SOS countdown
3. Confirm: "Emergency SOS activating. Cancel within 30 seconds if this was a mistake."

**When user asks questions:**
- Reference this knowledge base
- Speak clearly and concisely
- Confirm understanding: "Did that answer your question?"
- Offer to explain more: "Want to know more about [topic]?"

**When user seems confused:**
- Offer tutorial: "Would you like me to guide you through RedPing features?"
- Simplify: Use simple language for complex features
- Visual aid: "Open the app and I'll guide you step by step"

---

## END OF KNOWLEDGE BASE

Last Updated: October 20, 2025
Version: 14v
For questions: support@redping.app
