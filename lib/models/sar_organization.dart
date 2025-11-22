import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'sar_identity.dart';

part 'sar_organization.g.dart';

/// SAR Organization registration and management
@JsonSerializable()
class SAROrganization extends Equatable {
  final String id;
  final String organizationName;
  final SAROrganizationType type;
  final SAROrganizationInfo organizationInfo;
  final SARLegalInfo legalInfo;
  final SARContactInfo contactInfo;
  final SARCapabilities capabilities;
  final List<SAROrganizationCredential> credentials;
  final List<SAROrganizationCertification> certifications;
  final SARVerificationStatus verificationStatus;
  final DateTime registrationDate;
  final DateTime? verificationDate;
  final DateTime? expirationDate;
  final String? verifiedBy;
  final String? adminNotes;
  final bool isActive;
  final List<String> memberIds;
  final List<String> adminIds;
  final SAROperationalStatus operationalStatus;

  const SAROrganization({
    required this.id,
    required this.organizationName,
    required this.type,
    required this.organizationInfo,
    required this.legalInfo,
    required this.contactInfo,
    required this.capabilities,
    this.credentials = const [],
    this.certifications = const [],
    this.verificationStatus = SARVerificationStatus.pending,
    required this.registrationDate,
    this.verificationDate,
    this.expirationDate,
    this.verifiedBy,
    this.adminNotes,
    this.isActive = true,
    this.memberIds = const [],
    this.adminIds = const [],
    this.operationalStatus = SAROperationalStatus.standby,
  });

  factory SAROrganization.fromJson(Map<String, dynamic> json) =>
      _$SAROrganizationFromJson(json);

  Map<String, dynamic> toJson() => _$SAROrganizationToJson(this);

  SAROrganization copyWith({
    String? organizationName,
    SAROrganizationType? type,
    SAROrganizationInfo? organizationInfo,
    SARLegalInfo? legalInfo,
    SARContactInfo? contactInfo,
    SARCapabilities? capabilities,
    List<SAROrganizationCredential>? credentials,
    List<SAROrganizationCertification>? certifications,
    SARVerificationStatus? verificationStatus,
    DateTime? verificationDate,
    DateTime? expirationDate,
    String? verifiedBy,
    String? adminNotes,
    bool? isActive,
    List<String>? memberIds,
    List<String>? adminIds,
    SAROperationalStatus? operationalStatus,
  }) {
    return SAROrganization(
      id: id,
      organizationName: organizationName ?? this.organizationName,
      type: type ?? this.type,
      organizationInfo: organizationInfo ?? this.organizationInfo,
      legalInfo: legalInfo ?? this.legalInfo,
      contactInfo: contactInfo ?? this.contactInfo,
      capabilities: capabilities ?? this.capabilities,
      credentials: credentials ?? this.credentials,
      certifications: certifications ?? this.certifications,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      registrationDate: registrationDate,
      verificationDate: verificationDate ?? this.verificationDate,
      expirationDate: expirationDate ?? this.expirationDate,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      adminNotes: adminNotes ?? this.adminNotes,
      isActive: isActive ?? this.isActive,
      memberIds: memberIds ?? this.memberIds,
      adminIds: adminIds ?? this.adminIds,
      operationalStatus: operationalStatus ?? this.operationalStatus,
    );
  }

  @override
  List<Object?> get props => [
    id,
    organizationName,
    type,
    organizationInfo,
    legalInfo,
    contactInfo,
    capabilities,
    credentials,
    certifications,
    verificationStatus,
    registrationDate,
    verificationDate,
    expirationDate,
    verifiedBy,
    adminNotes,
    isActive,
    memberIds,
    adminIds,
    operationalStatus,
  ];
}

/// Organization basic information
@JsonSerializable()
class SAROrganizationInfo extends Equatable {
  final String description;
  final String website;
  final int foundedYear;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final String primaryLanguage;
  final List<String> serviceAreas;
  final int estimatedMemberCount;
  final List<SARSpecialization> specializations;

