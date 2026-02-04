import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sos_session.dart';
import '../core/logging/app_logger.dart';

/// Emergency contact information
class EmergencyContact {
  final String type; // 'national' or 'local'
  final String name;
  final String phoneNumber;
  final String? address;
  final double? distance; // Distance from user in km (for local services)
  final DateTime lastUpdated;
  final String? sourceUrl;

  const EmergencyContact({
    required this.type,
    required this.name,
    required this.phoneNumber,
    this.address,
    this.distance,
    required this.lastUpdated,
    this.sourceUrl,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'name': name,
    'phoneNumber': phoneNumber,
    'address': address,
    'distance': distance,
    'lastUpdated': lastUpdated.toIso8601String(),
    'sourceUrl': sourceUrl,
  };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(
        type: json['type'],
        name: json['name'],
        phoneNumber: json['phoneNumber'],
        address: json['address'],
        distance: json['distance']?.toDouble(),
        lastUpdated: DateTime.parse(json['lastUpdated']),
        sourceUrl: json['sourceUrl'],
      );

  @override
  String toString() =>
      '$name ($phoneNumber) - ${distance != null ? "${distance!.toStringAsFixed(1)}km away" : type}';
}

/// Emergency contact auto-update service
/// Automatically finds and updates emergency contact numbers based on user location
class EmergencyContactAutoUpdateService {
  static final EmergencyContactAutoUpdateService _instance =
      EmergencyContactAutoUpdateService._internal();
  factory EmergencyContactAutoUpdateService() => _instance;
  EmergencyContactAutoUpdateService._internal();

  // Cache
  EmergencyContact? _nationalEmergencyContact;
  EmergencyContact? _localEmergencyContact;
  DateTime? _lastUpdateTime;
  String? _lastKnownCountry;
  String? _lastKnownCity;

  // Configuration
  static const Duration _cacheExpiration = Duration(
    days: 7,
  ); // Cache valid for 7 days
  static const double _localSearchRadius = 50.0; // Search within 50km

