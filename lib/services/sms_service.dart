import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/sos_session.dart';
import '../models/emergency_contact.dart';
import '../core/constants/app_constants.dart';
import 'platform_sms_sender_service.dart';
import 'emergency_event_bus.dart';
import 'test_mode_diagnostic_service.dart';
import 'feature_access_service.dart';

class SMSService {
  static final SMSService instance = SMSService._internal();
  factory SMSService() => instance;
  SMSService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PlatformSMSSenderService _smsSender = PlatformSMSSenderService();
  final EmergencyEventBus _eventBus = EmergencyEventBus();
  final FeatureAccessService _featureAccessService =
      FeatureAccessService.instance;

  final Map<String, Timer?> _activeTimers = {};
  final Map<String, int> _smsCounts = {};
  final Map<String, DateTime> _lastSMSTimes = {};
  final Map<String, Set<String>> _respondedContacts = {}; // Track who responded
  final Map<String, List<EmergencyContact>> _escalatedContacts =
      {}; // Track escalation

  static const Duration _activePhaseInterval = Duration(minutes: 2);
  static const Duration _acknowledgedPhaseInterval = Duration(minutes: 10);
  static const int _activePhaseMaxCount = 10;
  static const int _acknowledgedPhaseMaxCount = 6;
  static const Duration _noResponseEscalationDelay = Duration(minutes: 5);

  // Response keywords for confirmation
  static const List<String> _helpResponseKeywords = [
    'HELP',
    'RESPONDING',
    'ON MY WAY',
    'COMING',
    'YES',
    'OK',
    'CONFIRMED',
  ];
  static const List<String> _falseAlarmKeywords = [
    'FALSE',
    'MISTAKE',
    'CANCEL',
    'NO',
    'SAFE',
    'OK',
  ];

  Future<void> startSMSNotifications(
    SOSSession session,
    List<EmergencyContact> contacts,
  ) async {
    // ?? SUBSCRIPTION GATE: SOS SMS requires Essential+ or above
    if (!_featureAccessService.hasFeatureAccess('sosSMS')) {
      debugPrint('?? SMSService: SOS SMS not available - Free tier');
      debugPrint('   Upgrade to Essential+ for Automated SMS Emergency Alerts');
      debugPrint('   In-app notifications will still be sent');
      return;
    }

    // TEST MODE v2.0: Override contacts if SMS test mode enabled
    List<EmergencyContact> effectiveContacts = contacts;
    if (AppConstants.testingModeEnabled && AppConstants.useSmsTestMode) {
      // Convert test phone numbers to EmergencyContact objects
      final now = DateTime.now();
      effectiveContacts = AppConstants.testModeEmergencyContacts
          .asMap()
          .entries
          .map((entry) {
            return EmergencyContact(
              id: 'test_contact_${entry.key}',
              name: 'Test Contact ${entry.key + 1}',
              phoneNumber: entry.value,
              relationship: 'Test',
              type: ContactType.other,
              isEnabled: true,
              priority: entry.key + 1,
              createdAt: now,
              updatedAt: now,
            );
          })
          .toList();

      debugPrint(
        '?? TEST MODE: SMS will be sent to ${effectiveContacts.length} test contacts instead of ${contacts.length} real contacts',
      );

      // Log test mode SMS override
      TestModeDiagnosticService().logStateTransition(
        fromState: 'real_contacts',
        toState: 'test_contacts',
        reason: 'sms_test_mode_enabled',
        additionalData: {
          'original_contact_count': contacts.length,
          'test_contact_count': effectiveContacts.length,
          'test_phone_numbers': AppConstants.testModeEmergencyContacts,
        },
      );
    }

    if (effectiveContacts.isEmpty) return;
    // Ensure Android SMS permission before attempting automatic send
    try {
      if (Platform.isAndroid) {
        // Try fast path check
        final hasPermission = await _smsSender.hasSMSPermission();
        if (!hasPermission) {
          // Request permission; if user grants it, plugin will immediately allow native send
          await _smsSender.requestSMSPermission();
        }
      }
    } catch (_) {
      // Non-fatal: fall back paths will still try cloud/URI
    }
    _smsCounts[session.id] = 0;
    _lastSMSTimes[session.id] = DateTime.now();
    _respondedContacts[session.id] = {};
    _escalatedContacts[session.id] = [];

    // ENHANCEMENT 1: Smart Contact Selection - Send to closest/priority contacts first
    final priorityContacts = _selectPriorityContacts(
      session,
      effectiveContacts,
    );
    await _sendInitialAlertSMS(session, priorityContacts);

    // Store remaining contacts for potential escalation
    final remainingContacts = effectiveContacts
        .where((c) => !priorityContacts.any((p) => p.id == c.id))
        .toList();
    if (remainingContacts.isNotEmpty) {
      _escalatedContacts[session.id] = remainingContacts;
    }

    _scheduleActivePhaseSMS(session.id, priorityContacts);

    // ENHANCEMENT 2: Schedule escalation check if no response after 5 minutes
    _scheduleNoResponseEscalation(session.id, effectiveContacts);
  }

