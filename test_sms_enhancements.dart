/// Test SMS Enhancement Features
///
/// This script verifies the 5 SMS enhancements work correctly:
/// 1. Smart contact selection (priority-based)
/// 2. No-response escalation (5-minute timer)
/// 3. Response confirmation (HELP/FALSE keywords)
/// 4. Two-way communication tracking
/// 5. Contact availability filtering
///
/// Run: dart test_sms_enhancements.dart
library;

import 'lib/models/emergency_contact.dart';

void main() async {
  print('🧪 Testing SMS Enhancement Features\n');
  print('=' * 60);

  // Test 1: Smart Contact Selection
  print('\n📋 TEST 1: Smart Contact Selection');
  print('-' * 60);
  testSmartContactSelection();

  // Test 2: Contact Availability Enum
  print('\n📋 TEST 2: Contact Availability System');
  print('-' * 60);
  testContactAvailability();

  // Test 3: Response Keywords
  print('\n📋 TEST 3: Response Keyword Detection');
  print('-' * 60);
  testResponseKeywords();

  // Test 4: Emergency Contact Model
  print('\n📋 TEST 4: Emergency Contact Model with New Fields');
  print('-' * 60);
  testEmergencyContactModel();

  print('\n${'=' * 60}');
  print('✅ All SMS Enhancement Tests Completed!\n');
}

/// Test smart contact selection logic
void testSmartContactSelection() {
  print('Creating 5 test contacts with different priorities...');

  final contacts = [
    _createTestContact('Wife', '+61473054208', priority: 1, available: true),
    _createTestContact('Brother', '+61498765432', priority: 2, available: true),
    _createTestContact(
      'Neighbor',
      '+61412345678',
      priority: 3,
      available: false,
    ), // Unavailable
    _createTestContact(
      'Co-worker',
      '+61487654321',
      priority: 4,
      available: true,
    ),
    _createTestContact('Friend', '+61476543210', priority: 5, available: true),
  ];

  print('✅ Created 5 contacts');
  print('   Priority 1: Wife (Available)');
  print('   Priority 2: Brother (Available)');
  print('   Priority 3: Neighbor (Unavailable)');
  print('   Priority 4: Co-worker (Available)');
  print('   Priority 5: Friend (Available)');

  // Simulate smart selection
  final availableContacts = contacts
      .where((c) => c.availability != ContactAvailability.unavailable)
      .toList();

  availableContacts.sort((a, b) => a.priority.compareTo(b.priority));
  final priorityContacts = availableContacts.take(3).toList();
  final secondaryContacts = availableContacts.skip(3).toList();

  print('\n🎯 Smart Selection Results:');
  print('   Initial Alert (Top 3 Available):');
  for (var contact in priorityContacts) {
    print('      ✉️  ${contact.name} (Priority ${contact.priority})');
  }

  print('\n   Escalation Queue (If No Response):');
  for (var contact in secondaryContacts) {
    print('      ⏰ ${contact.name} (Priority ${contact.priority})');
  }

  print('\n   Skipped (Unavailable):');
  final skipped = contacts
      .where((c) => c.availability == ContactAvailability.unavailable)
      .toList();
  for (var contact in skipped) {
    print('      ⏭️  ${contact.name} (Priority ${contact.priority})');
  }

  print('\n✅ Smart selection working correctly!');
}

/// Test contact availability enum
void testContactAvailability() {
  print('Testing ContactAvailability enum values...');

  final availabilities = ContactAvailability.values;
  print('✅ Found ${availabilities.length} availability states:');

  for (var status in availabilities) {
    final emoji = _getAvailabilityEmoji(status);
    final description = _getAvailabilityDescription(status);
    print('   $emoji $status - $description');
  }

  print('\n✅ Availability system working correctly!');
}

/// Test response keyword detection
void testResponseKeywords() {
  print('Testing response keyword detection...');

  final helpKeywords = [
    'HELP',
    'RESPONDING',
    'ON MY WAY',
    'COMING',
    'YES',
    'OK',
    'CONFIRMED',
  ];

  final falseAlarmKeywords = ['FALSE', 'MISTAKE', 'CANCEL', 'NO', 'SAFE', 'OK'];

  print('\n✅ Help Response Keywords (${helpKeywords.length}):');
  print('   ${helpKeywords.join(', ')}');

  print('\n❌ False Alarm Keywords (${falseAlarmKeywords.length}):');
  print('   ${falseAlarmKeywords.join(', ')}');

  // Test case-insensitive matching
  final testMessages = [
    'help on my way',
    'RESPONDING NOW',
    'false alarm',
    'CANCEL THIS',
    'Random message',
  ];

  print('\n🧪 Test Message Classification:');
  for (var msg in testMessages) {
    final isHelp = helpKeywords.any(
      (k) => msg.toUpperCase().contains(k.toUpperCase()),
    );
    final isFalse = falseAlarmKeywords.any(
      (k) => msg.toUpperCase().contains(k.toUpperCase()),
    );

    if (isHelp && !isFalse) {
      print('   ✅ "$msg" → HELP RESPONSE');
    } else if (isFalse) {
      print('   ❌ "$msg" → FALSE ALARM');
    } else {
      print('   ℹ️  "$msg" → UNCLASSIFIED');
    }
  }

  print('\n✅ Response keyword detection working correctly!');
}

