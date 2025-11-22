// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sar_organization.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SAROrganization _$SAROrganizationFromJson(Map<String, dynamic> json) =>
    SAROrganization(
      id: json['id'] as String,
      organizationName: json['organizationName'] as String,
      type: $enumDecode(_$SAROrganizationTypeEnumMap, json['type']),
      organizationInfo: SAROrganizationInfo.fromJson(
          json['organizationInfo'] as Map<String, dynamic>),
      legalInfo:
          SARLegalInfo.fromJson(json['legalInfo'] as Map<String, dynamic>),
      contactInfo:
          SARContactInfo.fromJson(json['contactInfo'] as Map<String, dynamic>),
      capabilities: SARCapabilities.fromJson(
          json['capabilities'] as Map<String, dynamic>),
      credentials: (json['credentials'] as List<dynamic>?)
              ?.map((e) =>
                  SAROrganizationCredential.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      certifications: (json['certifications'] as List<dynamic>?)
              ?.map((e) => SAROrganizationCertification.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          const [],
      verificationStatus: $enumDecodeNullable(
              _$SARVerificationStatusEnumMap, json['verificationStatus']) ??
          SARVerificationStatus.pending,
      registrationDate: DateTime.parse(json['registrationDate'] as String),
      verificationDate: json['verificationDate'] == null
          ? null
          : DateTime.parse(json['verificationDate'] as String),
      expirationDate: json['expirationDate'] == null
          ? null
          : DateTime.parse(json['expirationDate'] as String),
      verifiedBy: json['verifiedBy'] as String?,
      adminNotes: json['adminNotes'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      memberIds: (json['memberIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      adminIds: (json['adminIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      operationalStatus: $enumDecodeNullable(
              _$SAROperationalStatusEnumMap, json['operationalStatus']) ??
          SAROperationalStatus.standby,
    );

Map<String, dynamic> _$SAROrganizationToJson(SAROrganization instance) =>
    <String, dynamic>{
      'id': instance.id,
      'organizationName': instance.organizationName,
      'type': _$SAROrganizationTypeEnumMap[instance.type]!,
      'organizationInfo': instance.organizationInfo,
      'legalInfo': instance.legalInfo,
      'contactInfo': instance.contactInfo,
      'capabilities': instance.capabilities,
      'credentials': instance.credentials,
      'certifications': instance.certifications,
      'verificationStatus':
          _$SARVerificationStatusEnumMap[instance.verificationStatus]!,
      'registrationDate': instance.registrationDate.toIso8601String(),
      'verificationDate': instance.verificationDate?.toIso8601String(),
      'expirationDate': instance.expirationDate?.toIso8601String(),
      'verifiedBy': instance.verifiedBy,
      'adminNotes': instance.adminNotes,
      'isActive': instance.isActive,
      'memberIds': instance.memberIds,
      'adminIds': instance.adminIds,
      'operationalStatus':
          _$SAROperationalStatusEnumMap[instance.operationalStatus]!,
    };

const _$SAROrganizationTypeEnumMap = {
  SAROrganizationType.volunteerNonprofit: 'volunteer_nonprofit',
  SAROrganizationType.professionalRescue: 'professional_rescue',
  SAROrganizationType.governmentAgency: 'government_agency',
  SAROrganizationType.militaryUnit: 'military_unit',
  SAROrganizationType.privateCompany: 'private_company',
  SAROrganizationType.nationalTeam: 'national_team',
  SAROrganizationType.internationalTeam: 'international_team',
};

const _$SARVerificationStatusEnumMap = {
  SARVerificationStatus.pending: 'pending',
  SARVerificationStatus.underReview: 'under_review',
  SARVerificationStatus.verified: 'verified',
  SARVerificationStatus.rejected: 'rejected',
  SARVerificationStatus.expired: 'expired',
  SARVerificationStatus.suspended: 'suspended',
};

const _$SAROperationalStatusEnumMap = {
  SAROperationalStatus.standby: 'standby',
  SAROperationalStatus.active: 'active',
  SAROperationalStatus.deployed: 'deployed',
  SAROperationalStatus.training: 'training',
  SAROperationalStatus.maintenance: 'maintenance',
  SAROperationalStatus.unavailable: 'unavailable',
};

SAROrganizationInfo _$SAROrganizationInfoFromJson(Map<String, dynamic> json) =>
    SAROrganizationInfo(
      description: json['description'] as String,
      website: json['website'] as String,
      foundedYear: (json['foundedYear'] as num).toInt(),
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      zipCode: json['zipCode'] as String,
      country: json['country'] as String,
      primaryLanguage: json['primaryLanguage'] as String,
      serviceAreas: (json['serviceAreas'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      estimatedMemberCount: (json['estimatedMemberCount'] as num).toInt(),
      specializations: (json['specializations'] as List<dynamic>)
          .map((e) => $enumDecode(_$SARSpecializationEnumMap, e))
          .toList(),
    );

Map<String, dynamic> _$SAROrganizationInfoToJson(
        SAROrganizationInfo instance) =>
    <String, dynamic>{
      'description': instance.description,
      'website': instance.website,
      'foundedYear': instance.foundedYear,
      'address': instance.address,
      'city': instance.city,
      'state': instance.state,
      'zipCode': instance.zipCode,
      'country': instance.country,
      'primaryLanguage': instance.primaryLanguage,
      'serviceAreas': instance.serviceAreas,
      'estimatedMemberCount': instance.estimatedMemberCount,
      'specializations': instance.specializations
          .map((e) => _$SARSpecializationEnumMap[e]!)
          .toList(),
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

SARLegalInfo _$SARLegalInfoFromJson(Map<String, dynamic> json) => SARLegalInfo(
      legalName: json['legalName'] as String,
      registrationNumber: json['registrationNumber'] as String,
      taxId: json['taxId'] as String,
      legalStatus: $enumDecode(_$SARLegalStatusEnumMap, json['legalStatus']),
      jurisdiction: json['jurisdiction'] as String,
      licenses:
          (json['licenses'] as List<dynamic>).map((e) => e as String).toList(),
      accreditations: (json['accreditations'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      hasInsurance: json['hasInsurance'] as bool,
      insuranceProvider: json['insuranceProvider'] as String?,
      insurancePolicyNumber: json['insurancePolicyNumber'] as String?,
      insuranceExpiration: json['insuranceExpiration'] == null
          ? null
          : DateTime.parse(json['insuranceExpiration'] as String),
    );

Map<String, dynamic> _$SARLegalInfoToJson(SARLegalInfo instance) =>
    <String, dynamic>{
      'legalName': instance.legalName,
      'registrationNumber': instance.registrationNumber,
      'taxId': instance.taxId,
      'legalStatus': _$SARLegalStatusEnumMap[instance.legalStatus]!,
      'jurisdiction': instance.jurisdiction,
      'licenses': instance.licenses,
      'accreditations': instance.accreditations,
      'hasInsurance': instance.hasInsurance,
      'insuranceProvider': instance.insuranceProvider,
      'insurancePolicyNumber': instance.insurancePolicyNumber,
      'insuranceExpiration': instance.insuranceExpiration?.toIso8601String(),
    };

const _$SARLegalStatusEnumMap = {
  SARLegalStatus.nonprofit501c3: 'nonprofit_501c3',
  SARLegalStatus.governmentEntity: 'government_entity',
  SARLegalStatus.privateCorporation: 'private_corporation',
  SARLegalStatus.partnership: 'partnership',
  SARLegalStatus.soleProprietorship: 'sole_proprietorship',
  SARLegalStatus.cooperative: 'cooperative',
};

SARContactInfo _$SARContactInfoFromJson(Map<String, dynamic> json) =>
    SARContactInfo(
      primaryPhone: json['primaryPhone'] as String,
      secondaryPhone: json['secondaryPhone'] as String?,
      email: json['email'] as String,
      emergencyEmail: json['emergencyEmail'] as String?,
      primaryContactName: json['primaryContactName'] as String,
      primaryContactTitle: json['primaryContactTitle'] as String,
      dispatchCenter: json['dispatchCenter'] as String?,
      radioCallsign: json['radioCallsign'] as String?,
      communicationChannels: (json['communicationChannels'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$SARContactInfoToJson(SARContactInfo instance) =>
    <String, dynamic>{
      'primaryPhone': instance.primaryPhone,
      'secondaryPhone': instance.secondaryPhone,
      'email': instance.email,
      'emergencyEmail': instance.emergencyEmail,
      'primaryContactName': instance.primaryContactName,
      'primaryContactTitle': instance.primaryContactTitle,
      'dispatchCenter': instance.dispatchCenter,
      'radioCallsign': instance.radioCallsign,
      'communicationChannels': instance.communicationChannels,
    };

SARCapabilities _$SARCapabilitiesFromJson(Map<String, dynamic> json) =>
    SARCapabilities(
      primarySpecializations: (json['primarySpecializations'] as List<dynamic>)
          .map((e) => $enumDecode(_$SARSpecializationEnumMap, e))
          .toList(),
      equipment:
          (json['equipment'] as List<dynamic>).map((e) => e as String).toList(),
      vehicles:
          (json['vehicles'] as List<dynamic>).map((e) => e as String).toList(),
      has24x7Availability: json['has24x7Availability'] as bool,
      maxMemberDeployment: (json['maxMemberDeployment'] as num).toInt(),
      responseAreas: (json['responseAreas'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      averageResponseTime: (json['averageResponseTime'] as num).toInt(),
      hasTrainingPrograms: json['hasTrainingPrograms'] as bool,
      providesPublicEducation: json['providesPublicEducation'] as bool,
      partnerships: (json['partnerships'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$SARCapabilitiesToJson(SARCapabilities instance) =>
    <String, dynamic>{
      'primarySpecializations': instance.primarySpecializations
          .map((e) => _$SARSpecializationEnumMap[e]!)
          .toList(),
      'equipment': instance.equipment,
      'vehicles': instance.vehicles,
      'has24x7Availability': instance.has24x7Availability,
      'maxMemberDeployment': instance.maxMemberDeployment,
      'responseAreas': instance.responseAreas,
      'averageResponseTime': instance.averageResponseTime,
      'hasTrainingPrograms': instance.hasTrainingPrograms,
      'providesPublicEducation': instance.providesPublicEducation,
      'partnerships': instance.partnerships,
    };

SAROrganizationCredential _$SAROrganizationCredentialFromJson(
        Map<String, dynamic> json) =>
    SAROrganizationCredential(
      id: json['id'] as String,
      type: $enumDecode(_$SAROrganizationCredentialTypeEnumMap, json['type']),
      documentName: json['documentName'] as String,
      documentNumber: json['documentNumber'] as String,
      issueDate: DateTime.parse(json['issueDate'] as String),
      expirationDate: DateTime.parse(json['expirationDate'] as String),
      issuingAuthority: json['issuingAuthority'] as String,
      documentPath: json['documentPath'] as String,
      verificationStatus: $enumDecodeNullable(
              _$SARVerificationStatusEnumMap, json['verificationStatus']) ??
          SARVerificationStatus.pending,
      adminNotes: json['adminNotes'] as String?,
    );

Map<String, dynamic> _$SAROrganizationCredentialToJson(
        SAROrganizationCredential instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$SAROrganizationCredentialTypeEnumMap[instance.type]!,
      'documentName': instance.documentName,
      'documentNumber': instance.documentNumber,
      'issueDate': instance.issueDate.toIso8601String(),
      'expirationDate': instance.expirationDate.toIso8601String(),
      'issuingAuthority': instance.issuingAuthority,
      'documentPath': instance.documentPath,
      'verificationStatus':
          _$SARVerificationStatusEnumMap[instance.verificationStatus]!,
      'adminNotes': instance.adminNotes,
    };

const _$SAROrganizationCredentialTypeEnumMap = {
  SAROrganizationCredentialType.businessLicense: 'business_license',
  SAROrganizationCredentialType.nonprofitRegistration: 'nonprofit_registration',
  SAROrganizationCredentialType.taxExemption: 'tax_exemption',
  SAROrganizationCredentialType.insuranceCertificate: 'insurance_certificate',
  SAROrganizationCredentialType.governmentAuthorization:
      'government_authorization',
  SAROrganizationCredentialType.accreditation: 'accreditation',
};

SAROrganizationCertification _$SAROrganizationCertificationFromJson(
        Map<String, dynamic> json) =>
    SAROrganizationCertification(
      id: json['id'] as String,
      type:
          $enumDecode(_$SAROrganizationCertificationTypeEnumMap, json['type']),
      certificationName: json['certificationName'] as String,
      certificateNumber: json['certificateNumber'] as String,
      issueDate: DateTime.parse(json['issueDate'] as String),
      expirationDate: json['expirationDate'] == null
          ? null
          : DateTime.parse(json['expirationDate'] as String),
      issuingBody: json['issuingBody'] as String,
      documentPath: json['documentPath'] as String,
      verificationStatus: $enumDecodeNullable(
              _$SARVerificationStatusEnumMap, json['verificationStatus']) ??
          SARVerificationStatus.pending,
      adminNotes: json['adminNotes'] as String?,
    );

Map<String, dynamic> _$SAROrganizationCertificationToJson(
        SAROrganizationCertification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$SAROrganizationCertificationTypeEnumMap[instance.type]!,
      'certificationName': instance.certificationName,
      'certificateNumber': instance.certificateNumber,
      'issueDate': instance.issueDate.toIso8601String(),
      'expirationDate': instance.expirationDate?.toIso8601String(),
      'issuingBody': instance.issuingBody,
      'documentPath': instance.documentPath,
      'verificationStatus':
          _$SARVerificationStatusEnumMap[instance.verificationStatus]!,
      'adminNotes': instance.adminNotes,
    };

const _$SAROrganizationCertificationTypeEnumMap = {
  SAROrganizationCertificationType.sarAccreditation: 'sar_accreditation',
  SAROrganizationCertificationType.trainingCertification:
      'training_certification',
  SAROrganizationCertificationType.safetyCertification: 'safety_certification',
  SAROrganizationCertificationType.qualityManagement: 'quality_management',
  SAROrganizationCertificationType.internationalStandard:
      'international_standard',
  SAROrganizationCertificationType.governmentCertification:
      'government_certification',
};

SAROrganizationMember _$SAROrganizationMemberFromJson(
        Map<String, dynamic> json) =>
    SAROrganizationMember(
      id: json['id'] as String,
      userId: json['userId'] as String,
      organizationId: json['organizationId'] as String,
      memberName: json['memberName'] as String,
      memberEmail: json['memberEmail'] as String?,
      memberPhone: json['memberPhone'] as String?,
      role: $enumDecode(_$SARMemberRoleEnumMap, json['role']),
      status: $enumDecode(_$SARMemberStatusEnumMap, json['status']),
      joinedDate: DateTime.parse(json['joinedDate'] as String),
      lastActiveDate: json['lastActiveDate'] == null
          ? null
          : DateTime.parse(json['lastActiveDate'] as String),
      specializations: (json['specializations'] as List<dynamic>)
          .map((e) => $enumDecode(_$SARSpecializationEnumMap, e))
          .toList(),
      certifications: (json['certifications'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      isActive: json['isActive'] as bool? ?? true,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$SAROrganizationMemberToJson(
        SAROrganizationMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'organizationId': instance.organizationId,
      'memberName': instance.memberName,
      'memberEmail': instance.memberEmail,
      'memberPhone': instance.memberPhone,
      'role': _$SARMemberRoleEnumMap[instance.role]!,
      'status': _$SARMemberStatusEnumMap[instance.status]!,
      'joinedDate': instance.joinedDate.toIso8601String(),
      'lastActiveDate': instance.lastActiveDate?.toIso8601String(),
      'specializations': instance.specializations
          .map((e) => _$SARSpecializationEnumMap[e]!)
          .toList(),
      'certifications': instance.certifications,
      'isActive': instance.isActive,
      'notes': instance.notes,
    };

const _$SARMemberRoleEnumMap = {
  SARMemberRole.admin: 'admin',
  SARMemberRole.incidentCommander: 'incident_commander',
  SARMemberRole.teamLeader: 'team_leader',
  SARMemberRole.seniorMember: 'senior_member',
  SARMemberRole.member: 'member',
  SARMemberRole.trainee: 'trainee',
  SARMemberRole.support: 'support',
};

const _$SARMemberStatusEnumMap = {
  SARMemberStatus.active: 'active',
  SARMemberStatus.inactive: 'inactive',
  SARMemberStatus.training: 'training',
  SARMemberStatus.probationary: 'probationary',
  SARMemberStatus.suspended: 'suspended',
  SARMemberStatus.retired: 'retired',
};

SAROrganizationOperation _$SAROrganizationOperationFromJson(
        Map<String, dynamic> json) =>
    SAROrganizationOperation(
      id: json['id'] as String,
      organizationId: json['organizationId'] as String,
      operationName: json['operationName'] as String,
      type: $enumDecode(_$SAROperationTypeEnumMap, json['type']),
      status: $enumDecode(_$SAROperationStatusEnumMap, json['status']),
      priority: $enumDecode(_$SAROperationPriorityEnumMap, json['priority']),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] == null
          ? null
          : DateTime.parse(json['endTime'] as String),
      location: SAROperationLocation.fromJson(
          json['location'] as Map<String, dynamic>),
      description: json['description'] as String,
      subjectInfo: json['subjectInfo'] as String?,
      assignedMemberIds: (json['assignedMemberIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      resourcesDeployed: (json['resourcesDeployed'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      weatherConditions: json['weatherConditions'] == null
          ? null
          : SARWeatherConditions.fromJson(
              json['weatherConditions'] as Map<String, dynamic>),
      updates: (json['updates'] as List<dynamic>)
          .map((e) => SAROperationUpdate.fromJson(e as Map<String, dynamic>))
          .toList(),
      outcome: json['outcome'] == null
          ? null
          : SAROperationOutcome.fromJson(
              json['outcome'] as Map<String, dynamic>),
      incidentCommanderId: json['incidentCommanderId'] as String?,
      coordinatingAgencies: (json['coordinatingAgencies'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$SAROrganizationOperationToJson(
        SAROrganizationOperation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'organizationId': instance.organizationId,
      'operationName': instance.operationName,
      'type': _$SAROperationTypeEnumMap[instance.type]!,
      'status': _$SAROperationStatusEnumMap[instance.status]!,
      'priority': _$SAROperationPriorityEnumMap[instance.priority]!,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'location': instance.location,
      'description': instance.description,
      'subjectInfo': instance.subjectInfo,
      'assignedMemberIds': instance.assignedMemberIds,
      'resourcesDeployed': instance.resourcesDeployed,
      'weatherConditions': instance.weatherConditions,
      'updates': instance.updates,
      'outcome': instance.outcome,
      'incidentCommanderId': instance.incidentCommanderId,
      'coordinatingAgencies': instance.coordinatingAgencies,
    };

const _$SAROperationTypeEnumMap = {
  SAROperationType.searchRescue: 'search_rescue',
  SAROperationType.medicalEmergency: 'medical_emergency',
  SAROperationType.disasterResponse: 'disaster_response',
  SAROperationType.trainingExercise: 'training_exercise',
  SAROperationType.publicService: 'public_service',
  SAROperationType.mutualAid: 'mutual_aid',
};

const _$SAROperationStatusEnumMap = {
  SAROperationStatus.planning: 'planning',
  SAROperationStatus.active: 'active',
  SAROperationStatus.suspended: 'suspended',
  SAROperationStatus.completed: 'completed',
  SAROperationStatus.cancelled: 'cancelled',
  SAROperationStatus.transferred: 'transferred',
};

const _$SAROperationPriorityEnumMap = {
  SAROperationPriority.low: 'low',
  SAROperationPriority.normal: 'normal',
  SAROperationPriority.high: 'high',
  SAROperationPriority.critical: 'critical',
  SAROperationPriority.emergency: 'emergency',
};

SAROperationLocation _$SAROperationLocationFromJson(
        Map<String, dynamic> json) =>
    SAROperationLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      locationName: json['locationName'] as String?,
      address: json['address'] as String?,
      searchRadius: (json['searchRadius'] as num?)?.toDouble(),
      terrain: json['terrain'] as String?,
      elevation: (json['elevation'] as num?)?.toInt(),
      accessInfo: json['accessInfo'] as String?,
    );

Map<String, dynamic> _$SAROperationLocationToJson(
        SAROperationLocation instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'locationName': instance.locationName,
      'address': instance.address,
      'searchRadius': instance.searchRadius,
      'terrain': instance.terrain,
      'elevation': instance.elevation,
      'accessInfo': instance.accessInfo,
    };

SARWeatherConditions _$SARWeatherConditionsFromJson(
        Map<String, dynamic> json) =>
    SARWeatherConditions(
      temperature: (json['temperature'] as num).toDouble(),
      conditions: json['conditions'] as String,
      windSpeed: (json['windSpeed'] as num?)?.toDouble(),
      windDirection: json['windDirection'] as String?,
      visibility: (json['visibility'] as num?)?.toDouble(),
      precipitation: (json['precipitation'] as num?)?.toDouble(),
      alerts: json['alerts'] as String?,
    );

Map<String, dynamic> _$SARWeatherConditionsToJson(
        SARWeatherConditions instance) =>
    <String, dynamic>{
      'temperature': instance.temperature,
      'conditions': instance.conditions,
      'windSpeed': instance.windSpeed,
      'windDirection': instance.windDirection,
      'visibility': instance.visibility,
      'precipitation': instance.precipitation,
      'alerts': instance.alerts,
    };

SAROperationUpdate _$SAROperationUpdateFromJson(Map<String, dynamic> json) =>
    SAROperationUpdate(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      updatedBy: json['updatedBy'] as String,
      update: json['update'] as String,
      type: $enumDecode(_$SARUpdateTypeEnumMap, json['type']),
      location: json['location'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$SAROperationUpdateToJson(SAROperationUpdate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'timestamp': instance.timestamp.toIso8601String(),
      'updatedBy': instance.updatedBy,
      'update': instance.update,
      'type': _$SARUpdateTypeEnumMap[instance.type]!,
      'location': instance.location,
      'attachments': instance.attachments,
    };

const _$SARUpdateTypeEnumMap = {
  SARUpdateType.status: 'status',
  SARUpdateType.personnel: 'personnel',
  SARUpdateType.location: 'location',
  SARUpdateType.resource: 'resource',
  SARUpdateType.weather: 'weather',
  SARUpdateType.subject: 'subject',
  SARUpdateType.command: 'command',
};

SAROperationOutcome _$SAROperationOutcomeFromJson(Map<String, dynamic> json) =>
    SAROperationOutcome(
      type: $enumDecode(_$SAROutcomeTypeEnumMap, json['type']),
      description: json['description'] as String,
      subjectFound: json['subjectFound'] as bool,
      subjectCondition: json['subjectCondition'] as String?,
      totalPersonnelDeployed: (json['totalPersonnelDeployed'] as num).toInt(),
      totalHoursSpent: (json['totalHoursSpent'] as num).toInt(),
      resourcesUsed: (json['resourcesUsed'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      lessonsLearned: json['lessonsLearned'] as String?,
      totalCost: (json['totalCost'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$SAROperationOutcomeToJson(
        SAROperationOutcome instance) =>
    <String, dynamic>{
      'type': _$SAROutcomeTypeEnumMap[instance.type]!,
      'description': instance.description,
      'subjectFound': instance.subjectFound,
      'subjectCondition': instance.subjectCondition,
      'totalPersonnelDeployed': instance.totalPersonnelDeployed,
      'totalHoursSpent': instance.totalHoursSpent,
      'resourcesUsed': instance.resourcesUsed,
      'lessonsLearned': instance.lessonsLearned,
      'totalCost': instance.totalCost,
    };

const _$SAROutcomeTypeEnumMap = {
  SAROutcomeType.successful: 'successful',
  SAROutcomeType.unsuccessful: 'unsuccessful',
  SAROutcomeType.suspended: 'suspended',
  SAROutcomeType.transferred: 'transferred',
  SAROutcomeType.trainingComplete: 'training_complete',
};