  bool _isInitialized = false;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadCachedContacts();
      _isInitialized = true;
      AppLogger.i(
        'Emergency Contact Auto-Update Service initialized',
        tag: 'EmergencyContactService',
      );
    } catch (e) {
      AppLogger.e(
        'Failed to initialize Emergency Contact Service',
        tag: 'EmergencyContactService',
        error: e,
      );
    }
  }

  /// Auto-update emergency contacts based on current location
  Future<Map<String, EmergencyContact?>> autoUpdateEmergencyContacts(
    LocationInfo location,
  ) async {
    try {
      AppLogger.i(
        '🔍 Auto-updating emergency contacts for location (${location.latitude}, ${location.longitude})',
        tag: 'EmergencyContactService',
      );

      // Step 1: Get location details (country, city)
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isEmpty) {
        AppLogger.w(
          'Could not determine location details from coordinates',
          tag: 'EmergencyContactService',
        );
        return {
          'national': _nationalEmergencyContact,
          'local': _localEmergencyContact,
        };
      }

      final place = placemarks.first;
      final country = place.isoCountryCode ?? place.country ?? 'UNKNOWN';
      final city = place.locality ?? place.subAdministrativeArea ?? 'UNKNOWN';
      final state = place.administrativeArea ?? '';

      AppLogger.i(
        '📍 Location: $city, $state, $country',
        tag: 'EmergencyContactService',
      );

      // Step 2: Check if we need to update (location changed or cache expired)
      final needsUpdate = _needsUpdate(country, city);

      if (!needsUpdate) {
        AppLogger.i(
          '✅ Using cached emergency contacts (still valid)',
          tag: 'EmergencyContactService',
        );
        return {
          'national': _nationalEmergencyContact,
          'local': _localEmergencyContact,
        };
      }

      // Step 3: Search for national emergency hotline
      _nationalEmergencyContact = await _searchNationalEmergencyHotline(
        country,
        location,
      );

      // Step 4: Search for local emergency services
      _localEmergencyContact = await _searchLocalEmergencyServices(
        location,
        city,
        state,
        country,
      );

      // Step 5: Cache the results
      _lastKnownCountry = country;
      _lastKnownCity = city;
      _lastUpdateTime = DateTime.now();
      await _cacheContacts();

      AppLogger.i(
        '✅ Emergency contacts updated successfully',
        tag: 'EmergencyContactService',
      );
      AppLogger.i(
        '  📞 National: ${_nationalEmergencyContact?.phoneNumber ?? "N/A"}',
        tag: 'EmergencyContactService',
      );
      AppLogger.i(
        '  🏥 Local: ${_localEmergencyContact?.phoneNumber ?? "N/A"}',
        tag: 'EmergencyContactService',
      );

      return {
        'national': _nationalEmergencyContact,
        'local': _localEmergencyContact,
      };
    } catch (e) {
      AppLogger.e(
        'Failed to auto-update emergency contacts',
        tag: 'EmergencyContactService',
        error: e,
      );

      // Return cached contacts as fallback
      return {
        'national': _nationalEmergencyContact,
        'local': _localEmergencyContact,
      };
    }
  }

  /// Search for national emergency hotline number
  Future<EmergencyContact> _searchNationalEmergencyHotline(
    String countryCode,
    LocationInfo location,
  ) async {
    try {
      AppLogger.i(
        '🔍 Searching national emergency hotline for $countryCode...',
        tag: 'EmergencyContactService',
      );

      // Known national emergency numbers (primary database)
      final knownNumbers = {
        'US': {'number': '911', 'name': 'US Emergency Services (911)'},
        'CA': {'number': '911', 'name': 'Canada Emergency Services (911)'},
        'MX': {'number': '911', 'name': 'Mexico Emergency Services (911)'},
        'GB': {'number': '999', 'name': 'UK Emergency Services (999)'},
        'IE': {'number': '112', 'name': 'Ireland Emergency Services (112)'},
        'AU': {'number': '000', 'name': 'Australia Emergency Services (000)'},
        'NZ': {'number': '111', 'name': 'New Zealand Emergency Services (111)'},
        'IN': {'number': '112', 'name': 'India Emergency Services (112)'},
        'ZA': {'number': '10111', 'name': 'South Africa Police (10111)'},
        'JP': {'number': '119', 'name': 'Japan Emergency Services (119)'},
        'CN': {'number': '120', 'name': 'China Medical Emergency (120)'},
        'KR': {'number': '119', 'name': 'South Korea Emergency (119)'},
        'BR': {'number': '192', 'name': 'Brazil Medical Emergency (192)'},
        'AR': {'number': '107', 'name': 'Argentina Medical Emergency (107)'},
        'FR': {'number': '112', 'name': 'France Emergency Services (112)'},
        'DE': {'number': '112', 'name': 'Germany Emergency Services (112)'},
        'IT': {'number': '112', 'name': 'Italy Emergency Services (112)'},
        'ES': {'number': '112', 'name': 'Spain Emergency Services (112)'},
        'NL': {'number': '112', 'name': 'Netherlands Emergency Services (112)'},
        'SE': {'number': '112', 'name': 'Sweden Emergency Services (112)'},
        'NO': {'number': '112', 'name': 'Norway Emergency Services (112)'},
        'DK': {'number': '112', 'name': 'Denmark Emergency Services (112)'},
        'FI': {'number': '112', 'name': 'Finland Emergency Services (112)'},
        'PL': {'number': '112', 'name': 'Poland Emergency Services (112)'},
        'RU': {'number': '112', 'name': 'Russia Emergency Services (112)'},
        'TR': {'number': '112', 'name': 'Turkey Emergency Services (112)'},
        'SA': {'number': '997', 'name': 'Saudi Arabia Emergency (997)'},
        'AE': {'number': '999', 'name': 'UAE Emergency Services (999)'},
        'SG': {'number': '995', 'name': 'Singapore Ambulance (995)'},
        'MY': {'number': '999', 'name': 'Malaysia Emergency Services (999)'},
        'TH': {'number': '191', 'name': 'Thailand Emergency Services (191)'},
        'VN': {'number': '115', 'name': 'Vietnam Medical Emergency (115)'},
        'PH': {'number': '911', 'name': 'Philippines Emergency (911)'},
        'ID': {'number': '112', 'name': 'Indonesia Emergency Services (112)'},
        'EG': {'number': '123', 'name': 'Egypt Ambulance (123)'},
        'NG': {'number': '112', 'name': 'Nigeria Emergency Services (112)'},
        'KE': {'number': '999', 'name': 'Kenya Emergency Services (999)'},
        'GH': {'number': '193', 'name': 'Ghana Ambulance (193)'},
        'IL': {'number': '101', 'name': 'Israel Medical Emergency (101)'},
        'GR': {'number': '112', 'name': 'Greece Emergency Services (112)'},
        'PT': {'number': '112', 'name': 'Portugal Emergency Services (112)'},
        'CH': {'number': '144', 'name': 'Switzerland Ambulance (144)'},
        'AT': {'number': '112', 'name': 'Austria Emergency Services (112)'},
        'BE': {'number': '112', 'name': 'Belgium Emergency Services (112)'},
        'CZ': {'number': '112', 'name': 'Czech Republic Emergency (112)'},
        'HU': {'number': '112', 'name': 'Hungary Emergency Services (112)'},
        'RO': {'number': '112', 'name': 'Romania Emergency Services (112)'},
        'BG': {'number': '112', 'name': 'Bulgaria Emergency Services (112)'},
        'HR': {'number': '112', 'name': 'Croatia Emergency Services (112)'},
        'SK': {'number': '112', 'name': 'Slovakia Emergency Services (112)'},
        'SI': {'number': '112', 'name': 'Slovenia Emergency Services (112)'},
        'LT': {'number': '112', 'name': 'Lithuania Emergency Services (112)'},
        'LV': {'number': '112', 'name': 'Latvia Emergency Services (112)'},
        'EE': {'number': '112', 'name': 'Estonia Emergency Services (112)'},
      };

      if (knownNumbers.containsKey(countryCode)) {
        final data = knownNumbers[countryCode]!;
        AppLogger.i(
          '✅ Found national emergency number: ${data["number"]}',
          tag: 'EmergencyContactService',
        );

        return EmergencyContact(
          type: 'national',
          name: data['name']!,
          phoneNumber: data['number']!,
          lastUpdated: DateTime.now(),
          sourceUrl: 'built-in-database',
        );
      }

      // Fallback: Try to search online using Wikipedia API
      try {
        final nationalNumber = await _searchWikipediaForEmergencyNumber(
          countryCode,
        );
        if (nationalNumber != null) {
          return nationalNumber;
        }
      } catch (e) {
        AppLogger.w(
          'Wikipedia search failed',
          tag: 'EmergencyContactService',
          error: e,
        );
      }

      // Ultimate fallback: Use 112 (international emergency number)
      AppLogger.w(
        '⚠️ Unknown country code: $countryCode, using international 112',
        tag: 'EmergencyContactService',
      );
      return EmergencyContact(
        type: 'national',
        name: 'International Emergency Services (112)',
        phoneNumber: '112',
        lastUpdated: DateTime.now(),
        sourceUrl: 'default-fallback',
      );
    } catch (e) {
      AppLogger.e(
        'Error searching national emergency hotline',
        tag: 'EmergencyContactService',
        error: e,
      );

      // Return safe default
      return EmergencyContact(
        type: 'national',
        name: 'International Emergency Services (112)',
        phoneNumber: '112',
        lastUpdated: DateTime.now(),
        sourceUrl: 'error-fallback',
      );
    }
  }

  /// Search Wikipedia for emergency number
  Future<EmergencyContact?> _searchWikipediaForEmergencyNumber(
    String countryCode,
  ) async {
    try {
      // Wikipedia API to get emergency telephone number info
      final url = Uri.parse(
        'https://en.wikipedia.org/w/api.php?'
        'action=query&'
        'format=json&'
        'prop=extracts&'
        'titles=Emergency_telephone_number&'
        'explaintext=true',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Parse Wikipedia content for country-specific emergency numbers
        // This is a simplified version - could be enhanced with better parsing

        AppLogger.i(
          'Wikipedia API responded successfully',
          tag: 'EmergencyContactService',
        );
      }

      return null; // Parsing not implemented yet
    } catch (e) {
      AppLogger.w(
        'Wikipedia API search failed',
        tag: 'EmergencyContactService',
        error: e,
      );
      return null;
    }
  }

  /// Search for local emergency services (hospitals, fire stations, police)
  Future<EmergencyContact?> _searchLocalEmergencyServices(
    LocationInfo location,
    String city,
    String state,
    String country,
  ) async {
    try {
      AppLogger.i(
        '🔍 Searching local emergency services in $city, $state...',
        tag: 'EmergencyContactService',
      );

      // Try multiple search strategies

      // Strategy 1: Search using OpenStreetMap Nominatim API
      final osmResult = await _searchOpenStreetMapEmergencyServices(
        location,
        city,
        state,
      );
      if (osmResult != null) {
        return osmResult;
      }

      // Strategy 2: Search using Google Places-like free APIs
      // (In production, you would use Google Places API with proper API key)

      // Strategy 3: Use pre-defined local emergency service patterns
      final predefinedResult = await _searchPredefinedLocalServices(
        location,
        city,
        state,
        country,
      );
      if (predefinedResult != null) {
        return predefinedResult;
      }

      // No local service found
      AppLogger.w(
        '⚠️ No local emergency services found for $city',
        tag: 'EmergencyContactService',
      );
      return null;
    } catch (e) {
      AppLogger.e(
        'Error searching local emergency services',
        tag: 'EmergencyContactService',
        error: e,
      );
      return null;
    }
  }

  /// Search OpenStreetMap for emergency services
  Future<EmergencyContact?> _searchOpenStreetMapEmergencyServices(
    LocationInfo location,
    String city,
    String state,
  ) async {
    try {
      // OpenStreetMap Nominatim API for searching nearby emergency facilities
      // Search for hospitals, fire stations, police stations
      final amenities = ['hospital', 'fire_station', 'police'];

      for (final amenity in amenities) {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/search?'
          'format=json&'
          'amenity=$amenity&'
          'lat=${location.latitude}&'
          'lon=${location.longitude}&'
          'limit=5&'
          'addressdetails=1',
        );

        final response = await http
            .get(url, headers: {'User-Agent': 'RedPing-Emergency-App/1.0'})
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final List<dynamic> results = json.decode(response.body);

          if (results.isNotEmpty) {
            // Find the closest facility
            final closest = results.first;
            final lat = double.parse(closest['lat']);
            final lon = double.parse(closest['lon']);
            final distance = _calculateDistance(
              location.latitude,
              location.longitude,
              lat,
              lon,
            );

            // Check if within search radius
            if (distance <= _localSearchRadius) {
              final name = closest['display_name'] ?? 'Local Emergency Service';
              final address = closest['address']?['road'] ?? '';

              // Try to extract phone number from OSM data (if available)
              // Note: OSM usually doesn't have phone numbers, so we'll need alternative approach

              AppLogger.i(
                '✅ Found local service: $name (${distance.toStringAsFixed(1)}km away)',
                tag: 'EmergencyContactService',
              );

              // For now, return location info - phone number would need separate lookup
              return EmergencyContact(
                type: 'local',
                name: name,
                phoneNumber: 'LOCATION_ONLY', // Needs phone lookup
                address: address,
                distance: distance,
                lastUpdated: DateTime.now(),
                sourceUrl: 'openstreetmap',
              );
            }
          }
        }
      }

      return null;
    } catch (e) {
      AppLogger.w(
        'OpenStreetMap search failed',
        tag: 'EmergencyContactService',
        error: e,
      );
      return null;
    }
  }

  /// Search pre-defined local emergency services by region
  Future<EmergencyContact?> _searchPredefinedLocalServices(
    LocationInfo location,
    String city,
    String state,
    String country,
  ) async {
    try {
      // This is a simplified database of major city emergency numbers
      // In production, this would be a comprehensive database or API

      final localServicesDB = <String, Map<String, String>>{
        // United States - Major Cities
        'New York City_NY_US': {
          'number': '212-639-9675',
          'name': 'NYC Emergency Management',
        },
        'Los Angeles_CA_US': {
          'number': '213-978-3222',
          'name': 'LA Emergency Services',
        },
        'Chicago_IL_US': {
          'number': '312-746-6000',
          'name': 'Chicago Emergency Management',
        },
        'Houston_TX_US': {
          'number': '713-884-4500',
          'name': 'Houston Emergency Center',
        },
        'Phoenix_AZ_US': {
          'number': '602-262-6011',
          'name': 'Phoenix Fire Department',
        },
        'Philadelphia_PA_US': {
          'number': '215-686-1776',
          'name': 'Philadelphia Emergency Management',
        },
        'San Antonio_TX_US': {
          'number': '210-207-7273',
          'name': 'San Antonio Emergency Services',
        },
        'San Diego_CA_US': {
          'number': '619-533-4300',
          'name': 'San Diego Emergency Medical',
        },
        'Dallas_TX_US': {
          'number': '214-670-4413',
          'name': 'Dallas Emergency Services',
        },
        'San Jose_CA_US': {
          'number': '408-277-8000',
          'name': 'San Jose Fire Department',
        },

        // Canada - Major Cities
        'Toronto_ON_CA': {
          'number': '416-338-7600',
          'name': 'Toronto Paramedic Services',
        },
        'Vancouver_BC_CA': {
          'number': '604-873-7000',
          'name': 'Vancouver Fire & Rescue',
        },
        'Montreal_QC_CA': {
          'number': '514-872-3800',
          'name': 'Montreal Emergency Services',
        },

        // UK - Major Cities
        'London__GB': {
          'number': '020-7783-0155',
          'name': 'London Ambulance Service',
        },
        'Manchester__GB': {
          'number': '0161-794-4500',
          'name': 'Greater Manchester Fire',
        },

        // Australia - Major Cities
        'Sydney_NSW_AU': {
          'number': '02-9265-0111',
          'name': 'NSW Ambulance Service',
        },
        'Melbourne_VIC_AU': {
          'number': '03-9256-7777',
          'name': 'Ambulance Victoria',
        },
        'Brisbane_QLD_AU': {
          'number': '07-3000-5000',
          'name': 'Queensland Ambulance',
        },

        // Add more cities as needed...
      };

      final key = '${city}_${state}_$country';
      if (localServicesDB.containsKey(key)) {
        final data = localServicesDB[key]!;

        AppLogger.i(
          '✅ Found pre-defined local service for $city',
          tag: 'EmergencyContactService',
        );

        return EmergencyContact(
          type: 'local',
          name: data['name']!,
          phoneNumber: data['number']!,
          address: '$city, $state',
          lastUpdated: DateTime.now(),
          sourceUrl: 'pre-defined-database',
        );
      }

      // If exact city not found, try to find state/regional emergency number
      final stateKey = '${state}_$country';
      final stateServicesDB = <String, Map<String, String>>{
        'CA_US': {
          'number': '916-845-8911',
          'name': 'California Emergency Services',
        },
        'NY_US': {'number': '518-457-2222', 'name': 'New York State Emergency'},
        'TX_US': {'number': '512-424-2208', 'name': 'Texas Emergency Services'},
        // Add more states...
      };

      if (stateServicesDB.containsKey(stateKey)) {
        final data = stateServicesDB[stateKey]!;

        AppLogger.i(
          '✅ Found state/regional emergency service for $state',
          tag: 'EmergencyContactService',
        );

        return EmergencyContact(
          type: 'local',
          name: data['name']!,
          phoneNumber: data['number']!,
          address: '$state, $country',
          lastUpdated: DateTime.now(),
          sourceUrl: 'pre-defined-regional',
        );
      }

      return null;
    } catch (e) {
      AppLogger.w(
        'Pre-defined local service search failed',
        tag: 'EmergencyContactService',
        error: e,
      );
      return null;
    }
  }

  /// Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // π / 180
    final a =
        0.5 -
        (cos((lat2 - lat1) * p) / 2) +
        (cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2);

    return 12742 * asin(sqrt(a)); // Distance in kilometers
  }

  /// Check if contacts need updating
  bool _needsUpdate(String country, String city) {
    // Always update if no cached contacts
    if (_nationalEmergencyContact == null || _localEmergencyContact == null) {
      return true;
    }

    // Update if location changed significantly
    if (_lastKnownCountry != country || _lastKnownCity != city) {
      AppLogger.i(
        '📍 Location changed from $_lastKnownCity, $_lastKnownCountry to $city, $country',
        tag: 'EmergencyContactService',
      );
      return true;
    }

    // Update if cache expired
    if (_lastUpdateTime == null ||
        DateTime.now().difference(_lastUpdateTime!) > _cacheExpiration) {
      AppLogger.i(
        '⏰ Cache expired, updating contacts',
        tag: 'EmergencyContactService',
      );
      return true;
    }

    return false;
  }

  /// Load cached contacts from SharedPreferences
  Future<void> _loadCachedContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final nationalJson = prefs.getString('national_emergency_contact');
      if (nationalJson != null) {
        _nationalEmergencyContact = EmergencyContact.fromJson(
          json.decode(nationalJson),
        );
      }

      final localJson = prefs.getString('local_emergency_contact');
      if (localJson != null) {
        _localEmergencyContact = EmergencyContact.fromJson(
          json.decode(localJson),
        );
      }

      final lastUpdate = prefs.getString('last_contact_update');
      if (lastUpdate != null) {
        _lastUpdateTime = DateTime.parse(lastUpdate);
      }

      _lastKnownCountry = prefs.getString('last_known_country');
      _lastKnownCity = prefs.getString('last_known_city');

      if (_nationalEmergencyContact != null || _localEmergencyContact != null) {
        AppLogger.i(
          '✅ Loaded cached emergency contacts',
          tag: 'EmergencyContactService',
        );
      }
    } catch (e) {
      AppLogger.w(
        'Failed to load cached contacts',
        tag: 'EmergencyContactService',
        error: e,
      );
    }
  }

  /// Cache contacts to SharedPreferences
  Future<void> _cacheContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (_nationalEmergencyContact != null) {
        await prefs.setString(
          'national_emergency_contact',
          json.encode(_nationalEmergencyContact!.toJson()),
        );
      }

      if (_localEmergencyContact != null) {
        await prefs.setString(
          'local_emergency_contact',
          json.encode(_localEmergencyContact!.toJson()),
        );
      }

      if (_lastUpdateTime != null) {
        await prefs.setString(
          'last_contact_update',
          _lastUpdateTime!.toIso8601String(),
        );
      }

      if (_lastKnownCountry != null) {
        await prefs.setString('last_known_country', _lastKnownCountry!);
      }

      if (_lastKnownCity != null) {
        await prefs.setString('last_known_city', _lastKnownCity!);
      }

      AppLogger.i(
        '💾 Emergency contacts cached successfully',
        tag: 'EmergencyContactService',
      );
    } catch (e) {
      AppLogger.w(
        'Failed to cache contacts',
        tag: 'EmergencyContactService',
        error: e,
      );
    }
  }

  /// Get current emergency contacts (cached)
  Map<String, EmergencyContact?> getCurrentContacts() {
    return {
      'national': _nationalEmergencyContact,
      'local': _localEmergencyContact,
    };
  }

  /// Force refresh emergency contacts
  Future<Map<String, EmergencyContact?>> forceRefresh(
    LocationInfo location,
  ) async {
    AppLogger.i(
      '🔄 Force refreshing emergency contacts...',
      tag: 'EmergencyContactService',
    );
    _lastUpdateTime = null; // Invalidate cache
    return await autoUpdateEmergencyContacts(location);
  }

  /// Dispose resources
  void dispose() {
    _nationalEmergencyContact = null;
    _localEmergencyContact = null;
    _isInitialized = false;
  }
}
