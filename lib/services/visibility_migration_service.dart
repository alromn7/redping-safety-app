import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/sos_session.dart';
import '../repositories/sos_repository.dart';
import 'emergency_contacts_service.dart';

/// One-off helper to backfill visibility fields on existing SOS sessions
/// so that emergency contacts can view via email under the new rules.
class VisibilityMigrationService {
  static final VisibilityMigrationService _instance =
      VisibilityMigrationService._internal();
  factory VisibilityMigrationService() => _instance;
  VisibilityMigrationService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EmergencyContactsService _contacts = EmergencyContactsService();
  final SosRepository _sosRepo = SosRepository();

  /// Backfill the current user's active SOS session with allowed viewer fields.
  /// Safe to call multiple times; it only updates missing/empty fields.
  Future<void> backfillAllowedViewersForActiveSession() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final uid = user.uid;
      final session = await _sosRepo.getActiveSession(uid);
      if (session == null) return;

      final docRef = _firestore.collection('sos_sessions').doc(session.id);
      final snap = await docRef.get();
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;

      final currentEmails = List<String>.from(
        (data['allowedViewerEmails'] as List<dynamic>? ?? const []),
      );

      // Build allowed viewer emails from enabled contacts
      final emails = _contacts.enabledContacts
          .where((c) => c.isEnabled && (c.email != null && c.email!.isNotEmpty))
          .map((c) => c.email!)
          .toSet()
          .toList();

      // Nothing to update
      if (currentEmails.isNotEmpty && emails.every(currentEmails.contains)) {
        return;
      }

      final update = <String, dynamic>{
        'visibility': data['visibility'] ?? 'restricted',
        'allowedViewerEmails': (currentEmails.toSet()..addAll(emails)).toList(),
        // Keep 'allowedViewerIds' reserved for future mapping of contacts→users
      };

      await docRef.set(update, SetOptions(merge: true));
      debugPrint(
        'VisibilityMigrationService: Backfilled allowed viewers on session ${session.id}',
      );
    } catch (e) {
      debugPrint(
        'VisibilityMigrationService: Skipped backfill due to error: $e',
      );
    }
  }
}
