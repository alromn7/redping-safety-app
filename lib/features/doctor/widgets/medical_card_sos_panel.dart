import 'package:flutter/material.dart';
import '../../../models/medical/medical_profile.dart';

/// Minimal card showing critical medical info for SOS screens
class MedicalCardSosPanel extends StatelessWidget {
  final MedicalProfile? profile;
  const MedicalCardSosPanel({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final p = profile;
    if (p == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No medical profile set. Add blood type, allergies, and notes.',
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Medical Info',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (p.bloodType != null)
              Text('Blood type: ${_bloodTypeLabel(p.bloodType!)}'),
            if (p.allergies.isNotEmpty)
              Text('Allergies: ${p.allergies.join(', ')}'),
            if (p.conditions.isNotEmpty)
              Text('Conditions: ${p.conditions.join(', ')}'),
            if ((p.emergencyNotes ?? '').isNotEmpty)
              Text('Notes: ${p.emergencyNotes}'),
          ],
        ),
      ),
    );
  }

  String _bloodTypeLabel(BloodType t) {
    switch (t) {
      case BloodType.aPos:
        return 'A+';
      case BloodType.aNeg:
        return 'A-';
      case BloodType.bPos:
        return 'B+';
      case BloodType.bNeg:
        return 'B-';
      case BloodType.abPos:
        return 'AB+';
      case BloodType.abNeg:
        return 'AB-';
      case BloodType.oPos:
        return 'O+';
      case BloodType.oNeg:
        return 'O-';
    }
  }
}
