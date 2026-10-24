import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/admin/categories/data/datasources/category_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/categories/data/repositories/category_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/categories/domain/models/admin_category.dart';
import 'package:bakery_mobile/src/features/admin/products/data/datasources/product_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/products/data/repositories/product_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/products/domain/models/admin_product.dart';
import 'package:bakery_mobile/src/features/admin/products/presentation/controllers/products_admin_view_model.dart';
import 'package:bakery_mobile/src/features/admin/products/presentation/screens/products_screen.dart';
import 'package:bakery_mobile/src/features/auth/domain/models/user.dart';
import 'package:bakery_mobile/src/features/auth/presentation/controllers/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

AdminProductListItem _product(
  String id,
  String name, {
  double price = 25000,
  double? comparePrice,
  int stock = 10,
  bool isActive = true,
  String? categoryName,
  List<String> categoryIds = const [],
}) {
  return AdminProductListItem(
    id: id,
    name: name,
    slug: 'slug-$id',
    price: price,
    comparePrice: comparePrice,
    stock: stock,
    isActive: isActive,
    categoryName: categoryName,
    categoryIds: categoryIds,
  );
}

/// The fake catalog: 3 products covering active/inactive, sale price and
/// both category links.
List<AdminProductListItem> _catalog() => [
  _product(
    'p1',
    'Bánh mì tươi',
    price: 25000,
    stock: 12,
    isActive: true,
    categoryName: 'Bánh mì',
    categoryIds: const ['cat-1'],
  ),
  _product(
    'p2',
    'Bánh su kem',
    price: 15000,
    comparePrice: 20000,
    stock: 0,
    isActive: false,
    categoryName: 'Bánh ngọt',
    categoryIds: const ['cat-2'],
  ),
  _product('p3', 'Bánh bông lan', categoryIds: const ['cat-1', 'cat-3']),
];

/// One recorded `getProducts` call (the status/category filters are
/// client-side, so they never appear here).
typedef _Call = ({int page, String? search});

/// Fake repository: records every call, serves the catalog in pages of 2
/// (already-deleted products drop out, like the server) and throws on
/// deletes listed in [failDeleteIds].
class _FakeProductAdminRepository extends ProductAdminRepository {
  _FakeProductAdminRepository()
    : super(
        ProductAdminApiService(
          ApiClient(
            baseUrl: 'http://localhost:1',
            tokenProvider: () async => null,
          ),
        ),
      );

  final List<_Call> calls = [];
  final List<AdminProductListItem> items = _catalog();
  final List<String> deletedIds = [];
  final Set<String> failDeleteIds = {};
  Object? error;

  @override
  Future<ProductAdminPage> getProducts({
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    calls.add((page: page, search: search));
    final thrown = error;
    if (thrown != null) throw thrown;
    final live = items.where((p) => !deletedIds.contains(p.id)).toList();
    return ProductAdminPage(
      items: live.skip((page - 1) * 2).take(2).toList(),
      totalPages: (live.length / 2).ceil(),
      total: live.length,
    );
  }

  @override
  Future<void> deleteProduct(String id) async {
    if (failDeleteIds.contains(id)) {
      throw ApiException('Không tìm thấy sản phẩm', statusCode: 404);
    }
    deletedIds.add(id);
  }
}

/// Fake categories repository serving the same sample tree as the
/// categories VM tests.
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

