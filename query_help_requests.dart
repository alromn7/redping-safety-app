import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:redping_14v/firebase_options.dart';

/// Simple script to query and display help requests
void main() async {
  print('🔍 Querying help requests...\n');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;

  // Query help_requests collection
  print('📊 Help Requests Collection:');
  print('=' * 60);
  final helpRequests = await firestore.collection('help_requests').get();
  print('Total documents: ${helpRequests.docs.length}\n');

  for (var doc in helpRequests.docs) {
    final data = doc.data();
    print('ID: ${doc.id}');
    print('  Status: ${data['status'] ?? 'N/A'}');
    print('  User: ${data['userName'] ?? data['name'] ?? 'N/A'}');
    print('  Created: ${data['createdAt']}');
    print('  Type: ${data['type'] ?? 'N/A'}');
    print('');
  }

  // Query regional_pings for help requests
  print('\n📊 Regional Pings (Help Requests):');
  print('=' * 60);
  final regionalPings = await firestore.collection('regional_pings').get();
  int helpCount = 0;

  for (var doc in regionalPings.docs) {
    final data = doc.data();
    final id = doc.id;
    final type = (data['type'] ?? '').toString().toLowerCase();

    if (id.startsWith('help_') || type == 'help') {
      helpCount++;
      print('ID: ${doc.id}');
      print('  Status: ${data['status'] ?? 'N/A'}');
      print('  User: ${data['userName'] ?? data['name'] ?? 'N/A'}');
      print('  Created: ${data['createdAt']}');
      print('  Type: ${data['type'] ?? 'N/A'}');
      print('');
    }
  }

  print('Total help requests in regional_pings: $helpCount');
  print('\nDone!');
}
