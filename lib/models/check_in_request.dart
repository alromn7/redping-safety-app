import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'check_in_request.g.dart';

enum CheckInRequestStatus { pending, locationShared, denied, expired }

@JsonSerializable(explicitToJson: true)
class CheckInLocationSnapshot {
  final double lat;
  final double lng;
  final double? accuracy;
  final DateTime capturedAt;

  CheckInLocationSnapshot({
    required this.lat,
    required this.lng,
    this.accuracy,
    required this.capturedAt,
  });

  factory CheckInLocationSnapshot.fromJson(Map<String, dynamic> json) =>
      _$CheckInLocationSnapshotFromJson(json);
  Map<String, dynamic> toJson() => _$CheckInLocationSnapshotToJson(this);
}

@JsonSerializable(explicitToJson: true)
class CheckInRequest {
  final String id;
  final String familyId;
  final String requesterUserId;
  final String targetUserId;
  final CheckInRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;
  final DateTime expiresAt;
  final String? reason;
  final bool autoApproved;
  final CheckInLocationSnapshot? locationSnapshot;

  CheckInRequest({
    required this.id,
    required this.familyId,
    required this.requesterUserId,
    required this.targetUserId,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.respondedAt,
    this.reason,
    this.autoApproved = false,
    this.locationSnapshot,
  });

  factory CheckInRequest.fromJson(Map<String, dynamic> json) =>
      _$CheckInRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CheckInRequestToJson(this);

  CheckInRequest copyWith({
    CheckInRequestStatus? status,
    DateTime? respondedAt,
    CheckInLocationSnapshot? locationSnapshot,
    bool? autoApproved,
  }) {
    return CheckInRequest(
      id: id,
      familyId: familyId,
      requesterUserId: requesterUserId,
      targetUserId: targetUserId,
      status: status ?? this.status,
      createdAt: createdAt,
      expiresAt: expiresAt,
      respondedAt: respondedAt ?? this.respondedAt,
      reason: reason,
      autoApproved: autoApproved ?? this.autoApproved,
      locationSnapshot: locationSnapshot ?? this.locationSnapshot,
    );
  }

  static CheckInRequest newPending({
    required String familyId,
    required String requesterUserId,
    required String targetUserId,
    String? reason,
    Duration ttl = const Duration(days: 7),
    bool autoApproved = false,
  }) {
    final now = DateTime.now();
    return CheckInRequest(
      id: FirebaseFirestore.instance.collection('check_in_requests').doc().id,
      familyId: familyId,
      requesterUserId: requesterUserId,
      targetUserId: targetUserId,
      // Always start as pending; autoApproved recipients auto-respond client-side
      status: CheckInRequestStatus.pending,
      createdAt: now,
      expiresAt: now.add(ttl),
      reason: reason,
      autoApproved: autoApproved,
      respondedAt: null,
    );
  }
}