  @override
  Future<List<AdminCategoryNode>> getCategories() async {
    return [
      AdminCategoryNode(
        id: 'cat-1',
        name: 'Bánh mì',
        slug: 'banh-mi',
        children: const [
          AdminCategoryNode(
            id: 'cat-1a',
            name: 'Bánh mì cay',
            slug: 'banh-mi-cay',
          ),
        ],
      ),
      AdminCategoryNode(id: 'cat-2', name: 'Bánh ngọt', slug: 'banh-ngot'),
      AdminCategoryNode(id: 'cat-3', name: 'Đồ uống', slug: 'do-uong'),
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
  late _FakeProductAdminRepository repo;
  late _FakeAuthViewModel auth;
  late ProviderContainer container;

  setUp(() {
    repo = _FakeProductAdminRepository();
    auth = _FakeAuthViewModel();
    container = ProviderContainer(
      overrides: [
        productsAdminRepositoryProvider.overrideWithValue(repo),
        categoriesAdminRepositoryProvider.overrideWithValue(
          _FakeCategoryAdminRepository(),
        ),
        authViewModelProvider.overrideWith(() => auth),
      ],
    );
    addTearDown(container.dispose);
  });

  ProductsAdminState readState() =>
      container.read(productsAdminViewModelProvider);

  test('load() fetches page 1 with items and totalPages', () async {
    await container.read(productsAdminViewModelProvider.notifier).load();

    expect(repo.calls, [(page: 1, search: null)]);
    expect(readState().items.map((p) => p.id), ['p1', 'p2']);
    expect(readState().page, 1);
    expect(readState().totalPages, 2);
    expect(readState().total, 3);
    expect(readState().hasMore, isTrue);
    expect(readState().isLoading, isFalse);
    expect(readState().error, isNull);
  });

  test('loadMore appends the next page, then stops at the last page', () async {
    final vm = container.read(productsAdminViewModelProvider.notifier);
    await vm.load();
    await vm.loadMore();

    expect(repo.calls.last, (page: 2, search: null));
    expect(readState().items.map((p) => p.id), ['p1', 'p2', 'p3']);
    expect(readState().page, 2);
    expect(readState().hasMore, isFalse);

    // Last page reached → loadMore is a no-op.
    await vm.loadMore();
    expect(repo.calls, hasLength(2));
    expect(readState().items, hasLength(3));
  });

  test('setSearch trims, forwards search and resets to page 1', () async {
    final vm = container.read(productsAdminViewModelProvider.notifier);
    await vm.load();
    await vm.loadMore();
    expect(readState().page, 2);

    await vm.setSearch('  su kem ');

    expect(repo.calls.last, (page: 1, search: 'su kem'));
    expect(readState().search, 'su kem');
    expect(readState().page, 1);
    expect(readState().items.map((p) => p.id), ['p1', 'p2']);
  });

  test(
    "setStatusFilter('inactive') filters loaded items client-side",
    () async {
      final vm = container.read(productsAdminViewModelProvider.notifier);
      await vm.load();
      await vm.loadMore();
      expect(readState().visibleItems, hasLength(3));

      await vm.setStatusFilter('inactive');

      // The server never sees the status; the page just resets to 1 and the
      // loaded items are filtered in the VM.
      expect(repo.calls.last, (page: 1, search: null));
      expect(readState().page, 1);
      expect(readState().statusFilter, 'inactive');
      expect(readState().visibleItems.map((p) => p.id), ['p2']);
      expect(readState().visibleItems.every((p) => !p.isActive), isTrue);

      // 'ALL' clears the filter; only page 1 (p1, p2) is loaded after the
      // reset, both visible again.
      await vm.setStatusFilter('ALL');
      expect(readState().statusFilter, isNull);
      expect(readState().visibleItems.map((p) => p.id), ['p1', 'p2']);
    },
  );

  test('setCategory filters client-side by categoryIds', () async {
    final vm = container.read(productsAdminViewModelProvider.notifier);
    await vm.load();
    await vm.loadMore();

    await vm.setCategory('cat-1');

    // The reset reloads page 1 only — p3 (also cat-1) comes back on scroll.
    expect(repo.calls.last, (page: 1, search: null));
    expect(readState().page, 1);
    expect(readState().categoryFilter, 'cat-1');
    expect(readState().visibleItems.map((p) => p.id), ['p1']);

    await vm.setCategory(null);
    expect(readState().categoryFilter, isNull);
    expect(readState().visibleItems.map((p) => p.id), ['p1', 'p2']);
  });

  test('loadCategories flattens the tree for the dropdown', () async {
    await container
        .read(productsAdminViewModelProvider.notifier)
        .loadCategories();

    expect(readState().categories.map((c) => c.id), [
      'cat-1',
      'cat-1a',
      'cat-2',
      'cat-3',
    ]);
    expect(readState().categories.map((c) => c.name), [
      'Bánh mì',
      'Bánh mì cay',
      'Bánh ngọt',
      'Đồ uống',
    ]);
  });

  test('toggleSelect adds/removes; clearSelection empties and exits', () async {
    final vm = container.read(productsAdminViewModelProvider.notifier);

    await vm.toggleSelect('p1');
    expect(readState().selectedIds, {'p1'});
    expect(readState().isSelecting, isTrue);

    await vm.toggleSelect('p2');
    expect(readState().selectedIds, {'p1', 'p2'});

    await vm.toggleSelect('p1');
    expect(readState().selectedIds, {'p2'});

    await vm.clearSelection();
    expect(readState().selectedIds, isEmpty);
    expect(readState().isSelecting, isFalse);
  });

  test(
    'bulkDelete deletes each selection, reports ok/fail and reloads',
    () async {
      final vm = container.read(productsAdminViewModelProvider.notifier);
      await vm.load();
      await vm.toggleSelect('p1');
      await vm.toggleSelect('p2');
      await vm.toggleSelect('p3');
      repo.failDeleteIds.add('p2');

      await vm.bulkDelete();

      expect(repo.deletedIds, ['p1', 'p3']); // p2 was attempted but refused
      expect(readState().report, 'Đã xoá 2 sản phẩm, 1 lỗi');
      expect(readState().selectedIds, isEmpty);
      expect(readState().isSelecting, isFalse);
      expect(readState().isDeleting, isFalse);
      // The list reloaded: only the failed product survived on the server.
      expect(repo.calls, hasLength(2));
      expect(repo.calls.last, (page: 1, search: null));
      expect(readState().items.map((p) => p.id), ['p2']);
    },
  );

  test('generic ApiException surfaces as state.error; retry reloads', () async {
    repo.error = ApiException('Lỗi máy chủ', statusCode: 500);
    final vm = container.read(productsAdminViewModelProvider.notifier);
    await vm.load();

    expect(readState().error, 'Lỗi máy chủ');
    expect(readState().isLoading, isFalse);
    expect(auth.logoutCalls, 0);

    repo.error = null;
    await vm.retry();
    expect(readState().error, isNull);
    expect(readState().items, hasLength(2));
  });

  test('401 logs out through AuthViewModel and sets no error', () async {
    repo.error = ApiException('Unauthorized', statusCode: 401);
    await container.read(productsAdminViewModelProvider.notifier).load();

    expect(auth.logoutCalls, 1);
    expect(container.read(authViewModelProvider).user, isNull);
    expect(readState().error, isNull);
    expect(readState().isLoading, isFalse);
  });

  testWidgets('ProductsScreen: cards, filters, FAB and bulk delete', (
    tester,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ProductsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Cards render name, price, stock, sale price and status pills.
    expect(find.text('Bánh mì tươi'), findsOneWidget);
    expect(find.text('25.000 ₫'), findsOneWidget);
    expect(find.text('Kho: 12'), findsOneWidget);
    expect(find.text('15.000 ₫'), findsOneWidget);
    expect(find.text('20.000 ₫'), findsOneWidget);
    expect(find.text('Đang bán'), findsNWidgets(2)); // chip + p1's pill
    expect(find.text('Tạm ngừng'), findsNWidgets(2)); // chip + p2's pill
    expect(find.text('Tất cả danh mục'), findsOneWidget);

    // Status chip filters client-side.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Tạm ngừng'));
    await tester.pumpAndSettle();
    expect(find.text('Bánh mì tươi'), findsNothing);
    expect(find.text('Bánh su kem'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Tất cả'));
    await tester.pumpAndSettle();
    expect(find.text('Bánh mì tươi'), findsOneWidget);

    // Category dropdown filters client-side (only cat-1 products).
    await tester.tap(find.text('Tất cả danh mục'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bánh ngọt').last);
    await tester.pumpAndSettle();
    expect(find.text('Bánh su kem'), findsOneWidget);
    expect(find.text('Bánh bông lan'), findsNothing);

    await tester.tap(find.text('Bánh ngọt').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tất cả danh mục').last);
    await tester.pumpAndSettle();
    expect(find.text('Bánh mì tươi'), findsOneWidget);

    // FAB announces the upcoming form (plan 4b).
    await tester.tap(find.text('Thêm sản phẩm'));
    await tester.pumpAndSettle();
    expect(find.text('Form sản phẩm đầy đủ sắp có'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4)); // let the snackbar go
    await tester.pumpAndSettle();

    // Long-press enters selection mode; the bar counts the selection.
    await tester.longPress(find.text('Bánh mì tươi'));
    await tester.pumpAndSettle();
    expect(find.text('1 đã chọn'), findsOneWidget);
    expect(find.byTooltip('Huỷ chọn'), findsOneWidget);

    // Cancel exits selection mode.
    await tester.tap(find.byTooltip('Huỷ chọn'));
    await tester.pumpAndSettle();
    expect(find.text('0 đã chọn'), findsNothing);
    expect(find.byType(Checkbox), findsNothing);

    // Select, confirm-delete, and the report snackbar appears.
    await tester.longPress(find.text('Bánh mì tươi'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Xoá đã chọn'));
    await tester.pumpAndSettle();
    expect(find.text('Xoá 1 sản phẩm?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Xoá'));
    await tester.pumpAndSettle();

    expect(find.text('Đã xoá 1 sản phẩm'), findsOneWidget);
    expect(find.text('Bánh mì tươi'), findsNothing);
    expect(find.text('0 đã chọn'), findsNothing); // selection mode exited
  });
}
