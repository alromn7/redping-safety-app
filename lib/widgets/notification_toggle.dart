import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../services/satellite_service.dart';
import '../services/location_service.dart';

class NotificationToggle extends StatefulWidget {
  const NotificationToggle({super.key});
  @override
  State<NotificationToggle> createState() => _NotificationToggleState();
}

class _NotificationToggleState extends State<NotificationToggle> {
  bool _receiveNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Receive Notifications',
          style: TextStyle(color: Colors.white),
        ),
        Switch(
          value: _receiveNotifications,
          onChanged: (v) async {
            setState(() => _receiveNotifications = v);
            // Save preference to backend (Firestore)
            final user = FirebaseService().currentUser;
            if (user != null) {
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .set({
                      'receiveSARNotifications': v,
                      'updatedAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));
              } catch (_) {}
            }
            // Battery logic: hibernate services if notifications are off
            if (!v) {
              SatelliteService().hibernate();
              LocationService().hibernate();
            } else {
              SatelliteService().wake(sosActive: false, isOffline: false);
              LocationService().wake();
            }
          },
        ),
      ],
    );
  }
}
