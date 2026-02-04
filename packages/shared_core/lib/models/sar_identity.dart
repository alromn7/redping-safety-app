class SARIdentityCore {
  final String memberId;
  final String orgId;
  final String role; // observer, member, coordinator, admin

  const SARIdentityCore({
    required this.memberId,
    required this.orgId,
    required this.role,
  });
}
