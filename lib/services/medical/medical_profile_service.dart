import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../config/google_cloud_config.dart';
import '../../models/medical/medical_profile.dart';

/// Service to manage a user's medical profile (allergies, conditions, blood type, notes)
class MedicalProfileService {
  final FirebaseFirestore _db;
  MedicalProfileService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  /// Returns the doc ref for `users/{userId}/medical/profile`
  DocumentReference<Map<String, dynamic>> _profileDoc(String userId) {
    return _db
        .collection(GoogleCloudConfig.firestoreCollectionUsers)
        .doc(userId)
        .collection('medical')
        .doc('profile');
  }

  Future<MedicalProfile?> fetchProfile(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final snap = await _profileDoc(userId).get();
      if (!snap.exists || snap.data() == null) return null;
      final data = Map<String, dynamic>.from(snap.data()!);
      // Back-compat for older docs that may store Firestore Timestamps or omit fields.
      data['userId'] = data['userId'] ?? userId;
      data['createdAt'] = _coerceToIsoString(data['createdAt']);
      data['updatedAt'] = _coerceToIsoString(data['updatedAt']);
      return MedicalProfile.fromJson(data);
    } catch (e) {
      debugPrint('MedicalProfileService.fetchProfile error: $e');
      return null;
    }
  }

  Future<void> upsertProfile(MedicalProfile profile) async {
    if (profile.userId.isEmpty) {
      throw ArgumentError('MedicalProfile.userId is required');
    }
    try {
      await _profileDoc(profile.userId)
          .set(profile.toJson(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 6));
    } catch (e) {
      debugPrint('MedicalProfileService.upsertProfile error: $e');
      rethrow;
    }
  }

  String _coerceToIsoString(dynamic value) {
    if (value == null) return DateTime.now().toIso8601String();
    if (value is String) return value;
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    return DateTime.now().toIso8601String();
  }
}
