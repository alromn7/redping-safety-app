import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/medical/medication_service.dart';
import '../../../models/medical/medication.dart';

class MedicationListPage extends StatefulWidget {
  final String userId;
  const MedicationListPage({super.key, required this.userId});

  @override
  State<MedicationListPage> createState() => _MedicationListPageState();
}

class _MedicationListPageState extends State<MedicationListPage> {
  final _svc = MedicationService();
  late Future<List<Medication>> _future;

  @override
  void initState() {
    super.initState();
    _future = _svc.list(widget.userId);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _svc.list(widget.userId);
    });
  }

  void _openEditor([Medication? med]) async {
    await context.push('/doctor/medications/edit', extra: {'medication': med});
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medications')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Medication>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final meds = snapshot.data ?? const <Medication>[];
            if (meds.isEmpty) {
              return const Center(
                child: Text('No medications yet. Tap + to add or scan.'),
              );
            }
            return ListView.separated(
              itemCount: meds.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final m = meds[i];
                final subtitle = [
                  m.dosage,
                  if (m.timesOfDay.isNotEmpty)
                    'Times: ${m.timesOfDay.join(', ')}',
                ].where((s) => s.isNotEmpty).join(' • ');
                return ListTile(
                  title: Text(m.name),
                  subtitle: Text(subtitle),
                  trailing: IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: () async {
                      await _svc.markDoseTaken(widget.userId, m);
                      _refresh();
                    },
                    tooltip: 'Mark dose taken',
                  ),
                  onTap: () => _openEditor(m),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
