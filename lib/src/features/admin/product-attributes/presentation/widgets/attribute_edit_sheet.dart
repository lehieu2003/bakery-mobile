import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/theme/app_spacing.dart';
import 'package:bakery_mobile/src/features/admin/product-attributes/domain/models/product_attribute_models.dart';
import 'package:bakery_mobile/src/features/admin/product-attributes/presentation/controllers/product_attributes_admin_view_model.dart';

/// Create/edit attribute. Values are edited as label rows (the server
/// derives slug/value from label). Existing values come back prefilled.
Future<void> showAttributeEditSheet(
  BuildContext context, {
  AdminCatalogueAttribute? attribute,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _AttributeEditSheet(attribute: attribute),
  );
}

class _AttributeEditSheet extends ConsumerStatefulWidget {
  const _AttributeEditSheet({this.attribute});

  final AdminCatalogueAttribute? attribute;

  @override
  ConsumerState<_AttributeEditSheet> createState() =>
      _AttributeEditSheetState();
}

class _AttributeEditSheetState extends ConsumerState<_AttributeEditSheet> {
  late final _name = TextEditingController(text: widget.attribute?.name ?? '');
  late String _type = widget.attribute?.type ?? 'MULTI_SELECT';
  late final List<TextEditingController> _values = [
    for (final value
        in widget.attribute?.values ?? const <AdminCatalogueValue>[])
      TextEditingController(text: value.label),
    TextEditingController(),
  ];
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    for (final controller in _values) {
      controller.dispose();
    }
    super.dispose();
  }

  List<String> get _labels => [
    for (final controller in _values)
      if (controller.text.trim().isNotEmpty) controller.text.trim(),
  ];

  Future<void> _save() async {
    final vm = ref.read(productAttributesAdminViewModelProvider.notifier);
    final ok = widget.attribute == null
        ? await vm.create(name: _name.text, type: _type, valueLabels: _labels)
        : await vm.update(
            id: widget.attribute!.id,
            name: _name.text,
            valueLabels: _labels,
          );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(
        () => _error = ref.read(productAttributesAdminViewModelProvider).error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(
      productAttributesAdminViewModelProvider.select((s) => s.isSaving),
    );
    final isEdit = widget.attribute != null;

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
              isEdit ? 'Sửa thuộc tính' : 'Thêm thuộc tính',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const Gap(AppSpacing.lg),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'Tên thuộc tính (VD: Màu kem)',
              ),
            ),
            const Gap(AppSpacing.md),
            if (!isEdit)
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'MULTI_SELECT', label: Text('Nhiều')),
                  ButtonSegment(value: 'SELECT', label: Text('Một')),
                ],
                selected: {_type},
                onSelectionChanged: (selection) =>
                    setState(() => _type = selection.first),
              )
            else
              Text(
                _type == 'MULTI_SELECT' ? 'Chọn nhiều' : 'Chọn một',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const Gap(AppSpacing.md),
            Text('Giá trị', style: Theme.of(context).textTheme.labelLarge),
            const Gap(AppSpacing.xs),
            for (var i = 0; i < _values.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _values[i],
                        decoration: InputDecoration(
                          labelText: 'Giá trị ${i + 1}',
                          hintText: 'VD: Chocolate',
                        ),
                        onChanged: (_) {
                          // Typing into the last row grows the list.
                          if (i == _values.length - 1 &&
                              _values[i].text.trim().isNotEmpty) {
                            setState(() {
                              _values.add(TextEditingController());
                            });
                          }
                        },
                      ),
                    ),
                    if (i < _values.length - 1)
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Xóa giá trị',
                        onPressed: () => setState(() => _values.removeAt(i)),
                      ),
                  ],
                ),
              ),
            if (_error != null) ...[
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const Gap(AppSpacing.sm),
            ],
            const Gap(AppSpacing.sm),
            FilledButton(
              onPressed: isSaving ? null : _save,
              child: Text(isSaving ? 'Đang lưu…' : 'Lưu'),
            ),
          ],
        ),
      ),
    );
  }
}
