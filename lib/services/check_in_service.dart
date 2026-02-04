import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/check_in_request.dart';
import '../config/env.dart';

class CheckInService {
  CheckInService._();
  static final CheckInService instance = CheckInService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool get _enabled => Env.flag<bool>('enableCheckInPing', true);
  bool get _requireConsent => Env.flag<bool>('requireConsentForCheckIn', true);
  int get _maxPerDay => Env.flag<int>('maxCheckInPerDay', 5);

  Future<int> _countToday(String requesterUserId) async {
    final startOfDay = DateTime.now().toUtc();
    final truncated = DateTime.utc(
      startOfDay.year,
      startOfDay.month,
      startOfDay.day,
    );
    final snap = await _db
        .collection('check_in_requests')
        .where('requesterUserId', isEqualTo: requesterUserId)
        .where('createdAt', isGreaterThanOrEqualTo: truncated)
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<CheckInRequest> createRequest({
    required String familyId,
    required String requesterUserId,
    required String targetUserId,
    String? reason,
    bool autoApproved = false,
  }) async {
    if (!_enabled) {
      throw Exception('Check-in ping disabled');
    }
    final used = await _countToday(requesterUserId);
    if (_maxPerDay > 0 && used >= _maxPerDay) {
      throw Exception('Daily check-in limit reached');
    }

    // Guardian auto-approval override via target user doc field guardianAutoApproveIds
    bool guardianAutoApproved = false;
    try {
      final targetDoc = await _db.collection('users').doc(targetUserId).get();
      final guardianList =
          (targetDoc.data()?['guardianAutoApproveIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      if (guardianList.contains(requesterUserId) &&
          Env.flag<bool>('enableGuardianAutoApproval', true)) {
        guardianAutoApproved = true;
      }
    } catch (_) {}

    final request = CheckInRequest.newPending(
      familyId: familyId,
      requesterUserId: requesterUserId,
      targetUserId: targetUserId,
      reason: reason,
      autoApproved: guardianAutoApproved || (autoApproved && !_requireConsent),
    );

    await _db.collection('check_in_requests').doc(request.id).set({
      'familyId': request.familyId,
      'requesterUserId': request.requesterUserId,
      'targetUserId': request.targetUserId,
      'status': request.status.name,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(request.expiresAt),
      'reason': request.reason,
      'autoApproved': request.autoApproved,
      'respondedAt': request.respondedAt != null
          ? Timestamp.fromDate(request.respondedAt!)
          : null,
    });

    return request;
  }

  Future<void> respond({
    required String requestId,
    required bool accept,
    CheckInLocationSnapshot? location,
  }) async {
    final doc = _db.collection('check_in_requests').doc(requestId);
    final snapshot = await doc.get();
    if (!snapshot.exists) throw Exception('Request not found');
    final data = snapshot.data()!;
    final status = data['status'] as String?;
    if (status != 'pending') return; // ignore already processed

    if (!accept) {
      await doc.update({
        'status': CheckInRequestStatus.denied.name,
        'respondedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    if (location == null) {
      throw Exception('Location snapshot required on accept');
    }

    await doc.update({
      'status': CheckInRequestStatus.locationShared.name,
      'respondedAt': FieldValue.serverTimestamp(),
      'locationSnapshot': {
        'lat': location.lat,
        'lng': location.lng,
        'accuracy': location.accuracy,
        'capturedAt': Timestamp.fromDate(location.capturedAt),
      },
    });
  }

  Future<void> expirePending() async {
    final now = DateTime.now();
    final query = await _db
        .collection('check_in_requests')
        .where('status', isEqualTo: CheckInRequestStatus.pending.name)
        .where('expiresAt', isLessThan: Timestamp.fromDate(now))
        .get();
    for (final d in query.docs) {
      await d.reference.update({'status': CheckInRequestStatus.expired.name});
    }
  }

  /// Stream pending incoming requests for a target user
  Stream<List<CheckInRequest>> pendingForTarget(String targetUserId) {
    return _db
        .collection('check_in_requests')
        .where('targetUserId', isEqualTo: targetUserId)
        .where('status', isEqualTo: CheckInRequestStatus.pending.name)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) {
            final data = d.data();
            return CheckInRequest(
              id: d.id,
              familyId: data['familyId'] ?? '',
              requesterUserId: data['requesterUserId'] ?? '',
              targetUserId: data['targetUserId'] ?? '',
              status: CheckInRequestStatus.pending,
              createdAt:
                  (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              expiresAt:
                  (data['expiresAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              reason: data['reason'],
              autoApproved: data['autoApproved'] == true,
            );
          }).toList(),
        );
  }
}