  /// ENHANCEMENT 1: Select priority contacts based on availability, distance, and priority level
  List<EmergencyContact> _selectPriorityContacts(
    SOSSession session,
    List<EmergencyContact> contacts,
  ) {
    // Filter enabled contacts only
    var enabled = contacts.where((c) => c.isEnabled).toList();
    if (enabled.isEmpty) return contacts; // Fallback to all if none enabled

    // Sort by priority (lower number = higher priority)
    enabled.sort((a, b) => a.priority.compareTo(b.priority));

    // Send to top 3 priority contacts initially
    // (Others will be escalated if no response in 5 minutes)
    return enabled.take(3).toList();
  }

  /// ENHANCEMENT 2: Escalate to additional contacts if no response after 5 minutes
  void _scheduleNoResponseEscalation(
    String sessionId,
    List<EmergencyContact> allContacts,
  ) {
    Timer(_noResponseEscalationDelay, () async {
      // Check if anyone has responded
      final responded = _respondedContacts[sessionId] ?? {};
      if (responded.isEmpty) {
        // No response - escalate to secondary contacts
        final secondaryContacts = _escalatedContacts[sessionId] ?? [];
        if (secondaryContacts.isNotEmpty) {
          final sessionDoc = await _firestore
              .collection('sos_sessions')
              .doc(sessionId)
              .get();
          if (sessionDoc.exists) {
            final sessionData = sessionDoc.data();
            if (sessionData != null) {
              final session = _parseSOSSession(sessionId, sessionData);
              await _sendEscalatedAlertSMS(session, secondaryContacts);
              _eventBus.fireSMSSent(
                sessionId,
                EmergencyEventType.smsFollowUpSent,
                secondaryContacts.length,
                message:
                    'Escalated to ${secondaryContacts.length} additional contacts (no response from primary contacts)',
              );
            }
          }
        }
      }
    });
  }

  void _scheduleActivePhaseSMS(
    String sessionId,
    List<EmergencyContact> contacts,
  ) {
    _activeTimers[sessionId]?.cancel();
    _activeTimers[sessionId] = Timer.periodic(_activePhaseInterval, (
      timer,
    ) async {
      final count = _smsCounts[sessionId] ?? 0;
      if (count >= _activePhaseMaxCount) {
        timer.cancel();
        return;
      }
      final sessionDoc = await _firestore
          .collection('sos_sessions')
          .doc(sessionId)
          .get();
      if (!sessionDoc.exists) {
        timer.cancel();
        return;
      }
      final status = sessionDoc.data()?['status'] as String?;
      if (status == 'acknowledged' ||
          status == 'assigned' ||
          status == 'enRoute') {
        timer.cancel();
        _scheduleAcknowledgedPhaseSMS(sessionId, contacts);
        return;
      } else if (status == 'resolved' || status == 'cancelled') {
        timer.cancel();
        return;
      }
      final sessionData = sessionDoc.data();
      if (sessionData != null) {
        final session = _parseSOSSession(sessionId, sessionData);
        if (count < 2) {
          await _sendFollowUpSMS(session, contacts, count + 1);
        } else {
          await _sendEscalationSMS(session, contacts, count + 1);
        }
        _smsCounts[sessionId] = count + 1;
        _lastSMSTimes[sessionId] = DateTime.now();
      }
    });
  }

