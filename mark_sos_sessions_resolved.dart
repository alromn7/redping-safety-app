import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:redping_14v/firebase_options.dart';

/// Script to mark all active SOS sessions as resolved and clean up stale pointers
/// This prepares the system for proper SOS rule enforcement:
/// - User can only have ONE active SOS session at a time
/// - New SOS cannot be created until current session is resolved
/// - Sessions can be resolved by: SAR admin, user, emergency contact, or 5-second reset
void main() async {
  print('🚀 Starting SOS sessions cleanup script...\n');

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;

  // Track statistics
  int sessionsResolved = 0;
  int pointersCleared = 0;
  int sosPingsUpdated = 0;
  int alreadyResolved = 0;
  int errors = 0;

  print('📊 Step 1: Processing sos_sessions collection...');

  try {
    // Get all SOS sessions
    final sessionsSnapshot = await firestore.collection('sos_sessions').get();

    print('   Found ${sessionsSnapshot.docs.length} SOS session documents');

    for (final doc in sessionsSnapshot.docs) {
      try {
        final data = doc.data();
        final currentStatus = (data['status'] ?? 'active')
            .toString()
            .toLowerCase();

        // Skip if already resolved/cancelled
        if (currentStatus == 'resolved' ||
            currentStatus == 'cancelled' ||
            currentStatus == 'completed' ||
            currentStatus == 'false_alarm') {
          alreadyResolved++;
          print('   ⏭️  Skipped ${doc.id} - already $currentStatus');
          continue;
        }

        // Mark as resolved
        await doc.reference.update({
          'status': 'resolved',
          'endTime': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'resolvedBy': 'system_cleanup',
          'resolutionNotes':
              'Batch cleanup - preparing for SOS rule enforcement',
        });

        sessionsResolved++;
        print('   ✅ Marked ${doc.id} as resolved (was: $currentStatus)');
      } catch (e) {
        errors++;
        print('   ❌ Error updating ${doc.id}: $e');
      }
    }

    print('\n📊 Step 2: Clearing all active session pointers...');

    // Get all user state documents
    final usersSnapshot = await firestore.collection('users').get();

    print('   Found ${usersSnapshot.docs.length} user documents');

    for (final userDoc in usersSnapshot.docs) {
      try {
        final userId = userDoc.id;
        final stateDocRef = firestore.doc('users/$userId/meta/state');

        final stateDoc = await stateDocRef.get();

        if (stateDoc.exists) {
          final stateData = stateDoc.data();
          if (stateData != null && stateData.containsKey('activeSessionId')) {
            // Clear the active session pointer
            await stateDocRef.update({'activeSessionId': FieldValue.delete()});

            pointersCleared++;
            print('   ✅ Cleared active session pointer for user $userId');
          }
        }
      } catch (e) {
        errors++;
        print('   ❌ Error clearing pointer for user ${userDoc.id}: $e');
      }
    }

    print('\n📊 Step 3: Updating sos_pings collection...');

    // Get all SOS pings
    final pingsSnapshot = await firestore.collection('sos_pings').get();

    print('   Found ${pingsSnapshot.docs.length} SOS ping documents');

    for (final doc in pingsSnapshot.docs) {
      try {
        final data = doc.data();
        final currentStatus = (data['status'] ?? 'active')
            .toString()
            .toLowerCase();

        // Skip if already resolved
        if (currentStatus == 'resolved' || currentStatus == 'completed') {
          continue;
        }

        // Mark as resolved
        await doc.reference.update({
          'status': 'resolved',
          'lastUpdate': DateTime.now().toIso8601String(),
        });

        sosPingsUpdated++;
        print('   ✅ Marked ping ${doc.id} as resolved');
      } catch (e) {
        errors++;
        print('   ❌ Error updating ping ${doc.id}: $e');
      }
    }
  } catch (e) {
    print('\n❌ Fatal error: $e');
    return;
  }

  // Print summary
  print('\n${'=' * 70}');
  print('📊 CLEANUP SUMMARY');
  print('=' * 70);
  print('SOS Sessions marked as resolved:     $sessionsResolved');
  print('Active session pointers cleared:     $pointersCleared');
  print('SOS Pings updated:                   $sosPingsUpdated');
  print('Already resolved (skipped):          $alreadyResolved');
  print('Errors encountered:                  $errors');
  print('=' * 70);

  if (errors == 0) {
    print('\n✅ CLEANUP COMPLETE - System ready for SOS rule enforcement');
    print('\n📋 SOS RULES NOW ENFORCED:');
    print('   1. ✅ Only ONE active SOS session per user at a time');
    print('   2. ✅ Cannot create new SOS until current is resolved');
    print('   3. ✅ Sessions can be resolved by:');
    print('      - SAR admin via dashboard');
    print('      - User via 5-second reset button hold');
    print('      - Emergency contact via app');
    print('      - Automatic timeout (if implemented)');
    print('\n🎯 Next Steps:');
    print('   1. Hot reload the app');
    print('   2. Test manual SOS activation');
    print('   3. Verify inline SOS Active strip appears and stays visible');
    print('   4. Check SAR dashboard receives the ping');
    print('   5. Test 5-second reset to clear the session');
  } else {
    print(
      '\n⚠️  CLEANUP COMPLETED WITH ERRORS - Please review error messages above',
    );
  }
}
