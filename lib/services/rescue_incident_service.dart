import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/rescue_incident.dart';
import '../models/safety_fund_subscription.dart';
import 'safety_journey_service.dart';

class RescueIncidentService {
  static final RescueIncidentService _instance =
      RescueIncidentService._internal();
  factory RescueIncidentService() => _instance;
  RescueIncidentService._internal();

  static RescueIncidentService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SafetyJourneyService _journeyService = SafetyJourneyService.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Collections
  CollectionReference get _incidents =>
      _firestore.collection('rescue_incidents');
  CollectionReference get _subscriptions =>
      _firestore.collection('safety_fund_subscriptions');

  /// Create new rescue incident during SOS activation
  Future<RescueIncident> createIncident({
    required String sosSessionId,
    required RescueType rescueType,
    required double latitude,
    required double longitude,
    String? locationName,
    String? dispatcherId,
  }) async {
    if (_userId == null) throw Exception('User not authenticated');

    // Check if user has active Safety Fund subscription
    final subscription = await _checkFundStatus();
    final fundCovered = subscription != null && subscription.isActive;

    final incident = RescueIncident(
      id: _incidents.doc().id,
      userId: _userId!,
      sosSessionId: sosSessionId,
      status: RescueIncidentStatus.initiated,
      rescueType: rescueType,
      fundCovered: fundCovered,
      subscriptionId: subscription != null ? _userId : null,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      initiatedAt: DateTime.now(),
      dispatcherId: dispatcherId,
      estimatedCost: rescueType.estimatedCost,
    );

    await _incidents.doc(incident.id).set(incident.toJson());

    print('🚨 Rescue incident created: ${incident.id}');
    print('💰 Fund covered: $fundCovered');

    return incident;
  }

  /// Check user's Safety Fund status
  Future<SafetyFundSubscription?> _checkFundStatus() async {
    if (_userId == null) return null;

    try {
      final doc = await _subscriptions.doc(_userId).get();
      if (!doc.exists) return null;

      final subscription = SafetyFundSubscription.fromJson(
        doc.data() as Map<String, dynamic>,
      );

      return subscription.isActive ? subscription : null;
    } catch (e) {
      print('Error checking fund status: $e');
      return null;
    }
  }

  /// Update incident status (for SAR team)
  Future<void> updateIncidentStatus({
    required String incidentId,
    required RescueIncidentStatus status,
    String? sarTeamId,
    List<String>? responderIds,
    String? notes,
  }) async {
    final updates = <String, dynamic>{'status': status.name};

    if (status == RescueIncidentStatus.inProgress) {
      updates['sarTeamId'] = sarTeamId;
      updates['responderIds'] = responderIds ?? [];
    }

    if (status == RescueIncidentStatus.completed) {
      updates['completedAt'] = Timestamp.now();

      // Calculate duration
      final doc = await _incidents.doc(incidentId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final initiatedAt = (data['initiatedAt'] as Timestamp).toDate();
        final duration = DateTime.now().difference(initiatedAt).inMinutes;
        updates['durationMinutes'] = duration;
      }
    }

    if (notes != null) {
      updates['incidentNotes'] = notes;
    }

    await _incidents.doc(incidentId).update(updates);

    print('✅ Incident $incidentId updated to ${status.displayName}');
  }

  /// Update actual rescue cost (after completion)
  Future<void> updateRescueCost({
    required String incidentId,
    required double actualCost,
  }) async {
    await _incidents.doc(incidentId).update({'actualCost': actualCost});

    print('💵 Rescue cost updated: \$${actualCost.toStringAsFixed(2)}');
  }

  /// Submit claim for fund coverage
  Future<String> submitClaim({
    required String incidentId,
    String? additionalNotes,
    List<String>? receiptUrls,
  }) async {
    final incidentDoc = await _incidents.doc(incidentId).get();
    if (!incidentDoc.exists) {
      throw Exception('Incident not found');
    }

    final incident = RescueIncident.fromJson(
      incidentDoc.data() as Map<String, dynamic>,
    );

    if (!incident.fundCovered) {
      throw Exception('Incident not covered by Safety Fund');
    }

    if (incident.status != RescueIncidentStatus.completed) {
      throw Exception('Incident must be completed before claiming');
    }

    // Create claim document
    final claimId = _firestore.collection('fund_claims').doc().id;

    await _firestore.collection('fund_claims').doc(claimId).set({
      'id': claimId,
      'incidentId': incidentId,
      'userId': _userId,
      'subscriptionId': incident.subscriptionId,
      'rescueType': incident.rescueType.name,
      'estimatedCost': incident.estimatedCost,
      'actualCost': incident.actualCost ?? incident.estimatedCost,
      'coverageAmount': incident.fundCoverageAmount,
      'userCost': incident.userCost,
      'status': ClaimStatus.underReview.name,
      'submittedAt': Timestamp.now(),
      'additionalNotes': additionalNotes,
      'receiptUrls': receiptUrls ?? [],
      'latitude': incident.latitude,
      'longitude': incident.longitude,
      'locationName': incident.locationName,
      'incidentDate': incident.initiatedAt,
    });

    // Update incident with claim info
    await _incidents.doc(incidentId).update({
      'claimId': claimId,
      'claimStatus': ClaimStatus.underReview.name,
      'claimSubmittedAt': Timestamp.now(),
    });

    print('📋 Claim submitted: $claimId');
    return claimId;
  }

