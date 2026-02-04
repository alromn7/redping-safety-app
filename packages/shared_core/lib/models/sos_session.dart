class SOSSessionCore {
  final String id;
  final String userId;
  final String type; // crash, fall, manual
  final DateTime createdAt;

  SOSSessionCore({
    required this.id,
    required this.userId,
    required this.type,
    required this.createdAt,
  });
}
