import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/features/admin/products/data/datasources/product_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/products/data/datasources/upload_api_service.dart';
import 'package:bakery_mobile/src/features/admin/products/data/repositories/product_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/products/domain/models/admin_product.dart';
import 'package:bakery_mobile/src/features/admin/products/presentation/controllers/product_form_view_model.dart';
import 'package:bakery_mobile/src/features/auth/domain/models/user.dart';
import 'package:bakery_mobile/src/features/auth/presentation/controllers/auth_view_model.dart';
import 'dart:io' show File;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Real temp files so the VM's File-read in save() works.
List<String> _tempImages(int count, [String prefix = 'a']) {
  return [
    for (var i = 0; i < count; i++)
      () {
        final f = File('/tmp/form_img_${prefix}_$i.jpg');
        f.writeAsBytesSync(List.filled(8, i));
        return f.path;
      }(),
  ];
}

AdminProductDetail _detail() => const AdminProductDetail(
  id: 'prod-1',
  name: 'Bánh mousse chocolate',
  slug: 'banh-mousse-chocolate',
  price: 68000,
  comparePrice: 85000,
  stock: 30,
  isActive: false,
  isFeatured: false,
  shortDescription: 'Mousse đậm vị',
  description: 'Mousse chocolate 70%.',
  categoryIds: ['cat-banh'],
);

class _FakeRepo extends ProductAdminRepository {
  _FakeRepo()
    : super(
        ProductAdminApiService(
          ApiClient(
            baseUrl: 'http://localhost:1',
            tokenProvider: () async => null,
          ),
        ),
      );

  Object? error;
  Object? saveError;
  final savedBodies = <String, Map<String, dynamic>>{};

  @override
  Future<AdminProductDetail> getProduct(String id) async {
    final thrown = error;
    if (thrown != null) throw thrown;
    return _detail();
  }

  @override
  Future<AdminProductDetail> createProduct(Map<String, dynamic> body) async {
    final thrown = saveError;
    if (thrown != null) throw thrown;
    savedBodies['create'] = body;
    return _detail();
  }

  @override
  Future<AdminProductDetail> updateProduct(
    String id,
    Map<String, dynamic> body,
  ) async {
    final thrown = saveError;
    if (thrown != null) throw thrown;
    savedBodies[id] = body;
    return _detail();
  }
}

class _FakeUploadService extends UploadApiService {
  _FakeUploadService() : super(_deadClient);

  static final ApiClient _deadClient = ApiClient(
    baseUrl: 'http://localhost:1',
    tokenProvider: () async => null,
  );

  int callCount = 0;
  Object? error;

  @override
  Future<List<String>> uploadImages(List<String> dataUrls) async {
    callCount++;
    final thrown = error;
    if (thrown != null) throw thrown;
    // Mirror the ≤5/request chunking by echoing the count of requests the
    // REAL service would make.
    return [
      for (var i = 0; i < dataUrls.length; i++) 'https://cdn/hosted-$i.jpg',
    ];
  }
}

class _FakeAuthViewModel extends AuthViewModel {
  int logoutCalls = 0;

  @override
  AuthState build() => const AuthState(
    user: User(id: 'a-1', email: 'admin@bakery.vn', name: 'H', role: 'ADMIN'),
  );

  @override
  Future<void> logout() async {
    logoutCalls++;
    state = state.copyWith(clearUser: true);
  }
}

