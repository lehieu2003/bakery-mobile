import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/theme/app_durations.dart';
import 'package:bakery_mobile/src/core/theme/app_spacing.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/admin/categories/domain/models/admin_category.dart';
import 'package:bakery_mobile/src/features/admin/products/domain/models/admin_product.dart';
import 'package:bakery_mobile/src/features/admin/products/presentation/controllers/products_admin_view_model.dart';
import 'package:bakery_mobile/src/features/admin/products/presentation/screens/product_form_screen.dart';
import 'package:bakery_mobile/src/features/admin/shared/presentation/widgets/admin_paged_list.dart';
import 'package:bakery_mobile/src/shared/utils/format_utils.dart';
import 'package:bakery_mobile/src/shared/widgets/app_network_image_widget.dart';

/// Status filter chips: 'Tất cả' plus on-sale / paused.
final List<AdminFilterChip> _statusFilters = [
  const AdminFilterChip(label: 'Tất cả', value: allStatusesFilter),
  const AdminFilterChip(label: 'Đang bán', value: activeStatusFilter),
  const AdminFilterChip(label: 'Tạm ngừng', value: inactiveStatusFilter),
];

/// Admin products list (section "Sản phẩm"): server-side search, client-side
/// status + category filters and infinite scroll. Long-pressing a card
/// enters multi-select mode for bulk delete; the FAB announces the product
/// form coming in phase 4b.
class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  /// Raw text of the search field. Kept here (not read back from the VM's
  /// trimmed, debounced `search`) so rebuilds never overwrite what the admin
  /// is still typing.
  String _searchText = '';
  Timer? _debounce;

  ProductsAdminViewModel get _vm =>
      ref.read(productsAdminViewModelProvider.notifier);

  @override
  void initState() {
    super.initState();
    _searchText = ref.read(productsAdminViewModelProvider).search;
    Future.microtask(() {
      _vm.load();
      _vm.loadCategories();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _searchText = value);
    _debounce?.cancel();
    _debounce = Timer(AppDurations.searchDebounce, () => _vm.setSearch(value));
  }

  Future<void> _confirmBulkDelete() async {
    final count = ref.read(productsAdminViewModelProvider).selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Xóa $count sản phẩm?'),
          content: const Text(
            'Các sản phẩm được chọn sẽ bị xóa vĩnh viễn. Sản phẩm đã bị xóa ở '
            'nơi khác sẽ được bỏ qua.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Huỷ'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    // The outcome surfaces as the report snackbar via ref.listen below.
    await _vm.bulkDelete();
  }

  Future<void> _openEditForm(String productId) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductFormScreen(productId: productId),
      ),
    );
    _vm.load();
  }

  Future<void> _openCreateForm() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ProductFormScreen(productId: null),
      ),
    );
    _vm.load();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productsAdminViewModelProvider);

    // Errors and bulk-delete outcomes surface as snackbars whenever the
    // paged list itself does not render them (see its footer logic).
    ref.listen<ProductsAdminState>(productsAdminViewModelProvider, (
      prev,
      next,
    ) {
      final report = next.report;
      if (report != null && report != prev?.report) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(report)));
        return;
      }
      final error = next.error;
      if (error == null || error == prev?.error) return;
      if (next.visibleItems.isEmpty || next.hasMore) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    });

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateForm,
        icon: const Icon(Icons.add),
        label: const Text('Thêm sản phẩm'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.isSelecting)
            _SelectionBar(
              count: state.selectedIds.length,
              isDeleting: state.isDeleting,
              onCancel: _vm.clearSelection,
              onDelete: _confirmBulkDelete,
            ),
          _CategoryDropdown(
            categories: state.categories,
            value: state.categoryFilter,
            onChanged: _vm.setCategory,
          ),
          Expanded(
            child: AdminPagedList<AdminProductListItem>(
              items: state.visibleItems,
              isLoading: state.isLoading,
              error: state.error,
              onRetry: _vm.retry,
              isLoadingMore: state.isLoadingMore,
              hasMore: state.hasMore,
              onLoadMore: _vm.loadMore,
              onRefresh: _vm.load,
              itemBuilder: (context, product) => _ProductCard(
                product: product,
                isSelecting: state.isSelecting,
                isSelected: state.selectedIds.contains(product.id),
                onToggleSelect: () => _vm.toggleSelect(product.id),
                onOpen: () => _openEditForm(product.id),
              ),
              searchHint: 'Tìm sản phẩm…',
              searchText: _searchText,
              onSearchChanged: _onSearchChanged,
              filters: _statusFilters,
              selectedFilter: state.statusFilter ?? allStatusesFilter,
              onFilterSelected: (value) =>
                  _vm.setStatusFilter(value ?? allStatusesFilter),
              emptyText: 'Chưa có sản phẩm',
            ),
          ),
        ],
      ),
    );
  }
}