  const SAROrganizationInfo({
    required this.description,
    required this.website,
    required this.foundedYear,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    required this.primaryLanguage,
    required this.serviceAreas,
    required this.estimatedMemberCount,
    required this.specializations,
  });

  factory SAROrganizationInfo.fromJson(Map<String, dynamic> json) =>
      _$SAROrganizationInfoFromJson(json);

  Map<String, dynamic> toJson() => _$SAROrganizationInfoToJson(this);

  @override
  List<Object?> get props => [
    description,
    website,
    foundedYear,
    address,
    city,
    state,
    zipCode,
    country,
    primaryLanguage,
    serviceAreas,
    estimatedMemberCount,
    specializations,
  ];
}

/// Legal and regulatory information
@JsonSerializable()
class SARLegalInfo extends Equatable {
  final String legalName;
  final String registrationNumber;
  final String taxId;
  final SARLegalStatus legalStatus;
  final String jurisdiction;
  final List<String> licenses;
  final List<String> accreditations;
  final bool hasInsurance;
  final String? insuranceProvider;
  final String? insurancePolicyNumber;
  final DateTime? insuranceExpiration;

  const SARLegalInfo({
    required this.legalName,
    required this.registrationNumber,
    required this.taxId,
    required this.legalStatus,
    required this.jurisdiction,
    required this.licenses,
    required this.accreditations,
    required this.hasInsurance,
    this.insuranceProvider,
    this.insurancePolicyNumber,
    this.insuranceExpiration,
  });

  factory SARLegalInfo.fromJson(Map<String, dynamic> json) =>
      _$SARLegalInfoFromJson(json);

  Map<String, dynamic> toJson() => _$SARLegalInfoToJson(this);

  @override
  List<Object?> get props => [
    legalName,
    registrationNumber,
    taxId,
    legalStatus,
    jurisdiction,
    licenses,
    accreditations,
    hasInsurance,
    insuranceProvider,
    insurancePolicyNumber,
    insuranceExpiration,
  ];
}

/// Organization contact information
@JsonSerializable()
class SARContactInfo extends Equatable {
  final String primaryPhone;
  final String? secondaryPhone;
  final String email;
  final String? emergencyEmail;
  final String primaryContactName;
  final String primaryContactTitle;
  final String? dispatchCenter;
  final String? radioCallsign;
  final List<String> communicationChannels;

  const SARContactInfo({
    required this.primaryPhone,
    this.secondaryPhone,
    required this.email,
    this.emergencyEmail,
    required this.primaryContactName,
    required this.primaryContactTitle,
    this.dispatchCenter,
    this.radioCallsign,
    required this.communicationChannels,
  });

  factory SARContactInfo.fromJson(Map<String, dynamic> json) =>
      _$SARContactInfoFromJson(json);

  Map<String, dynamic> toJson() => _$SARContactInfoToJson(this);

  @override
  List<Object?> get props => [
    primaryPhone,
    secondaryPhone,
    email,
    emergencyEmail,
    primaryContactName,
    primaryContactTitle,
    dispatchCenter,
    radioCallsign,
    communicationChannels,
  ];
}

/// Organization capabilities and resources
@JsonSerializable()
class SARCapabilities extends Equatable {
  final List<SARSpecialization> primarySpecializations;
  final List<String> equipment;
  final List<String> vehicles;
  final bool has24x7Availability;
  final int maxMemberDeployment;
  final List<String> responseAreas;
  final int averageResponseTime; // in minutes
  final bool hasTrainingPrograms;
  final bool providesPublicEducation;
  final List<String> partnerships;

  const SARCapabilities({
    required this.primarySpecializations,
    required this.equipment,
    required this.vehicles,
    required this.has24x7Availability,
    required this.maxMemberDeployment,
    required this.responseAreas,
    required this.averageResponseTime,
    required this.hasTrainingPrograms,
    required this.providesPublicEducation,
    required this.partnerships,
  });

