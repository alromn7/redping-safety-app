import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreTest {
  static Future<void> testConnection() async {
    try {
      print('🔥 Testing Firestore connection...');

      // Use existing initialized app and attempt a write to logs (allowed for authed users)
      final firestore = FirebaseFirestore.instance;
      print('✅ Firestore instance created');

      final testDoc = firestore
          .collection('logs')
          .doc('device_connection_test');
      await testDoc.set({
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Device Firestore connectivity OK',
        'testId': DateTime.now().millisecondsSinceEpoch.toString(),
        'platform': 'flutter_app',
      }, SetOptions(merge: true));
      print('✅ Document written to Firestore (logs/device_connection_test)');

      final doc = await testDoc.get();
      if (doc.exists) {
        print('✅ Document read from Firestore: ${doc.data()}');
      } else {
        print('❌ Document not found');
      }

      print('📡 Setting up real-time listener...');
      testDoc.snapshots().listen((snapshot) {
        if (snapshot.exists) {
          print('📡 Real-time update received: ${snapshot.data()}');
        }
      });

      print('✅ Firestore connection test completed successfully!');
    } catch (e, st) {
      print('❌ Firestore connection test failed: $e');
      print(st);
      print('💡 This might indicate:');
      print(
        '   - Firestore security rules require auth (ensure anonymous auth)',
      );
      print('   - Network/connectivity or project mismatch');
    }
  }
}
