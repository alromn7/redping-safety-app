import 'package:flutter/material.dart';
import '../../../services/medical/appointment_service.dart';
import '../../../models/medical/appointment.dart';
import 'package:intl/intl.dart';

class AppointmentListPage extends StatefulWidget {
  final String userId;
  const AppointmentListPage({super.key, required this.userId});

  @override
  State<AppointmentListPage> createState() => _AppointmentListPageState();
}

class _AppointmentListPageState extends State<AppointmentListPage> {
  final _svc = AppointmentService();
  late Future<List<HealthAppointment>> _future;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<HealthAppointment>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snapshot.data ?? const <HealthAppointment>[];
            if (items.isEmpty) {
              return const Center(child: Text('No appointments'));
            }
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final a = items[i];
                final time = DateFormat('EEE, d MMM h:mm a').format(a.dateTime);
                return ListTile(
                  title: Text(a.title),
                  subtitle: Text(
                    [
                      if (a.doctorName != null) a.doctorName,
                      time,
                      a.location,
                    ].whereType<String>().join(' • '),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
