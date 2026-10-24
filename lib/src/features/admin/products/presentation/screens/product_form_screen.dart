import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/theme/app_radius.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/admin/products/presentation/controllers/product_form_view_model.dart';
import 'package:bakery_mobile/src/features/admin/products/presentation/widgets/product_attributes_section.dart';
import 'package:bakery_mobile/src/features/admin/products/presentation/widgets/product_images_section.dart';
import 'package:bakery_mobile/src/features/admin/products/presentation/widgets/product_variants_section.dart';
import 'package:bakery_mobile/src/shared/widgets/error_retry_widget.dart';

/// Create/edit product form (phase 4b). Sections land in stages: T2 info +
/// category, T3 images, T4 variants + attribute filters; T5 wires save.
class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.productId});

  final String? productId;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.productId != null) {
      Future.microtask(
        () => ref
            .read(productFormViewModelProvider(widget.productId).notifier)
            .load(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productFormViewModelProvider(widget.productId));
    final isEdit = widget.productId != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Sửa sản phẩm' : 'Thêm sản phẩm')),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
          ? ErrorRetryWidget(
              message: state.error!,
              onRetry: () => ref
                  .read(productFormViewModelProvider(widget.productId).notifier)
                  .load(),
            )
          : _buildForm(context, state),
      bottomNavigationBar: _SaveBar(state: state),
    );
  }

  Widget _buildForm(BuildContext context, ProductFormState state) {
    final vm = ref.read(
      productFormViewModelProvider(widget.productId).notifier,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionCard(
            title: 'Thông tin',
            child: Column(
              children: [
                TextField(
                  controller: TextEditingController(text: state.name)
                    ..selection = TextSelection.collapsed(
                      offset: state.name.length,
                    ),
                  decoration: const InputDecoration(labelText: 'Tên sản phẩm'),
                  onChanged: vm.setName,
                ),
                const Gap(AppSpacing.md),
                TextField(
                  controller: TextEditingController(text: state.slug)
                    ..selection = TextSelection.collapsed(
                      offset: state.slug.length,
                    ),
                  decoration: const InputDecoration(
                    labelText: 'Slug',
                    hintText: 'để trống tự sinh',
                  ),
                  onChanged: vm.setSlug,
                ),
                const Gap(AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: state.priceText)
                          ..selection = TextSelection.collapsed(
                            offset: state.priceText.length,
                          ),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Giá (₫)'),
                        onChanged: vm.setPriceText,
                      ),
                    ),
                    const Gap(AppSpacing.md),
                    Expanded(
                      child: TextField(
                        controller:
                            TextEditingController(text: state.comparePriceText)
                              ..selection = TextSelection.collapsed(
                                offset: state.comparePriceText.length,
                              ),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Giá so sánh (không bắt buộc)',
                        ),
                        onChanged: vm.setComparePriceText,
                      ),
                    ),
                  ],
                ),
                const Gap(AppSpacing.md),
                TextField(
                  controller: TextEditingController(text: state.stockText)
                    ..selection = TextSelection.collapsed(
                      offset: state.stockText.length,
                    ),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Tồn kho'),
                  onChanged: vm.setStockText,
                ),
                const Gap(AppSpacing.md),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Đang bán'),
                  value: state.isActive,
                  onChanged: vm.setIsActive,
                ),
                const Gap(AppSpacing.md),
                TextField(
                  controller:
                      TextEditingController(text: state.shortDescription)
                        ..selection = TextSelection.collapsed(
                          offset: state.shortDescription.length,
                        ),
                  decoration: const InputDecoration(labelText: 'Mô tả ngắn'),
                  maxLines: 2,
                  onChanged: vm.setShortDescription,
                ),
                const Gap(AppSpacing.md),
                TextField(
                  controller: TextEditingController(text: state.description)
                    ..selection = TextSelection.collapsed(
                      offset: state.description.length,
                    ),
                  decoration: const InputDecoration(labelText: 'Mô tả đầy đủ'),
                  maxLines: 5,
                  onChanged: vm.setDescription,
                ),
              ],
            ),
          ),
          const Gap(AppSpacing.md),
          _CategorySection(state: state),
          const Gap(AppSpacing.md),
          _SectionCard(
            title: 'Ảnh',
            child: ProductImagesSection(productId: widget.productId),
          ),
          const Gap(AppSpacing.md),
          _SectionCard(
            title: 'Biến thể',
            child: ProductVariantsSection(productId: widget.productId),
          ),
          const Gap(AppSpacing.md),
          _SectionCard(
            title: 'Bộ lọc sản phẩm',
            child: ProductAttributesSection(productId: widget.productId),
          ),
          const Gap(AppSpacing.xl),
        ],
      ),
    );
  }
}

class _CategorySection extends ConsumerWidget {
  const _CategorySection({required this.state});

  final ProductFormState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesAdminRepositoryProvider);
    // The tree loads asynchronously; keep the pick even before it lands.
    return FutureBuilder(
      future: categories.getCategories(),
      builder: (context, snapshot) {
        final flat = <({String id, String name})>[
          (id: '', name: 'Không có'),
          if (snapshot.hasData)
            for (final node in snapshot.data!) (id: node.id, name: node.name),
        ];
        return _SectionCard(
          title: 'Danh mục',
          child: DropdownButtonFormField<String>(
            value: flat.any((c) => c.id == (state.categoryId ?? ''))
                ? (state.categoryId ?? '')
                : null,
            items: [
              for (final c in flat)
                DropdownMenuItem(value: c.id, child: Text(c.name)),
            ],
            onChanged: (v) => ref
                .read(productFormViewModelProvider(state.detail?.id).notifier)
                .setCategory(v == '' ? null : v),
            decoration: const InputDecoration(labelText: 'Chọn danh mục'),
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.canvasCream,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: AppTheme.warmBrown.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Gap(AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _SaveBar extends ConsumerWidget {
  const _SaveBar({required this.state});

  final ProductFormState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: FilledButton(
          onPressed: state.isSaving
              ? null
              : () {
                  final message = state.validate();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        message ?? 'Form hợp lệ — lưu sẽ được nối ở tác vụ lưu',
                      ),
                    ),
                  );
                },
          child: state.isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Lưu'),
        ),
      ),
    );
  }
}
