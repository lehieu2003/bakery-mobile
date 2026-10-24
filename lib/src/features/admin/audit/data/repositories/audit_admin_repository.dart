import 'package:bakery_mobile/src/features/admin/audit/data/datasources/audit_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/audit/domain/models/audit_models.dart';

AuditLogRow auditRowFromJson(Map<String, dynamic> json) => AuditLogRow(
  id: (json['id'] ?? '').toString(),
  module: (json['module'] ?? '').toString(),
  entity: (json['entity'] ?? '').toString(),
  summary: (json['summary'] ?? '').toString(),
  mutationType: (json['mutationType'] ?? '').toString(),
  actorName: json['actor'] is Map<String, dynamic>
      ? json['actor']['name']?.toString()
      : null,
  actorRole: (json['actorRole'] ?? '').toString(),
  createdAt: DateTime.tryParse('${json['createdAt'] ?? ''}') ?? DateTime.now(),
);

class AuditLogPage {
  const AuditLogPage({required this.items, required this.totalPages});

  final List<AuditLogRow> items;
  final int totalPages;
}

class AuditAdminRepository {
  const AuditAdminRepository(this._service);

  final AuditAdminApiService _service;

  Future<AuditLogPage> getAudit({int page = 1, int limit = 20}) async {
    final response = await _service.getAudit(page: page, limit: limit);
    final data = response;
    final rows = data['logs'];
    final pagination = data['pagination'];
    return AuditLogPage(
      items: rows is List<dynamic>
          ? [
              for (final row in rows)
                if (row is Map<String, dynamic>) auditRowFromJson(row),
            ]
          : const [],
      totalPages:
          pagination is Map<String, dynamic> && pagination['totalPages'] is num
          ? (pagination['totalPages'] as num).toInt()
          : 1,
    );
  }
}
