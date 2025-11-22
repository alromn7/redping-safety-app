# RedPing Adaptive Sound System - Audio Creation Guide

## Overview
RedPing uses a 5-level adaptive sound system that escalates in intensity based on emergency severity and duration. Each level has a unique sonic signature designed to convey the appropriate urgency level.

## Sound Philosophy
**"Progressive Urgency Through Audio"**
- Each level should be instantly recognizable
- Sounds should escalate naturally without jarring transitions
- Audio cues must work in noisy environments
- Vibration patterns complement the audio

## Sound Files Required

### Level 1: Initial Alert (Gentle)
**Filename:** `redping_level1.mp3`  
**Duration:** 2-3 seconds  
**Character:** Gentle, attention-getting  
**Description:** "Something needs your attention"

**Sound Design:**
```
- Base: Soft bell tone (440 Hz - A4)
- Envelope: Gentle fade-in (0.2s), sustain (1.5s), fade-out (0.5s)
- Pattern: Single chime with subtle echo
- Volume: 50% of max
- Vibration: Two gentle taps (200ms each)
```

**Audacity/Audio Editor Steps:**
1. Generate → Tone: Sine wave, 440 Hz, 2 seconds
2. Add subtle reverb (room size: small)
3. Apply fade-in envelope (0.2s)
4. Apply fade-out envelope (0.5s)
5. Normalize to -6dB
6. Export as MP3 (192kbps)

**Sound Character:**
- Friendly notification
- Gentle wake-up
- "Hey, check this out"

---

### Level 2: Follow-up (Moderate)
**Filename:** `redping_level2.mp3`  
**Duration:** 3-4 seconds  
**Character:** More urgent, two-tone pattern  
**Description:** "This is important, please respond"

**Sound Design:**
```
- Base: Two-tone chirp (550 Hz → 660 Hz)
- Envelope: Quick attack (0.1s), sustain (1s each), short decay
- Pattern: Double ping with rising pitch
- Volume: 65% of max
- Vibration: Three taps with 150ms gap
```

