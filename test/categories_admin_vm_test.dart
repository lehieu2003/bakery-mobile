import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/admin/categories/data/datasources/category_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/categories/data/repositories/category_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/categories/domain/models/admin_category.dart';
import 'package:bakery_mobile/src/features/admin/categories/presentation/controllers/categories_admin_view_model.dart';
import 'package:bakery_mobile/src/features/admin/categories/presentation/screens/categories_screen.dart';
import 'package:bakery_mobile/src/features/auth/domain/models/user.dart';
import 'package:bakery_mobile/src/features/auth/presentation/controllers/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AdminCategoryNode _node(
  String id,
  String name, [
  List<AdminCategoryNode> children = const [],
]) {
  return AdminCategoryNode(
    id: id,
    name: name,
    slug: 'slug-$id',
    children: children,
  );
}

/// The sample tree every test starts from (two levels, server order).
List<AdminCategoryNode> _sampleTree() {
  return [
    _node('cat-1', 'Bánh mì', [
      _node('cat-1a', 'Bánh mì cay'),
      _node('cat-1b', 'Bánh mì chà bông'),
    ]),
    _node('cat-2', 'Bánh ngọt', [_node('cat-2a', 'Bánh su kem')]),
    _node('cat-3', 'Đồ uống'),
  ];
}

/// One recorded save (create when [id] is null, update otherwise).
typedef _SaveCall = ({String? id, String name, String? slug, String? parentId});

/// Fake repository: records every call and serves [tree]; the `*Error`
/// fields (when set) are thrown by the matching method instead. A recorded
/// reorder is applied to [tree] so a reload reflects the new order.
class _FakeCategoryAdminRepository extends CategoryAdminRepository {
  _FakeCategoryAdminRepository()
    : super(
        CategoryAdminApiService(
          ApiClient(
            baseUrl: 'http://localhost:1',
            tokenProvider: () async => null,
          ),
        ),
      );

  List<AdminCategoryNode> tree = _sampleTree();
  int loadCount = 0;
  final List<_SaveCall> saves = [];
  final List<String> deletedIds = [];
  final List<List<String>> reorders = [];

  Object? loadError;
  Object? saveError;
  Object? deleteError;
  Object? reorderError;

  @override
  Future<List<AdminCategoryNode>> getCategories() async {
    loadCount++;
    final thrown = loadError;
    if (thrown != null) throw thrown;
    return tree;
  }

  @override
  Future<AdminCategoryNode> createCategory({
    required String name,
    String? slug,
    String? parentId,
  }) async {
    return _recordSave(id: null, name: name, slug: slug, parentId: parentId);
  }

  @override
  Future<AdminCategoryNode> updateCategory(
    String id, {
    String? name,
    String? slug,
    String? parentId,
  }) async {
    return _recordSave(
      id: id,
      name: name ?? '',
      slug: slug,
      parentId: parentId,
    );
  }

  Future<AdminCategoryNode> _recordSave({
    required String? id,
    required String name,
    String? slug,
    String? parentId,
  }) async {
    saves.add((id: id, name: name, slug: slug, parentId: parentId));
    final thrown = saveError;
    if (thrown != null) throw thrown;
    return _node('cat-9', name);
  }

  @override
  Future<void> deleteCategory(String id) async {
    deletedIds.add(id);
    final thrown = deleteError;
    if (thrown != null) throw thrown;
  }

  @override
  Future<void> reorderCategories(List<String> orderedIds) async {
    reorders.add(List.of(orderedIds));
    final thrown = reorderError;
    if (thrown != null) throw thrown;
    tree = _applyReorder(tree, orderedIds);
  }

  /// Replaces whichever sibling level matches [orderedIds] (as a set) with
  /// the new order, mirroring what the real backend persists.
  static List<AdminCategoryNode> _applyReorder(
    List<AdminCategoryNode> nodes,
    List<String> orderedIds,
  ) {
    if (nodes.isEmpty) return nodes;
    final nodeIds = nodes.map((node) => node.id).toSet();
    final wanted = orderedIds.toSet();
    if (nodeIds.containsAll(wanted) && wanted.containsAll(nodeIds)) {
      final byId = {for (final node in nodes) node.id: node};
      return [for (final id in orderedIds) byId[id]!];
    }
    return [
      for (final node in nodes)
        AdminCategoryNode(
          id: node.id,
          name: node.name,
          slug: node.slug,
          children: _applyReorder(node.children, orderedIds),
        ),
    ];
  }
}

