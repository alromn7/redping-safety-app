import '../../models/medical/appointment.dart';

/// Minimal ICS export generator for a single appointment
class ICSExportService {
  /// Generate ICS content for the given appointment
  String generateICS(HealthAppointment appt) {
    return generateICSWithOptions(appt);
  }

  /// Generate ICS with options like custom duration and attendees
  String generateICSWithOptions(
    HealthAppointment appt, {
    Duration? duration,
    List<String>? attendees, // list of attendee emails or names
  }) {
    final dt = appt.dateTime.toUtc();
    final dtStart = _fmt(dt);
    final dur = duration ?? const Duration(hours: 1);
    final dtEnd = _fmt(dt.add(dur).toUtc());
    final uid = 'redping-${appt.id}@redping.app';
    final summary = appt.title;
    final location = appt.location ?? '';
    final description = _buildDescription(appt);

    final lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//RedPing Doctor//EN',
      'CALSCALE:GREGORIAN',
      'METHOD:PUBLISH',
      'BEGIN:VEVENT',
      'UID:$uid',
      'DTSTAMP:${_fmt(DateTime.now().toUtc())}',
      'DTSTART:$dtStart',
      'DTEND:$dtEnd',
      'SUMMARY:${_escape(summary)}',
      if (location.isNotEmpty) 'LOCATION:${_escape(location)}',
      if (description.isNotEmpty) 'DESCRIPTION:${_escape(description)}',
    ];

    // Add attendees if provided
    if (attendees != null && attendees.isNotEmpty) {
      for (final a in attendees) {
        final esc = _escape(a);
        // Basic attendee line; email if supplied, otherwise CN only
        if (a.contains('@')) {
          lines.add('ATTENDEE;ROLE=REQ-PARTICIPANT;RSVP=FALSE:mailto:$esc');
        } else {
          lines.add('ATTENDEE;CN=$esc;ROLE=REQ-PARTICIPANT;RSVP=FALSE');
        }
      }
    }

    lines.addAll(['END:VEVENT', 'END:VCALENDAR']);

    return lines.join('\n');
  }

  String _fmt(DateTime dt) {
    // YYYYMMDDTHHMMSSZ
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}${two(dt.month)}${two(dt.day)}T${two(dt.hour)}${two(dt.minute)}${two(dt.second)}Z';
  }

  String _buildDescription(HealthAppointment appt) {
    final parts = <String>[];
    if (appt.doctorName != null && appt.doctorName!.isNotEmpty) {
      parts.add('Doctor: ${appt.doctorName}');
    }
    if (appt.notes != null && appt.notes!.isNotEmpty) {
      parts.add('Notes: ${appt.notes}');
    }
    return parts.join('\n');
  }

  String _escape(String s) {
    // Basic ICS escaping for commas, semicolons, and newlines
    return s
        .replaceAll('\\', '\\\\')
        .replaceAll('\n', '\\n')
        .replaceAll(',', '\\,')
        .replaceAll(';', '\\;');
  }
}