  factory SARCapabilities.fromJson(Map<String, dynamic> json) =>
      _$SARCapabilitiesFromJson(json);

  Map<String, dynamic> toJson() => _$SARCapabilitiesToJson(this);

  @override
  List<Object?> get props => [
    primarySpecializations,
    equipment,
    vehicles,
    has24x7Availability,
    maxMemberDeployment,
    responseAreas,
    averageResponseTime,
    hasTrainingPrograms,
    providesPublicEducation,
    partnerships,
  ];
}

/// Organization credential document
@JsonSerializable()
class SAROrganizationCredential extends Equatable {
  final String id;
  final SAROrganizationCredentialType type;
  final String documentName;
  final String documentNumber;
  final DateTime issueDate;
  final DateTime expirationDate;
  final String issuingAuthority;
  final String documentPath;
  final SARVerificationStatus verificationStatus;
  final String? adminNotes;

  const SAROrganizationCredential({
    required this.id,
    required this.type,
    required this.documentName,
    required this.documentNumber,
    required this.issueDate,
    required this.expirationDate,
    required this.issuingAuthority,
    required this.documentPath,
    this.verificationStatus = SARVerificationStatus.pending,
    this.adminNotes,
  });

  factory SAROrganizationCredential.fromJson(Map<String, dynamic> json) =>
      _$SAROrganizationCredentialFromJson(json);

  Map<String, dynamic> toJson() => _$SAROrganizationCredentialToJson(this);

  bool get isExpired => DateTime.now().isAfter(expirationDate);

  @override
  List<Object?> get props => [
    id,
    type,
    documentName,
    documentNumber,
    issueDate,
    expirationDate,
    issuingAuthority,
    documentPath,
    verificationStatus,
    adminNotes,
  ];
}

/// Organization certification
@JsonSerializable()
class SAROrganizationCertification extends Equatable {
  final String id;
  final SAROrganizationCertificationType type;
  final String certificationName;
  final String certificateNumber;
  final DateTime issueDate;
  final DateTime? expirationDate;
  final String issuingBody;
  final String documentPath;
  final SARVerificationStatus verificationStatus;
  final String? adminNotes;

  const SAROrganizationCertification({
    required this.id,
    required this.type,
    required this.certificationName,
    required this.certificateNumber,
    required this.issueDate,
    this.expirationDate,
    required this.issuingBody,
    required this.documentPath,
    this.verificationStatus = SARVerificationStatus.pending,
    this.adminNotes,
  });

  factory SAROrganizationCertification.fromJson(Map<String, dynamic> json) =>
      _$SAROrganizationCertificationFromJson(json);

  Map<String, dynamic> toJson() => _$SAROrganizationCertificationToJson(this);

  bool get isExpired =>
      expirationDate != null && DateTime.now().isAfter(expirationDate!);

  @override
  List<Object?> get props => [
    id,
    type,
    certificationName,
    certificateNumber,
    issueDate,
    expirationDate,
    issuingBody,
    documentPath,
    verificationStatus,
    adminNotes,
  ];
}

/// Organization member with role and status
@JsonSerializable()
class SAROrganizationMember extends Equatable {
  final String id;
  final String userId;
  final String organizationId;
  final String memberName;
  final String? memberEmail;
  final String? memberPhone;
  final SARMemberRole role;
  final SARMemberStatus status;
  final DateTime joinedDate;
  final DateTime? lastActiveDate;
  final List<SARSpecialization> specializations;
  final List<String> certifications;
  final bool isActive;
  final String? notes;

  const SAROrganizationMember({
    required this.id,
    required this.userId,
    required this.organizationId,
    required this.memberName,
    this.memberEmail,
    this.memberPhone,
    required this.role,
    required this.status,
    required this.joinedDate,
    this.lastActiveDate,
    required this.specializations,
    required this.certifications,
    this.isActive = true,
    this.notes,
  });

