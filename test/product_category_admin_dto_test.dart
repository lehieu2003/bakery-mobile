import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/features/admin/categories/data/datasources/category_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/categories/data/dtos/category_admin_dto.dart';
import 'package:bakery_mobile/src/features/admin/categories/data/repositories/category_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/categories/domain/models/admin_category.dart';
import 'package:bakery_mobile/src/features/admin/products/data/datasources/product_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/products/data/dtos/product_admin_list_dto.dart';
import 'package:bakery_mobile/src/features/admin/products/data/repositories/product_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/products/domain/models/admin_product.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixtures mirror the admin payload shapes pinned from
/// `bakery-web/app/api/admin/products` + `/categories` (Prisma
/// serialization): Decimal money fields arrive as numeric strings, product
/// categories are m2m join rows `{ categoryId, category }`, images are
/// ordered by displayOrder (thumbnail = images[0]), the list envelope is
/// `{ products: [...], pagination: {...} }` and the categories envelope is
/// `{ categories: TREE }` with two nesting levels.
const Map<String, dynamic> sampleProductRow = {
  'id': 'prod-1',
  'name': 'Bánh mì pate trứng',
  'slug': 'banh-mi-pate-trung',
  'price': '45000.00', // Decimal serialized as string
  'comparePrice': '60000.00', // money string; null when there is no sale
  'stock': 24,
  'isActive': true,
  'images': [
    {
      'id': 'img-1',
      'url': 'https://cdn.bakery.vn/prod-1/main.jpg',
      'isPrimary': true,
      'displayOrder': 0,
    },
    {
      'id': 'img-2',
      'url': 'https://cdn.bakery.vn/prod-1/extra.jpg',
      'isPrimary': false,
      'displayOrder': 1,
    },
  ],
  'variants': [
    {'id': 'var-1', 'name': 'Nhỏ', 'price': '40000.00', 'stock': 10},
  ], // list only — contents ignored
  'categories': [
    {
      'categoryId': 'cat-2',
      'category': {'id': 'cat-2', 'name': 'Bánh mì', 'slug': 'banh-mi'},
    },
    {
      'categoryId': 'cat-5',
      'category': {'id': 'cat-5', 'name': 'Mặn', 'slug': 'man'},
    },
  ],
};

/// A product with no categories and no images must still parse.
const Map<String, dynamic> sampleBareProductRow = {
  'id': 'prod-2',
  'name': 'Bánh bông lan trứng muối',
  'slug': 'banh-bong-lan-trung-muoi',
  'price': 120000, // money as number
  'comparePrice': null,
  'stock': 0,
  'isActive': false,
  'images': [],
  'variants': [],
  'categories': [],
};

const Map<String, dynamic> sampleCategoryTreeEnvelope = {
  'categories': [
    {
      'id': 'cat-1',
      'name': 'Bánh ngọt',
      'slug': 'banh-ngot',
      'parentId': null,
      'displayOrder': 0,
      'isActive': true,
      '_count': {'products': 12},
      'children': [
        {
          'id': 'cat-1-1',
          'name': 'Bánh su kem',
          'slug': 'banh-su-kem',
          'parentId': 'cat-1',
          'displayOrder': 0,
          'isActive': true,
          '_count': {'products': 5},
          'children': [], // leaf: empty children
        },
        {
          'id': 'cat-1-2',
          'name': 'Bánh mousse',
          'slug': 'banh-mousse',
          'parentId': 'cat-1',
          'displayOrder': 1,
          'isActive': true,
          '_count': {'products': 7},
          'children': [],
        },
      ],
    },
    {
      'id': 'cat-2',
      'name': 'Bánh mì',
      'slug': 'banh-mi',
      'parentId': null,
      'displayOrder': 1,
      'isActive': true,
      '_count': {'products': 9},
      'children': [], // root without children
    },
  ],
};

/// One recorded mutation call against the fake transport.
typedef _MutationCall = ({String method, String path, Object? body});

