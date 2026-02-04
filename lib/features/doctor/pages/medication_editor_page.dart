import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/medical/medication.dart';
import '../../../models/medical/document_scan_result.dart';
import '../../../services/medical/medication_service.dart';
import '../../../services/medical/ocr_scan_service.dart';

class MedicationEditorPage extends StatefulWidget {
  final String userId;
  final Medication? medication;
  const MedicationEditorPage({
    super.key,
    required this.userId,
    this.medication,
  });

  @override
  State<MedicationEditorPage> createState() => _MedicationEditorPageState();
}

class _MedicationEditorPageState extends State<MedicationEditorPage> {
  final _svc = MedicationService();
  final _ocr = OcrScanService();

  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _formCtrl = TextEditingController(text: 'tablet');
  final _timeCtrls = <TextEditingController>[];
  bool _reminders = true;

  @override
  void initState() {
    super.initState();
    final m = widget.medication;
    if (m != null) {
      _nameCtrl.text = m.name;
      _dosageCtrl.text = m.dosage;
      _formCtrl.text = m.form;
      _reminders = m.remindersEnabled;
      for (final t in m.timesOfDay) {
        _timeCtrls.add(TextEditingController(text: t));
      }
    } else {
      _timeCtrls.add(TextEditingController(text: '08:00'));
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _formCtrl.dispose();
    for (final c in _timeCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _scanPrescription() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);
      if (image == null) return;
      final scan = await _ocr.scanImage(
        File(image.path),
        type: ScanDocumentType.prescription,
      );
      final draft = _ocr.toMedicationDraft(scan);
      setState(() {
        _nameCtrl.text = draft.name;
        _dosageCtrl.text = draft.dosage;
        _formCtrl.text = draft.form;
        _timeCtrls
          ..clear()
          ..addAll(draft.timesOfDay.map((t) => TextEditingController(text: t)));
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Prescription scanned. Verify details before saving.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Scan failed. Please allow camera permission in Settings and try again. ($e)',
          ),
        ),
      );
    }
  }

  Future<void> _save() async {
    final times = _timeCtrls
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    final med =
        (widget.medication ??
                Medication(
                  id: MedicationService.newId(),
                  name: _nameCtrl.text.trim(),
                  dosage: _dosageCtrl.text.trim(),
                  form: _formCtrl.text.trim(),
                  timesOfDay: times,
                  frequencyPerDay: times.length,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ))
            .copyWith(
              name: _nameCtrl.text.trim(),
              dosage: _dosageCtrl.text.trim(),
              form: _formCtrl.text.trim(),
              timesOfDay: times,
              frequencyPerDay: times.length,
              remindersEnabled: _reminders,
              updatedAt: DateTime.now(),
            );
    await _svc.upsert(widget.userId, med);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.medication == null ? 'Add Medication' : 'Edit Medication',
        ),
        actions: [
          IconButton(
            onPressed: _scanPrescription,
            icon: const Icon(Icons.document_scanner_outlined),
            tooltip: 'Scan prescription',
          ),
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.save_alt),
            tooltip: 'Save',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Medication name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _dosageCtrl,
            decoration: const InputDecoration(
              labelText: 'Dosage (e.g., 500 mg)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _formCtrl,
            decoration: const InputDecoration(labelText: 'Form (e.g., tablet)'),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Enable reminders'),
            value: _reminders,
            onChanged: (v) => setState(() => _reminders = v),
          ),
          const SizedBox(height: 12),
          const Text(
            'Times of day (HH:mm):',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._timeCtrls.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: c,
                      decoration: const InputDecoration(hintText: '08:00'),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () {
                      setState(() {
                        _timeCtrls.remove(c);
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => setState(
              () => _timeCtrls.add(TextEditingController(text: '20:00')),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add time'),
          ),
        ],
      ),
    );
  }
}
