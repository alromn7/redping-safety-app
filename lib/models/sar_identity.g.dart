// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sar_identity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SARIdentity _$SARIdentityFromJson(Map<String, dynamic> json) => SARIdentity(
      id: json['id'] as String,
      userId: json['userId'] as String,
      memberType: $enumDecode(_$SARMemberTypeEnumMap, json['memberType']),
      verificationStatus: $enumDecode(
          _$SARVerificationStatusEnumMap, json['verificationStatus']),
      personalInfo:
          PersonalInfo.fromJson(json['personalInfo'] as Map<String, dynamic>),
      credentials: (json['credentials'] as List<dynamic>)
          .map((e) => SARCredential.fromJson(e as Map<String, dynamic>))
          .toList(),
      certifications: (json['certifications'] as List<dynamic>)
          .map((e) => SARCertification.fromJson(e as Map<String, dynamic>))
          .toList(),
      experience:
          SARExperience.fromJson(json['experience'] as Map<String, dynamic>),
      registrationDate: DateTime.parse(json['registrationDate'] as String),
      verificationDate: json['verificationDate'] == null
          ? null
          : DateTime.parse(json['verificationDate'] as String),
      expirationDate: json['expirationDate'] == null
          ? null
          : DateTime.parse(json['expirationDate'] as String),
      verifiedBy: json['verifiedBy'] as String?,
      photoIds:
          (json['photoIds'] as List<dynamic>).map((e) => e as String).toList(),
      isActive: json['isActive'] as bool? ?? true,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$SARIdentityToJson(SARIdentity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'memberType': _$SARMemberTypeEnumMap[instance.memberType]!,
      'verificationStatus':
          _$SARVerificationStatusEnumMap[instance.verificationStatus]!,
      'personalInfo': instance.personalInfo,
      'credentials': instance.credentials,
      'certifications': instance.certifications,
      'experience': instance.experience,
      'registrationDate': instance.registrationDate.toIso8601String(),
      'verificationDate': instance.verificationDate?.toIso8601String(),
      'expirationDate': instance.expirationDate?.toIso8601String(),
      'verifiedBy': instance.verifiedBy,
      'photoIds': instance.photoIds,
      'isActive': instance.isActive,
      'notes': instance.notes,
    };

const _$SARMemberTypeEnumMap = {
  SARMemberType.volunteer: 'volunteer',
  SARMemberType.professional: 'professional',
  SARMemberType.emergencyServices: 'emergency_services',
  SARMemberType.medicalPersonnel: 'medical_personnel',
  SARMemberType.teamLeader: 'team_leader',
  SARMemberType.coordinator: 'coordinator',
};

const _$SARVerificationStatusEnumMap = {
  SARVerificationStatus.pending: 'pending',
  SARVerificationStatus.underReview: 'under_review',
  SARVerificationStatus.verified: 'verified',
  SARVerificationStatus.rejected: 'rejected',
  SARVerificationStatus.expired: 'expired',
  SARVerificationStatus.suspended: 'suspended',
};

PersonalInfo _$PersonalInfoFromJson(Map<String, dynamic> json) => PersonalInfo(
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      zipCode: json['zipCode'] as String,
      country: json['country'] as String,
      emergencyContact: json['emergencyContact'] as String?,
      emergencyPhone: json['emergencyPhone'] as String?,
    );

Map<String, dynamic> _$PersonalInfoToJson(PersonalInfo instance) =>
    <String, dynamic>{
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'dateOfBirth': instance.dateOfBirth.toIso8601String(),
      'phoneNumber': instance.phoneNumber,
      'email': instance.email,
      'address': instance.address,
      'city': instance.city,
      'state': instance.state,
      'zipCode': instance.zipCode,
      'country': instance.country,
      'emergencyContact': instance.emergencyContact,
      'emergencyPhone': instance.emergencyPhone,
    };

