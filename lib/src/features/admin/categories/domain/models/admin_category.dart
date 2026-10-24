/// Admin view of one category node in the tree returned by
/// `GET /api/admin/categories` (roots with nested `children`, two levels
/// deep). Leaves simply carry an empty [children] list.
class AdminCategoryNode {
  const AdminCategoryNode({
    required this.id,
    required this.name,
    required this.slug,
    this.children = const [],
  });

  final String id;
  final String name;
  final String slug;

  /// Direct child categories, already ordered by displayOrder server-side.
  final List<AdminCategoryNode> children;

  /// Flattens this node's subtree depth-first, self first — the order
  /// dropdowns and the reorder list render.
  List<AdminCategoryNode> flatten() {
    return [this, ...children.expand((child) => child.flatten())];
  }

  /// Flattens a whole forest of roots depth-first (each root followed by
  /// its subtree), e.g. for a flat parent-picker dropdown.
  static List<AdminCategoryNode> flattenAll(Iterable<AdminCategoryNode> roots) {
    return roots.expand((root) => root.flatten()).toList();
  }
}
