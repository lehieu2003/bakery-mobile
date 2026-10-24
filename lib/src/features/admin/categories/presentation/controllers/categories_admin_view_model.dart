import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/features/admin/categories/domain/models/admin_category.dart';
import 'package:bakery_mobile/src/shared/utils/error_message.dart';

/// Immutable UI state for the admin categories tree screen.
class CategoriesAdminState {
  const CategoriesAdminState({
    this.tree = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.saveError,
  });

  /// Root category nodes with nested children, in display order.
  final List<AdminCategoryNode> tree;

  /// True while the tree is being (re)loaded.
  final bool isLoading;

  /// True while a create/update from the edit sheet is in flight.
  final bool isSaving;

  /// Failure of the last load, delete or reorder — the retry state when the
  /// tree is empty, a snackbar otherwise.
  final String? error;

  /// Failure of the last create/update — shown inside the edit sheet.
  final String? saveError;

  CategoriesAdminState copyWith({
    List<AdminCategoryNode>? tree,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
    String? saveError,
    bool clearSaveError = false,
  }) {
    return CategoriesAdminState(
      tree: tree ?? this.tree,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      saveError: clearSaveError ? null : (saveError ?? this.saveError),
    );
  }
}

/// Drives the admin categories screen: tree load, create/update via the edit
/// sheet, delete and same-level reordering. Every successful mutation reloads
/// the whole tree (server order, generated slugs and nesting stay truthful);
/// a 401 logs the admin out instead of surfacing an error.
class CategoriesAdminViewModel extends Notifier<CategoriesAdminState> {
  /// Bumped by every [load]; responses of superseded requests are dropped.
  int _generation = 0;

  @override
  CategoriesAdminState build() => const CategoriesAdminState();

  /// (Re)loads the category tree.
  Future<void> load() async {
    final generation = ++_generation;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final tree = await ref
          .read(categoriesAdminRepositoryProvider)
          .getCategories();
      if (generation != _generation) return;
      state = state.copyWith(tree: tree, isLoading: false);
    } catch (error) {
      if (generation != _generation) return;
      await _fail(error);
    }
  }

  /// Retries a failed [load].
  Future<void> retry() => load();

  /// Creates ([id] null) or updates ([id] set) a category. [name] and [slug]
  /// are trimmed; an empty [slug] is sent as null (the server slugifies the
  /// name), a null [parentId] means root. Returns true on success — the tree
  /// is reloaded — false with [CategoriesAdminState.saveError] otherwise.
  Future<bool> save({
    String? id,
    required String name,
    String? slug,
    String? parentId,
  }) async {
    if (state.isSaving) return false;
    final trimmedName = name.trim();
    final trimmedSlug = slug?.trim();
    state = state.copyWith(isSaving: true, clearSaveError: true);
    final repo = ref.read(categoriesAdminRepositoryProvider);
    try {
      if (id == null) {
        await repo.createCategory(
          name: trimmedName,
          slug: (trimmedSlug == null || trimmedSlug.isEmpty)
              ? null
              : trimmedSlug,
          parentId: parentId,
        );
      } else {
        await repo.updateCategory(
          id,
          name: trimmedName,
          slug: (trimmedSlug == null || trimmedSlug.isEmpty)
              ? null
              : trimmedSlug,
          parentId: parentId,
        );
      }
    } catch (error) {
      if (await _logoutOn401(error)) {
        state = state.copyWith(isSaving: false);
        return false;
      }
      state = state.copyWith(
        isSaving: false,
        saveError: userErrorMessage(error),
      );
      return false;
    }
    await load();
    state = state.copyWith(isSaving: false);
    return true;
  }

  /// Deletes a category. Returns true on success (tree reloaded); false
  /// otherwise with the server's refusal (e.g. "still has products") in
  /// [CategoriesAdminState.error] — the tree stays on screen.
  Future<bool> delete(String id) async {
    try {
      await ref.read(categoriesAdminRepositoryProvider).deleteCategory(id);
    } catch (error) {
      if (await _logoutOn401(error)) return false;
      state = state.copyWith(error: userErrorMessage(error));
      return false;
    }
    await load();
    return true;
  }

  /// Moves [id] one slot within its sibling level ([delta] -1 = up,
  /// +1 = down): the swap is applied optimistically, the new sibling order
  /// persisted via `reorderCategories` and the tree reloaded (which also
  /// reverts the optimistic move when the server refuses). A no-op when the
  /// node is already at the edge of its level.
  Future<void> move(String id, int delta) async {
    final reordered = _movedWithinLevel(state.tree, id, delta);
    if (identical(reordered, state.tree)) return;
    state = state.copyWith(tree: reordered);
    String? failure;
    try {
      await ref
          .read(categoriesAdminRepositoryProvider)
          .reorderCategories(_siblingIdsOf(reordered, id));
    } catch (error) {
      if (await _logoutOn401(error)) return;
      failure = userErrorMessage(error);
    }
    // Reload reverts the optimistic move when the server refused (and
    // picks up the persisted order otherwise) — and clears `error`, so a
    // refusal is (re-)surfaced afterwards, unless the reload itself failed.
    await load();
    if (failure != null && state.error == null) {
      state = state.copyWith(error: failure);
    }
  }

  /// Returns [nodes] with [id] swapped [delta] slots within the sibling list
  /// holding it, or the very same list instance when nothing can move (not
  /// found / already at the edge).
  List<AdminCategoryNode> _movedWithinLevel(
    List<AdminCategoryNode> nodes,
    String id,
    int delta,
  ) {
    final index = nodes.indexWhere((node) => node.id == id);
    if (index >= 0) {
      final target = index + delta;
      if (target < 0 || target >= nodes.length) return nodes;
      final list = [...nodes];
      final moved = list.removeAt(index);
      list.insert(target, moved);
      return list;
    }
    // Not at this level — rebuild the branch whose subtree contains the node.
    final result = <AdminCategoryNode>[];
    var changed = false;
    for (final node in nodes) {
      final children = _movedWithinLevel(node.children, id, delta);
      if (identical(children, node.children)) {
        result.add(node);
      } else {
        changed = true;
        result.add(
          AdminCategoryNode(
            id: node.id,
            name: node.name,
            slug: node.slug,
            children: children,
          ),
        );
      }
    }
    return changed ? result : nodes;
  }

  /// The sibling ids of [id]'s level within [tree], in their current order —
  /// the payload `reorderCategories` expects.
  List<String> _siblingIdsOf(List<AdminCategoryNode> tree, String id) {
    if (tree.any((node) => node.id == id)) {
      return [for (final node in tree) node.id];
    }
    for (final node in tree) {
      final found = _siblingIdsOf(node.children, id);
      if (found.isNotEmpty) return found;
    }
    return const [];
  }

  Future<bool> _logoutOn401(Object error) async {
    if (error is ApiException && error.statusCode == 401) {
      await ref.read(authViewModelProvider.notifier).logout();
      return true;
    }
    return false;
  }

  Future<void> _fail(Object error) async {
    if (await _logoutOn401(error)) {
      state = state.copyWith(isLoading: false, clearError: true);
      return;
    }
    state = state.copyWith(isLoading: false, error: userErrorMessage(error));
  }
}

/// Note: unlike most VM providers (centralised in `core/di/app_providers.dart`)
/// this one lives next to its VM — the Task 2 file list allows touching only
/// the categories feature files.
final categoriesAdminViewModelProvider =
    NotifierProvider<CategoriesAdminViewModel, CategoriesAdminState>(
      CategoriesAdminViewModel.new,
    );
