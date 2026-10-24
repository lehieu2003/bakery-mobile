/// System audit log row (`GET /api/admin/audit`).
class AuditLogRow {
  const AuditLogRow({
    required this.id,
    required this.module,
    required this.entity,
    required this.summary,
    required this.mutationType,
    this.actorName,
    required this.actorRole,
    required this.createdAt,
  });

  final String id;
  final String module;
  final String entity;
  final String summary;
  final String mutationType;
  final String? actorName;
  final String actorRole;
  final DateTime createdAt;
}
