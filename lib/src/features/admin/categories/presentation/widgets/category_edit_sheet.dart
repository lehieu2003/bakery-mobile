import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'package:bakery_mobile/src/core/theme/app_spacing.dart';
import 'package:bakery_mobile/src/features/admin/categories/domain/models/admin_category.dart';
import 'package:bakery_mobile/src/features/admin/categories/presentation/controllers/categories_admin_view_model.dart';

/// One selectable row of the parent dropdown (indent carries the depth).
typedef _ParentOption = ({AdminCategoryNode node, int depth});

/// Opens the category editor. [node] null = create (a new category, root
/// unless another parent is picked); otherwise the node is edited.
Future<void> showCategoryEditSheet(
  BuildContext context, {
  AdminCategoryNode? node,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CategoryEditSheet(node: node),
  );
}

class _CategoryEditSheet extends ConsumerStatefulWidget {
  const _CategoryEditSheet({required this.node});

  /// The category being edited, or null when creating.
  final AdminCategoryNode? node;

  @override
  ConsumerState<_CategoryEditSheet> createState() => _CategoryEditSheetState();
}

class _CategoryEditSheetState extends ConsumerState<_CategoryEditSheet> {
  late final TextEditingController _name = TextEditingController(
    text: widget.node?.name ?? '',
  );
  late final TextEditingController _slug = TextEditingController(
    text: widget.node?.slug ?? '',
  );
  String? _parentId;
  bool _parentInitialized = false;
  String? _nameError;
  String? _actionError;
  ScaffoldMessengerState? _messenger;

  @override
  void dispose() {
    _name.dispose();
    _slug.dispose();
    super.dispose();
  }

  /// Every category of the current tree except the edited node's own
  /// subtree (a category cannot be its own parent), flattened depth-first
  /// with its depth for the dropdown indent.
  List<_ParentOption> _parentOptions(List<AdminCategoryNode> tree) {
    final excluded = widget.node == null
        ? const <String>{}
        : widget.node!.flatten().map((node) => node.id).toSet();
    List<_ParentOption> walk(List<AdminCategoryNode> nodes, int depth) => [
      for (final node in nodes)
        if (!excluded.contains(node.id)) ...[
          (node: node, depth: depth),
          ...walk(node.children, depth + 1),
        ],
    ];
    return walk(tree, 0);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Tên danh mục không được để trống');
      return;
    }
    final id = widget.node?.id;
    final notifier = ref.read(categoriesAdminViewModelProvider.notifier);
    // Capture before the sheet pops — the element is gone afterwards.
    final messenger = _messenger ?? ScaffoldMessenger.maybeOf(context);
    final ok = await notifier.save(
      id: id,
      name: name,
      slug: _slug.text,
      parentId: _parentId,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            id == null ? 'Đã thêm danh mục' : 'Đã cập nhật danh mục',
          ),
        ),
      );
      return;
    }
    // A 401 already logged the admin out (no saveError) — nothing to show.
    final saveError = ref.read(categoriesAdminViewModelProvider).saveError;
    if (saveError != null) setState(() => _actionError = saveError);
  }

  /// The id of the category whose children contain [id] — the edited node's
  /// current parent, null when it is a root. ([AdminCategoryNode] carries no
  /// parentId, so it is looked up in the tree.)
  String? _findParentId(List<AdminCategoryNode> tree, String id) {
    for (final node in tree) {
      if (node.children.any((child) => child.id == id)) return node.id;
      final found = _findParentId(node.children, id);
      if (found != null) return found;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    _messenger ??= ScaffoldMessenger.maybeOf(context);
    final state = ref.watch(categoriesAdminViewModelProvider);
    final options = _parentOptions(state.tree);
    // Prefill the edited node's current parent once the tree is available.
    if (!_parentInitialized) {
      _parentInitialized = true;
      final editedId = widget.node?.id;
      _parentId = editedId == null ? null : _findParentId(state.tree, editedId);
    }
    // Keep a valid selection when the tree reloaded without the chosen
    // parent (e.g. it was just deleted in another sheet).
    if (_parentId != null &&
        !options.any((option) => option.node.id == _parentId)) {
      _parentId = null;
    }

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
            widget.node == null ? 'Thêm danh mục' : 'Chỉnh sửa danh mục',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _name,
            autofocus: widget.node == null,
            decoration: InputDecoration(
              labelText: 'Tên danh mục',
              errorText: _nameError,
            ),
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _slug,
            decoration: const InputDecoration(
              labelText: 'Slug',
              hintText: 'để trống tự sinh',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: _parentId,
            decoration: const InputDecoration(labelText: 'Danh mục cha'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Không có'),
              ),
              for (final option in options)
                DropdownMenuItem<String?>(
                  value: option.node.id,
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: AppSpacing.lg * option.depth,
                    ),
                    child: Text(option.node.name),
                  ),
                ),
            ],
            onChanged: (value) => setState(() => _parentId = value),
          ),
          if (_actionError != null) ...[
            const Gap(AppSpacing.sm),
            Text(
              _actionError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: state.isSaving ? null : _save,
            child: state.isSaving
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