  /// Process claim approval (admin only)
  Future<void> approveClaim({
    required String claimId,
    required String incidentId,
    String? notes,
  }) async {
    await _firestore.collection('fund_claims').doc(claimId).update({
      'status': ClaimStatus.approved.name,
      'approvedAt': Timestamp.now(),
      'reviewNotes': notes,
    });

    await _incidents.doc(incidentId).update({
      'claimStatus': ClaimStatus.approved.name,
      'claimApprovedAt': Timestamp.now(),
    });

    // Award rescue badges
    await _awardRescueBadges(incidentId);

    print('✅ Claim approved: $claimId');
  }

  /// Reject claim (admin only)
  Future<void> rejectClaim({
    required String claimId,
    required String incidentId,
    required String reason,
  }) async {
    await _firestore.collection('fund_claims').doc(claimId).update({
      'status': ClaimStatus.rejected.name,
      'rejectedAt': Timestamp.now(),
      'rejectionReason': reason,
    });

    await _incidents.doc(incidentId).update({
      'claimStatus': ClaimStatus.rejected.name,
      'claimRejectionReason': reason,
    });

    print('❌ Claim rejected: $claimId - $reason');
  }

  /// Award badges after rescue
  Future<void> _awardRescueBadges(String incidentId) async {
    final doc = await _incidents.doc(incidentId).get();
    if (!doc.exists) return;

    final incident = RescueIncident.fromJson(
      doc.data() as Map<String, dynamic>,
    );

    // Award appropriate badge based on rescue type
    final badgeTypes = <String>[];

    switch (incident.rescueType) {
      case RescueType.helicopter:
        badgeTypes.add('helicopterRescue');
        break;
      case RescueType.ambulance:
        badgeTypes.add('savedByAmbulance');
        break;
      case RescueType.searchAndRescue:
        badgeTypes.add('searchAndRescue');
        break;
      default:
        badgeTypes.add('communityHero');
    }

    // Badge awarding will be implemented in journey service
    // For now, just log the badge types that should be awarded
    print('🏆 Rescue badges to award: ${badgeTypes.join(", ")}');

    await _incidents.doc(incidentId).update({
      'badgesAwarded': badgeTypes.length,
    });
  }

  /// Reset journey after rescue (start recovery phase)
  Future<void> resetJourneyAfterRescue(String incidentId) async {
    if (_userId == null) return;

    final doc = await _incidents.doc(incidentId).get();
    if (!doc.exists) return;

    final incident = RescueIncident.fromJson(
      doc.data() as Map<String, dynamic>,
    );

    // Reset subscription streak but keep contribution history
    final subscriptionDoc = await _subscriptions.doc(_userId).get();
    if (subscriptionDoc.exists) {
      await _subscriptions.doc(_userId).update({
        'streakMonths': 0,
        'currentStage': SafetyStage.none.name,
        'lastRescueDate': Timestamp.now(),
        'totalRescues': FieldValue.increment(1),
      });
    }

    // Create recovery milestone
    await _journeyService.createRecoveryMilestone(incidentId);

    await _incidents.doc(incidentId).update({
      'journeyReset': true,
      'recoveryData': {
        'resetDate': Timestamp.now(),
        'previousStreak': incident.recoveryData?['previousStreak'] ?? 0,
        'recoveryStarted': true,
      },
    });

    print('🔄 Journey reset for recovery phase');
  }

  /// Get user's rescue history
  Stream<List<RescueIncident>> getUserIncidents() {
    if (_userId == null) return Stream.value([]);

    return _incidents
        .where('userId', isEqualTo: _userId)
        .orderBy('initiatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    RescueIncident.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList();
        });
  }

  /// Get specific incident
  Future<RescueIncident?> getIncident(String incidentId) async {
    final doc = await _incidents.doc(incidentId).get();
    if (!doc.exists) return null;

    return RescueIncident.fromJson(doc.data() as Map<String, dynamic>);
  }

  /// Get active incidents (for SAR dashboard)
  Stream<List<RescueIncident>> getActiveIncidents() {
    return _incidents
        .where(
          'status',
          whereIn: [
            RescueIncidentStatus.initiated.name,
            RescueIncidentStatus.inProgress.name,
          ],
        )
        .orderBy('initiatedAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    RescueIncident.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList();
        });
  }

  /// Get pending claims (for admin)
  Stream<List<Map<String, dynamic>>> getPendingClaims() {
    return _firestore
        .collection('fund_claims')
        .where('status', isEqualTo: ClaimStatus.underReview.name)
        .orderBy('submittedAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => doc.data()).toList();
        });
  }

  /// Calculate total fund payouts
  Future<double> getTotalFundPayouts() async {
    final snapshot = await _firestore
        .collection('fund_claims')
        .where('status', isEqualTo: ClaimStatus.approved.name)
        .get();

    double total = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      total += (data['coverageAmount'] as num?)?.toDouble() ?? 0;
    }

    return total;
  }

  /// Get fund coverage statistics
  Future<Map<String, dynamic>> getFundStatistics() async {
    final incidents = await _incidents
        .where('fundCovered', isEqualTo: true)
        .get();

    int totalRescues = incidents.size;
    int completedRescues = 0;
    int claimsApproved = 0;
    double totalCovered = 0;

    for (final doc in incidents.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final incident = RescueIncident.fromJson(data);

      if (incident.status == RescueIncidentStatus.completed) {
        completedRescues++;
      }

      if (incident.claimStatus == ClaimStatus.approved) {
        claimsApproved++;
        totalCovered += incident.fundCoverageAmount;
      }
    }

    return {
      'totalRescues': totalRescues,
      'completedRescues': completedRescues,
      'claimsApproved': claimsApproved,
      'totalCovered': totalCovered,
      'averageCoverage': claimsApproved > 0 ? totalCovered / claimsApproved : 0,
    };
  }
}
