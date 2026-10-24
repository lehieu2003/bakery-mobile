import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/features/admin/customers/domain/models/admin_customer.dart';
import 'package:bakery_mobile/src/features/admin/customers/presentation/controllers/customer_detail_view_model.dart';
import 'package:bakery_mobile/src/features/admin/customers/presentation/widgets/member_level_badge.dart';

/// The member-level/points editor behind the detail screen's 'Chỉnh sửa'
/// button. Saves through [customerDetailViewModelProvider]; the server
/// re-validates both fields (400 'Invalid points' surfaces in the sheet).
Future<void> showCustomerEditSheet(
  BuildContext context,
  AdminCustomerDetail detail,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CustomerEditSheet(detail: detail),
  );
}

class _CustomerEditSheet extends ConsumerStatefulWidget {
  const _CustomerEditSheet({required this.detail});

  final AdminCustomerDetail detail;

  @override
  ConsumerState<_CustomerEditSheet> createState() => _CustomerEditSheetState();
}

class _CustomerEditSheetState extends ConsumerState<_CustomerEditSheet> {
  static const _levels = <String>['SILVER', 'GOLD', 'PLATINUM'];

  late String _level = widget.detail.memberLevel;
  late final TextEditingController _points = TextEditingController(
    text: '${widget.detail.points}',
  );
  String? _pointsError;
  ScaffoldMessengerState? _messenger;

  @override
  void dispose() {
    _points.dispose();
    super.dispose();
  }

  String? _validatePoints(String raw) {
    final points = int.tryParse(raw.trim());
    if (points == null || points < 0) {
      return 'Điểm phải là số nguyên không âm';
    }
    return null;
  }

  Future<void> _save() async {
    final pointsError = _validatePoints(_points.text);
    if (pointsError != null) {
      setState(() => _pointsError = pointsError);
      return;
    }
    final id = widget.detail.id;
    final notifier = ref.read(customerDetailViewModelProvider(id).notifier);
    // Capture before the sheet pops — the element is gone afterwards.
    final messenger = _messenger ?? ScaffoldMessenger.maybeOf(context);
    final ok = await notifier.update(
      memberLevel: _level,
      points: int.parse(_points.text.trim()),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      messenger?.showSnackBar(
        const SnackBar(content: Text('Đã cập nhật khách hàng')),
      );
      return;
    }
    setState(() {
      _pointsError = ref.read(customerDetailViewModelProvider(id)).updateError;
    });
  }

  @override
  Widget build(BuildContext context) {
    _messenger ??= ScaffoldMessenger.maybeOf(context);
    final isSaving = ref
        .watch(customerDetailViewModelProvider(widget.detail.id))
        .isSaving;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Chỉnh sửa khách hàng',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          Text(
            'Hạng thành viên',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final level in _levels)
                ChoiceChip(
                  label: Text(level),
                  selected: _level == level,
                  onSelected: (_) => setState(() => _level = level),
                ),
              MemberLevelBadge(level: _level),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _points,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Điểm',
              errorText: _pointsError,
            ),
            onChanged: (_) {
              if (_pointsError != null) setState(() => _pointsError = null);
            },
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: isSaving ? null : _save,
            child: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}