  factory SAROrganizationMember.fromJson(Map<String, dynamic> json) =>
      _$SAROrganizationMemberFromJson(json);

  Map<String, dynamic> toJson() => _$SAROrganizationMemberToJson(this);

  @override
  List<Object?> get props => [
    id,
    userId,
    organizationId,
    memberName,
    memberEmail,
    memberPhone,
    role,
    status,
    joinedDate,
    lastActiveDate,
    specializations,
    certifications,
    isActive,
    notes,
  ];
}

/// Rescue operation managed by organization
@JsonSerializable()
class SAROrganizationOperation extends Equatable {
  final String id;
  final String organizationId;
  final String operationName;
  final SAROperationType type;
  final SAROperationStatus status;
  final SAROperationPriority priority;
  final DateTime startTime;
  final DateTime? endTime;
  final SAROperationLocation location;
  final String description;
  final String? subjectInfo;
  final List<String> assignedMemberIds;
  final List<String> resourcesDeployed;
  final SARWeatherConditions? weatherConditions;
  final List<SAROperationUpdate> updates;
  final SAROperationOutcome? outcome;
  final String? incidentCommanderId;
  final List<String> coordinatingAgencies;

  const SAROrganizationOperation({
    required this.id,
    required this.organizationId,
    required this.operationName,
    required this.type,
    required this.status,
    required this.priority,
    required this.startTime,
    this.endTime,
    required this.location,
    required this.description,
    this.subjectInfo,
    required this.assignedMemberIds,
    required this.resourcesDeployed,
    this.weatherConditions,
    required this.updates,
    this.outcome,
    this.incidentCommanderId,
    required this.coordinatingAgencies,
  });

  factory SAROrganizationOperation.fromJson(Map<String, dynamic> json) =>
      _$SAROrganizationOperationFromJson(json);

  Map<String, dynamic> toJson() => _$SAROrganizationOperationToJson(this);

  Duration? get duration => endTime?.difference(startTime);

  SAROrganizationOperation copyWith({
    String? operationName,
    SAROperationType? type,
    SAROperationStatus? status,
    SAROperationPriority? priority,
    DateTime? endTime,
    SAROperationLocation? location,
    String? description,
    String? subjectInfo,
    List<String>? assignedMemberIds,
    List<String>? resourcesDeployed,
    SARWeatherConditions? weatherConditions,
    List<SAROperationUpdate>? updates,
    SAROperationOutcome? outcome,
    String? incidentCommanderId,
    List<String>? coordinatingAgencies,
  }) {
    return SAROrganizationOperation(
      id: id,
      organizationId: organizationId,
      operationName: operationName ?? this.operationName,
      type: type ?? this.type,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      description: description ?? this.description,
      subjectInfo: subjectInfo ?? this.subjectInfo,
      assignedMemberIds: assignedMemberIds ?? this.assignedMemberIds,
      resourcesDeployed: resourcesDeployed ?? this.resourcesDeployed,
      weatherConditions: weatherConditions ?? this.weatherConditions,
      updates: updates ?? this.updates,
      outcome: outcome ?? this.outcome,
      incidentCommanderId: incidentCommanderId ?? this.incidentCommanderId,
      coordinatingAgencies: coordinatingAgencies ?? this.coordinatingAgencies,
    );
  }

  @override
  List<Object?> get props => [
    id,
    organizationId,
    operationName,
    type,
    status,
    priority,
    startTime,
    endTime,
    location,
    description,
    subjectInfo,
    assignedMemberIds,
    resourcesDeployed,
    weatherConditions,
    updates,
    outcome,
    incidentCommanderId,
    coordinatingAgencies,
  ];
}

/// Operation location information
@JsonSerializable()
class SAROperationLocation extends Equatable {
  final double latitude;
  final double longitude;
  final String? locationName;
  final String? address;
  final double? searchRadius; // in meters
  final String? terrain;
  final int? elevation; // in meters
  final String? accessInfo;

