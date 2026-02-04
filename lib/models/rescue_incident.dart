import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of rescue incident
enum RescueIncidentStatus { initiated, inProgress, completed, cancelled }

extension RescueIncidentStatusExt on RescueIncidentStatus {
  String get displayName {
    switch (this) {
      case RescueIncidentStatus.initiated:
        return 'Rescue Initiated';
      case RescueIncidentStatus.inProgress:
        return 'Rescue In Progress';
      case RescueIncidentStatus.completed:
        return 'Rescue Completed';
      case RescueIncidentStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get icon {
    switch (this) {
      case RescueIncidentStatus.initiated:
        return '🚨';
      case RescueIncidentStatus.inProgress:
        return '🚁';
      case RescueIncidentStatus.completed:
        return '✅';
      case RescueIncidentStatus.cancelled:
        return '❌';
    }
  }
}

/// Type of rescue operation
enum RescueType {
  ambulance,
  helicopter,
  roadAssist,
  searchAndRescue,
  fireRescue,
  waterRescue,
}

extension RescueTypeExt on RescueType {
  String get displayName {
    switch (this) {
      case RescueType.ambulance:
        return 'Ambulance';
      case RescueType.helicopter:
        return 'Helicopter Rescue';
      case RescueType.roadAssist:
        return 'Road Assistance';
      case RescueType.searchAndRescue:
        return 'Search & Rescue';
      case RescueType.fireRescue:
        return 'Fire Rescue';
      case RescueType.waterRescue:
        return 'Water Rescue';
    }
  }

  String get icon {
    switch (this) {
      case RescueType.ambulance:
        return '🚑';
      case RescueType.helicopter:
        return '🚁';
      case RescueType.roadAssist:
        return '🚗';
      case RescueType.searchAndRescue:
        return '🔦';
      case RescueType.fireRescue:
        return '🚒';
      case RescueType.waterRescue:
        return '🚤';
    }
  }

  double get estimatedCost {
    switch (this) {
      case RescueType.ambulance:
        return 1500.0;
      case RescueType.helicopter:
        return 15000.0;
      case RescueType.roadAssist:
        return 300.0;
      case RescueType.searchAndRescue:
        return 5000.0;
      case RescueType.fireRescue:
        return 3000.0;
      case RescueType.waterRescue:
        return 2500.0;
    }
  }
}

/// Status of fund claim
enum ClaimStatus { pending, underReview, approved, rejected, paid }

extension ClaimStatusExt on ClaimStatus {
  String get displayName {
    switch (this) {
      case ClaimStatus.pending:
        return 'Pending Submission';
      case ClaimStatus.underReview:
        return 'Under Review';
      case ClaimStatus.approved:
        return 'Approved';
      case ClaimStatus.rejected:
        return 'Rejected';
      case ClaimStatus.paid:
        return 'Paid';
    }
  }

  String get icon {
    switch (this) {
      case ClaimStatus.pending:
        return '⏳';
      case ClaimStatus.underReview:
        return '🔍';
      case ClaimStatus.approved:
        return '✅';
      case ClaimStatus.rejected:
        return '❌';
      case ClaimStatus.paid:
        return '💰';
    }
  }
}

/// Rescue incident linked to Safety Fund
class RescueIncident {
  final String id;
  final String userId;
  final String sosSessionId;
  final RescueIncidentStatus status;
  final RescueType rescueType;

  // Safety Fund link
  final bool fundCovered;
  final String? subscriptionId;

  // Location details
  final double latitude;
  final double longitude;
  final String? locationName;

  // Timing
  final DateTime initiatedAt;
  final DateTime? completedAt;
  final int? durationMinutes;

  // Rescue details
  final String? sarTeamId;
  final String? dispatcherId;
  final List<String> responderIds;
  final String? incidentNotes;

  // Cost & claim
  final double estimatedCost;
  final double? actualCost;
  final ClaimStatus claimStatus;
  final String? claimId;
  final DateTime? claimSubmittedAt;
  final DateTime? claimApprovedAt;
  final String? claimRejectionReason;

  // Journey impact
  final bool journeyReset;
  final int badgesAwarded;
  final Map<String, dynamic>? recoveryData;

  RescueIncident({
    required this.id,
    required this.userId,
    required this.sosSessionId,
    required this.status,
    required this.rescueType,
    required this.fundCovered,
    this.subscriptionId,
    required this.latitude,
    required this.longitude,
    this.locationName,
    required this.initiatedAt,
    this.completedAt,
    this.durationMinutes,
    this.sarTeamId,
    this.dispatcherId,
    this.responderIds = const [],
    this.incidentNotes,
    required this.estimatedCost,
    this.actualCost,
    this.claimStatus = ClaimStatus.pending,
    this.claimId,
    this.claimSubmittedAt,
    this.claimApprovedAt,
    this.claimRejectionReason,
    this.journeyReset = false,
    this.badgesAwarded = 0,
    this.recoveryData,
  });

  /// Calculate fund coverage amount
  double get fundCoverageAmount {
    if (!fundCovered) return 0.0;

    final cost = actualCost ?? estimatedCost;
    // Fund covers up to 80% of rescue costs
    return cost * 0.8;
  }

  /// Calculate user's out-of-pocket cost
  double get userCost {
    final cost = actualCost ?? estimatedCost;
    return cost - fundCoverageAmount;
  }

  /// Check if claim is actionable by user
  bool get canSubmitClaim {
    return fundCovered &&
        status == RescueIncidentStatus.completed &&
        claimStatus == ClaimStatus.pending;
  }

  /// Check if incident is active
  bool get isActive {
    return status == RescueIncidentStatus.initiated ||
        status == RescueIncidentStatus.inProgress;
  }

  /// Get incident duration text
  String get durationText {
    if (durationMinutes == null) return 'In progress';

    final hours = durationMinutes! ~/ 60;
    final mins = durationMinutes! % 60;

    if (hours > 0) {
      return '$hours hr ${mins > 0 ? "$mins min" : ""}';
    }
    return '$mins min';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'sosSessionId': sosSessionId,
      'status': status.name,
      'rescueType': rescueType.name,
      'fundCovered': fundCovered,
      'subscriptionId': subscriptionId,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'initiatedAt': Timestamp.fromDate(initiatedAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'durationMinutes': durationMinutes,
      'sarTeamId': sarTeamId,
      'dispatcherId': dispatcherId,
      'responderIds': responderIds,
      'incidentNotes': incidentNotes,
      'estimatedCost': estimatedCost,
      'actualCost': actualCost,
      'claimStatus': claimStatus.name,
      'claimId': claimId,
      'claimSubmittedAt': claimSubmittedAt != null
          ? Timestamp.fromDate(claimSubmittedAt!)
          : null,
      'claimApprovedAt': claimApprovedAt != null
          ? Timestamp.fromDate(claimApprovedAt!)
          : null,
      'claimRejectionReason': claimRejectionReason,
      'journeyReset': journeyReset,
      'badgesAwarded': badgesAwarded,
      'recoveryData': recoveryData,
    };
  }

  factory RescueIncident.fromJson(Map<String, dynamic> json) {
    return RescueIncident(
      id: json['id'] as String,
      userId: json['userId'] as String,
      sosSessionId: json['sosSessionId'] as String,
      status: RescueIncidentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => RescueIncidentStatus.initiated,
      ),
      rescueType: RescueType.values.firstWhere(
        (e) => e.name == json['rescueType'],
        orElse: () => RescueType.ambulance,
      ),
      fundCovered: json['fundCovered'] as bool? ?? false,
      subscriptionId: json['subscriptionId'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      locationName: json['locationName'] as String?,
      initiatedAt: (json['initiatedAt'] as Timestamp).toDate(),
      completedAt: json['completedAt'] != null
          ? (json['completedAt'] as Timestamp).toDate()
          : null,
      durationMinutes: json['durationMinutes'] as int?,
      sarTeamId: json['sarTeamId'] as String?,
      dispatcherId: json['dispatcherId'] as String?,
      responderIds: json['responderIds'] != null
          ? List<String>.from(json['responderIds'] as List)
          : [],
      incidentNotes: json['incidentNotes'] as String?,
      estimatedCost: (json['estimatedCost'] as num).toDouble(),
      actualCost: json['actualCost'] != null
          ? (json['actualCost'] as num).toDouble()
          : null,
      claimStatus: json['claimStatus'] != null
          ? ClaimStatus.values.firstWhere(
              (e) => e.name == json['claimStatus'],
              orElse: () => ClaimStatus.pending,
            )
          : ClaimStatus.pending,
      claimId: json['claimId'] as String?,
      claimSubmittedAt: json['claimSubmittedAt'] != null
          ? (json['claimSubmittedAt'] as Timestamp).toDate()
          : null,
      claimApprovedAt: json['claimApprovedAt'] != null
          ? (json['claimApprovedAt'] as Timestamp).toDate()
          : null,
      claimRejectionReason: json['claimRejectionReason'] as String?,
      journeyReset: json['journeyReset'] as bool? ?? false,
      badgesAwarded: json['badgesAwarded'] as int? ?? 0,
      recoveryData: json['recoveryData'] as Map<String, dynamic>?,
    );
  }

  RescueIncident copyWith({
    String? id,
    String? userId,
    String? sosSessionId,
    RescueIncidentStatus? status,
    RescueType? rescueType,
    bool? fundCovered,
    String? subscriptionId,
    double? latitude,
    double? longitude,
    String? locationName,
    DateTime? initiatedAt,
    DateTime? completedAt,
    int? durationMinutes,
    String? sarTeamId,
    String? dispatcherId,
    List<String>? responderIds,
    String? incidentNotes,
    double? estimatedCost,
    double? actualCost,
    ClaimStatus? claimStatus,
    String? claimId,
    DateTime? claimSubmittedAt,
    DateTime? claimApprovedAt,
    String? claimRejectionReason,
    bool? journeyReset,
    int? badgesAwarded,
    Map<String, dynamic>? recoveryData,
  }) {
    return RescueIncident(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sosSessionId: sosSessionId ?? this.sosSessionId,
      status: status ?? this.status,
      rescueType: rescueType ?? this.rescueType,
      fundCovered: fundCovered ?? this.fundCovered,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      initiatedAt: initiatedAt ?? this.initiatedAt,
      completedAt: completedAt ?? this.completedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      sarTeamId: sarTeamId ?? this.sarTeamId,
      dispatcherId: dispatcherId ?? this.dispatcherId,
      responderIds: responderIds ?? this.responderIds,
      incidentNotes: incidentNotes ?? this.incidentNotes,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      actualCost: actualCost ?? this.actualCost,
      claimStatus: claimStatus ?? this.claimStatus,
      claimId: claimId ?? this.claimId,
      claimSubmittedAt: claimSubmittedAt ?? this.claimSubmittedAt,
      claimApprovedAt: claimApprovedAt ?? this.claimApprovedAt,
      claimRejectionReason: claimRejectionReason ?? this.claimRejectionReason,
      journeyReset: journeyReset ?? this.journeyReset,
      badgesAwarded: badgesAwarded ?? this.badgesAwarded,
      recoveryData: recoveryData ?? this.recoveryData,
    );
  }
}
