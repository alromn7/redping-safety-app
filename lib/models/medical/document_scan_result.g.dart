// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_scan_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentScanResult _$DocumentScanResultFromJson(Map<String, dynamic> json) =>
    DocumentScanResult(
      id: json['id'] as String,
      type: $enumDecode(_$ScanDocumentTypeEnumMap, json['type']),
      rawText: json['rawText'] as String,
      extractedFields:
          json['extractedFields'] as Map<String, dynamic>? ?? const {},
      scannedAt: DateTime.parse(json['scannedAt'] as String),
    );

Map<String, dynamic> _$DocumentScanResultToJson(DocumentScanResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$ScanDocumentTypeEnumMap[instance.type]!,
      'rawText': instance.rawText,
      'extractedFields': instance.extractedFields,
      'scannedAt': instance.scannedAt.toIso8601String(),
    };

const _$ScanDocumentTypeEnumMap = {
  ScanDocumentType.prescription: 'prescription',
  ScanDocumentType.appointmentCard: 'appointment_card',
  ScanDocumentType.testResult: 'test_result',
  ScanDocumentType.insuranceCard: 'insurance_card',
  ScanDocumentType.other: 'other',
};