  void _scheduleAcknowledgedPhaseSMS(
    String sessionId,
    List<EmergencyContact> contacts,
  ) {
    _activeTimers[sessionId]?.cancel();
    _smsCounts[sessionId] = 0;
    _activeTimers[sessionId] = Timer.periodic(_acknowledgedPhaseInterval, (
      timer,
    ) async {
      final count = _smsCounts[sessionId] ?? 0;
      if (count >= _acknowledgedPhaseMaxCount) {
        timer.cancel();
        return;
      }
      final sessionDoc = await _firestore
          .collection('sos_sessions')
          .doc(sessionId)
          .get();
      if (!sessionDoc.exists) {
        timer.cancel();
        return;
      }
      final status = sessionDoc.data()?['status'] as String?;
      if (status == 'resolved' || status == 'cancelled') {
        timer.cancel();
        return;
      }
      final sessionData = sessionDoc.data();
      if (sessionData != null) {
        final session = _parseSOSSession(sessionId, sessionData);
        await _sendAcknowledgedSMS(session, contacts, count + 1);
        _smsCounts[sessionId] = count + 1;
        _lastSMSTimes[sessionId] = DateTime.now();
      }
    });
  }

  /// ENHANCEMENT 3: Record contact response confirmation
  Future<void> recordContactResponse(
    String sessionId,
    String contactPhone,
    String responseMessage,
  ) async {
    final upperMessage = responseMessage.toUpperCase();

    // Check if it's a help confirmation
    if (_helpResponseKeywords.any(
      (keyword) => upperMessage.contains(keyword),
    )) {
      _respondedContacts[sessionId]?.add(contactPhone);

      // Log response to Firestore
      await _firestore
          .collection('sos_sessions')
          .doc(sessionId)
          .collection('contact_responses')
          .add({
            'contactPhone': contactPhone,
            'responseMessage': responseMessage,
            'responseType': 'helping',
            'timestamp': FieldValue.serverTimestamp(),
          });

      _eventBus.fireSMSSent(
        sessionId,
        EmergencyEventType.smsFollowUpSent,
        1,
        message: 'Contact $contactPhone confirmed they are responding',
      );
    }
    // Check if it's a false alarm
    else if (_falseAlarmKeywords.any(
      (keyword) => upperMessage.contains(keyword),
    )) {
      await _firestore.collection('sos_sessions').doc(sessionId).update({
        'status': 'cancelled',
        'cancelReason': 'emergency_contact_reported_false_alarm',
        'cancelledBy': contactPhone,
        'endTime': FieldValue.serverTimestamp(),
      });
    }
  }

  /// ENHANCEMENT 4: Check if any contacts have responded
  bool hasContactResponded(String sessionId) {
    return (_respondedContacts[sessionId]?.isNotEmpty ?? false);
  }

  /// Get list of contacts who have responded
  List<String> getRespondedContacts(String sessionId) {
    return _respondedContacts[sessionId]?.toList() ?? [];
  }

  Future<void> stopSMSNotifications(
    String sessionId, {
    bool sendFinalSMS = true,
  }) async {
    _activeTimers[sessionId]?.cancel();
    _activeTimers.remove(sessionId);
    if (sendFinalSMS) {
      final sessionDoc = await _firestore
          .collection('sos_sessions')
          .doc(sessionId)
          .get();
      if (sessionDoc.exists) {
        final sessionData = sessionDoc.data();
        if (sessionData != null) {
          final session = _parseSOSSession(sessionId, sessionData);
          final contacts = await _getEmergencyContacts(session.userId);
          final status = sessionData['status'] as String?;
          if (status == 'cancelled') {
            await _sendCancellationSMS(session, contacts);
          } else {
            await _sendResolvedSMS(session, contacts);
          }
        }
      }
    }
    _smsCounts.remove(sessionId);
    _lastSMSTimes.remove(sessionId);
    _respondedContacts.remove(sessionId);
    _escalatedContacts.remove(sessionId);
  }