/// Contextual bar shown while products are selected: cancel X, 'N đã chọn',
/// bulk-delete action (a spinner while the deletes run).
class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    required this.count,
    required this.isDeleting,
    required this.onCancel,
    required this.onDelete,
  });

  final int count;
  final bool isDeleting;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.primaryPink,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Huỷ chọn',
              icon: const Icon(Icons.close),
              color: AppTheme.inkBrown,
              onPressed: onCancel,
            ),
            Expanded(
              child: Text(
                '$count đã chọn',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.inkBrown,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (isDeleting)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                tooltip: 'Xóa đã chọn',
                icon: const Icon(Icons.delete_outline),
                color: AppTheme.inkBrown,
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

/// Category filter dropdown above the list: 'Tất cả danh mục' plus every
/// category of the flattened tree. The chosen id filters the loaded
/// products client-side.
class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.categories,
    required this.value,
    required this.onChanged,
  });

  final List<AdminCategoryNode> categories;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    // Keep the selection valid when the chosen category is no longer in the
    // (possibly failed-to-load) tree.
    final effectiveValue = value != null && categories.any((c) => c.id == value)
        ? value
        : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: DropdownButtonFormField<String?>(
        value: effectiveValue,
        isDense: true,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.category_outlined),
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('Tất cả danh mục'),
          ),
          for (final category in categories)
            DropdownMenuItem<String?>(
              value: category.id,
              child: Text(category.name),
            ),
        ],
        onChanged: categories.isEmpty ? null : onChanged,
      ),
    );
  }
}

/// One row of the admin products list: thumbnail, name, price (+ crossed-out
/// pre-sale price), stock and the status pill. Long-press enters selection
/// mode; in it, tapping toggles the card's checkbox.
class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.isSelecting,
    required this.isSelected,
    required this.onToggleSelect,
    required this.onOpen,
  });

  final AdminProductListItem product;
  final VoidCallback onOpen;
  final bool isSelecting;
  final bool isSelected;
  final VoidCallback onToggleSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: AppTheme.warmBrown,
    );
    // The server sends 0 (or null) when the product is not on sale.
    final onSale = product.comparePrice != null && product.comparePrice! > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      color: isSelected ? theme.colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: isSelecting ? onToggleSelect : onOpen,
        onLongPress: onToggleSelect,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              if (isSelecting) ...[
                Checkbox(value: isSelected, onChanged: (_) => onToggleSelect()),
                const Gap(AppSpacing.sm),
              ],
              AppNetworkImageWidget(
                url: product.thumbnailUrl,
                width: 56,
                height: 56,
                borderRadius: BorderRadius.circular(8),
                iconSize: 24,
              ),
              const Gap(AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.inkBrown,
                      ),
                    ),
                    const Gap(AppSpacing.xs),
                    Row(
                      children: [
                        Text(
                          formatVnd(product.price),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (onSale) ...[
                          const Gap(AppSpacing.sm),
                          Text(
                            formatVnd(product.comparePrice!),
                            style: muted?.copyWith(
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const Gap(AppSpacing.xs),
                    Text(
                      'Kho: ${product.stock}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: muted,
                    ),
                  ],
                ),
              ),
              const Gap(AppSpacing.sm),
              _StatusPill(isActive: product.isActive),
            ],
          ),
        ),
      ),
    );
  }
}

/// Status pill: 'Đang bán' on soft green, 'Tạm ngừng' on neutral grey
/// (Tailwind hues like the web admin / member-level badge).
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    const activeStyle = (
      background: Color(0xFFECFDF5),
      foreground: Color(0xFF047857),
      border: Color(0xFFA7F3D0),
    );
    const inactiveStyle = (
      background: Color(0xFFF3F4F6),
      foreground: Color(0xFF4B5563),
      border: Color(0xFFE5E7EB),
    );
    final style = isActive ? activeStyle : inactiveStyle;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.border),
      ),
      child: Text(
        isActive ? 'Đang bán' : 'Tạm ngừng',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: style.foreground,
        ),
      ),
    );
  }
}
