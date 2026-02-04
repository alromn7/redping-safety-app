class SARIncidentCore {
  final String id;
  final String orgId;
  final String type; // crash, missing_person, disaster
  final String priority; // low, medium, high
  final String status; // open, active, complete, cancelled
  final DateTime createdAt;
  final double? lat;
  final double? lon;

  const SARIncidentCore({
    required this.id,
    required this.orgId,
    required this.type,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.lat,
    this.lon,
  });
}
