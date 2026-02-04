import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../config/google_cloud_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/medical/medication.dart';
import '../notification_service.dart';

/// CRUD for medications and basic reminder scheduling hooks
class MedicationService {
  final FirebaseFirestore _db;
  final NotificationService _notifications;

  MedicationService({
    FirebaseFirestore? firestore,
    NotificationService? notifications,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _notifications = notifications ?? NotificationService();

  CollectionReference<Map<String, dynamic>> _medsCol(String userId) {
    return _db
        .collection(GoogleCloudConfig.firestoreCollectionUsers)
        .doc(userId)
        .collection('medical')
        .doc('profile')
        .collection('medications');
  }

  Future<List<Medication>> list(String userId) async {
    try {
      final q = await _medsCol(
        userId,
      ).orderBy('createdAt', descending: true).get();
      return q.docs.map((d) => Medication.fromJson(d.data())).toList();
    } catch (e) {
      debugPrint('MedicationService.list error: $e');
      return [];
    }
  }

  Future<void> upsert(String userId, Medication med) async {
    try {
      await _medsCol(
        userId,
      ).doc(med.id).set(med.toJson(), SetOptions(merge: true));

      if (med.remindersEnabled && med.timesOfDay.isNotEmpty) {
        await _scheduleReminders(userId, med);
      }

      // Schedule refill alert if configured
      await _scheduleRefillAlert(userId, med);
    } catch (e) {
      debugPrint('MedicationService.upsert error: $e');
      rethrow;
    }
  }

  Future<void> delete(String userId, String id) async {
    try {
      await _medsCol(userId).doc(id).delete();
      await _cancelReminders(id);
    } catch (e) {
      debugPrint('MedicationService.delete error: $e');
      rethrow;
    }
  }

  Future<void> markDoseTaken(String userId, Medication med) async {
    try {
      final updated = med.copyWith(
        lastTakenAt: DateTime.now(),
        dosesTaken: med.dosesTaken + 1,
        updatedAt: DateTime.now(),
      );
      await upsert(userId, updated);
    } catch (e) {
      debugPrint('MedicationService.markDoseTaken error: $e');
    }
  }

  // --- Reminder scheduling (local notifications) ---

  Future<void> _scheduleReminders(String userId, Medication med) async {
    await _notifications.initialize();

    // Clear previous reminders for this med id
    await _cancelReminders(med.id);

    // Respect global medical reminders toggle
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('medical_reminders_enabled') ?? true;
      if (!enabled) {
        debugPrint(
          'MedicationService: global medical reminders disabled, skipping schedule',
        );
        return;
      }
    } catch (_) {}

    for (final t in med.timesOfDay) {
      // t formatted as HH:mm
      final parts = t.split(':');
      if (parts.length != 2) continue;
      final hour = int.tryParse(parts[0]) ?? 8;
      final minute = int.tryParse(parts[1]) ?? 0;
      final idSeed = med.id.hashCode ^ t.hashCode ^ userId.hashCode;
      final notificationId = idSeed & 0x7FFFFFFF; // positive int

      // Schedule a daily reminder at local time
      await _notifications.scheduleDailyNotification(
        id: notificationId,
        hour: hour,
        minute: minute,
        title: 'Medication Reminder',
        body: '${med.name} ${med.dosage}',
        payload: 'med:${med.id}:$t',
        importance: NotificationImportance.high,
      );
    }
  }

  Future<void> _cancelReminders(String medicationId) async {
    await _notifications.cancelScheduledByPayloadPrefix('med:$medicationId');
    await _notifications.cancelScheduledByPayloadPrefix('refill:$medicationId');
  }

  /// Simple heuristic to derive frequency from times list
  static int deriveFrequency(List<String> timesOfDay) => timesOfDay.length;

  /// Utility to generate a random id if needed
  static String newId() =>
      'med_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';

  // --- Refill alerts ---
  Future<void> _scheduleRefillAlert(String userId, Medication med) async {
    if (med.refillCycleDays == null) return;
    if (med.startDate == null) return;
    await _notifications.initialize();

    // Respect global toggle
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('medical_reminders_enabled') ?? true;
      if (!enabled) return;
    } catch (_) {}

    final cycleDays = med.refillCycleDays!;
    if (cycleDays <= 0) return;
    final start = med.startDate!;
    final refillDate = start.add(Duration(days: cycleDays));
    final alertDate = refillDate.subtract(const Duration(days: 5));

    // If alert date already passed, skip
    if (alertDate.isBefore(DateTime.now())) return;

    // Use daily scheduler at alert time (9:00 local)
    final idSeed = med.id.hashCode ^ userId.hashCode ^ 0xABCDEF;
    final notificationId = (idSeed & 0x7FFFFFFF);

    await _notifications.scheduleCalendarNotification(
      id: notificationId,
      dateTime: DateTime(alertDate.year, alertDate.month, alertDate.day, 9, 0),
      title: 'Refill Reminder',
      body: 'Refill ${med.name} ${med.dosage} in 5 days',
      payload: 'refill:${med.id}',
      importance: NotificationImportance.high,
    );
  }
}