/// Fake [ApiClient] transport: records every mutation call; [deleteError]
/// (when set) is thrown by `delete` so error pass-through can be pinned.
class _RecordingApiClient extends ApiClient {
  _RecordingApiClient({this.deleteError})
    : super(baseUrl: 'http://localhost:1', tokenProvider: () async => null);

  final ApiException? deleteError;
  final List<_MutationCall> calls = [];

  @override
  Future<dynamic> delete(String path, {Object? body}) async {
    calls.add((method: 'DELETE', path: path, body: body));
    final error = deleteError;
    if (error != null) throw error;
    return <String, dynamic>{};
  }

  @override
  Future<dynamic> patch(String path, {Object? body}) async {
    calls.add((method: 'PATCH', path: path, body: body));
    return <String, dynamic>{};
  }

  @override
  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    calls.add((method: 'POST', path: path, body: body));
    return <String, dynamic>{'category': sampleCategoryNode};
  }

  @override
  Future<dynamic> put(String path, {Object? body}) async {
    calls.add((method: 'PUT', path: path, body: body));
    return <String, dynamic>{'category': sampleCategoryNode};
  }
}

const Map<String, dynamic> sampleCategoryNode = {
  'id': 'cat-9',
  'name': 'Bánh Tart',
  'slug': 'banh-tart',
  'parentId': null,
  '_count': {'products': 0},
};

