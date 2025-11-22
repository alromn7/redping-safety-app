import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:redping_14v/firebase_options.dart';

/// Script to mark all help requests as resolved for testing
/// This will move them from Help Requests tab to Resolved tab
void main() async {
  print('🚀 Starting help requests resolution script...\n');

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;

  // Track statistics
  int helpRequestsUpdated = 0;
  int regionalPingsUpdated = 0;
  int alreadyResolved = 0;
  int errors = 0;

  print('📊 Processing help_requests collection...');

  try {
    // Get all help requests
    final helpRequestsSnapshot = await firestore
        .collection('help_requests')
        .get();

    print(
      '   Found ${helpRequestsSnapshot.docs.length} help request documents',
    );

    for (final doc in helpRequestsSnapshot.docs) {
      try {
        final data = doc.data();
        final currentStatus = (data['status'] ?? 'active')
            .toString()
            .toLowerCase();

        // Skip if already resolved
        if (currentStatus == 'resolved' ||
            currentStatus == 'completed' ||
            currentStatus == 'closed') {
          alreadyResolved++;
          print('   ⏭️  Skipped ${doc.id} - already resolved ($currentStatus)');
          continue;
        }

        // Mark as resolved
        await doc.reference.update({
          'status': 'resolved',
          'resolvedAt': FieldValue.serverTimestamp(),
          'resolvedBy': 'system_batch_update',
          'resolutionNotes':
              'Batch marked as resolved for testing resolved tab functionality',
        });

        helpRequestsUpdated++;
        print('   ✅ Marked ${doc.id} as resolved (was: $currentStatus)');
      } catch (e) {
        errors++;
        print('   ❌ Error updating ${doc.id}: $e');
      }
    }

    print('\n📊 Processing regional_pings collection...');

    // Get all regional pings that are help requests
    final regionalPingsSnapshot = await firestore
        .collection('regional_pings')
        .get();

    print(
      '   Found ${regionalPingsSnapshot.docs.length} regional ping documents',
    );

    for (final doc in regionalPingsSnapshot.docs) {
      try {
        final data = doc.data();
        final id = doc.id;
        final type = (data['type'] ?? '').toString().toLowerCase();

        // Only process help requests
        if (!id.startsWith('help_') && type != 'help') {
          continue;
        }

        final currentStatus = (data['status'] ?? 'active')
            .toString()
            .toLowerCase();

        // Skip if already resolved
        if (currentStatus == 'resolved' ||
            currentStatus == 'completed' ||
            currentStatus == 'closed') {
          alreadyResolved++;
          print('   ⏭️  Skipped ${doc.id} - already resolved ($currentStatus)');
          continue;
        }

        // Mark as resolved
        await doc.reference.update({
          'status': 'resolved',
          'resolvedAt': FieldValue.serverTimestamp(),
          'resolvedBy': 'system_batch_update',
          'resolutionNotes':
              'Batch marked as resolved for testing resolved tab functionality',
        });

        regionalPingsUpdated++;
        print('   ✅ Marked ${doc.id} as resolved (was: $currentStatus)');
      } catch (e) {
        errors++;
        print('   ❌ Error updating ${doc.id}: $e');
      }
    }
  } catch (e) {
    print('\n❌ Fatal error: $e');
    return;
  }

  // Print summary
  print('\n${'=' * 60}');
  print('📊 RESOLUTION SUMMARY');
  print('=' * 60);
  print('Help Requests marked as resolved: $helpRequestsUpdated');
  print('Regional Pings marked as resolved: $regionalPingsUpdated');
  print('Already resolved (skipped):      $alreadyResolved');
  print('Errors encountered:               $errors');
  print(
    'Total processed:                  ${helpRequestsUpdated + regionalPingsUpdated + alreadyResolved}',
  );
  print('=' * 60);

  print('\n✅ Script completed successfully!');
  print('\n📱 Next steps:');
  print('   1. Open SAR Dashboard in the running app');
  print(
    '   2. Go to "Help Requests" tab - should be empty or show only new requests',
  );
  print(
    '   3. Go to "Resolved" tab - should show all resolved help requests with SOS cases',
  );
  print(
    '   4. Check "Resolved" KPI counter - should include help requests count',
  );
  print('   5. Verify help requests show help icon (not SOS icon)');
  print('   6. Click "View Help Request Details" button to verify routing\n');
}
