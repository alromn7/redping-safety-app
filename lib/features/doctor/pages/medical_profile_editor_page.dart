import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../models/medical/medical_profile.dart';
import '../../../models/external_coverage.dart';
import '../../../services/auth_service.dart';
import '../../../services/medical/medical_profile_service.dart';
import '../../../services/medical/external_coverage_service.dart';

class MedicalProfileEditorPage extends StatefulWidget {
  const MedicalProfileEditorPage({super.key});

  @override
  State<MedicalProfileEditorPage> createState() =>
      _MedicalProfileEditorPageState();
}

class _MedicalProfileEditorPageState extends State<MedicalProfileEditorPage> {
  final _profileSvc = MedicalProfileService();
  final _coverageSvc = ExternalCoverageService();

  MedicalProfile? _profile;
  ExternalCoverageProfile? _coverage;

  final _allergiesCtrl = TextEditingController();
  final _conditionsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  BloodType? _bloodType;
  bool _shareCoverageWithFamily = true;
  bool _smartCoverageEnabled = false;
  final _activeCoverages = <ExternalCoverageType>{};

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = AuthService.instance.currentUser.id;
    final p = await _profileSvc.fetchProfile(uid);
    final c = await _coverageSvc.getOrCreate(uid);

    setState(() {
      _profile =
          p ??
          MedicalProfile(
            userId: uid,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
      _bloodType = _profile!.bloodType;
      _allergiesCtrl.text = _profile!.allergies.join(', ');
      _conditionsCtrl.text = _profile!.conditions.join(', ');
      _notesCtrl.text = _profile!.emergencyNotes ?? '';
      _shareCoverageWithFamily = _profile!.shareCoverageWithFamily;

      _coverage = c;
      _smartCoverageEnabled = c.smartExternalCoverageEnabled;
      _activeCoverages.addAll(c.activeCoverages);
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_profile == null) return;
    final uid = AuthService.instance.currentUser.id;
    final prof = _profile!.copyWith(
      bloodType: _bloodType,
      allergies: _splitList(_allergiesCtrl.text),
      conditions: _splitList(_conditionsCtrl.text),
      emergencyNotes: _notesCtrl.text.trim().isEmpty
          ? null
          : _notesCtrl.text.trim(),
      shareCoverageWithFamily: _shareCoverageWithFamily,
      updatedAt: DateTime.now(),
    );
    await _profileSvc.upsertProfile(prof);

    final cov = (_coverage ?? ExternalCoverageProfile.initial(uid)).copyWith(
      smartExternalCoverageEnabled: _smartCoverageEnabled,
      activeCoverages: _activeCoverages.toList(),
      lastUpdated: DateTime.now(),
    );
    await _coverageSvc.save(cov);

    if (mounted) context.pop();
  }

  List<String> _splitList(String input) =>
      input.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  @override
  void dispose() {
    _allergiesCtrl.dispose();
    _conditionsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Profile'),
        actions: [
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
          const Text(
            'Emergency Medical Info',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<BloodType>(
            value: _bloodType,
            decoration: const InputDecoration(labelText: 'Blood type'),
            items: BloodType.values
                .map((b) => DropdownMenuItem(value: b, child: Text(_label(b))))
                .toList(),
            onChanged: (v) => setState(() => _bloodType = v),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _allergiesCtrl,
            decoration: const InputDecoration(
              labelText: 'Allergies (comma separated)',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _conditionsCtrl,
            decoration: const InputDecoration(
              labelText: 'Conditions (comma separated)',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              labelText: 'Emergency notes (visible during SOS)',
            ),
            minLines: 2,
            maxLines: 4,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'Coverage Information (Operational Only)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text('Enable coverage info'),
            subtitle: const Text(
              'Share coverage details with family and rescuers during SOS',
            ),
            value: _smartCoverageEnabled,
            onChanged: (v) => setState(() => _smartCoverageEnabled = v),
          ),
          if (_smartCoverageEnabled)
            Column(
              children: ExternalCoverageType.values
                  .map(
                    (t) => CheckboxListTile(
                      title: Text('${t.icon} ${t.displayName}'),
                      value: _activeCoverages.contains(t),
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _activeCoverages.add(t);
                          } else {
                            _activeCoverages.remove(t);
                          }
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
          const SizedBox(height: 8),
          SwitchListTile(
            title: const Text('Share with family'),
            subtitle: const Text('Family members can view coverage info'),
            value: _shareCoverageWithFamily,
            onChanged: (v) => setState(() => _shareCoverageWithFamily = v),
          ),
        ],
      ),
    );
  }

  String _label(BloodType t) {
    switch (t) {
      case BloodType.aPos:
        return 'A+';
      case BloodType.aNeg:
        return 'A-';
      case BloodType.bPos:
        return 'B+';
      case BloodType.bNeg:
        return 'B-';
      case BloodType.abPos:
        return 'AB+';
      case BloodType.abNeg:
        return 'AB-';
      case BloodType.oPos:
        return 'O+';
      case BloodType.oNeg:
        return 'O-';
    }
  }
}
