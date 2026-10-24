import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/theme/app_spacing.dart';
import 'package:bakery_mobile/src/features/admin/audit/domain/models/audit_models.dart';
import 'package:bakery_mobile/src/features/admin/audit/presentation/controllers/audit_admin_view_model.dart';
import 'package:bakery_mobile/src/shared/utils/format_utils.dart';
import 'package:bakery_mobile/src/shared/widgets/error_retry_widget.dart';

/// "Nhật ký hệ thống" admin: paged audit log with load-more.
class AuditScreen extends ConsumerStatefulWidget {
  const AuditScreen({super.key});

  @override
  ConsumerState<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends ConsumerState<AuditScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(auditAdminViewModelProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(auditAdminViewModelProvider);
    final vm = ref.read(auditAdminViewModelProvider.notifier);

    return Scaffold(
      body: state.isLoading && state.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.items.isEmpty
          ? ErrorRetryWidget(message: state.error!, onRetry: vm.load)
          : state.items.isEmpty
          ? Center(
              child: Text(
                'Chưa có hoạt động nào',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          : RefreshIndicator(
              onRefresh: vm.load,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: state.items.length + (state.canLoadMore ? 1 : 0),
                separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
                itemBuilder: (context, index) {
                  if (index >= state.items.length) {
                    return OutlinedButton(
                      onPressed: state.isLoadingMore ? null : vm.loadMore,
                      child: Text(
                        state.isLoadingMore ? 'Đang tải…' : 'Tải thêm',
                      ),
                    );
                  }
                  return _AuditRow(row: state.items[index]);
                },
              ),
            ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  const _AuditRow({required this.row});

  final AuditLogRow row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCreate = row.mutationType == 'CREATE';
    final isDelete = row.mutationType == 'DELETE';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Chip(
                  label: _moduleLabel(row.module),
                  color: theme.colorScheme.secondaryContainer,
                ),
                const Gap(AppSpacing.xs),
                _Chip(
                  label: row.mutationType,
                  color: isDelete
                      ? theme.colorScheme.errorContainer
                      : isCreate
                      ? Colors.green.withValues(alpha: 0.15)
                      : theme.colorScheme.surfaceContainerHighest,
                ),
                const Spacer(),
                Text(
                  formatDateTimeVi(row.createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const Gap(AppSpacing.xs),
            Text(
              row.summary.isEmpty ? _fallbackSummary(row) : row.summary,
              style: theme.textTheme.bodyMedium,
            ),
            if (row.actorName != null || row.actorRole.isNotEmpty)
              Text(
                [
                  if (row.actorName != null) row.actorName!,
                  if (row.actorRole.isNotEmpty) row.actorRole,
                ].join(' · '),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _moduleLabel(String module) => switch (module) {
    'products' => 'Sản phẩm',
    'categories' => 'Danh mục',
    'orders' => 'Đơn hàng',
    'customers' => 'Khách hàng',
    'marketing' => 'Marketing',
    'settings' => 'Cài đặt',
    'membership' => 'Thành viên',
    'content' => 'Nội dung',
    _ => module,
  };

  String _fallbackSummary(AuditLogRow row) => [
    row.mutationType,
    if (row.entity.isNotEmpty) row.entity,
  ].where((part) => part.isNotEmpty).join(' ');
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