  Future<void> _sendInitialAlertSMS(
    SOSSession session,
    List<EmergencyContact> contacts,
  ) async {
    final timestamp = DateFormat('h:mm a').format(session.startTime);
    final address = await _getAddressString(
      session.location.latitude,
      session.location.longitude,
    );
    final locationLink = _generateLocationLink(
      session.location.latitude,
      session.location.longitude,
    );
    final userName = session.userName?.isNotEmpty == true
        ? session.userName!
        : 'RedPing User';
    final userPhone = session.userPhone?.isNotEmpty == true
        ? session.userPhone!
        : 'Phone not available';

    // ENHANCEMENT 3: Add response confirmation prompt
    // TEST MODE v2.0: Prefix message if in test mode
    final testModePrefix =
        (AppConstants.testingModeEnabled && AppConstants.useSmsTestMode)
        ? '?? [TEST MODE] '
        : '';

    final message =
        '$testModePrefix?? EMERGENCY - RedPing\n\nName: $userName\nPhone: $userPhone\nType: ${_getAccidentTypeString(session.type)}\nTime: $timestamp\n\nLocation: $address\n\nACTION REQUIRED:\n1. CALL: $userPhone\n2. If no answer: Call emergency services\n3. OPEN REDPING APP to view full emergency card\n\n?? Reply "HELP" to confirm you\'re responding\n? Reply "FALSE" if false alarm\n\nNavigate:\n$locationLink\n\nAlert 1/5\nRedPing Emergency Response';

    await _sendSMSToContacts(message, contacts);
    await _logSMS(session.id, 'initial_alert', contacts.length);

    // Log test mode SMS send
    if (AppConstants.testingModeEnabled && AppConstants.useSmsTestMode) {
      TestModeDiagnosticService().logStateTransition(
        fromState: 'sos_session_started',
        toState: 'initial_sms_sent',
        reason: 'test_mode_sms_notification',
        additionalData: {
          'recipient_count': contacts.length,
          'message_length': message.length,
          'test_mode': true,
        },
      );
    }

    _eventBus.fireSMSSent(
      session.id,
      EmergencyEventType.smsInitialSent,
      contacts.length,
      message:
          'Initial alert SMS sent to ${contacts.length} priority contacts${(AppConstants.testingModeEnabled && AppConstants.useSmsTestMode) ? " [TEST MODE]" : ""}',
    );
  }

  /// ENHANCEMENT 2: Send escalated alert to secondary contacts
  Future<void> _sendEscalatedAlertSMS(
    SOSSession session,
    List<EmergencyContact> contacts,
  ) async {
    final elapsedMinutes = DateTime.now()
        .difference(session.startTime)
        .inMinutes;
    final address = await _getAddressString(
      session.location.latitude,
      session.location.longitude,
    );
    final locationLink = _generateLocationLink(
      session.location.latitude,
      session.location.longitude,
    );
    final userName = session.userName?.isNotEmpty == true
        ? session.userName!
        : 'RedPing User';
    final userPhone = session.userPhone?.isNotEmpty == true
        ? session.userPhone!
        : 'Phone not available';

    // TEST MODE v2.0: Prefix message if in test mode
    final testModePrefix =
        (AppConstants.testingModeEnabled && AppConstants.useSmsTestMode)
        ? '?? [TEST MODE] '
        : '';

    final message =
        '$testModePrefix?? ESCALATED EMERGENCY - RedPing\n\nName: $userName\nPhone: $userPhone\nNo response from primary contacts for ${elapsedMinutes}min\n\nLocation: $address\n\nURGENT ACTION NEEDED:\n1. CALL: $userPhone NOW\n2. If no answer: Call emergency services\n3. OPEN REDPING APP to view emergency card\n\n?? Reply "HELP" to confirm responding\n\nNavigate:\n$locationLink\n\nEscalated Alert\nRedPing Emergency Response';

    await _sendSMSToContacts(message, contacts);
    await _logSMS(session.id, 'escalated_alert', contacts.length);
  }

  Future<void> _sendFollowUpSMS(
    SOSSession session,
    List<EmergencyContact> contacts,
    int alertNumber,
  ) async {
    final elapsedMinutes = DateTime.now()
        .difference(session.startTime)
        .inMinutes;
    final address = await _getAddressString(
      session.location.latitude,
      session.location.longitude,
    );
    final batteryLevel = session.batteryLevel ?? 0;
    final userName = session.userName?.isNotEmpty == true
        ? session.userName!
        : 'RedPing User';
    final userPhone = session.userPhone?.isNotEmpty == true
        ? session.userPhone!
        : 'Phone not available';
    final locationLink = _generateLocationLink(
      session.location.latitude,
      session.location.longitude,
    );

    // TEST MODE v2.0: Prefix message if in test mode
    final testModePrefix =
        (AppConstants.testingModeEnabled && AppConstants.useSmsTestMode)
        ? '?? [TEST MODE] '
        : '';

    final message =
        '${testModePrefix}URGENT - RedPing\n\nName: $userName\nPhone: $userPhone\nElapsed: ${elapsedMinutes}m\n\nLocation: $address\nBattery: $batteryLevel%\n\nCALL NOW: $userPhone\nIf unreachable: Call emergency services\nOPEN REDPING APP for updates\n\nNavigate:\n$locationLink\n\nAlert $alertNumber/5\nRedPing Emergency Response';

    await _sendSMSToContacts(message, contacts);
    await _logSMS(session.id, 'follow_up', contacts.length);
    _eventBus.fireSMSSent(
      session.id,
      EmergencyEventType.smsFollowUpSent,
      contacts.length,
      message: 'Follow-up SMS #$alertNumber sent ($elapsedMinutes min elapsed)',
    );
  }

