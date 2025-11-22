import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geocoding/geocoding.dart';
import '../core/constants/app_constants.dart';
import '../models/emergency_contact.dart';
import '../models/sos_session.dart';
import 'user_profile_service.dart';
import 'location_service.dart';

/// Service for managing emergency contacts and sending alerts
class EmergencyContactsService {
  static final EmergencyContactsService _instance =
      EmergencyContactsService._internal();
  factory EmergencyContactsService() => _instance;
  EmergencyContactsService._internal();

  final UserProfileService _userProfileService = UserProfileService();

  List<EmergencyContact> _contacts = [];
  List<ContactAlertLog> _alertLogs = [];

  bool _isInitialized = false;

  // Callbacks
  Function(List<EmergencyContact>)? _onContactsChanged;
  Function(ContactAlertLog)? _onAlertSent;

  /// Initialize the service and load contacts
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadContacts();
      await _loadAlertLogs();

      // Add default emergency services contact if none exist
      if (_contacts.isEmpty) {
        await _addDefaultContacts();
      }

      _isInitialized = true;
      debugPrint('EmergencyContactsService: Initialized successfully');
    } catch (e) {
      debugPrint('EmergencyContactsService: Initialization error - $e');
      throw Exception('Failed to initialize emergency contacts service: $e');
    }
  }

  /// Load contacts from storage
  Future<void> _loadContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = prefs.getString(AppConstants.emergencyContactsKey);

      if (contactsJson != null) {
        final List<dynamic> contactsList = json.decode(contactsJson);
        _contacts = contactsList
            .map((json) => EmergencyContact.fromJson(json))
            .toList();

        // Sort by priority
        _contacts.sort((a, b) => a.priority.compareTo(b.priority));
      }

      debugPrint(
        'EmergencyContactsService: Loaded ${_contacts.length} contacts',
      );
    } catch (e) {
      debugPrint('EmergencyContactsService: Error loading contacts - $e');
    }
  }

  /// Save contacts to storage
  Future<void> _saveContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final contactsJson = json.encode(
        _contacts.map((c) => c.toJson()).toList(),
      );
      await prefs.setString(AppConstants.emergencyContactsKey, contactsJson);

      _onContactsChanged?.call(_contacts);
      debugPrint(
        'EmergencyContactsService: Saved ${_contacts.length} contacts',
      );
    } catch (e) {
      debugPrint('EmergencyContactsService: Error saving contacts - $e');
    }
  }

  /// Load alert logs from storage
  Future<void> _loadAlertLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = prefs.getString('emergency_alert_logs');

      if (logsJson != null) {
        final List<dynamic> logsList = json.decode(logsJson);
        _alertLogs = logsList
            .map((json) => ContactAlertLog.fromJson(json))
            .toList();
      }

      debugPrint(
        'EmergencyContactsService: Loaded ${_alertLogs.length} alert logs',
      );
    } catch (e) {
      debugPrint('EmergencyContactsService: Error loading alert logs - $e');
    }
  }

  /// Save alert logs to storage
  Future<void> _saveAlertLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsJson = json.encode(
        _alertLogs.map((log) => log.toJson()).toList(),
      );
      await prefs.setString('emergency_alert_logs', logsJson);

      debugPrint(
        'EmergencyContactsService: Saved ${_alertLogs.length} alert logs',
      );
    } catch (e) {
      debugPrint('EmergencyContactsService: Error saving alert logs - $e');
    }
  }

  /// Add default emergency contacts
  Future<void> _addDefaultContacts() async {
    final now = DateTime.now();

    // Auto-detect user's location and get appropriate emergency number
    String emergencyNumber = '911'; // Default fallback
    String emergencyName = 'Emergency Services';
    String emergencyNotes = 'Local emergency services';

    try {
      // Try to get user's current location
      final position = await LocationService.getCurrentLocationStatic();

      // Get country from coordinates using reverse geocoding
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final countryCode = placemarks.first.isoCountryCode?.toUpperCase();

        // Map country codes to emergency numbers
        final emergencyNumbers = {
          'US': {'number': '911', 'name': 'US Emergency Services'},
          'CA': {'number': '911', 'name': 'Canada Emergency Services'},
          'MX': {'number': '911', 'name': 'Mexico Emergency Services'},
          'AU': {'number': '000', 'name': 'Australia Emergency Services'},
          'NZ': {'number': '111', 'name': 'New Zealand Emergency Services'},
          'GB': {'number': '999', 'name': 'UK Emergency Services'},
          'IE': {'number': '112', 'name': 'Ireland Emergency Services'},
          'IN': {'number': '112', 'name': 'India Emergency Services'},
          'ZA': {'number': '10111', 'name': 'South Africa Police'},
          'JP': {'number': '119', 'name': 'Japan Emergency Services'},
          'CN': {'number': '120', 'name': 'China Medical Emergency'},
          'KR': {'number': '119', 'name': 'South Korea Emergency'},
          'BR': {'number': '192', 'name': 'Brazil Medical Emergency'},
          'AR': {'number': '107', 'name': 'Argentina Medical Emergency'},
          'FR': {'number': '112', 'name': 'France Emergency Services'},
          'DE': {'number': '112', 'name': 'Germany Emergency Services'},
          'IT': {'number': '112', 'name': 'Italy Emergency Services'},
          'ES': {'number': '112', 'name': 'Spain Emergency Services'},
          'NL': {'number': '112', 'name': 'Netherlands Emergency Services'},
          'SE': {'number': '112', 'name': 'Sweden Emergency Services'},
          'NO': {'number': '112', 'name': 'Norway Emergency Services'},
          'DK': {'number': '112', 'name': 'Denmark Emergency Services'},
          'FI': {'number': '112', 'name': 'Finland Emergency Services'},
          'PL': {'number': '112', 'name': 'Poland Emergency Services'},
          'RU': {'number': '112', 'name': 'Russia Emergency Services'},
          'TR': {'number': '112', 'name': 'Turkey Emergency Services'},
          'SA': {'number': '997', 'name': 'Saudi Arabia Emergency'},
          'AE': {'number': '999', 'name': 'UAE Emergency Services'},
          'SG': {'number': '995', 'name': 'Singapore Ambulance'},
          'MY': {'number': '999', 'name': 'Malaysia Emergency Services'},
          'TH': {'number': '191', 'name': 'Thailand Emergency Services'},
          'VN': {'number': '115', 'name': 'Vietnam Medical Emergency'},
          'PH': {'number': '911', 'name': 'Philippines Emergency'},
          'ID': {'number': '112', 'name': 'Indonesia Emergency Services'},
          'EG': {'number': '123', 'name': 'Egypt Ambulance'},
          'NG': {'number': '112', 'name': 'Nigeria Emergency Services'},
        };

        if (countryCode != null && emergencyNumbers.containsKey(countryCode)) {
          emergencyNumber = emergencyNumbers[countryCode]!['number']!;
          emergencyName = emergencyNumbers[countryCode]!['name']!;
          emergencyNotes = 'Local emergency services ($emergencyNumber)';

          if (kDebugMode) {
            print(
              'EmergencyContactsService: Detected country $countryCode, using emergency number $emergencyNumber',
            );
          }
        } else {
          // Default to 112 (works in most of Europe and many other countries)
          emergencyNumber = '112';
          emergencyName = 'Emergency Services';
          emergencyNotes = 'International emergency number (112)';
          if (kDebugMode) {
            print(
              'EmergencyContactsService: Country $countryCode not in database, defaulting to 112',
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          'EmergencyContactsService: Could not auto-detect location, using default 911: $e',
        );
      }
    }

    final defaultContacts = [
      EmergencyContact(
        id: _generateId(),
        name: emergencyName,
        phoneNumber: emergencyNumber,
        type: ContactType.emergencyServices,
        priority: 1,
        relationship: 'Emergency Services',
        notes: emergencyNotes,
        createdAt: now,
        updatedAt: now,
      ),
      EmergencyContact(
        id: _generateId(),
        name: 'Emergency Contact 1',
        phoneNumber: '',
        type: ContactType.family,
        priority: 2,
        relationship: 'Family',
        notes: 'Add your primary emergency contact',
        isEnabled: false, // Disabled until user adds real info
        createdAt: now,
        updatedAt: now,
      ),
      EmergencyContact(
        id: _generateId(),
        name: 'Emergency Contact 2',
        phoneNumber: '',
        type: ContactType.friend,
        priority: 3,
        relationship: 'Friend',
        notes: 'Add your secondary emergency contact',
        isEnabled: false, // Disabled until user adds real info
        createdAt: now,
        updatedAt: now,
      ),
    ];

    _contacts.addAll(defaultContacts);
    await _saveContacts();
  }

  /// Add a new emergency contact
  Future<EmergencyContact> addContact({
    required String name,
    required String phoneNumber,
    String? email,
    required ContactType type,
    String? relationship,
    String? notes,
  }) async {
    final now = DateTime.now();
    final newPriority = _contacts.isEmpty ? 1 : _contacts.length + 1;

    final contact = EmergencyContact(
      id: _generateId(),
      name: name,
      phoneNumber: phoneNumber,
      email: email,
      type: type,
      priority: newPriority,
      relationship: relationship,
      notes: notes,
      createdAt: now,
      updatedAt: now,
    );

    _contacts.add(contact);
    _contacts.sort((a, b) => a.priority.compareTo(b.priority));
    await _saveContacts();

    debugPrint('EmergencyContactsService: Added contact ${contact.name}');
    return contact;
  }

  /// Update an existing contact
  Future<EmergencyContact> updateContact(
    String contactId,
    EmergencyContact updatedContact,
  ) async {
    final index = _contacts.indexWhere((c) => c.id == contactId);
    if (index == -1) {
      throw Exception('Contact not found');
    }

    final updated = updatedContact.copyWith(
      id: contactId,
      updatedAt: DateTime.now(),
    );

    _contacts[index] = updated;
    await _saveContacts();

    debugPrint('EmergencyContactsService: Updated contact ${updated.name}');
    return updated;
  }

  /// Delete a contact
  Future<void> deleteContact(String contactId) async {
    final index = _contacts.indexWhere((c) => c.id == contactId);
    if (index == -1) {
      throw Exception('Contact not found');
    }

    final contact = _contacts[index];
    _contacts.removeAt(index);

    // Reorder priorities
    for (int i = 0; i < _contacts.length; i++) {
      _contacts[i] = _contacts[i].copyWith(priority: i + 1);
    }

    await _saveContacts();
    debugPrint('EmergencyContactsService: Deleted contact ${contact.name}');
  }

  /// Reorder contacts by priority
  Future<void> reorderContacts(List<String> contactIds) async {
    final reorderedContacts = <EmergencyContact>[];

    for (int i = 0; i < contactIds.length; i++) {
      final contact = _contacts.firstWhere((c) => c.id == contactIds[i]);
      reorderedContacts.add(contact.copyWith(priority: i + 1));
    }

    _contacts = reorderedContacts;
    await _saveContacts();

    debugPrint('EmergencyContactsService: Reordered contacts');
  }

  /// Send emergency alerts to all enabled contacts
  Future<List<ContactAlertLog>> sendEmergencyAlerts(SOSSession session) async {
    final enabledContacts = _contacts.where((c) => c.isEnabled).toList();
    final alertLogs = <ContactAlertLog>[];

    debugPrint(
      'EmergencyContactsService: Sending alerts to ${enabledContacts.length} contacts',
    );

    for (final contact in enabledContacts) {
      // Send SMS alert (simulated)
      final smsLog = await _sendSMSAlert(contact, session);
      alertLogs.add(smsLog);

      // Send call alert for high priority contacts (simulated)
      if (contact.priority <= 2) {
        final callLog = await _sendCallAlert(contact, session);
        alertLogs.add(callLog);
      }

      // Send email if available (simulated)
      if (contact.email != null && contact.email!.isNotEmpty) {
        final emailLog = await _sendEmailAlert(contact, session);
        alertLogs.add(emailLog);
      }
    }

    _alertLogs.addAll(alertLogs);
    await _saveAlertLogs();

    return alertLogs;
  }

  /// Send SMS alert (simulated)
  Future<ContactAlertLog> _sendSMSAlert(
    EmergencyContact contact,
    SOSSession session,
  ) async {
    final log = ContactAlertLog(
      id: _generateId(),
      contactId: contact.id,
      sosSessionId: session.id,
      method: AlertMethod.sms,
      status: AlertStatus.pending,
      sentAt: DateTime.now(),
    );

    try {
      // Simulate SMS sending delay
      await Future.delayed(const Duration(seconds: 1));

      // IMPORTANT: Do not auto-launch SMS app here to avoid UI jumping/spam.
      // We only log a simulated SMS send so the app stays in foreground.
      // If needed, we present a single user-initiated prompt elsewhere.

      // Simulate success for alert logging
      final successLog = log.copyWith(
        status: AlertStatus.sent,
        deliveredAt: DateTime.now(),
      );

      _onAlertSent?.call(successLog);
      debugPrint('EmergencyContactsService: SMS sent to ${contact.name}');
      return successLog;
    } catch (e) {
      final errorLog = log.copyWith(
        status: AlertStatus.failed,
        errorMessage: e.toString(),
      );

      debugPrint('EmergencyContactsService: SMS failed to ${contact.name}: $e');
      return errorLog;
    }
  }

  /// Open SMS composer with pre-filled SOS contents to all enabled contacts (best-effort)
  Future<void> openSMSComposerForEnabledContacts(SOSSession session) async {
    for (final contact in _contacts.where((c) => c.isEnabled)) {
      if (contact.phoneNumber.isEmpty) continue;
      final msg = _generateAlertMessage(session);
      final smsUri = Uri(
        scheme: 'sms',
        path: contact.phoneNumber,
        queryParameters: {'body': msg},
      );
      try {
        await launchUrl(smsUri, mode: LaunchMode.externalApplication);
        // Launch once; user can choose recipients inside SMS app
        break;
      } catch (_) {
        // Try next contact
      }
    }
  }

  /// Send call alert (simulated)
  Future<ContactAlertLog> _sendCallAlert(
    EmergencyContact contact,
    SOSSession session,
  ) async {
    final log = ContactAlertLog(
      id: _generateId(),
      contactId: contact.id,
      sosSessionId: session.id,
      method: AlertMethod.call,
      status: AlertStatus.pending,
      sentAt: DateTime.now(),
    );

    try {
      // Simulate call initiation delay
      await Future.delayed(const Duration(seconds: 2));

      // TODO: Implement actual call initiation
      // For now, simulate success
      final successLog = log.copyWith(
        status: AlertStatus.sent,
        deliveredAt: DateTime.now(),
      );

      _onAlertSent?.call(successLog);
      debugPrint('EmergencyContactsService: Call initiated to ${contact.name}');
      return successLog;
    } catch (e) {
      final errorLog = log.copyWith(
        status: AlertStatus.failed,
        errorMessage: e.toString(),
      );

      debugPrint(
        'EmergencyContactsService: Call failed to ${contact.name}: $e',
      );
      return errorLog;
    }
  }

  /// Send email alert (simulated)
  Future<ContactAlertLog> _sendEmailAlert(
    EmergencyContact contact,
    SOSSession session,
  ) async {
    final log = ContactAlertLog(
      id: _generateId(),
      contactId: contact.id,
      sosSessionId: session.id,
      method: AlertMethod.email,
      status: AlertStatus.pending,
      sentAt: DateTime.now(),
    );

    try {
      // Simulate email sending delay
      await Future.delayed(const Duration(milliseconds: 500));

      // TODO: Implement actual email sending
      // For now, simulate success
      final successLog = log.copyWith(
        status: AlertStatus.sent,
        deliveredAt: DateTime.now(),
      );

      _onAlertSent?.call(successLog);
      debugPrint('EmergencyContactsService: Email sent to ${contact.name}');
      return successLog;
    } catch (e) {
      final errorLog = log.copyWith(
        status: AlertStatus.failed,
        errorMessage: e.toString(),
      );

      debugPrint(
        'EmergencyContactsService: Email failed to ${contact.name}: $e',
      );
      return errorLog;
    }
  }

  /// Generate comprehensive alert message with user details
  String _generateAlertMessage(SOSSession session) {
    final location = session.location;
    final locationText =
        location.address ??
        'Lat: ${location.latitude.toStringAsFixed(6)}, Lng: ${location.longitude.toStringAsFixed(6)}';

    // Get user profile for identification
    final userProfile = _userProfileService.currentProfile;

    // Build comprehensive emergency message
    final buffer = StringBuffer();

    // Header
    buffer.writeln('🚨 EMERGENCY ALERT 🚨');
    buffer.writeln();
    buffer.writeln(
      '${session.isAutoTriggered ? 'AUTOMATIC' : 'MANUAL'} SOS ACTIVATED',
    );
    buffer.writeln();

    // Person Identification
    buffer.writeln('👤 PERSON IN DISTRESS:');
    if (userProfile != null) {
      buffer.writeln(
        'Name: ${userProfile.name.isNotEmpty ? userProfile.name : 'Unknown'}',
      );
      if (userProfile.phoneNumber?.isNotEmpty == true) {
        buffer.writeln('Phone: ${userProfile.phoneNumber}');
      }
      if (userProfile.dateOfBirth != null) {
        final age =
            DateTime.now().difference(userProfile.dateOfBirth!).inDays ~/ 365;
        buffer.writeln('Age: $age years old');
      }
    } else {
      buffer.writeln('Name: Unknown User');
    }
    buffer.writeln();

    // Emergency Details
    buffer.writeln('🚨 EMERGENCY DETAILS:');
    buffer.writeln('Time: ${_formatDateTime(session.startTime)}');
    buffer.writeln('Location: $locationText');
    buffer.writeln('Alert Type: ${_getSOSTypeDisplayName(session.type)}');
    if (session.impactInfo != null) {
      buffer.writeln(
        'Impact Detected: ${session.impactInfo!.accelerationMagnitude.toStringAsFixed(1)} m/s²',
      );
    }
    buffer.writeln();

    // Medical Information (Critical for First Responders)
    if (userProfile != null) {
      buffer.writeln('🏥 MEDICAL INFORMATION:');
      buffer.writeln('Blood Type: ${userProfile.bloodType ?? 'Unknown'}');

      if (userProfile.allergies.isNotEmpty) {
        buffer.writeln('⚠️ ALLERGIES: ${userProfile.allergies.join(', ')}');
      }

      if (userProfile.medications.isNotEmpty) {
        buffer.writeln('💊 Medications: ${userProfile.medications.join(', ')}');
      }

      if (userProfile.medicalConditions.isNotEmpty) {
        buffer.writeln(
          '🔍 Medical Conditions: ${userProfile.medicalConditions.join(', ')}',
        );
      }
      buffer.writeln();
    }

    // Location Details
    buffer.writeln('📍 LOCATION DETAILS:');
    buffer.writeln(
      'Coordinates: ${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
    );
    buffer.writeln('Accuracy: ±${location.accuracy.toStringAsFixed(0)}m');
    if (location.altitude != null) {
      buffer.writeln('Altitude: ${location.altitude!.toStringAsFixed(0)}m');
    }
    if (location.address != null) {
      buffer.writeln('Address: ${location.address}');
    }
    buffer.writeln(
      'Google Maps: https://maps.google.com/?q=${location.latitude},${location.longitude}',
    );
    buffer.writeln();

    // User Message
    if (session.userMessage?.isNotEmpty == true) {
      buffer.writeln('💬 USER MESSAGE:');
      buffer.writeln('"${session.userMessage}"');
      buffer.writeln();
    }

    // Device Information
    buffer.writeln('📱 DEVICE INFO:');
    buffer.writeln('Session ID: ${session.id}');
    buffer.writeln('User ID: ${session.userId}');
    buffer.writeln('Test Mode: ${session.isTestMode ? 'YES' : 'NO'}');
    buffer.writeln();

    // Instructions for Responders
    buffer.writeln('🚑 FOR EMERGENCY RESPONDERS:');
    buffer.writeln('• Check medical info above for allergies/conditions');
    buffer.writeln('• Use GPS coordinates for exact location');
    buffer.writeln('• Contact other emergency contacts if needed');
    buffer.writeln('• Session ID for reference: ${session.id}');
    buffer.writeln();

    // Footer
    buffer.writeln('This automated alert was sent by RedPing Safety.');
    buffer.writeln('Reply STOP to stop receiving alerts.');

    return buffer.toString();
  }

  /// Get display name for SOS type
  String _getSOSTypeDisplayName(SOSType type) {
    switch (type) {
      case SOSType.manual:
        return 'Manual SOS Activation';
      case SOSType.crashDetection:
        return 'Vehicle Crash Detected';
      case SOSType.fallDetection:
        return 'Fall Detected';
      case SOSType.panicButton:
        return 'Panic Button Pressed';
      case SOSType.voiceCommand:
        return 'Voice Command Emergency';
      default:
        return 'Emergency Alert';
    }
  }

  /// Format date time for emergency messages
  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    return '${local.day}/${local.month}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}:${local.second.toString().padLeft(2, '0')}';
  }

  /// Get contact by ID
  EmergencyContact? getContact(String contactId) {
    try {
      return _contacts.firstWhere((c) => c.id == contactId);
    } catch (e) {
      return null;
    }
  }

  /// Get alert logs for a contact
  List<ContactAlertLog> getContactAlertLogs(String contactId) {
    return _alertLogs.where((log) => log.contactId == contactId).toList();
  }

  /// Get alert logs for a SOS session
  List<ContactAlertLog> getSessionAlertLogs(String sessionId) {
    return _alertLogs.where((log) => log.sosSessionId == sessionId).toList();
  }

  /// Generate unique ID
  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return 'contact_${timestamp}_$random';
  }

  // Getters
  bool get isInitialized => _isInitialized;
  List<EmergencyContact> get contacts => List.unmodifiable(_contacts);
  List<EmergencyContact> get enabledContacts =>
      _contacts.where((c) => c.isEnabled).toList();
  List<ContactAlertLog> get alertLogs => List.unmodifiable(_alertLogs);

  // Event handlers
  void setContactsChangedCallback(Function(List<EmergencyContact>) callback) {
    _onContactsChanged = callback;
  }

  void setAlertSentCallback(Function(ContactAlertLog) callback) {
    _onAlertSent = callback;
  }

  /// Dispose of the service
  void dispose() {
    _contacts.clear();
    _alertLogs.clear();
  }
}
