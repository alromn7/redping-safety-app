class SARMessageCore {
  final String id;
  final String incidentId;
  final String authorId;
  final String content;
  final DateTime createdAt;

  const SARMessageCore({
    required this.id,
    required this.incidentId,
    required this.authorId,
    required this.content,
    required this.createdAt,
  });
}
