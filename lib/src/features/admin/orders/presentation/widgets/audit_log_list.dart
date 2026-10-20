import 'package:flutter/material.dart';

import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/admin/orders/domain/models/order_audit.dart';
import 'package:bakery_mobile/src/features/admin/shared/domain/order_status_display.dart';
import 'package:bakery_mobile/src/features/admin/shared/utils/admin_format.dart';

const Map<String, String> _mutationLabels = {
  'STATUS_UPDATE': 'Cập nhật trạng thái',
  'PAYMENT_CALLBACK': 'Callback thanh toán',
  'CREATE': 'Tạo đơn',
  'UPDATE': 'Cập nhật',
  'UPSERT': 'Cập nhật',
  'DELETE': 'Xoá',
};

/// Order audit trail: one row per log with actor, action, status transition
/// (labels in Vietnamese), note and time — newest first as served.
class AuditLogList extends StatelessWidget {
  const AuditLogList({super.key, required this.logs});

  final List<OrderAuditLog> logs;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Chưa có nhật ký',
          style: TextStyle(color: AppTheme.warmBrown),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final log in logs) _AuditLogTile(log: log)],
    );
  }
}

class _AuditLogTile extends StatelessWidget {
  const _AuditLogTile({required this.log});

  final OrderAuditLog log;

  /// `'PENDING->CONFIRMED'` → `'Chờ xác nhận → Đã xác nhận'`.
  String? get _transition {
    final raw = log.metadata?['transition'];
    if (raw is! String || !raw.contains('->')) return null;
    final parts = raw.split('->');
    return parts.map((s) => orderStatusLabel(s.trim())).join(' → ');
  }

  String? get _note {
    final raw = log.metadata?['note'];
    return raw is String && raw.trim().isNotEmpty ? raw.trim() : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: AppTheme.warmBrown,
    );
    final actor = log.actorName ?? 'Hệ thống';
    final role = log.actorRole;
    final transition = _transition;
    final note = _note;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 4, right: 10),
            child: Icon(Icons.circle, size: 8, color: AppTheme.primaryPink),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _mutationLabels[log.mutationType] ?? log.mutationType,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (transition != null)
                  Text(transition, style: theme.textTheme.bodyMedium),
                if (note != null)
                  Text(
                    'Ghi chú: $note',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                Text(
                  '$actor${role != null ? ' ($role)' : ''} · '
                  '${formatDateTimeVi(log.createdAt.toLocal())}',
                  style: muted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
