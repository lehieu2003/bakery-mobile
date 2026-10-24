import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/theme/app_spacing.dart';
import 'package:bakery_mobile/src/features/admin/coupons/domain/models/coupon_models.dart';
import 'package:bakery_mobile/src/features/admin/coupons/presentation/controllers/coupons_admin_view_model.dart';
import 'package:bakery_mobile/src/features/admin/coupons/presentation/widgets/coupon_edit_sheet.dart';
import 'package:bakery_mobile/src/shared/utils/format_utils.dart';
import 'package:bakery_mobile/src/shared/widgets/error_retry_widget.dart';

/// Coupon admin: list + create sheet + delete confirm + active toggle.
class CouponsScreen extends ConsumerStatefulWidget {
  const CouponsScreen({super.key});

  @override
  ConsumerState<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends ConsumerState<CouponsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(couponsAdminViewModelProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(couponsAdminViewModelProvider);
    final vm = ref.read(couponsAdminViewModelProvider.notifier);

    // Sheet-level errors surface as a snackbar once the sheet has closed.
    ref.listen(couponsAdminViewModelProvider, (previous, next) {
      final message = next.error;
      if (message == null || message == previous?.error) return;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    });

    return Scaffold(
      body: state.isLoading && state.items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.items.isEmpty
          ? ErrorRetryWidget(message: state.error!, onRetry: vm.load)
          : state.items.isEmpty
          ? Center(
              child: Text(
                'Chưa có coupon nào',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          : RefreshIndicator(
              onRefresh: vm.load,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: state.items.length,
                separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
                itemBuilder: (context, index) => _CouponCard(
                  coupon: state.items[index],
                  onToggle: (active) =>
                      vm.setActive(state.items[index].id, isActive: active),
                  onDelete: () => _confirmDelete(state.items[index]),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCouponEditSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm coupon'),
      ),
    );
  }

  Future<void> _confirmDelete(AdminCoupon coupon) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoá coupon?'),
        content: Text('"${coupon.code}" sẽ không còn dùng được.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await ref
        .read(couponsAdminViewModelProvider.notifier)
        .remove(coupon.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Đã xoá coupon'
                : (ref.read(couponsAdminViewModelProvider).error ??
                      'Xoá thất bại'),
          ),
        ),
      );
    }
  }
}

class _CouponCard extends StatelessWidget {
  const _CouponCard({
    required this.coupon,
    required this.onToggle,
    required this.onDelete,
  });

  final AdminCoupon coupon;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isPercent = coupon.type == 'PERCENTAGE';
    final valueLabel = isPercent
        ? '-${_trimNum(coupon.value)}%'
        : '-${formatVnd(coupon.value)}';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: coupon.isActive
                    ? Colors.green.withValues(alpha: 0.12)
                    : Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSpacing.sm),
              ),
              child: Text(
                coupon.code,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Gap(AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    valueLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    [
                      if (coupon.minOrder != null)
                        'Đơn tối thiểu ${formatVnd(coupon.minOrder!)}',
                      '${formatDateVi(coupon.startAt ?? DateTime.now())} - '
                          '${formatDateVi(coupon.endAt ?? DateTime.now())}',
                    ].join(' · '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Switch(value: coupon.isActive, onChanged: onToggle),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Xoá coupon',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  String _trimNum(num value) => value == value.truncateToDouble()
      ? value.truncate().toString()
      : value.toStringAsFixed(1);
}
