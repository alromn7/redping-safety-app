import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'document_scan_result.g.dart';

@JsonSerializable()
class DocumentScanResult extends Equatable {
  final String id;
  final ScanDocumentType type;
  final String rawText;
  final Map<String, dynamic> extractedFields; // e.g., { name, dosage, times }
  final DateTime scannedAt;

  const DocumentScanResult({
    required this.id,
    required this.type,
    required this.rawText,
    this.extractedFields = const {},
    required this.scannedAt,
  });

  factory DocumentScanResult.fromJson(Map<String, dynamic> json) =>
      _$DocumentScanResultFromJson(json);
  Map<String, dynamic> toJson() => _$DocumentScanResultToJson(this);

  @override
  List<Object?> get props => [id, type, rawText, extractedFields, scannedAt];
}

enum ScanDocumentType {
  @JsonValue('prescription')
  prescription,
  @JsonValue('appointment_card')
  appointmentCard,
  @JsonValue('test_result')
  testResult,
  @JsonValue('insurance_card')
  insuranceCard,
  @JsonValue('other')
  other,
}