  Future<void> _sendEscalationSMS(
    SOSSession session,
    List<EmergencyContact> contacts,
    int alertNumber,
  ) async {
    final elapsedMinutes = DateTime.now()
        .difference(session.startTime)
        .inMinutes;
    final address = await _getAddressString(
      session.location.latitude,
      session.location.longitude,
    );
    final coordinates =
        '${session.location.latitude.toStringAsFixed(6)}, ${session.location.longitude.toStringAsFixed(6)}';
    final userName = session.userName?.isNotEmpty == true
        ? session.userName!
        : 'RedPing User';
    final userPhone = session.userPhone?.isNotEmpty == true
        ? session.userPhone!
        : 'Phone not available';
    final locationLink = _generateLocationLink(
      session.location.latitude,
      session.location.longitude,
    );
    final reasonCode = session.metadata['escalationReason'] as String?;

    final message =
        'CRITICAL - RedPing\n\nName: $userName\nPhone: $userPhone\nNo response: ${elapsedMinutes}m\n\nCALL: $userPhone\nIf no answer: Call emergency services now\n\nLocation: $address\nCoords: $coordinates\nOPEN REDPING APP for details\n\nNavigate:\n$locationLink\n\nAlert $alertNumber/5\nRedPing Emergency Response';

    await _sendSMSToContacts(message, contacts);
    await _logSMS(
      session.id,
      'escalation',
      contacts.length,
      reasonCode: reasonCode,
      escalationPhase: 'escalation',
      cardLinkUsed: 'digital',
    );
  }

  Future<void> _sendAcknowledgedSMS(
    SOSSession session,
    List<EmergencyContact> contacts,
    int alertNumber,
  ) async {
    final elapsedMinutes = DateTime.now()
        .difference(session.startTime)
        .inMinutes;
    final sarName = session.assignedSARName ?? 'SAR Team';
    final sarPhone = session.assignedSARPhone ?? 'N/A';
    final address = await _getAddressString(
      session.location.latitude,
      session.location.longitude,
    );
    final userName = session.userName?.isNotEmpty == true
        ? session.userName!
        : 'RedPing User';
    final locationLink = _generateLocationLink(
      session.location.latitude,
      session.location.longitude,
    );

    final message =
        'SAR RESPONDING - RedPing\n\nName: $userName\nSAR: $sarName\nSAR Phone: $sarPhone\nETA: $elapsedMinutes min\n\nLocation: $address\nOPEN REDPING APP for live updates\n\nNavigate:\n$locationLink\n\nAlert $alertNumber\nRedPing Emergency Response';

    await _sendSMSToContacts(message, contacts);
    await _logSMS(session.id, 'acknowledged', contacts.length);
  }

  Future<void> _sendResolvedSMS(
    SOSSession session,
    List<EmergencyContact> contacts,
  ) async {
    final duration = DateTime.now().difference(session.startTime).inMinutes;
    final sarTeam = session.assignedSARName ?? 'SAR Team';
    final userName = session.userName?.isNotEmpty == true
        ? session.userName!
        : 'RedPing User';
    final address = await _getAddressString(
      session.location.latitude,
      session.location.longitude,
    );

    final message =
        'SOS RESOLVED - RedPing\n\nName: $userName\nDuration: $duration min\nResolved by: $sarTeam\n\nLocation: $address\n\nThank you - no further action needed\n\nRedPing Emergency Response';

    await _sendSMSToContacts(message, contacts);
    await _logSMS(session.id, 'resolved', contacts.length);
  }