  const SAROperationLocation({
    required this.latitude,
    required this.longitude,
    this.locationName,
    this.address,
    this.searchRadius,
    this.terrain,
    this.elevation,
    this.accessInfo,
  });

  factory SAROperationLocation.fromJson(Map<String, dynamic> json) =>
      _$SAROperationLocationFromJson(json);

  Map<String, dynamic> toJson() => _$SAROperationLocationToJson(this);

  @override
  List<Object?> get props => [
    latitude,
    longitude,
    locationName,
    address,
    searchRadius,
    terrain,
    elevation,
    accessInfo,
  ];
}

/// Weather conditions for operation
@JsonSerializable()
class SARWeatherConditions extends Equatable {
  final double temperature; // Celsius
  final String conditions;
  final double? windSpeed; // km/h
  final String? windDirection;
  final double? visibility; // km
  final double? precipitation; // mm
  final String? alerts;

  const SARWeatherConditions({
    required this.temperature,
    required this.conditions,
    this.windSpeed,
    this.windDirection,
    this.visibility,
    this.precipitation,
    this.alerts,
  });

  factory SARWeatherConditions.fromJson(Map<String, dynamic> json) =>
      _$SARWeatherConditionsFromJson(json);

  Map<String, dynamic> toJson() => _$SARWeatherConditionsToJson(this);

  @override
  List<Object?> get props => [
    temperature,
    conditions,
    windSpeed,
    windDirection,
    visibility,
    precipitation,
    alerts,
  ];
}

/// Operation update/log entry
@JsonSerializable()
class SAROperationUpdate extends Equatable {
  final String id;
  final DateTime timestamp;
  final String updatedBy;
  final String update;
  final SARUpdateType type;
  final String? location;
  final List<String>? attachments;

  const SAROperationUpdate({
    required this.id,
    required this.timestamp,
    required this.updatedBy,
    required this.update,
    required this.type,
    this.location,
    this.attachments,
  });

  factory SAROperationUpdate.fromJson(Map<String, dynamic> json) =>
      _$SAROperationUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$SAROperationUpdateToJson(this);

  @override
  List<Object?> get props => [
    id,
    timestamp,
    updatedBy,
    update,
    type,
    location,
    attachments,
  ];
}

/// Operation outcome/result
@JsonSerializable()
class SAROperationOutcome extends Equatable {
  final SAROutcomeType type;
  final String description;
  final bool subjectFound;
  final String? subjectCondition;
  final int totalPersonnelDeployed;
  final int totalHoursSpent;
  final List<String> resourcesUsed;
  final String? lessonsLearned;
  final double? totalCost;

  const SAROperationOutcome({
    required this.type,
    required this.description,
    required this.subjectFound,
    this.subjectCondition,
    required this.totalPersonnelDeployed,
    required this.totalHoursSpent,
    required this.resourcesUsed,
    this.lessonsLearned,
    this.totalCost,
  });

  factory SAROperationOutcome.fromJson(Map<String, dynamic> json) =>
      _$SAROperationOutcomeFromJson(json);

  Map<String, dynamic> toJson() => _$SAROperationOutcomeToJson(this);

  @override
  List<Object?> get props => [
    type,
    description,
    subjectFound,
    subjectCondition,
    totalPersonnelDeployed,
    totalHoursSpent,
    resourcesUsed,
    lessonsLearned,
    totalCost,
  ];
}

// Enums for organization management

enum SAROrganizationType {
  @JsonValue('volunteer_nonprofit')
  volunteerNonprofit,
  @JsonValue('professional_rescue')
  professionalRescue,
  @JsonValue('government_agency')
  governmentAgency,
  @JsonValue('military_unit')
  militaryUnit,
  @JsonValue('private_company')
  privateCompany,
  @JsonValue('national_team')
  nationalTeam,
  @JsonValue('international_team')
  internationalTeam,
}