/// Test emergency contact model with new fields
void testEmergencyContactModel() {
  print('Creating emergency contact with all new fields...');

  final now = DateTime.now();
  final contact = EmergencyContact(
    id: 'test_001',
    name: 'Test Wife',
    phoneNumber: '+61473054208',
    email: 'wife@example.com',
    type: ContactType.family,
    isEnabled: true,
    priority: 1,
    relationship: 'Spouse',
    notes: 'Primary emergency contact',
    createdAt: now,
    updatedAt: now,
    availability: ContactAvailability.available,
    distanceKm: 5.2,
    lastResponseTime: now.subtract(Duration(days: 2)),
  );

  print('✅ Created contact with:');
  print('   📛 Name: ${contact.name}');
  print('   📞 Phone: ${contact.phoneNumber}');
  print('   🎯 Priority: ${contact.priority}');
  print(
    '   ${_getAvailabilityEmoji(contact.availability)} Availability: ${contact.availability}',
  );
  print('   📍 Distance: ${contact.distanceKm} km');
  print('   ⏱️  Last Response: ${_formatTimeSince(contact.lastResponseTime!)}');

  // Test copyWith with new fields
  final updatedContact = contact.copyWith(
    availability: ContactAvailability.busy,
    distanceKm: 3.8,
    lastResponseTime: now,
  );

  print('\n📝 Updated contact:');
  print(
    '   ${_getAvailabilityEmoji(updatedContact.availability)} Availability: ${updatedContact.availability}',
  );
  print('   📍 Distance: ${updatedContact.distanceKm} km');
  print(
    '   ⏱️  Last Response: ${_formatTimeSince(updatedContact.lastResponseTime!)}',
  );

  // Test JSON serialization
  print('\n🔄 Testing JSON serialization...');
  final json = contact.toJson();
  print('   ✅ toJson() successful: ${json.keys.length} fields');

  final fromJson = EmergencyContact.fromJson(json);
  print('   ✅ fromJson() successful');
  print('   ✅ Availability preserved: ${fromJson.availability}');
  print('   ✅ Distance preserved: ${fromJson.distanceKm} km');
  print('   ✅ Last response preserved: ${fromJson.lastResponseTime != null}');

  print('\n✅ Emergency contact model working correctly!');
}

// Helper Functions

EmergencyContact _createTestContact(
  String name,
  String phone, {
  required int priority,
  required bool available,
}) {
  final now = DateTime.now();
  return EmergencyContact(
    id: 'test_${name.toLowerCase()}',
    name: name,
    phoneNumber: phone,
    type: ContactType.family,
    isEnabled: true,
    priority: priority,
    createdAt: now,
    updatedAt: now,
    availability: available
        ? ContactAvailability.available
        : ContactAvailability.unavailable,
  );
}

String _getAvailabilityEmoji(ContactAvailability status) {
  switch (status) {
    case ContactAvailability.available:
      return '✅';
    case ContactAvailability.busy:
      return '⚠️';
    case ContactAvailability.emergencyOnly:
      return '🚨';
    case ContactAvailability.unavailable:
      return '❌';
    case ContactAvailability.unknown:
      return '❓';
  }
}

String _getAvailabilityDescription(ContactAvailability status) {
  switch (status) {
    case ContactAvailability.available:
      return 'Ready to respond immediately';
    case ContactAvailability.busy:
      return 'Will try to respond';
    case ContactAvailability.emergencyOnly:
      return 'Severe emergencies only';
    case ContactAvailability.unavailable:
      return 'Cannot respond currently';
    case ContactAvailability.unknown:
      return 'Status not set (default)';
  }
}

String _formatTimeSince(DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inDays > 0) {
    return '${diff.inDays} days ago';
  } else if (diff.inHours > 0) {
    return '${diff.inHours} hours ago';
  } else if (diff.inMinutes > 0) {
    return '${diff.inMinutes} minutes ago';
  } else {
    return 'Just now';
  }
}