**Creation Steps:**
1. Generate first tone: 550 Hz (C#5), 1.2 seconds
2. Generate second tone: 660 Hz (E5), 1.2 seconds
3. Add 0.3s silence between tones
4. Apply slight tremolo effect (4 Hz, 20% depth)
5. Add small room reverb
6. Normalize to -4dB
7. Export as MP3

**Sound Character:**
- Insistent but not alarming
- "Please pay attention now"
- Moderate concern level

---

### Level 3: Escalation (High Urgency)
**Filename:** `redping_level3.mp3`  
**Duration:** 4-5 seconds  
**Character:** Three-tone rising pattern, urgent  
**Description:** "This requires immediate attention"

**Sound Design:**
```
- Base: Three ascending tones (660 Hz → 880 Hz → 1100 Hz)
- Envelope: Sharp attack (0.05s), sustain (0.8s), quick decay
- Pattern: Rising triplet pattern
- Volume: 80% of max
- Vibration: Four persistent pulses
```

**Creation Steps:**
1. Generate tone 1: 660 Hz (E5), 1 second
2. Generate tone 2: 880 Hz (A5), 1 second
3. Generate tone 3: 1100 Hz (C#6), 1.2 seconds
4. Add 0.2s gaps between tones
5. Apply slight distortion (10%) for urgency
6. Add medium hall reverb
7. Increase high frequencies (+3dB at 2kHz)
8. Normalize to -2dB
9. Export as MP3

**Sound Character:**
- Clearly urgent
- Rising tension
- "Act now, this is serious"
- Emergency vehicle inspired

---

### Level 4: Critical (Maximum Urgency)
**Filename:** `redping_level4.mp3`  
**Duration:** 5-6 seconds  
**Character:** Intense siren-like pattern  
**Description:** "Emergency situation - immediate action required"

**Sound Design:**
```
- Base: Siren sweep (400 Hz ↔ 1200 Hz)
- Envelope: No fade, immediate attack
- Pattern: Two complete siren cycles
- Volume: 95% of max
- Vibration: Eight intense pulses
```

**Creation Steps:**
1. Generate chirp tone: 400-1200 Hz sweep, 1.5 seconds
2. Duplicate and reverse to create return sweep
3. Repeat pattern twice (4 cycles total)
4. Add amplitude modulation (8 Hz, 40% depth) for warble
5. Apply compressor (ratio 4:1, threshold -10dB)
6. Boost mids and highs (+5dB at 1-3kHz)
7. Add small room reverb for presence
8. Normalize to -1dB
9. Export as MP3

**Sound Character:**
- Unmistakable emergency
- Demanding immediate attention
- Similar to ambulance/police siren
- Cannot be ignored

---

### Level 5: Auto-Escalation (Continuous Alarm)
**Filename:** `redping_level5.mp3`  
**Duration:** 8-10 seconds (loops continuously)  
**Character:** Maximum intensity alarm  
**Description:** "Critical emergency - continuous monitoring"

**Sound Design:**
```
- Base: Dual-tone alarm (800 Hz + 1000 Hz alternating)
- Envelope: No envelope, steady state
- Pattern: Rapid alternation with overlapping tones
- Volume: 100% of max
- Vibration: Continuous pulsing pattern
- Note: Designed to loop seamlessly
```

**Creation Steps:**
1. Generate tone A: 800 Hz (G5), 0.5 seconds
2. Generate tone B: 1000 Hz (C6), 0.5 seconds
3. Alternate 10 times (5 seconds per tone = 10s total)
4. Add 50ms crossfade at loop point
5. Apply heavy amplitude modulation (12 Hz, 60% depth)
6. Boost all frequencies above 800 Hz (+6dB)
7. Add short decay reverb (0.3s)
8. Hard limiter at -0.3dB
9. Ensure seamless loop (crossfade end to beginning)
10. Export as MP3 with loop metadata

**Sound Character:**
- Maximum alert level
- Fire alarm intensity
- Cannot be ignored
- Designed for life-threatening situations

---

## File Placement
All sound files must be placed in:
```
assets/sounds/
├── redping_level1.mp3
├── redping_level2.mp3
├── redping_level3.mp3
├── redping_level4.mp3
└── redping_level5.mp3
```

## Android Raw Resources (For System Notifications)
For Android notification sounds (not managed by audioplayers), copy to:
```
android/app/src/main/res/raw/
├── redping_level1.mp3
├── redping_level2.mp3
├── redping_level3.mp3
├── redping_level4.mp3
└── redping_level5.mp3
```

**Note:** Android raw filenames must be lowercase with no special characters.

## iOS Sound Files
For iOS notifications, ensure files are also added to:
```
ios/Runner/Sounds/
├── redping_level1.aiff (converted from MP3)
├── redping_level2.aiff
├── redping_level3.aiff
├── redping_level4.aiff
└── redping_level5.aiff
```

**iOS Conversion Command:**
```bash
ffmpeg -i redping_level1.mp3 -acodec pcm_s16le redping_level1.aiff
```

## Audio Specifications

### Technical Requirements
- **Format:** MP3 (192kbps CBR)
- **Sample Rate:** 44100 Hz
- **Channels:** Mono (saves space, adequate for alerts)
- **Bit Depth:** 16-bit
- **Normalization:** Levels 1-5 normalized to -6dB, -4dB, -2dB, -1dB, -0.3dB respectively
- **File Size Target:** <100KB per file

### Quality Checklist
- [ ] No clipping or distortion
- [ ] Clear at low volumes
- [ ] Effective at high volumes
- [ ] Works with phone speakers
- [ ] Works with earphones
- [ ] Distinct from system sounds
- [ ] Professional quality
- [ ] Seamless loop (Level 5 only)

## Testing Procedure

### 1. Volume Test
Test each level at:
- Minimum phone volume
- 25% volume
- 50% volume
- 75% volume
- Maximum volume

**Expected:** All levels should be audible and distinguishable at all volumes.

### 2. Environment Test
Test in:
- Quiet room
- Office environment
- Outdoor street noise
- Car interior
- Busy restaurant

**Expected:** Higher levels must cut through ambient noise.

### 3. Distance Test
Play sound and test recognition at:
- 1 meter (arms length)
- 3 meters (across room)
- 5 meters (next room with door open)
- 10 meters (down hallway)

**Expected:** Level 4-5 must be heard from next room.

### 4. Recognition Test
- Users should identify urgency level by sound alone
- No two levels should sound too similar
- Escalation should feel natural, not jarring

### 5. Vibration Sync Test
- Vibration patterns should match audio rhythm
- Combined audio + vibration should feel cohesive
- Vibration alone should convey urgency (for deaf users)

## Sound Design Tools

### Free Tools
1. **Audacity** (Recommended)
   - Free, open-source
   - All features needed for this project
   - Cross-platform
   - Download: https://www.audacityteam.org/

2. **Sonic Visualizer**
   - Excellent for waveform analysis
   - Verify no clipping

3. **FFmpeg**
   - Command-line audio conversion
   - iOS AIFF conversion

### Paid Tools (Optional)
1. **Adobe Audition** - Professional audio editing
2. **Logic Pro** - Mac users, excellent synth tools
3. **FL Studio** - Great for creating tones and patterns

## Alternative: Use Synthesized Tones

If creating custom audio files is not possible, use synthesized tones:

```dart
// Example using flutter_beep or similar
class SynthesizedSounds {
  static Future<void> playLevel1() async {
    await Beep.beep(frequency: 440, duration: Duration(seconds: 2));
  }
  
  static Future<void> playLevel2() async {
    await Beep.beep(frequency: 550, duration: Duration(seconds: 1));
    await Future.delayed(Duration(milliseconds: 300));
    await Beep.beep(frequency: 660, duration: Duration(seconds: 1));
  }
  
  // ... and so on
}
```

**Pros:** No audio files needed, programmatically generated  
**Cons:** Less sophisticated, harder to fine-tune, may sound robotic

## Brand Identity

### RedPing Sonic Signature
The Level 1 sound (440 Hz soft chime) becomes RedPing's "audio logo":
- Used in non-emergency notifications
- Opening/closing sound for app
- Subtle background in tutorials
- Consistent brand recognition

### Audio Accessibility
- **For Deaf Users:** Vibration patterns alone must convey urgency
- **For Blind Users:** Sounds must be instantly recognizable
- **For Elderly:** Lower frequency components for better hearing
- **For Children:** Not too scary at Level 1-2, appropriately alarming at 4-5

## Implementation Checklist

- [ ] Create 5 audio files (MP3)
- [ ] Test each file for quality
- [ ] Place in `assets/sounds/`
- [ ] Update `pubspec.yaml` (already configured)
- [ ] Copy to Android `raw/` folder
- [ ] Convert to AIFF for iOS
- [ ] Copy to iOS `Sounds/` folder
- [ ] Test Level 1 with AdaptiveSoundService
- [ ] Test Level 2-5 progression
- [ ] Test vibration patterns
- [ ] Verify loops work for Level 5
- [ ] Test on multiple devices
- [ ] Get user feedback
- [ ] Refine if needed

## Sound Examples (Reference)

### Similar Sound Patterns (for inspiration)
- **Level 1:** iPhone "Note" notification
- **Level 2:** WhatsApp incoming message (double chirp)
- **Level 3:** Samsung "Ascending" ringtone
- **Level 4:** Car alarm chirp pattern
- **Level 5:** Fire alarm continuous tone

### What to Avoid
- ❌ Generic beep sounds (too common)
- ❌ Pleasant melodies (wrong context)
- ❌ Jarring harsh noise (causes panic)
- ❌ Too long duration (battery concern)
- ❌ Copyright music clips (legal issues)
- ❌ Complex musical patterns (confusing)

## Future Enhancements

### Dynamic Sound Adaptation
- Adjust volume based on ambient noise detection
- Change tone frequency based on user age
- Personalized sound preferences
- Machine learning to optimize recognition

### Voice Integration
"RedPing Emergency Alert. Level 3. Check your phone immediately."

### Spatial Audio (iOS)
Use directional sound to guide user to phone location.

### Haptic Audio
On devices with advanced haptics (iPhone), sync precise haptic feedback with audio waveform.

## Legal Considerations

### Copyright
- All sounds must be original or licensed
- Do not use copyrighted emergency siren sounds
- Public domain sounds are acceptable
- Attribution required for CC-licensed sounds

### Emergency Sound Regulations
- Check local laws about emergency alert sounds
- Some countries restrict use of police/ambulance sirens
- RedPing sounds should be "emergency alert" not "emergency vehicle"

## Support & Resources

### Need Help?
- Sound design tutorials: YouTube "Audacity emergency alert tutorial"
- Frequency guide: https://pages.mtu.edu/~suits/notefreqs.html
- Vibration patterns: Android Vibration API documentation

### Community Sounds
Consider open-sourcing RedPing sound pack for community use.

---

**Document Version:** 1.0  
**Last Updated:** November 12, 2025  
**Author:** RedPing Development Team
