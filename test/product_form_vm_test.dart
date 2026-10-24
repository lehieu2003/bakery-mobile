import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/features/admin/products/data/datasources/product_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/products/data/repositories/product_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/products/domain/models/admin_product.dart';
import 'package:bakery_mobile/src/features/admin/products/presentation/controllers/product_form_view_model.dart';
import 'package:bakery_mobile/src/features/auth/domain/models/user.dart';
import 'package:bakery_mobile/src/features/auth/presentation/controllers/auth_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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

  @override
  Future<AdminProductDetail> getProduct(String id) async {
    final thrown = error;
    if (thrown != null) throw thrown;
    return _detail();
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
  late _FakeAuthViewModel auth;
  late ProviderContainer container;

  setUp(() {
    repo = _FakeRepo();
    auth = _FakeAuthViewModel();
    container = ProviderContainer(
      overrides: [
        productsAdminRepositoryProvider.overrideWithValue(repo),
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
      final many = List.generate(12, (i) => '/tmp/img\$i.jpg');
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
}
