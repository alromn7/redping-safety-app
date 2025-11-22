import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'sar_identity.g.dart';

/// SAR member identity and credentials
@JsonSerializable()
class SARIdentity extends Equatable {
  final String id;
  final String userId;
  final SARMemberType memberType;
  final SARVerificationStatus verificationStatus;
  final PersonalInfo personalInfo;
  final List<SARCredential> credentials;
  final List<SARCertification> certifications;
  final SARExperience experience;
  final DateTime registrationDate;
  final DateTime? verificationDate;
  final DateTime? expirationDate;
  final String? verifiedBy;
  final List<String> photoIds;
  final bool isActive;
  final String? notes;

  const SARIdentity({
    required this.id,
    required this.userId,
    required this.memberType,
    required this.verificationStatus,
    required this.personalInfo,
    required this.credentials,
    required this.certifications,
    required this.experience,
    required this.registrationDate,
    this.verificationDate,
    this.expirationDate,
    this.verifiedBy,
    required this.photoIds,
    this.isActive = true,
    this.notes,
  });

  factory SARIdentity.fromJson(Map<String, dynamic> json) =>
      _$SARIdentityFromJson(json);

  Map<String, dynamic> toJson() => _$SARIdentityToJson(this);

  SARIdentity copyWith({
    String? id,
    String? userId,
    SARMemberType? memberType,
    SARVerificationStatus? verificationStatus,
    PersonalInfo? personalInfo,
    List<SARCredential>? credentials,
    List<SARCertification>? certifications,
    SARExperience? experience,
    DateTime? registrationDate,
    DateTime? verificationDate,
    DateTime? expirationDate,
    String? verifiedBy,
    List<String>? photoIds,
    bool? isActive,
    String? notes,
  }) {
    return SARIdentity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      memberType: memberType ?? this.memberType,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      personalInfo: personalInfo ?? this.personalInfo,
      credentials: credentials ?? this.credentials,
      certifications: certifications ?? this.certifications,
      experience: experience ?? this.experience,
      registrationDate: registrationDate ?? this.registrationDate,
      verificationDate: verificationDate ?? this.verificationDate,
      expirationDate: expirationDate ?? this.expirationDate,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      photoIds: photoIds ?? this.photoIds,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    memberType,
    verificationStatus,
    personalInfo,
    credentials,
    certifications,
    experience,
    registrationDate,
    verificationDate,
    expirationDate,
    verifiedBy,
    photoIds,
    isActive,
    notes,
  ];
}

/// Personal information for SAR member
@JsonSerializable()
class PersonalInfo extends Equatable {
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String phoneNumber;
  final String email;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final String? emergencyContact;
  final String? emergencyPhone;

  const PersonalInfo({
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.phoneNumber,
    required this.email,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    this.emergencyContact,
    this.emergencyPhone,
  });

  factory PersonalInfo.fromJson(Map<String, dynamic> json) =>
      _$PersonalInfoFromJson(json);

  Map<String, dynamic> toJson() => _$PersonalInfoToJson(this);

  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    dateOfBirth,
    phoneNumber,
    email,
    address,
    city,
    state,
    zipCode,
    country,
    emergencyContact,
    emergencyPhone,
  ];
}

/// SAR credential document
@JsonSerializable()
class SARCredential extends Equatable {
  final String id;
  final SARCredentialType type;
  final String documentNumber;
  final String issuingAuthority;
  final DateTime issueDate;
  final DateTime expirationDate;
  final String photoPath;
  final SARVerificationStatus verificationStatus;
  final DateTime? verificationDate;
  final String? verifiedBy;
  final String? notes;

  const SARCredential({
    required this.id,
    required this.type,
    required this.documentNumber,
    required this.issuingAuthority,
    required this.issueDate,
    required this.expirationDate,
    required this.photoPath,
    required this.verificationStatus,
    this.verificationDate,
    this.verifiedBy,
    this.notes,
  });

  factory SARCredential.fromJson(Map<String, dynamic> json) =>
      _$SARCredentialFromJson(json);

  Map<String, dynamic> toJson() => _$SARCredentialToJson(this);

  bool get isExpired => DateTime.now().isAfter(expirationDate);
  bool get isValid =>
      verificationStatus == SARVerificationStatus.verified && !isExpired;

  @override
  List<Object?> get props => [
    id,
    type,
    documentNumber,
    issuingAuthority,
    issueDate,
    expirationDate,
    photoPath,
    verificationStatus,
    verificationDate,
    verifiedBy,
    notes,
  ];
}

/// SAR certification
@JsonSerializable()
class SARCertification extends Equatable {
  final String id;
  final SARCertificationType type;
  final String certificationName;
  final String issuingOrganization;
  final DateTime issueDate;
  final DateTime? expirationDate;
  final String certificateNumber;
  final String photoPath;
  final SARVerificationStatus verificationStatus;
  final DateTime? verificationDate;
  final String? verifiedBy;
  final List<String> specializations;
  final String? notes;

  const SARCertification({
    required this.id,
    required this.type,
    required this.certificationName,
    required this.issuingOrganization,
    required this.issueDate,
    this.expirationDate,
    required this.certificateNumber,
    required this.photoPath,
    required this.verificationStatus,
    this.verificationDate,
    this.verifiedBy,
    required this.specializations,
    this.notes,
  });

  factory SARCertification.fromJson(Map<String, dynamic> json) =>
      _$SARCertificationFromJson(json);