class _FakeAuthViewModel extends AuthViewModel {
  int logoutCalls = 0;

  @override
  AuthState build() => const AuthState(
    user: User(
      id: 'a-1',
      email: 'admin@bakery.vn',
      name: 'Hieu',
      role: 'ADMIN',
    ),
  );

  @override
  Future<void> logout() async {
    logoutCalls++;
    state = state.copyWith(clearUser: true);
  }
}

void main() {
  late _FakeCategoryAdminRepository repo;
  late _FakeAuthViewModel auth;
  late ProviderContainer container;

  setUp(() {
    repo = _FakeCategoryAdminRepository();
    auth = _FakeAuthViewModel();
    container = ProviderContainer(
      overrides: [
        categoriesAdminRepositoryProvider.overrideWithValue(repo),
        authViewModelProvider.overrideWith(() => auth),
      ],
    );
    addTearDown(container.dispose);
  });

  test('load() puts the roots, with nested children, into state', () async {
    await container.read(categoriesAdminViewModelProvider.notifier).load();

    final state = container.read(categoriesAdminViewModelProvider);
    expect(repo.loadCount, 1);
    expect(state.tree.map((node) => node.id), ['cat-1', 'cat-2', 'cat-3']);
    expect(state.tree.first.children.map((node) => node.id), [
      'cat-1a',
      'cat-1b',
    ]);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
  });

  test('create sends name + parentId with slug null when left empty', () async {
    final vm = container.read(categoriesAdminViewModelProvider.notifier);
    await vm.load();

    final ok = await vm.save(
      name: ' Bánh tart ',
      slug: '   ',
      parentId: 'cat-1',
    );

    expect(ok, isTrue);
    expect(repo.saves.single, (
      id: null,
      name: 'Bánh tart',
      slug: null,
      parentId: 'cat-1',
    ));
    // The tree is re-fetched after every successful mutation.
    expect(repo.loadCount, 2);
  });

  test('update renames through updateCategory with the trimmed name', () async {
    final vm = container.read(categoriesAdminViewModelProvider.notifier);
    await vm.load();

    final ok = await vm.save(
      id: 'cat-3',
      name: 'Đồ uống lạnh',
      slug: 'do-uong-lanh',
      parentId: null,
    );

    expect(ok, isTrue);
    expect(repo.saves.single, (
      id: 'cat-3',
      name: 'Đồ uống lạnh',
      slug: 'do-uong-lanh',
      parentId: null,
    ));
    expect(repo.loadCount, 2);
  });

  test('save failure lands in saveError without touching the tree', () async {
    repo.saveError = ApiException('Tên danh mục đã tồn tại', statusCode: 400);
    final vm = container.read(categoriesAdminViewModelProvider.notifier);
    await vm.load();

    final ok = await vm.save(name: 'Bánh mì', slug: null, parentId: null);

    expect(ok, isFalse);
    final state = container.read(categoriesAdminViewModelProvider);
    expect(state.saveError, 'Tên danh mục đã tồn tại');
    expect(state.error, isNull);
    expect(state.isSaving, isFalse);
    expect(repo.loadCount, 1); // no reload after a failed save
  });

  test('delete failure surfaces the server message in state.error', () async {
    repo.deleteError = ApiException(
      'Cannot delete category with 3 products',
      statusCode: 400,
    );
    final vm = container.read(categoriesAdminViewModelProvider.notifier);
    await vm.load();

    final ok = await vm.delete('cat-1');

    expect(ok, isFalse);
    final state = container.read(categoriesAdminViewModelProvider);
    expect(state.error, 'Cannot delete category with 3 products');
    expect(state.tree, isNotEmpty); // the tree stays on screen
    expect(repo.loadCount, 1);
  });

  test('delete success calls the repo and reloads the tree', () async {
    final vm = container.read(categoriesAdminViewModelProvider.notifier);
    await vm.load();

    final ok = await vm.delete('cat-3');

    expect(ok, isTrue);
    expect(repo.deletedIds, ['cat-3']);
    expect(repo.loadCount, 2);
  });

  test('move up at root level sends the new sibling order', () async {
    final vm = container.read(categoriesAdminViewModelProvider.notifier);
    await vm.load();

    await vm.move('cat-2', -1);

    expect(repo.reorders.single, ['cat-2', 'cat-1', 'cat-3']);
    // Optimistic order + reload: the fake applied the reorder to its tree.
    final state = container.read(categoriesAdminViewModelProvider);
    expect(state.tree.map((node) => node.id), ['cat-2', 'cat-1', 'cat-3']);
    expect(state.error, isNull);
  });

  test('move up within a parent reorders that level only', () async {
    final vm = container.read(categoriesAdminViewModelProvider.notifier);
    await vm.load();

    await vm.move('cat-1b', -1);

    expect(repo.reorders.single, ['cat-1b', 'cat-1a']);
    final state = container.read(categoriesAdminViewModelProvider);
    expect(state.tree.map((node) => node.id), ['cat-1', 'cat-2', 'cat-3']);
    expect(state.tree.first.children.map((node) => node.id), [
      'cat-1b',
      'cat-1a',
    ]);
  });

  test(
    'move failure reverts through a reload and surfaces the error',
    () async {
      repo.reorderError = ApiException('Không thể lưu thứ tự', statusCode: 500);
      final vm = container.read(categoriesAdminViewModelProvider.notifier);
      await vm.load();

      await vm.move('cat-2', -1);

      final state = container.read(categoriesAdminViewModelProvider);
      expect(state.error, 'Không thể lưu thứ tự');
      // The optimistic move was rolled back by the reload (fake tree
      // unchanged because the reorder threw).
      expect(state.tree.map((node) => node.id), ['cat-1', 'cat-2', 'cat-3']);
    },
  );

  test(
    '401 on load logs out through AuthViewModel and sets no error',
    () async {
      repo.loadError = ApiException('Unauthorized', statusCode: 401);
      await container.read(categoriesAdminViewModelProvider.notifier).load();

      final state = container.read(categoriesAdminViewModelProvider);
      expect(auth.logoutCalls, 1);
      expect(container.read(authViewModelProvider).user, isNull);
      expect(state.error, isNull);
      expect(state.isLoading, isFalse);
    },
  );

  testWidgets('CategoriesScreen renders the tree with reorder buttons', (
    tester,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(body: CategoriesScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Roots and children are all visible (children indented under roots).
    expect(find.text('Bánh mì'), findsOneWidget);
    expect(find.text('Bánh mì cay'), findsOneWidget);
    expect(find.text('Bánh mì chà bông'), findsOneWidget);
    expect(find.text('Đồ uống'), findsOneWidget);
    expect(find.text('slug-cat-1a'), findsOneWidget);

    // Move up on the first root is disabled (nothing above it).
    final firstRow = find.ancestor(
      of: find.text('Bánh mì'),
      matching: find.byType(ListTile),
    );
    final firstUp = find.ancestor(
      of: find
          .descendant(of: firstRow, matching: find.byIcon(Icons.arrow_upward))
          .first,
      matching: find.byType(IconButton),
    );
    expect(tester.widget<IconButton>(firstUp).onPressed, isNull);

    // Move up on the second root reorders the root level server-side.
    await tester.tap(
      find.descendant(
        of: find.ancestor(
          of: find.text('Bánh ngọt'),
          matching: find.byType(ListTile),
        ),
        matching: find.byIcon(Icons.arrow_upward),
      ),
    );
    await tester.pumpAndSettle();
    expect(repo.reorders, [
      ['cat-2', 'cat-1', 'cat-3'],
    ]);

    // Delete goes through the confirm dialog.
    await tester.tap(
      find.descendant(
        of: find.ancestor(
          of: find.text('Đồ uống'),
          matching: find.byType(ListTile),
        ),
        matching: find.byIcon(Icons.delete_outline),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Xóa danh mục?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
    await tester.pumpAndSettle();
    expect(repo.deletedIds, ['cat-3']);
    expect(find.text('Đã xóa danh mục'), findsOneWidget);
    // Let the snackbar float away — it covers the FAB while visible.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // The FAB opens the create sheet with the root parent default.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Thêm danh mục'), findsOneWidget);
    expect(find.text('Không có'), findsOneWidget);
    // Close the sheet the way tapping its barrier would.
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();

    // Editing a child preselects its parent in the dropdown ('Bánh mì'
    // then appears twice: the tree row and the dropdown's selection).
    await tester.tap(find.text('Bánh mì cay'));
    await tester.pumpAndSettle();
    expect(find.text('Chỉnh sửa danh mục'), findsOneWidget);
    expect(find.text('Bánh mì'), findsNWidgets(2));
  });
}