  Future<void> _sendCancellationSMS(
    SOSSession session,
    List<EmergencyContact> contacts,
  ) async {
    final duration = DateTime.now().difference(session.startTime).inMinutes;
    final userName = session.userName?.isNotEmpty == true
        ? session.userName!
        : 'RedPing User';
    final userPhone = session.userPhone?.isNotEmpty == true
        ? session.userPhone!
        : 'Phone not available';
    final address = await _getAddressString(
      session.location.latitude,
      session.location.longitude,
    );

    final message =
        'SOS CANCELLED - RedPing\n\nName: $userName\nPhone: $userPhone\nDuration: $duration min\n\nUser cancelled SOS - no action needed\n\nLocation: $address\n\nRedPing Emergency Response';

    await _sendSMSToContacts(message, contacts);
    await _logSMS(session.id, 'cancelled', contacts.length);
  }

  Future<void> _sendSMSToContacts(
    String message,
    List<EmergencyContact> contacts,
  ) async {
    int successCount = 0;
    int failCount = 0;
    for (final contact in contacts) {
      try {
        await _sendSMS(contact.phoneNumber, message);
        successCount++;
        debugPrint('SMS sent to ${contact.name}: ${contact.phoneNumber}');
      } catch (e) {
        failCount++;
        debugPrint('Failed to send SMS to ${contact.name}: $e');
        _eventBus.fireSMSFailed('unknown_session', contact.phoneNumber, e);
      }
    }
    debugPrint(
      'SMS bulk send complete: $successCount success, $failCount failed',
    );
  }