  Map<String, dynamic> toJson() => _$SARCertificationToJson(this);

  bool get isExpired =>
      expirationDate != null && DateTime.now().isAfter(expirationDate!);
  bool get isValid =>
      verificationStatus == SARVerificationStatus.verified && !isExpired;

  @override
  List<Object?> get props => [
    id,
    type,
    certificationName,
    issuingOrganization,
    issueDate,
    expirationDate,
    certificateNumber,
    photoPath,
    verificationStatus,
    verificationDate,
    verifiedBy,
    specializations,
    notes,
  ];
}

/// SAR experience information
@JsonSerializable()
class SARExperience extends Equatable {
  final int yearsOfExperience;
  final int numberOfMissions;
  final List<SARSpecialization> specializations;
  final List<String> previousOrganizations;
  final String? currentOrganization;
  final SARRank? rank;
  final List<String> equipmentProficiency;
  final List<String> terrainExperience;
  final String? additionalSkills;

  const SARExperience({
    required this.yearsOfExperience,
    required this.numberOfMissions,
    required this.specializations,
    required this.previousOrganizations,
    this.currentOrganization,
    this.rank,
    required this.equipmentProficiency,
    required this.terrainExperience,
    this.additionalSkills,
  });

  factory SARExperience.fromJson(Map<String, dynamic> json) =>
      _$SARExperienceFromJson(json);

  Map<String, dynamic> toJson() => _$SARExperienceToJson(this);

  SARExperience copyWith({
    int? yearsOfExperience,
    int? numberOfMissions,
    List<SARSpecialization>? specializations,
    List<String>? previousOrganizations,
    String? currentOrganization,
    SARRank? rank,
    List<String>? equipmentProficiency,
    List<String>? terrainExperience,
    String? additionalSkills,
  }) {
    return SARExperience(
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      numberOfMissions: numberOfMissions ?? this.numberOfMissions,
      specializations: specializations ?? this.specializations,
      previousOrganizations:
          previousOrganizations ?? this.previousOrganizations,
      currentOrganization: currentOrganization ?? this.currentOrganization,
      rank: rank ?? this.rank,
      equipmentProficiency: equipmentProficiency ?? this.equipmentProficiency,
      terrainExperience: terrainExperience ?? this.terrainExperience,
      additionalSkills: additionalSkills ?? this.additionalSkills,
    );
  }

  @override
  List<Object?> get props => [
    yearsOfExperience,
    numberOfMissions,
    specializations,
    previousOrganizations,
    currentOrganization,
    rank,
    equipmentProficiency,
    terrainExperience,
    additionalSkills,
  ];
}

/// Enums for SAR identity system

enum SARMemberType {
  @JsonValue('volunteer')
  volunteer,
  @JsonValue('professional')
  professional,
  @JsonValue('emergency_services')
  emergencyServices,
  @JsonValue('medical_personnel')
  medicalPersonnel,
  @JsonValue('team_leader')
  teamLeader,
  @JsonValue('coordinator')
  coordinator,
}

enum SARVerificationStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('under_review')
  underReview,
  @JsonValue('verified')
  verified,
  @JsonValue('rejected')
  rejected,
  @JsonValue('expired')
  expired,
  @JsonValue('suspended')
  suspended,
}

enum SARCredentialType {
  @JsonValue('drivers_license')
  driversLicense,
  @JsonValue('passport')
  passport,
  @JsonValue('state_id')
  stateId,
  @JsonValue('government_id')
  governmentId,
  @JsonValue('professional_license')
  professionalLicense,
  @JsonValue('background_check')
  backgroundCheck,
}

enum SARCertificationType {
  @JsonValue('wilderness_first_aid')
  wildernessFirstAid,
  @JsonValue('cpr_certification')
  cprCertification,
  @JsonValue('rescue_technician')
  rescueTechnician,
  @JsonValue('mountain_rescue')
  mountainRescue,
  @JsonValue('water_rescue')
  waterRescue,
  @JsonValue('technical_rescue')
  technicalRescue,
  @JsonValue('medical_training')
  medicalTraining,
  @JsonValue('incident_command')
  incidentCommand,
  @JsonValue('radio_operator')
  radioOperator,
  @JsonValue('search_management')
  searchManagement,
  @JsonValue('k9_handler')
  k9Handler,
  @JsonValue('aviation_rescue')
  aviationRescue,
}

enum SARSpecialization {
  @JsonValue('ground_search')
  groundSearch,
  @JsonValue('technical_rescue')
  technicalRescue,
  @JsonValue('water_rescue')
  waterRescue,
  @JsonValue('mountain_rescue')
  mountainRescue,
  @JsonValue('urban_rescue')
  urbanRescue,
  @JsonValue('medical_support')
  medicalSupport,
  @JsonValue('k9_search')
  k9Search,
  @JsonValue('aviation_support')
  aviationSupport,
  @JsonValue('communications')
  communications,
  @JsonValue('logistics')
  logistics,
  @JsonValue('command_control')
  commandControl,
}

enum SARRank {
  @JsonValue('trainee')
  trainee,
  @JsonValue('searcher')
  searcher,
  @JsonValue('senior_searcher')
  seniorSearcher,
  @JsonValue('team_leader')
  teamLeader,
  @JsonValue('section_leader')
  sectionLeader,
  @JsonValue('operations_leader')
  operationsLeader,
  @JsonValue('incident_commander')
  incidentCommander,
}