void main() {
  group('AdminProductListDto', () {
    test('parses the list envelope: money strings, thumbnail from images[0], '
        'm2m categories, pagination', () {
      final list = AdminProductListDto.fromJson({
        'products': [sampleProductRow, sampleBareProductRow],
        'pagination': {'page': 2, 'limit': 20, 'total': 41, 'totalPages': 3},
      });

      expect(list.products, hasLength(2));
      final product = list.products[0];
      expect(product, isA<AdminProductListItem>());
      expect(product.id, 'prod-1');
      expect(product.name, 'Bánh mì pate trứng');
      expect(product.slug, 'banh-mi-pate-trung');
      // Decimal money coerced from numeric strings.
      expect(product.price, 45000.0);
      expect(product.price, isA<double>());
      expect(product.comparePrice, 60000.0);
      expect(product.comparePrice, isA<double>());
      expect(product.stock, 24);
      expect(product.stock, isA<int>());
      expect(product.isActive, isTrue);
      // Thumbnail is images[0].url (server orders by displayOrder), not
      // the extra image.
      expect(product.thumbnailUrl, 'https://cdn.bakery.vn/prod-1/main.jpg');
      // First m2m join row names the category; every join row feeds ids.
      expect(product.categoryName, 'Bánh mì');
      expect(product.categoryIds, ['cat-2', 'cat-5']);

      // A product without categories/images parses with nulls.
      final bare = list.products[1];
      expect(bare.price, 120000.0);
      expect(bare.comparePrice, isNull);
      expect(bare.categoryName, isNull);
      expect(bare.categoryIds, isEmpty);
      expect(bare.thumbnailUrl, isNull);
      expect(bare.isActive, isFalse);

      expect(list.pagination.page, 2);
      expect(list.pagination.limit, 20);
      expect(list.pagination.total, 41);
      expect(list.pagination.totalPages, 3);
    });
  });

  group('ProductAdminRepository', () {
    test('deleteProduct: success hits /api/admin/products/{id}', () async {
      final client = _RecordingApiClient();
      final repository = ProductAdminRepository(ProductAdminApiService(client));

      await repository.deleteProduct('prod-1');

      expect(client.calls, hasLength(1));
      expect(client.calls.single.method, 'DELETE');
      expect(client.calls.single.path, '/api/admin/products/prod-1');
    });

    test(
      'deleteProduct: bubbles the server error message (404 product gone)',
      () async {
        final client = _RecordingApiClient(
          deleteError: ApiException('Không tìm thấy sản phẩm', statusCode: 404),
        );
        final repository = ProductAdminRepository(
          ProductAdminApiService(client),
        );

        await expectLater(
          repository.deleteProduct('prod-404'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.message, 'message', 'Không tìm thấy sản phẩm')
                .having((e) => e.statusCode, 'statusCode', 404),
          ),
        );
      },
    );
  });

  group('CategoryAdminDto', () {
    test('parses the 2-level tree envelope; leaves carry empty children', () {
      final roots = CategoryAdminDto.fromEnvelope(sampleCategoryTreeEnvelope);

      expect(roots, hasLength(2));
      expect(roots[0], isA<AdminCategoryNode>());
      expect(roots[0].id, 'cat-1');
      expect(roots[0].name, 'Bánh ngọt');
      expect(roots[0].slug, 'banh-ngot');
      expect(roots[0].children, hasLength(2));
      expect(roots[0].children[0].id, 'cat-1-1');
      expect(roots[0].children[1].name, 'Bánh mousse');
      // Leaf and childless root both parse to empty children lists.
      expect(roots[0].children[0].children, isEmpty);
      expect(roots[1].children, isEmpty);
      expect(roots[1].id, 'cat-2');

      // A node flatten() walks its own subtree depth-first, self first.
      expect(roots[0].flatten().map((node) => node.id), [
        'cat-1',
        'cat-1-1',
        'cat-1-2',
      ]);
      // flattenAll walks the whole forest in the same order.
      expect(AdminCategoryNode.flattenAll(roots).map((node) => node.id), [
        'cat-1',
        'cat-1-1',
        'cat-1-2',
        'cat-2',
      ]);
    });

    test('parses the {category} envelope of create/update responses', () {
      final node = CategoryAdminDto.fromMutationEnvelope({
        'category': sampleCategoryNode,
      });

      expect(node.id, 'cat-9');
      expect(node.name, 'Bánh Tart');
      expect(node.slug, 'banh-tart');
      expect(node.children, isEmpty);
    });
  });

  group('CategoryAdminRepository', () {
    test('reorderCategories: PATCHes the server items[{id, displayOrder}] body '
        'derived from the ordered ids', () async {
      final client = _RecordingApiClient();
      final repository = CategoryAdminRepository(
        CategoryAdminApiService(client),
      );

      await repository.reorderCategories(['cat-2', 'cat-1', 'cat-3']);

      expect(client.calls, hasLength(1));
      final call = client.calls.single;
      expect(call.method, 'PATCH');
      expect(call.path, '/api/admin/categories/reorder');
      // bakery-web's reorder route requires
      // `{ items: [{ id, displayOrder }] }` — it rejects an `orderedIds`
      // body with "items array is required". displayOrder = list index.
      expect(call.body, {
        'items': [
          {'id': 'cat-2', 'displayOrder': 0},
          {'id': 'cat-1', 'displayOrder': 1},
          {'id': 'cat-3', 'displayOrder': 2},
        ],
      });
    });

    test('create/update send only non-null keys; deleteCategory bubbles the '
        'server refusal', () async {
      final client = _RecordingApiClient(
        deleteError: ApiException('Cannot delete category with 3 products'),
      );
      final repository = CategoryAdminRepository(
        CategoryAdminApiService(client),
      );

      await repository.createCategory(name: 'Bánh Tart');
      await repository.createCategory(
        name: 'Bánh Tart',
        slug: 'tart',
        parentId: 'cat-1',
      );
      await repository.updateCategory('cat-9', name: 'Bánh Tart Trứng');

      expect(client.calls, hasLength(3));
      expect(client.calls[0].method, 'POST');
      expect(client.calls[0].path, '/api/admin/categories');
      expect(client.calls[0].body, {'name': 'Bánh Tart'});
      expect(client.calls[1].body, {
        'name': 'Bánh Tart',
        'slug': 'tart',
        'parentId': 'cat-1',
      });
      expect(client.calls[2].method, 'PUT');
      expect(client.calls[2].path, '/api/admin/categories/cat-9');
      expect(client.calls[2].body, {'name': 'Bánh Tart Trứng'});

      await expectLater(
        repository.deleteCategory('cat-1'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Cannot delete category with 3 products',
          ),
        ),
      );
    });
  });
}
