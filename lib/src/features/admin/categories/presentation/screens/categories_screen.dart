// Admin categories screen (section "Danh mục"): the tree rendered as flat
// rows indented by depth (the server tree is two levels deep and short, so
// no collapse state is kept — unlike an ExpansionTile this also makes every
// row's tap open the editor). Up/down reorder within a node's own level,
// delete behind a confirm dialog, FAB adds a root category.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/theme/app_spacing.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/admin/categories/domain/models/admin_category.dart';
import 'package:bakery_mobile/src/features/admin/categories/presentation/controllers/categories_admin_view_model.dart';
import 'package:bakery_mobile/src/features/admin/categories/presentation/widgets/category_edit_sheet.dart';
import 'package:bakery_mobile/src/shared/widgets/error_retry_widget.dart';

/// Admin categories screen (section "Danh mục"): tree, CRUD and reorder.
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  CategoriesAdminViewModel get _vm =>
      ref.read(categoriesAdminViewModelProvider.notifier);

  @override
  void initState() {
    super.initState();
    Future.microtask(_vm.load);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(categoriesAdminViewModelProvider);

    // Failures while the tree is on screen (a delete the server refused —
    // e.g. "still has products" — or a failed reorder) surface as a
    // snackbar; with an empty tree the retry state below renders them.
    ref.listen<CategoriesAdminState>(categoriesAdminViewModelProvider, (
      prev,
      next,
    ) {
      final error = next.error;
      if (error == null || error == prev?.error) return;
      if (next.tree.isEmpty) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    });

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCategoryEditSheet(context),
        tooltip: 'Thêm danh mục',
        child: const Icon(Icons.add),
      ),
      body: _CategoriesBody(
        state: state,
        onRetry: _vm.retry,
        onRefresh: _vm.load,
      ),
    );
  }
}

/// Loading / retry / empty / tree body of the categories screen.
class _CategoriesBody extends StatelessWidget {
  const _CategoriesBody({
    required this.state,
    required this.onRetry,
    required this.onRefresh,
  });

  final CategoriesAdminState state;
  final VoidCallback onRetry;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.tree.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.tree.isEmpty) {
      return ErrorRetryWidget(message: state.error!, onRetry: onRetry);
    }
    if (state.tree.isEmpty) {
      return const _EmptyCategories();
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.x3l,
        ),
        children: [
          for (final (index, node) in state.tree.indexed)
            ..._rowsOf(node, siblings: state.tree, index: index, depth: 0),
        ],
      ),
    );
  }

  /// A node's row followed by its subtree's rows (depth-first, the order
  /// the flat tree renders in).
  List<Widget> _rowsOf(
    AdminCategoryNode node, {
    required List<AdminCategoryNode> siblings,
    required int index,
    required int depth,
  }) {
    return [
      _CategoryRow(node: node, siblings: siblings, index: index, depth: depth),
      for (final (childIndex, child) in node.children.indexed)
        ..._rowsOf(
          child,
          siblings: node.children,
          index: childIndex,
          depth: depth + 1,
        ),
    ];
  }
}

/// "Nothing here yet" state with a hint towards the FAB.
class _EmptyCategories extends StatelessWidget {
  const _EmptyCategories();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.category_outlined,
            size: 44,
            color: AppTheme.warmBrown,
          ),
          const Gap(AppSpacing.md),
          Text(
            'Chưa có danh mục',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const Gap(AppSpacing.sm),
          Text(
            'Thêm danh mục gốc bằng nút + ở dưới',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// One category row: name + slug, up/down (same-level reorder, disabled at
/// the level's edges), delete (confirm-guarded) and tap → the edit sheet.
/// Indented by [depth] levels.
class _CategoryRow extends ConsumerWidget {
  const _CategoryRow({
    required this.node,
    required this.siblings,
    required this.index,
    required this.depth,
  });

  final AdminCategoryNode node;
  final List<AdminCategoryNode> siblings;
  final int index;
  final int depth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(left: depth * AppSpacing.xl),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        leading: Icon(
          node.children.isEmpty
              ? Icons.category_outlined
              : Icons.folder_outlined,
          color: AppTheme.warmBrown,
        ),
        title: Text(
          node.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.inkBrown,
          ),
        ),
        subtitle: Text(
          node.slug,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.warmBrown),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_upward),
              iconSize: 20,
              tooltip: 'Đưa lên',
              // Disabled at the top of its own level.
              onPressed: index > 0
                  ? () => ref
                        .read(categoriesAdminViewModelProvider.notifier)
                        .move(node.id, -1)
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.arrow_downward),
              iconSize: 20,
              tooltip: 'Đưa xuống',
              // Disabled at the bottom of its own level.
              onPressed: index < siblings.length - 1
                  ? () => ref
                        .read(categoriesAdminViewModelProvider.notifier)
                        .move(node.id, 1)
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              iconSize: 20,
              tooltip: 'Xóa',
              onPressed: () => _confirmDelete(context, ref),
            ),
          ],
        ),
        onTap: () => showCategoryEditSheet(context, node: node),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xóa danh mục?'),
          content: Text(
            '"${node.name}" sẽ bị xóa. Danh mục còn danh mục con hoặc sản phẩm '
            'sẽ bị máy chủ từ chối.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await ref
        .read(categoriesAdminViewModelProvider.notifier)
        .delete(node.id);
    if (!context.mounted) return;
    // A refusal (state.error) is already surfaced as a snackbar by the
    // screen's ref.listen — only announce successes here.
    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã xóa danh mục')));
    }
  }
}
