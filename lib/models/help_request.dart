import 'package:equatable/equatable.dart';
import 'location_data.dart';
import 'help_response.dart';

/// Model representing a help request in the REDP!NG system
class HelpRequest extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String? userPhone;
  final String? userEmail;
  final String categoryId;
  final String? subCategoryId;
  final String description;
  final String? additionalInfo;
  final LocationData location;
  final HelpRequestStatus status;
  final HelpPriority priority;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> attachments;
  final List<String> assignedHelpers;
  final List<HelpResponse> responses;

  const HelpRequest({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhone,
    this.userEmail,
    required this.categoryId,
    this.subCategoryId,
    required this.description,
    this.additionalInfo,
    required this.location,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.attachments = const [],
    this.assignedHelpers = const [],
    this.responses = const [],
  });

  /// Create a copy of this help request with updated fields
  HelpRequest copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    String? userEmail,
    String? categoryId,
    String? subCategoryId,
    String? description,
    String? additionalInfo,
    LocationData? location,
    HelpRequestStatus? status,
    HelpPriority? priority,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? attachments,
    List<String>? assignedHelpers,
    List<HelpResponse>? responses,
  }) {
    return HelpRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      userEmail: userEmail ?? this.userEmail,
      categoryId: categoryId ?? this.categoryId,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      description: description ?? this.description,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      location: location ?? this.location,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachments: attachments ?? this.attachments,
      assignedHelpers: assignedHelpers ?? this.assignedHelpers,
      responses: responses ?? this.responses,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'phoneNumber': userPhone,
      'phone': userPhone,
      'userEmail': userEmail,
      'categoryId': categoryId,
      'subCategoryId': subCategoryId,
      'description': description,
      'additionalInfo': additionalInfo,
      'location': location.toJson(),
      'status': status.name,
      'priority': priority.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'attachments': attachments,
      'assignedHelpers': assignedHelpers,
      'responses': responses.map((r) => r.toJson()).toList(),
    };
  }

  /// Create from JSON
  factory HelpRequest.fromJson(Map<String, dynamic> json) {
    return HelpRequest(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userPhone:
          json['userPhone'] as String? ??
          json['phoneNumber'] as String? ??
          json['phone'] as String?,
      userEmail: json['userEmail'] as String?,
      categoryId: json['categoryId'] as String,
      subCategoryId: json['subCategoryId'] as String?,
      description: json['description'] as String,
      additionalInfo: json['additionalInfo'] as String?,
      location: LocationData.fromJson(json['location'] as Map<String, dynamic>),
      status: HelpRequestStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => HelpRequestStatus.active,
      ),
      priority: HelpPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => HelpPriority.low,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      attachments: List<String>.from(json['attachments'] ?? []),
      assignedHelpers: List<String>.from(json['assignedHelpers'] ?? []),
      responses:
          (json['responses'] as List<dynamic>?)
              ?.map((r) => HelpResponse.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    userName,
    userPhone,
    userEmail,
    categoryId,
    subCategoryId,
    description,
    additionalInfo,
    location,
    status,
    priority,
    createdAt,
    updatedAt,
    attachments,
    assignedHelpers,
    responses,
  ];
}

/// Status of a help request
enum HelpRequestStatus {
  active,
  assigned,
  inProgress,
  resolved,
  cancelled,
  expired,
}

/// Priority level of a help request
enum HelpPriority { low, medium, high, critical }
