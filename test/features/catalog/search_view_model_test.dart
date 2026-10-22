import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/product.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/controllers/search_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_api_client.dart';
import '../../helpers/fixture.dart';
import '../../helpers/pump_app.dart';
import 'catalog_fixtures.dart';

void main() {
  late FakeApiClient api;

  setUp(() => api = FakeApiClient());

  test('initial state is idle and empty', () {
    final state = makeContainer(api).read(searchViewModelProvider);

    expect(state.isLoading, isFalse);
    expect(state.isLoadingMore, isFalse);
    expect(state.error, isNull);
    expect(state.query, isEmpty);
    expect(state.products, isEmpty);
    expect(state.sort, SearchSortOption.popular);
    expect(state.hasActiveFilters, isFalse);
    expect(api.calls, isEmpty);
  });

  test('loading → success: first page and total', () async {
    stubSearch(api);
    final gate = api.hold('GET', productsPath);
    final container = makeContainer(api);
    final vm = container.read(searchViewModelProvider.notifier);

    final loading = vm.search('  bánh ');
    expect(container.read(searchViewModelProvider).isLoading, isTrue);
    gate.complete();
    await loading;

    final state = container.read(searchViewModelProvider);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
    expect(state.query, 'bánh');
    expect(state.products.map((p) => p.id), idsOf(productsSuccess, 'products'));
    expect(state.total, productsTotal());
    expect(state.hasMore, isTrue);
    expect(api.callsTo('GET', productsPath).single.query, {
      'page': 1,
      'limit': 16,
      'search': 'bánh',
    });
  });

  test('loading → empty: no products, nothing more', () async {
    stubSearch(api, products: productsEmpty);
    final container = makeContainer(api);

    await container.read(searchViewModelProvider.notifier).search('zzz');

    final state = container.read(searchViewModelProvider);
    expect(state.error, isNull);
    expect(state.products, isEmpty);
    expect(state.hasMore, isFalse);
  });

  test('loading → error: message, results cleared', () async {
    stubSearch(api);
    final container = makeContainer(api);
    final vm = container.read(searchViewModelProvider.notifier);
    await vm.search('');
    api.stubError('GET', productsPath);

    await vm.search('bánh');

    final state = container.read(searchViewModelProvider);
    expect(state.isLoading, isFalse);
    expect(state.error, fixtureError(error500).message);
    expect(state.products, isEmpty);
    expect(state.total, 0);
  });

  group('pagination', () {
    test('loadMore appends the next page with the same query', () async {
      stubSearch(api);
      api.stub('GET', productsPath, pagedProducts);
      final container = makeContainer(api);
      final vm = container.read(searchViewModelProvider.notifier);
      await vm.search('bánh');

      await vm.loadMore();

      final state = container.read(searchViewModelProvider);
      expect(state.page, 2);
      expect(
        state.products,
        hasLength(idsOf(productsSuccess, 'products').length * 2),
      );
      expect(api.callsTo('GET', productsPath).last.query, {
        'page': 2,
        'limit': 16,
        'search': 'bánh',
      });
    });

    test('loadMore does nothing once every product is loaded', () async {
      stubSearch(api, products: productsEmpty);
      final container = makeContainer(api);
      final vm = container.read(searchViewModelProvider.notifier);
      await vm.search('');

      await vm.loadMore();

      expect(api.callsTo('GET', productsPath), hasLength(1));
    });

    test('a failed next page keeps loaded products', () async {
      stubSearch(api);
      final container = makeContainer(api);
      final vm = container.read(searchViewModelProvider.notifier);
      await vm.search('');
      api.stubError('GET', productsPath);

      await vm.loadMore();

      final state = container.read(searchViewModelProvider);
      expect(
        state.products,
        hasLength(idsOf(productsSuccess, 'products').length),
      );
      expect(state.page, 1);
      expect(state.isLoadingMore, isFalse);
      expect(state.error, isNotNull);
    });
  });

  test('loadFilters reads attribute groups; a failure is silent', () async {
    stubSearch(api);
    final container = makeContainer(api);
    final vm = container.read(searchViewModelProvider.notifier);

    await vm.loadFilters();
    expect(container.read(searchViewModelProvider).filters.groups, isNotEmpty);

    api.stubError('GET', filtersPath);
    await vm.loadFilters();
    expect(container.read(searchViewModelProvider).error, isNull);
  });

  test('applyFilters re-searches with price/stock/attributes', () async {
    stubSearch(api);
    final container = makeContainer(api);
    final vm = container.read(searchViewModelProvider.notifier);
    const attribute = ProductAttributeFilter(
      attributeSlug: 'size',
      valueSlugs: ['16cm'],
    );

    await vm.applyFilters(
      attributeFilters: const [attribute],
      minPrice: 100000,
      maxPrice: 500000,
      inStock: true,
    );

    final query = api.callsTo('GET', productsPath).single.query!;
    expect(query['minPrice'], 100000);
    expect(query['maxPrice'], 500000);
    expect(query['inStock'], true);
    expect(query['attribute'], isNotEmpty);
    expect(container.read(searchViewModelProvider).hasActiveFilters, isTrue);

    await vm.clearFilters();

    expect(container.read(searchViewModelProvider).hasActiveFilters, isFalse);
    expect(api.callsTo('GET', productsPath).last.query, {
      'page': 1,
      'limit': 16,
    });
  });

  test('setSort orders by price locally without a request', () async {
    stubSearch(api);
    final container = makeContainer(api);
    final vm = container.read(searchViewModelProvider.notifier);
    await vm.search('');

    vm.setSort(SearchSortOption.priceAsc);
    final asc = container
        .read(searchViewModelProvider)
        .sortedProducts
        .map((p) => p.price)
        .toList();
    vm.setSort(SearchSortOption.priceDesc);
    final desc = container
        .read(searchViewModelProvider)
        .sortedProducts
        .map((p) => p.price)
        .toList();

    expect(asc, [...asc]..sort());
    expect(desc, asc.reversed);
    expect(api.callsTo('GET', productsPath), hasLength(1));
  });
}