  Future<void> _sendSMS(String phoneNumber, String message) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    try {
      final success = await _smsSender.sendSMSWithFallback(
        phoneNumber: cleanPhone,
        message: message,
      );
      if (success) {
        debugPrint('SMS sent automatically to $cleanPhone');
        return;
      }
      debugPrint('Automatic SMS failed, falling back to SMS app');
      final uri = Uri(
        scheme: 'sms',
        path: cleanPhone,
        queryParameters: {'body': message},
      );
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        debugPrint('Opened SMS app for manual sending to $cleanPhone');
      } else {
        debugPrint('Cannot launch SMS URI: $uri');
      }
    } catch (e) {
      debugPrint('Error sending SMS: $e');
      try {
        final uri = Uri(
          scheme: 'sms',
          path: cleanPhone,
          queryParameters: {'body': message},
        );
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      } catch (fallbackError) {
        debugPrint('All SMS methods failed: $fallbackError');
      }
      rethrow;
    }
  }

  Future<void> _logSMS(
    String sessionId,
    String smsType,
    int recipientCount, {
    String? reasonCode,
    String? escalationPhase,
    String? verificationOutcome,
    String? cardLinkUsed,
  }) async {
    try {
      await _firestore
          .collection('sos_sessions')
          .doc(sessionId)
          .collection('sms_logs')
          .add({
            'type': smsType,
            'recipientCount': recipientCount,
            'timestamp': FieldValue.serverTimestamp(),
            'sentAt': DateTime.now().toIso8601String(),
            if (reasonCode != null) 'reasonCode': reasonCode,
            if (escalationPhase != null) 'escalationPhase': escalationPhase,
            if (verificationOutcome != null)
              'verificationOutcome': verificationOutcome,
            if (cardLinkUsed != null) 'cardLinkUsed': cardLinkUsed,
          });
      await _firestore.collection('sos_sessions').doc(sessionId).update({
        'smsCount': FieldValue.increment(recipientCount),
      });
    } catch (e) {
      debugPrint('Error logging SMS: $e');
    }
  }

  Future<List<EmergencyContact>> _getEmergencyContacts(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();
      if (data == null || !data.containsKey('emergencyContacts')) return [];
      final contactsData = data['emergencyContacts'] as List<dynamic>?;
      if (contactsData == null) return [];
      return contactsData
          .map((c) {
            final contact = c as Map<String, dynamic>;
            final now = DateTime.now();
            return EmergencyContact(
              id: contact['id'] as String? ?? 'unknown',
              name: contact['name'] as String? ?? 'Unknown',
              phoneNumber: contact['phone'] as String? ?? '',
              type: ContactType.other,
              priority: contact['priority'] as int? ?? 1,
              relationship: contact['relation'] as String?,
              createdAt: now,
              updatedAt: now,
            );
          })
          .where((c) => c.phoneNumber.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Error fetching emergency contacts: $e');
      return [];
    }
  }

  /// Generate Google Maps link for location
  /// This is universally accessible and works on all devices
  String _generateLocationLink(double latitude, double longitude) {
    // Google Maps link that works on all devices
    return 'https://maps.google.com/?q=$latitude,$longitude';
  }

  Future<String> _getAddressString(double latitude, double longitude) async {
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  String _getAccidentTypeString(SOSType type) {
    switch (type) {
      case SOSType.manual:
        return 'Manual SOS';
      case SOSType.crashDetection:
        return 'Crash Detected';
      case SOSType.fallDetection:
        return 'Fall Detected';
      case SOSType.panicButton:
        return 'Panic Button';
      case SOSType.voiceCommand:
        return 'Voice Command';
      case SOSType.externalTrigger:
        return 'External Trigger';
    }
  }

  SOSSession _parseSOSSession(String sessionId, Map<String, dynamic> data) {
    final userPhone =
        data['userPhone'] as String? ??
        data['phoneNumber'] as String? ??
        data['phone'] as String? ??
        (data['metadata'] as Map<String, dynamic>?)?['userPhone'] as String? ??
        '';
    return SOSSession(
      id: sessionId,
      userId: data['userId'] as String? ?? '',
      type: _parseSOSType(data['type'] as String? ?? 'manual'),
      status: _parseSOSStatus(data['status'] as String? ?? 'active'),
      startTime:
          (data['timestamp'] as Timestamp?)?.toDate() ??
          (data['startTime'] != null
              ? DateTime.parse(data['startTime'] as String)
              : DateTime.now()),
      location: LocationInfo(
        latitude:
            (data['latitude'] as num?)?.toDouble() ??
            (data['location'] as Map<String, dynamic>?)?['latitude']
                as double? ??
            0.0,
        longitude:
            (data['longitude'] as num?)?.toDouble() ??
            (data['location'] as Map<String, dynamic>?)?['longitude']
                as double? ??
            0.0,
        accuracy:
            (data['accuracy'] as num?)?.toDouble() ??
            (data['location'] as Map<String, dynamic>?)?['accuracy']
                as double? ??
            0.0,
        timestamp:
            (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        address:
            data['address'] as String? ??
            (data['location'] as Map<String, dynamic>?)?['address'] as String?,
        speed: (data['speed'] as num?)?.toDouble(),
      ),
      userMessage: data['message'] as String? ?? data['userMessage'] as String?,
      metadata: {
        'userName': data['userName'] as String? ?? '',
        'userPhone': userPhone,
        'batteryLevel':
            (data['batteryLevel'] as num?)?.toInt() ??
            (data['metadata'] as Map<String, dynamic>?)?['batteryLevel']
                as int? ??
            0,
        'assignedSARName': data['assignedSARName'] as String? ?? '',
        'assignedSARPhone': data['assignedSARPhone'] as String? ?? '',
        // Pass through optional fields if present so downstream services can read them
        'escalationReason':
            (data['metadata'] as Map<String, dynamic>?)?['escalationReason']
                as String? ??
            data['escalationReason'] as String?,
        'verificationOutcome':
            (data['metadata'] as Map<String, dynamic>?)?['verificationOutcome']
                as String? ??
            data['verificationOutcome'] as String?,
      },
    );
  }

  SOSType _parseSOSType(String type) {
    switch (type.toLowerCase()) {
      case 'crash':
      case 'crash_detection':
        return SOSType.crashDetection;
      case 'fall':
      case 'fall_detection':
        return SOSType.fallDetection;
      case 'manual':
        return SOSType.manual;
      case 'panic':
      case 'panic_button':
        return SOSType.panicButton;
      case 'voice':
      case 'voice_command':
        return SOSType.voiceCommand;
      case 'external':
      case 'external_trigger':
        return SOSType.externalTrigger;
      default:
        return SOSType.manual;
    }
  }

  SOSStatus _parseSOSStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return SOSStatus.active;
      case 'acknowledged':
        return SOSStatus.acknowledged;
      case 'assigned':
        return SOSStatus.assigned;
      case 'enroute':
      case 'en_route':
        return SOSStatus.enRoute;
      case 'resolved':
        return SOSStatus.resolved;
      case 'cancelled':
        return SOSStatus.cancelled;
      default:
        return SOSStatus.active;
    }
  }
}
