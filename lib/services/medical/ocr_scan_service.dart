import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../models/medical/document_scan_result.dart';
import '../../models/medical/medication.dart';

/// OCR & parsing utilities for prescriptions and appointment cards
class OcrScanService {
  /// Extract raw text from an image file using on-device ML Kit
  Future<DocumentScanResult> scanImage(
    File image, {
    ScanDocumentType type = ScanDocumentType.other,
  }) async {
    final inputImage = InputImage.fromFile(image);
    final textRecognizer = TextRecognizer();
    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      final raw = recognizedText.text;
      final fields = _extractFields(raw, type: type);
      return DocumentScanResult(
        id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        rawText: raw,
        extractedFields: fields,
        scannedAt: DateTime.now(),
      );
    } on Exception {
      // Wrap common failures with a minimal result so UI can proceed gracefully
      return DocumentScanResult(
        id: 'scan_${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        rawText: '',
        extractedFields: const {},
        scannedAt: DateTime.now(),
      );
    } finally {
      await textRecognizer.close();
    }
  }

  /// Heuristic extraction for common prescription patterns
  Map<String, dynamic> _extractFields(
    String text, {
    required ScanDocumentType type,
  }) {
    final result = <String, dynamic>{};
    final normalized = text
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Very lightweight heuristics: look for NAME (dosage) x/day or times
    // Examples: "Metformin 500 mg twice daily" or "Atorvastatin 20mg nocte"

    // Medication name and dosage
    final nameDosage = RegExp(
      r'([A-Za-z][A-Za-z\-]+)\s+(\d+\s?mg|\d+\s?mcg|\d+\s?g)',
    ).firstMatch(normalized);
    if (nameDosage != null) {
      result['name'] = nameDosage.group(1);
      result['dosage'] = nameDosage.group(2);
    }

    // Times per day keywords
    if (normalized.contains('once daily') || normalized.contains('od ')) {
      result['frequencyPerDay'] = 1;
    } else if (normalized.contains('twice daily') ||
        normalized.contains('bd ')) {
      result['frequencyPerDay'] = 2;
    } else if (normalized.contains('three times') ||
        normalized.contains('tds ')) {
      result['frequencyPerDay'] = 3;
    } else if (normalized.contains('four times') ||
        normalized.contains('qid ')) {
      result['frequencyPerDay'] = 4;
    }

    // Simple time hints
    final times = <String>[];
    if (normalized.contains('morning')) times.add('08:00');
    if (normalized.contains('noon') || normalized.contains('midday')) {
      times.add('12:00');
    }
    if (normalized.contains('evening')) times.add('18:00');
    if (normalized.contains('night') || normalized.contains('nocte')) {
      times.add('21:00');
    }
    if (times.isNotEmpty) result['timesOfDay'] = times;

    return result;
  }

  /// Build a draft Medication from a scan result (user can edit before saving)
  Medication toMedicationDraft(DocumentScanResult scan) {
    final f = scan.extractedFields;
    final times =
        (f['timesOfDay'] as List?)?.cast<String>() ?? const <String>[];
    final freq = f['frequencyPerDay'] as int? ?? times.length;
    return Medication(
      id: _newId(),
      name: (f['name'] as String?) ?? 'Medication',
      brand: null,
      dosage: (f['dosage'] as String?) ?? '',
      form: 'tablet',
      timesOfDay: times,
      frequencyPerDay: freq,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  String _newId() =>
      'med_${DateTime.now().millisecondsSinceEpoch}_${(DateTime.now().microsecondsSinceEpoch % 10000)}';
}