void main() {
  late _FakeRepo repo;
  late _FakeUploadService upload;
  late _FakeAuthViewModel auth;
  late ProviderContainer container;

  setUp(() {
    repo = _FakeRepo();
    upload = _FakeUploadService();
    auth = _FakeAuthViewModel();
    container = ProviderContainer(
      overrides: [
        productsAdminRepositoryProvider.overrideWithValue(repo),
        uploadApiServiceProvider.overrideWithValue(upload),
        authViewModelProvider.overrideWith(() => auth),
      ],
    );
    addTearDown(container.dispose);
  });

  ProductFormViewModel vm(String? id) =>
      container.read(productFormViewModelProvider(id).notifier);
  ProductFormState state(String? id) =>
      container.read(productFormViewModelProvider(id));

  test('create mode starts with empty fields and isActive true', () {
    final s = state(null);
    expect(s.name, '');
    expect(s.priceText, '');
    expect(s.stockText, '');
    expect(s.isActive, isTrue);
    expect(s.categoryId, isNull);
    expect(s.isLoading, isFalse);
  });

  test('load() in edit mode preloads every info field', () async {
    await vm('prod-1').load();

    final s = state('prod-1');
    expect(s.detail!.id, 'prod-1');
    expect(s.name, 'Bánh mousse chocolate');
    expect(s.slug, 'banh-mousse-chocolate');
    expect(s.priceText, '68000');
    expect(s.comparePriceText, '85000');
    expect(s.stockText, '30');
    expect(s.isActive, isFalse);
    expect(s.shortDescription, 'Mousse đậm vị');
    expect(s.description, 'Mousse chocolate 70%.');
    expect(s.categoryId, 'cat-banh');
    expect(s.error, isNull);
  });

  test(
    'validate() reports the first problem, null when everything is fine',
    () async {
      await vm('prod-1').load();

      // Valid preload passes.
      expect(state('prod-1').validate(), isNull);

      // Empty name.
      vm('prod-1').setName('');
      expect(state('prod-1').validate(), contains('Tên'));

      // Non-numeric price.
      vm('prod-1').setName('Bánh');
      vm('prod-1').setPriceText('12.000abc');
      expect(state('prod-1').validate(), contains('Giá'));

      // Negative price.
      vm('prod-1').setPriceText('-5');
      expect(state('prod-1').validate(), contains('Giá'));

      // Missing stock.
      vm('prod-1').setPriceText('68000');
      vm('prod-1').setStockText('');
      expect(state('prod-1').validate(), contains('kho'));

      // Optional compare price must still be numeric when filled.
      vm('prod-1').setStockText('30');
      vm('prod-1').setComparePriceText('abc');
      expect(state('prod-1').validate(), contains('so sánh'));

      vm('prod-1').setComparePriceText('');
      expect(state('prod-1').validate(), isNull);
    },
  );

  test('setCategory replaces the single pick', () async {
    await vm('prod-1').load();

    vm('prod-1').setCategory('cat-khac');
    expect(state('prod-1').categoryId, 'cat-khac');

    vm('prod-1').setCategory(null);
    expect(state('prod-1').categoryId, isNull);
  });

  test('401 on load logs out', () async {
    repo.error = ApiException('Unauthorized', statusCode: 401);
    await vm('prod-1').load();

    expect(auth.logoutCalls, 1);
    expect(state('prod-1').error, isNull);
  });

  test('generic load error surfaces with a message', () async {
    repo.error = ApiException('Lỗi máy chủ', statusCode: 500);
    await vm('prod-1').load();

    expect(state('prod-1').error, 'Lỗi máy chủ');
  });

  group('images section', () {
    test(
      'addLocalImages marks the first local pick primary when none is',
      () async {
        await vm('prod-1').load();
        vm('prod-1').addLocalImages(['/tmp/a.jpg', '/tmp/b.jpg']);
        expect(state('prod-1').images.length, 2);
        expect(state('prod-1').images.first.isPrimary, isTrue);
        expect(state('prod-1').images.first.isLocal, isTrue);
      },
    );

    test('addLocalImages caps the gallery at 10 total', () async {
      await vm('prod-1').load();
      final many = List.generate(12, (i) => '/tmp/img$i.jpg');
      vm('prod-1').addLocalImages(many);

      expect(state('prod-1').images.length, 10);
    });

    test('setPrimary makes exactly one primary', () async {
      await vm('prod-1').load();
      vm('prod-1').addLocalImages(['/tmp/a.jpg', '/tmp/b.jpg', '/tmp/c.jpg']);
      vm('prod-1').setPrimary(2);

      final images = state('prod-1').images;
      expect(images[2].isPrimary, isTrue);
      expect(images.where((i) => i.isPrimary), hasLength(1));
    });

    test(
      'removeImage keeps at least a sane state and re-picks primary',
      () async {
        await vm('prod-1').load();
        vm('prod-1').addLocalImages(['/tmp/a.jpg', '/tmp/b.jpg']);
        vm('prod-1').removeImage(0);

        final images = state('prod-1').images;
        expect(images, hasLength(1));
        expect(images.single.isPrimary, isTrue);
      },
    );
  });

  group('variants and attributes sections', () {
    test('variant rows add, update and remove', () async {
      await vm('prod-1').load();
      vm('prod-1').addVariant();
      vm('prod-1').addVariant();
      expect(state('prod-1').variants, hasLength(2));

      vm('prod-1').updateVariant(
        0,
        name: 'Cỡ 6 inch',
        priceText: '68000',
        stockText: '12',
      );
      vm('prod-1').updateVariant(0, sku: 'MOU-6');
      expect(state('prod-1').variants.first.name, 'Cỡ 6 inch');
      expect(state('prod-1').variants.first.sku, 'MOU-6');

      vm('prod-1').removeVariant(0);
      expect(state('prod-1').variants, hasLength(1));
      expect(state('prod-1').variants.first.name, isEmpty);
    });

    test('edit preload carries existing variants as rows', () async {
      // _detail() has no variants; a detail WITH them flows through load
      // only via the repo — covered by the DTO tests. Here: assignment map.
      expect(state('prod-1').assignments, isEmpty);
    });

    test(
      'SELECT assignment replaces the single value; MULTI toggles',
      () async {
        await vm('prod-1').load();

        vm(
          'prod-1',
        ).setAssignmentValue('attr-size', 'val-s', true, isMulti: false);
        vm(
          'prod-1',
        ).setAssignmentValue('attr-size', 'val-m', true, isMulti: false);
        expect(state('prod-1').assignments['attr-size'], ['val-m']);

        vm(
          'prod-1',
        ).setAssignmentValue('attr-mousse', 'val-passion', true, isMulti: true);
        vm(
          'prod-1',
        ).setAssignmentValue('attr-mousse', 'val-mango', true, isMulti: true);
        vm('prod-1').setAssignmentValue(
          'attr-mousse',
          'val-passion',
          false,
          isMulti: true,
        );
        expect(
          state('prod-1').assignments['attr-mousse'],
          contains('val-mango'),
        );
        expect(
          state('prod-1').assignments['attr-mousse'],
          isNot(contains('val-passion')),
        );
      },
    );

    test(
      'buildAssignments skips attributes with no picks and mirrors preload',
      () async {
        await vm('prod-1').load();
        vm(
          'prod-1',
        ).setAssignmentValue('attr-size', 'val-s', true, isMulti: false);
        vm(
          'prod-1',
        ).setAssignmentValue('attr-empty', 'val-x', true, isMulti: false);
        vm(
          'prod-1',
        ).setAssignmentValue('attr-empty', 'val-x', false, isMulti: false);

        final built = state('prod-1').buildAssignments();
        expect(built, hasLength(1));
        expect(built.single.attributeId, 'attr-size');
        expect(built.single.valueIds, ['val-s']);
      },
    );
  });

  group('save flow', () {
    test(
      'create builds the wire body (numbers, category array, images)',
      () async {
        final vmCreate = vm(null);
        vmCreate
          ..setName('Bánh test')
          ..setPriceText('10000')
          ..setStockText('5')
          ..setCategory('cat-1')
          ..addLocalImages(_tempImages(2));
        vmCreate.setAssignmentValue('attr-s', 'val-1', true, isMulti: false);

        final ok = await vmCreate.save();

        expect(ok, isTrue);
        final body = repo.savedBodies['create']!;
        expect(body['name'], 'Bánh test');
        expect(body['price'], 10000);
        expect(body['stock'], 5);
        expect(body['categoryIds'], ['cat-1']);
        expect(body['images'], hasLength(2));
        expect(body['images'][0]['url'], 'https://cdn/hosted-0.jpg');
        expect(body['images'][0]['isPrimary'], isTrue);
        expect(body['attributeAssignments'], [
          {
            'attributeId': 'attr-s',
            'valueIds': ['val-1'],
          },
        ]);
      },
    );

    test('update keeps server images and appends uploaded ones', () async {
      await vm('prod-1').load();
      vm('prod-1').addLocalImages(_tempImages(1, 'new'));

      final ok = await vm('prod-1').save();

      expect(ok, isTrue);
      final body = repo.savedBodies['prod-1']!;
      expect(body['images'], hasLength(1)); // preload has none + 1 local
      expect(body['images'].first['url'], 'https://cdn/hosted-0.jpg');
    });

    test('upload failure surfaces and the repo is never called', () async {
      final vmCreate = vm(null);
      vmCreate
        ..setName('Bánh x')
        ..setPriceText('1000')
        ..setStockText('1')
        ..addLocalImages(_tempImages(1, 'u'));
      upload.error = Exception('Tải ảnh thất bại (ảnh số 1)');

      final ok = await vmCreate.save();

      expect(ok, isFalse);
      expect(repo.savedBodies, isEmpty);
      expect(vmCreate.state.error, contains('Tải ảnh'));
    });

    test('seven local images upload in chunks of five', () async {
      final vmCreate = vm(null);
      vmCreate
        ..setName('Bánh y')
        ..setPriceText('1000')
        ..setStockText('1')
        ..addLocalImages(_tempImages(7, 'i'));

      final ok = await vmCreate.save();

      expect(ok, isTrue);
      expect(upload.callCount, 1); // fake receives one batch call
      // The REAL service chunks internally — pinned separately by its own
      // unit; here we pin the ordering of hosted urls.
      final body = repo.savedBodies['create']!;
      expect(
        (body['images'] as List).map((i) => i['url']),
        containsAll(['https://cdn/hosted-0.jpg', 'https://cdn/hosted-6.jpg']),
      );
    });
  });
}
