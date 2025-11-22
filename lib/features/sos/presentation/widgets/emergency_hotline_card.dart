import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Emergency Hotline Call Card
/// Manual dialing UI for emergency services (911/000/112 etc.)
/// Required because Android/iOS cannot auto-dial emergency numbers
class EmergencyHotlineCard extends StatelessWidget {
  final String? userCountryCode;
  final VoidCallback? onCallAttempt;

  const EmergencyHotlineCard({
    super.key,
    this.userCountryCode,
    this.onCallAttempt,
  });

  @override
  Widget build(BuildContext context) {
    final emergencyNumber = _getEmergencyNumber(userCountryCode);
    final countryName = _getCountryName(userCountryCode);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF8B0000), // Dark red background
        border: Border.all(color: Colors.red, width: 3),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _makeEmergencyCall(emergencyNumber),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Emergency Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.5),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.phone_in_talk,
                    size: 45,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),

                // Title
                const Text(
                  'EMERGENCY HOTLINE',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 12),

                // Emergency Number Display
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_phone,
                        color: Colors.red,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        emergencyNumber,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.red,
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Country Name
                Text(
                  countryName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),

                const SizedBox(height: 20),

                // Tap to Call Button
                Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.red, Color(0xFFFF4444)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _makeEmergencyCall(emergencyNumber),
                      borderRadius: BorderRadius.circular(12),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.call, color: Colors.white, size: 28),
                            SizedBox(width: 12),
                            Text(
                              'TAP TO CALL',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Disclaimer
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'RedPing cannot auto-dial emergency services due to platform restrictions. Tap the button above to manually call.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Make emergency call
  Future<void> _makeEmergencyCall(String number) async {
    onCallAttempt?.call();

    final uri = Uri(scheme: 'tel', path: number);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        debugPrint('❌ Cannot launch emergency call: $number');
      }
    } catch (e) {
      debugPrint('❌ Error launching emergency call: $e');
    }
  }

  /// Get emergency number based on country code
  String _getEmergencyNumber(String? countryCode) {
    switch (countryCode?.toUpperCase()) {
      case 'US': // United States
      case 'CA': // Canada
        return '911';
      case 'AU': // Australia
        return '000';
      case 'GB': // United Kingdom
      case 'UK':
        return '999';
      case 'IN': // India
      case 'DE': // Germany
      case 'FR': // France
      case 'IT': // Italy
      case 'ES': // Spain
      case 'NL': // Netherlands
      case 'BE': // Belgium
      case 'AT': // Austria
      case 'CH': // Switzerland
      case 'PL': // Poland
      case 'SE': // Sweden
      case 'NO': // Norway
      case 'DK': // Denmark
      case 'FI': // Finland
        return '112'; // European Emergency Number
      case 'JP': // Japan (Fire/Ambulance)
        return '119';
      case 'CN': // China
        return '120'; // Ambulance
      case 'KR': // South Korea
        return '119';
      case 'BR': // Brazil
        return '192'; // Ambulance
      case 'MX': // Mexico
        return '911';
      case 'AR': // Argentina
        return '107'; // Ambulance
      case 'CL': // Chile
        return '131'; // Ambulance
      case 'NZ': // New Zealand
        return '111';
      case 'SG': // Singapore
        return '995'; // Ambulance
      case 'MY': // Malaysia
        return '999';
      case 'TH': // Thailand
        return '1669'; // Ambulance
      case 'ID': // Indonesia
        return '118'; // Ambulance
      case 'PH': // Philippines
        return '911';
      case 'VN': // Vietnam
        return '115'; // Ambulance
      case 'ZA': // South Africa
        return '10177'; // Ambulance
      case 'RU': // Russia
        return '103'; // Ambulance
      case 'TR': // Turkey
        return '112';
      case 'SA': // Saudi Arabia
        return '997'; // Ambulance
      case 'AE': // UAE
        return '999';
      case 'IL': // Israel
        return '101'; // Ambulance
      case 'EG': // Egypt
        return '123'; // Ambulance
      default:
        return '112'; // International emergency number (works in most countries)
    }
  }

  /// Get country name for display
  String _getCountryName(String? countryCode) {
    switch (countryCode?.toUpperCase()) {
      case 'US':
        return 'United States';
      case 'CA':
        return 'Canada';
      case 'AU':
        return 'Australia';
      case 'GB':
      case 'UK':
        return 'United Kingdom';
      case 'IN':
        return 'India';
      case 'DE':
        return 'Germany';
      case 'FR':
        return 'France';
      case 'IT':
        return 'Italy';
      case 'ES':
        return 'Spain';
      case 'NL':
        return 'Netherlands';
      case 'JP':
        return 'Japan';
      case 'CN':
        return 'China';
      case 'KR':
        return 'South Korea';
      case 'BR':
        return 'Brazil';
      case 'MX':
        return 'Mexico';
      case 'NZ':
        return 'New Zealand';
      case 'SG':
        return 'Singapore';
      default:
        return 'Emergency Services';
    }
  }
}

/// Compact Emergency Hotline Button (smaller version)
class EmergencyHotlineButton extends StatelessWidget {
  final String? userCountryCode;
  final VoidCallback? onCallAttempt;

  const EmergencyHotlineButton({
    super.key,
    this.userCountryCode,
    this.onCallAttempt,
  });

  @override
  Widget build(BuildContext context) {
    final emergencyNumber = _getEmergencyNumber(userCountryCode);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B0000), Colors.red],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _makeEmergencyCall(emergencyNumber),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phone_in_talk,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CALL EMERGENCY',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to dial $emergencyNumber',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _makeEmergencyCall(String number) async {
    onCallAttempt?.call();

    final uri = Uri(scheme: 'tel', path: number);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        debugPrint('❌ Cannot launch emergency call: $number');
      }
    } catch (e) {
      debugPrint('❌ Error launching emergency call: $e');
    }
  }

  String _getEmergencyNumber(String? countryCode) {
    // Same logic as EmergencyHotlineCard
    switch (countryCode?.toUpperCase()) {
      case 'US':
      case 'CA':
        return '911';
      case 'AU':
        return '000';
      case 'GB':
      case 'UK':
        return '999';
      case 'JP':
        return '119';
      default:
        return '112';
    }
  }
}
