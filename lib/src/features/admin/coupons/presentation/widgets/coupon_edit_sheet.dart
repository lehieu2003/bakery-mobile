import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/theme/app_spacing.dart';
import 'package:bakery_mobile/src/features/admin/coupons/presentation/controllers/coupons_admin_view_model.dart';

/// Create-coupon sheet. Server rules: code `^[A-Z0-9_-]{3,40}$`,
/// PERCENTAGE ≤ 100, endAt after startAt — validated again in the VM.
Future<void> showCouponEditSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _CouponEditSheet(),
  );
}

class _CouponEditSheet extends ConsumerStatefulWidget {
  const _CouponEditSheet();

  @override
  ConsumerState<_CouponEditSheet> createState() => _CouponEditSheetState();
}

class _CouponEditSheetState extends ConsumerState<_CouponEditSheet> {
  final _code = TextEditingController();
  final _value = TextEditingController();
  final _minOrder = TextEditingController();
  final _usageLimit = TextEditingController();
  final _perUserLimit = TextEditingController();
  String _type = 'PERCENTAGE';
  DateTime _startAt = DateTime.now();
  DateTime _endAt = DateTime.now().add(const Duration(days: 30));
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    _value.dispose();
    _minOrder.dispose();
    _usageLimit.dispose();
    _perUserLimit.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startAt : _endAt;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startAt = picked;
      } else {
        _endAt = picked;
      }
    });
  }

  Future<void> _save() async {
    final ok = await ref
        .read(couponsAdminViewModelProvider.notifier)
        .create(
          code: _code.text,
          type: _type,
          value: double.tryParse(_value.text.replaceAll(',', '.')) ?? 0,
          startAt: _startAt,
          endAt: _endAt,
          minOrder: _minOrder.text.trim().isEmpty
              ? null
              : double.tryParse(_minOrder.text.replaceAll(',', '.')),
          usageLimit: _usageLimit.text.trim().isEmpty
              ? null
              : int.tryParse(_usageLimit.text),
          perUserLimit: _perUserLimit.text.trim().isEmpty
              ? null
              : int.tryParse(_perUserLimit.text),
        );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _error = ref.read(couponsAdminViewModelProvider).error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(
      couponsAdminViewModelProvider.select((s) => s.isSaving),
    );

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Thêm coupon',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Gap(AppSpacing.lg),
            TextField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Mã coupon (VD: SALE20)',
              ),
            ),
            const Gap(AppSpacing.md),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'PERCENTAGE', label: Text('Phần trăm')),
                ButtonSegment(value: 'FIXED', label: Text('Số tiền')),
              ],
              selected: {_type},
              onSelectionChanged: (selection) =>
                  setState(() => _type = selection.first),
            ),
            const Gap(AppSpacing.md),
            TextField(
              controller: _value,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: _type == 'PERCENTAGE'
                    ? 'Giá trị (% giảm)'
                    : 'Giá trị (đ giảm)',
              ),
            ),
            const Gap(AppSpacing.md),
            TextField(
              controller: _minOrder,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Đơn tối thiểu (đ, tuỳ chọn)',
              ),
            ),
            const Gap(AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _usageLimit,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Giới hạn lượt',
                    ),
                  ),
                ),
                const Gap(AppSpacing.md),
                Expanded(
                  child: TextField(
                    controller: _perUserLimit,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Mỗi khách'),
                  ),
                ),
              ],
            ),
            const Gap(AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _DateTile(
                    label: 'Bắt đầu',
                    date: _startAt,
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const Gap(AppSpacing.md),
                Expanded(
                  child: _DateTile(
                    label: 'Kết thúc',
                    date: _endAt,
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const Gap(AppSpacing.md),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const Gap(AppSpacing.lg),
            FilledButton(
              onPressed: isSaving ? null : _save,
              child: Text(isSaving ? 'Đang lưu…' : 'Tạo coupon'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.sm),
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(
          '${date.day.toStringAsFixed(0).padLeft(2, '0')}/'
          '${date.month.toStringAsFixed(0).padLeft(2, '0')}/'
          '${date.year}',
        ),
      ),
    );
  }
}