SARCredential _$SARCredentialFromJson(Map<String, dynamic> json) =>
    SARCredential(
      id: json['id'] as String,
      type: $enumDecode(_$SARCredentialTypeEnumMap, json['type']),
      documentNumber: json['documentNumber'] as String,
      issuingAuthority: json['issuingAuthority'] as String,
      issueDate: DateTime.parse(json['issueDate'] as String),
      expirationDate: DateTime.parse(json['expirationDate'] as String),
      photoPath: json['photoPath'] as String,
      verificationStatus: $enumDecode(
          _$SARVerificationStatusEnumMap, json['verificationStatus']),
      verificationDate: json['verificationDate'] == null
          ? null
          : DateTime.parse(json['verificationDate'] as String),
      verifiedBy: json['verifiedBy'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$SARCredentialToJson(SARCredential instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$SARCredentialTypeEnumMap[instance.type]!,
      'documentNumber': instance.documentNumber,
      'issuingAuthority': instance.issuingAuthority,
      'issueDate': instance.issueDate.toIso8601String(),
      'expirationDate': instance.expirationDate.toIso8601String(),
      'photoPath': instance.photoPath,
      'verificationStatus':
          _$SARVerificationStatusEnumMap[instance.verificationStatus]!,
      'verificationDate': instance.verificationDate?.toIso8601String(),
      'verifiedBy': instance.verifiedBy,
      'notes': instance.notes,
    };

const _$SARCredentialTypeEnumMap = {
  SARCredentialType.driversLicense: 'drivers_license',
  SARCredentialType.passport: 'passport',
  SARCredentialType.stateId: 'state_id',
  SARCredentialType.governmentId: 'government_id',
  SARCredentialType.professionalLicense: 'professional_license',
  SARCredentialType.backgroundCheck: 'background_check',
};

SARCertification _$SARCertificationFromJson(Map<String, dynamic> json) =>
    SARCertification(
      id: json['id'] as String,
      type: $enumDecode(_$SARCertificationTypeEnumMap, json['type']),
      certificationName: json['certificationName'] as String,
      issuingOrganization: json['issuingOrganization'] as String,
      issueDate: DateTime.parse(json['issueDate'] as String),
      expirationDate: json['expirationDate'] == null
          ? null
          : DateTime.parse(json['expirationDate'] as String),
      certificateNumber: json['certificateNumber'] as String,
      photoPath: json['photoPath'] as String,
      verificationStatus: $enumDecode(
          _$SARVerificationStatusEnumMap, json['verificationStatus']),
      verificationDate: json['verificationDate'] == null
          ? null
          : DateTime.parse(json['verificationDate'] as String),
      verifiedBy: json['verifiedBy'] as String?,
      specializations: (json['specializations'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$SARCertificationToJson(SARCertification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$SARCertificationTypeEnumMap[instance.type]!,
      'certificationName': instance.certificationName,
      'issuingOrganization': instance.issuingOrganization,
      'issueDate': instance.issueDate.toIso8601String(),
      'expirationDate': instance.expirationDate?.toIso8601String(),
      'certificateNumber': instance.certificateNumber,
      'photoPath': instance.photoPath,
      'verificationStatus':
          _$SARVerificationStatusEnumMap[instance.verificationStatus]!,
      'verificationDate': instance.verificationDate?.toIso8601String(),
      'verifiedBy': instance.verifiedBy,
      'specializations': instance.specializations,
      'notes': instance.notes,
    };

const _$SARCertificationTypeEnumMap = {
  SARCertificationType.wildernessFirstAid: 'wilderness_first_aid',
  SARCertificationType.cprCertification: 'cpr_certification',
  SARCertificationType.rescueTechnician: 'rescue_technician',
  SARCertificationType.mountainRescue: 'mountain_rescue',
  SARCertificationType.waterRescue: 'water_rescue',
  SARCertificationType.technicalRescue: 'technical_rescue',
  SARCertificationType.medicalTraining: 'medical_training',
  SARCertificationType.incidentCommand: 'incident_command',
  SARCertificationType.radioOperator: 'radio_operator',
  SARCertificationType.searchManagement: 'search_management',
  SARCertificationType.k9Handler: 'k9_handler',
  SARCertificationType.aviationRescue: 'aviation_rescue',
};

SARExperience _$SARExperienceFromJson(Map<String, dynamic> json) =>
    SARExperience(
      yearsOfExperience: (json['yearsOfExperience'] as num).toInt(),
      numberOfMissions: (json['numberOfMissions'] as num).toInt(),
      specializations: (json['specializations'] as List<dynamic>)
          .map((e) => $enumDecode(_$SARSpecializationEnumMap, e))
          .toList(),
      previousOrganizations: (json['previousOrganizations'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      currentOrganization: json['currentOrganization'] as String?,
      rank: $enumDecodeNullable(_$SARRankEnumMap, json['rank']),
      equipmentProficiency: (json['equipmentProficiency'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      terrainExperience: (json['terrainExperience'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      additionalSkills: json['additionalSkills'] as String?,
    );

Map<String, dynamic> _$SARExperienceToJson(SARExperience instance) =>
    <String, dynamic>{
      'yearsOfExperience': instance.yearsOfExperience,
      'numberOfMissions': instance.numberOfMissions,
      'specializations': instance.specializations
          .map((e) => _$SARSpecializationEnumMap[e]!)
          .toList(),
      'previousOrganizations': instance.previousOrganizations,
      'currentOrganization': instance.currentOrganization,
      'rank': _$SARRankEnumMap[instance.rank],
      'equipmentProficiency': instance.equipmentProficiency,
      'terrainExperience': instance.terrainExperience,
      'additionalSkills': instance.additionalSkills,
    };

const _$SARSpecializationEnumMap = {
  SARSpecialization.groundSearch: 'ground_search',
  SARSpecialization.technicalRescue: 'technical_rescue',
  SARSpecialization.waterRescue: 'water_rescue',
  SARSpecialization.mountainRescue: 'mountain_rescue',
  SARSpecialization.urbanRescue: 'urban_rescue',
  SARSpecialization.medicalSupport: 'medical_support',
  SARSpecialization.k9Search: 'k9_search',
  SARSpecialization.aviationSupport: 'aviation_support',
  SARSpecialization.communications: 'communications',
  SARSpecialization.logistics: 'logistics',
  SARSpecialization.commandControl: 'command_control',
};

const _$SARRankEnumMap = {
  SARRank.trainee: 'trainee',
  SARRank.searcher: 'searcher',
  SARRank.seniorSearcher: 'senior_searcher',
  SARRank.teamLeader: 'team_leader',
  SARRank.sectionLeader: 'section_leader',
  SARRank.operationsLeader: 'operations_leader',
  SARRank.incidentCommander: 'incident_commander',
};
