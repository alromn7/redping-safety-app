import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../config/google_cloud_config.dart';
import '../../models/medical/appointment.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../notification_service.dart';
import 'ics_export_service.dart';

class AppointmentICSOptions {
  final Duration? duration;
  final List<String> attendees;
  const AppointmentICSOptions({this.duration, this.attendees = const []});
}

class AppointmentService {
  final FirebaseFirestore _db;
  final NotificationService _notifications;
  final ICSExportService _ics = ICSExportService();
  AppointmentService({
    FirebaseFirestore? firestore,
    NotificationService? notifications,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _notifications = notifications ?? NotificationService();

  CollectionReference<Map<String, dynamic>> _col(String userId) => _db
      .collection(GoogleCloudConfig.firestoreCollectionUsers)
      .doc(userId)
      .collection('medical')
      .doc('profile')
      .collection('appointments');

  Future<List<HealthAppointment>> list(String userId) async {
    try {
      final q = await _col(userId).orderBy('dateTime').get();
      return q.docs.map((d) => HealthAppointment.fromJson(d.data())).toList();
    } catch (e) {
      debugPrint('AppointmentService.list error: $e');
      return [];
    }
  }

  Future<void> upsert(String userId, HealthAppointment appt) async {
    try {
      await _col(
        userId,
      ).doc(appt.id).set(appt.toJson(), SetOptions(merge: true));

      // Schedule tiered reminders
      await _scheduleReminders(userId, appt);
    } catch (e) {
      debugPrint('AppointmentService.upsert error: $e');
      rethrow;
    }
  }

  Future<void> delete(String userId, String id) async {
    try {
      await _col(userId).doc(id).delete();
      await _cancelReminders(id);
    } catch (e) {
      debugPrint('AppointmentService.delete error: $e');
      rethrow;
    }
  }

  /// Generate ICS calendar content for an appointment
  Future<String> generateICSAuto(HealthAppointment appt) async {
    final opts = await loadICSOptions(appt.id);
    return _ics.generateICSWithOptions(
      appt,
      duration: opts.duration,
      attendees: opts.attendees,
    );
  }

  /// Persist ICS options for an appointment
  Future<void> saveICSOptions(
    String apptId, {
    Duration? duration,
    List<String>? attendees,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (duration != null) {
      await prefs.setInt(
        'appt_meta_${apptId}_duration_minutes',
        duration.inMinutes,
      );
    }
    if (attendees != null) {
      await prefs.setString(
        'appt_meta_${apptId}_attendees',
        attendees.join(','),
      );
    }
  }

  /// Load ICS options for an appointment
  Future<AppointmentICSOptions> loadICSOptions(String apptId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final minutes = prefs.getInt('appt_meta_${apptId}_duration_minutes');
      final attendeesCsv = prefs.getString('appt_meta_${apptId}_attendees');
      final attendees = (attendeesCsv == null || attendeesCsv.isEmpty)
          ? <String>[]
          : attendeesCsv
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
      return AppointmentICSOptions(
        duration: minutes != null ? Duration(minutes: minutes) : null,
        attendees: attendees,
      );
    } catch (_) {
      return const AppointmentICSOptions();
    }
  }

  Future<void> _scheduleReminders(String userId, HealthAppointment appt) async {
    await _notifications.initialize();

    // Clear previous reminders for this appointment id
    await _cancelReminders(appt.id);

    // Respect global medical reminders toggle
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('medical_reminders_enabled') ?? true;
      if (!enabled) return;
    } catch (_) {}

    final dt = appt.dateTime;
    final now = DateTime.now();

    // Define reminder offsets
    final reminders = <Duration>[
      const Duration(days: 7),
      const Duration(days: 1),
      const Duration(hours: 2),
    ];

    for (final offset in reminders) {
      final alertTime = dt.subtract(offset);
      if (alertTime.isBefore(now)) continue; // skip past reminders

      final seed =
          appt.id.hashCode ^ userId.hashCode ^ offset.inMinutes.hashCode;
      final notificationId = (seed & 0x7FFFFFFF);

      final label = _offsetLabel(offset);
      await _notifications.scheduleCalendarNotification(
        id: notificationId,
        dateTime: alertTime,
        title: 'Appointment Reminder',
        body: '${appt.title} in $label',
        payload: 'appt:${appt.id}:$label',
        importance: NotificationImportance.high,
      );
    }
  }

  Future<void> _cancelReminders(String appointmentId) async {
    await _notifications.cancelScheduledByPayloadPrefix('appt:$appointmentId');
  }

  String _offsetLabel(Duration d) {
    if (d.inDays >= 7) return '1 week';
    if (d.inDays >= 1) return '1 day';
    if (d.inHours >= 2) return '2 hours';
    return '${d.inMinutes} minutes';
  }
}