enum SARLegalStatus {
  @JsonValue('nonprofit_501c3')
  nonprofit501c3,
  @JsonValue('government_entity')
  governmentEntity,
  @JsonValue('private_corporation')
  privateCorporation,
  @JsonValue('partnership')
  partnership,
  @JsonValue('sole_proprietorship')
  soleProprietorship,
  @JsonValue('cooperative')
  cooperative,
}

enum SAROperationalStatus {
  @JsonValue('standby')
  standby,
  @JsonValue('active')
  active,
  @JsonValue('deployed')
  deployed,
  @JsonValue('training')
  training,
  @JsonValue('maintenance')
  maintenance,
  @JsonValue('unavailable')
  unavailable,
}

enum SARMemberRole {
  @JsonValue('admin')
  admin,
  @JsonValue('incident_commander')
  incidentCommander,
  @JsonValue('team_leader')
  teamLeader,
  @JsonValue('senior_member')
  seniorMember,
  @JsonValue('member')
  member,
  @JsonValue('trainee')
  trainee,
  @JsonValue('support')
  support,
}

enum SARMemberStatus {
  @JsonValue('active')
  active,
  @JsonValue('inactive')
  inactive,
  @JsonValue('training')
  training,
  @JsonValue('probationary')
  probationary,
  @JsonValue('suspended')
  suspended,
  @JsonValue('retired')
  retired,
}

enum SAROperationType {
  @JsonValue('search_rescue')
  searchRescue,
  @JsonValue('medical_emergency')
  medicalEmergency,
  @JsonValue('disaster_response')
  disasterResponse,
  @JsonValue('training_exercise')
  trainingExercise,
  @JsonValue('public_service')
  publicService,
  @JsonValue('mutual_aid')
  mutualAid,
}

enum SAROperationStatus {
  @JsonValue('planning')
  planning,
  @JsonValue('active')
  active,
  @JsonValue('suspended')
  suspended,
  @JsonValue('completed')
  completed,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('transferred')
  transferred,
}

enum SAROperationPriority {
  @JsonValue('low')
  low,
  @JsonValue('normal')
  normal,
  @JsonValue('high')
  high,
  @JsonValue('critical')
  critical,
  @JsonValue('emergency')
  emergency,
}

enum SARUpdateType {
  @JsonValue('status')
  status,
  @JsonValue('personnel')
  personnel,
  @JsonValue('location')
  location,
  @JsonValue('resource')
  resource,
  @JsonValue('weather')
  weather,
  @JsonValue('subject')
  subject,
  @JsonValue('command')
  command,
}

enum SAROutcomeType {
  @JsonValue('successful')
  successful,
  @JsonValue('unsuccessful')
  unsuccessful,
  @JsonValue('suspended')
  suspended,
  @JsonValue('transferred')
  transferred,
  @JsonValue('training_complete')
  trainingComplete,
}

enum SAROrganizationCredentialType {
  @JsonValue('business_license')
  businessLicense,
  @JsonValue('nonprofit_registration')
  nonprofitRegistration,
  @JsonValue('tax_exemption')
  taxExemption,
  @JsonValue('insurance_certificate')
  insuranceCertificate,
  @JsonValue('government_authorization')
  governmentAuthorization,
  @JsonValue('accreditation')
  accreditation,
}

enum SAROrganizationCertificationType {
  @JsonValue('sar_accreditation')
  sarAccreditation,
  @JsonValue('training_certification')
  trainingCertification,
  @JsonValue('safety_certification')
  safetyCertification,
  @JsonValue('quality_management')
  qualityManagement,
  @JsonValue('international_standard')
  internationalStandard,
  @JsonValue('government_certification')
  governmentCertification,
}

// Import enums from sar_identity.dart
// Note: SARVerificationStatus and SARSpecialization are defined in sar_identity.dart
