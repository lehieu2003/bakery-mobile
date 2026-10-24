import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/theme/app_spacing.dart';
import 'package:bakery_mobile/src/features/admin/membership/presentation/controllers/membership_admin_view_model.dart';
import 'package:bakery_mobile/src/shared/utils/format_utils.dart';
import 'package:bakery_mobile/src/shared/widgets/error_retry_widget.dart';

/// "Thành viên" admin: 3 tier cards (minPoints editable) + points-per-order.
class MembershipScreen extends ConsumerStatefulWidget {
  const MembershipScreen({super.key});

  @override
  ConsumerState<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends ConsumerState<MembershipScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(membershipAdminViewModelProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(membershipAdminViewModelProvider);
    final vm = ref.read(membershipAdminViewModelProvider.notifier);
    final config = state.config;

    ref.listen(membershipAdminViewModelProvider, (previous, next) {
      final message = next.error;
      if (message == null || message == previous?.error) return;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    });

    if (state.isLoading && config == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (state.error != null && config == null) {
      return Scaffold(
        body: ErrorRetryWidget(message: state.error!, onRetry: vm.load),
      );
    }
    if (config == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: vm.load,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            for (final level in config.levels) ...[
              _LevelCard(
                label: level.label,
                minPoints: level.minPoints,
                discountPercent: level.discountPercent,
                memberCount: level.memberCount,
                onEdit: () =>
                    _editMinPoints(level.level, level.label, level.minPoints),
              ),
              const Gap(AppSpacing.md),
            ],
            _PointsPerOrderCard(
              pointsPerOrder: config.pointsPerOrder,
              onEdit: () => _editPointsPerOrder(config.pointsPerOrder),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editMinPoints(String tierKey, String label, int current) =>
      _editInt(
        title: 'Điểm tối thiểu hạng $label',
        current: current,
        submit: (value) => ref
            .read(membershipAdminViewModelProvider.notifier)
            .updateConfig(tierKey: tierKey, value: value),
      );

  Future<void> _editPointsPerOrder(int current) => _editInt(
    title: 'Điểm thưởng mỗi đơn',
    current: current,
    submit: (value) => ref
        .read(membershipAdminViewModelProvider.notifier)
        .updateConfig(value: value),
  );

  Future<void> _editInt({
    required String title,
    required int current,
    required Future<bool> Function(int value) submit,
  }) async {
    final controller = TextEditingController(text: '$current');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Số điểm'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final value = int.tryParse(controller.text) ?? -1;
    final ok = await submit(value);
    if (mounted) {
      final state = ref.read(membershipAdminViewModelProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Đã lưu thay đổi' : (state.error ?? 'Lưu thất bại'),
          ),
        ),
      );
    }
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.label,
    required this.minPoints,
    required this.discountPercent,
    required this.memberCount,
    required this.onEdit,
  });

  final String label;
  final int minPoints;
  final int discountPercent;
  final int memberCount;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        title: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          'Từ $minPoints điểm · giảm $discountPercent% · $memberCount thành viên',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Sửa điểm tối thiểu',
          onPressed: onEdit,
        ),
      ),
    );
  }
}

class _PointsPerOrderCard extends StatelessWidget {
  const _PointsPerOrderCard({
    required this.pointsPerOrder,
    required this.onEdit,
  });

  final int pointsPerOrder;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: ListTile(
        title: Text(
          'Điểm thưởng mỗi đơn',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        subtitle: Text('${formatVnd(pointsPerOrder)} đồng = 1 điểm thưởng'),
        trailing: IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: 'Sửa điểm mỗi đơn',
          onPressed: onEdit,
        ),
      ),
    );
  }
}
