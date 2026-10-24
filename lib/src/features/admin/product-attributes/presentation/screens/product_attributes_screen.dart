import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/theme/app_spacing.dart';
import 'package:bakery_mobile/src/features/admin/product-attributes/domain/models/product_attribute_models.dart';
import 'package:bakery_mobile/src/features/admin/product-attributes/presentation/controllers/product_attributes_admin_view_model.dart';
import 'package:bakery_mobile/src/features/admin/product-attributes/presentation/widgets/attribute_edit_sheet.dart';
import 'package:bakery_mobile/src/shared/widgets/error_retry_widget.dart';

/// "Bộ lọc sản phẩm" admin: attribute catalogue list + create/edit/delete.
class ProductAttributesScreen extends ConsumerStatefulWidget {
  const ProductAttributesScreen({super.key});

  @override
  ConsumerState<ProductAttributesScreen> createState() =>
      _ProductAttributesScreenState();
}

class _ProductAttributesScreenState
    extends ConsumerState<ProductAttributesScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(productAttributesAdminViewModelProvider.notifier).load(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productAttributesAdminViewModelProvider);
    final vm = ref.read(productAttributesAdminViewModelProvider.notifier);

    ref.listen(productAttributesAdminViewModelProvider, (previous, next) {
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
                'Chưa có thuộc tính nào',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          : RefreshIndicator(
              onRefresh: vm.load,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: state.items.length,
                separatorBuilder: (_, _) => const Gap(AppSpacing.sm),
                itemBuilder: (context, index) => _AttributeCard(
                  attribute: state.items[index],
                  onEdit: () => showAttributeEditSheet(
                    context,
                    attribute: state.items[index],
                  ),
                  onDelete: () => _confirmDelete(state.items[index]),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAttributeEditSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm thuộc tính'),
      ),
    );
  }

  Future<void> _confirmDelete(AdminCatalogueAttribute attribute) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa thuộc tính?'),
        content: Text(
          '"${attribute.name}" và ${attribute.values.length} giá trị sẽ bị '
          'gỡ khỏi bộ lọc sản phẩm.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await ref
        .read(productAttributesAdminViewModelProvider.notifier)
        .remove(attribute.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Đã xóa thuộc tính'
                : (ref.read(productAttributesAdminViewModelProvider).error ??
                      'Xóa thất bại'),
          ),
        ),
      );
    }
  }
}

class _AttributeCard extends StatelessWidget {
  const _AttributeCard({
    required this.attribute,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminCatalogueAttribute attribute;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        title: Text(
          attribute.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          [
            attribute.type == 'MULTI_SELECT' ? 'Chọn nhiều' : 'Chọn một',
            if (attribute.values.isNotEmpty)
              attribute.values.map((v) => v.label).take(4).join(', '),
          ].join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: false,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Xóa thuộc tính',
          onPressed: onDelete,
        ),
        onTap: onEdit,
      ),
    );
  }
}
