import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_api_client.dart';
import '../../helpers/fixture.dart';
import '../../helpers/pump_app.dart';
import 'catalog_fixtures.dart';

void main() {
  late FakeApiClient api;

  setUp(() => api = FakeApiClient());

  test('initial state is idle and empty', () {
    final state = makeContainer(api).read(homeViewModelProvider);

    expect(state.isLoading, isFalse);
    expect(state.errorMessage, isNull);
    expect(state.banners, isEmpty);
    expect(state.categories, isEmpty);
    expect(state.bestSellers, isEmpty);
    expect(state.personalizedProducts, isEmpty);
    expect(state.selectedCategoryId, isNull);
    expect(api.calls, isEmpty);
  });

  test('loading → success: every home section is filled', () async {
    stubHome(api);
    final gate = api.hold('GET', bestSellersPath);
    final container = makeContainer(api);
    final vm = container.read(homeViewModelProvider.notifier);

    final loading = vm.loadInitial();
    expect(container.read(homeViewModelProvider).isLoading, isTrue);
    gate.complete();
    await loading;

    final state = container.read(homeViewModelProvider);
    final personalized = fixtureData(personalizedSuccess) as Map;
    expect(state.isLoading, isFalse);
    expect(state.errorMessage, isNull);
    expect(
      state.banners,
      hasLength((fixtureData(bannersSuccess) as List).length),
    );
    expect(
      state.categories.map((c) => c.id),
      idsOf(categoriesSuccess, 'categories'),
    );
    expect(
      state.bestSellers.map((p) => p.id),
      idsOf(bestSellersSuccess, 'products'),
    );
    expect(
      state.personalizedProducts.map((p) => p.id),
      idsOf(personalizedSuccess, 'products'),
    );
    expect(state.personalizedSource, personalized['source']);
    expect(state.personalizedReason, personalized['reason']);
    expect(api.callsTo('GET', personalizedPath).single.query, {'limit': 8});
  });

  test('loading → empty: no products, no error', () async {
    stubHome(
      api,
      bestSellers: bestSellersEmpty,
      personalized: personalizedEmpty,
    );
    final container = makeContainer(api);

    await container.read(homeViewModelProvider.notifier).loadInitial();

    final state = container.read(homeViewModelProvider);
    expect(state.isLoading, isFalse);
    expect(state.errorMessage, isNull);
    expect(state.bestSellers, isEmpty);
    expect(state.personalizedProducts, isEmpty);
  });

  test('loading → error: any failed section fails the load', () async {
    stubHome(api);
    api.stubError('GET', bannersPath);
    final container = makeContainer(api);

    await container.read(homeViewModelProvider.notifier).loadInitial();

    final state = container.read(homeViewModelProvider);
    expect(state.isLoading, isFalse);
    expect(state.errorMessage, fixtureError(error500).message);
    expect(state.bestSellers, isEmpty);
  });

  test('refresh reloads and clears a previous error', () async {
    stubHome(api);
    api.stubError('GET', bestSellersPath);
    final container = makeContainer(api);
    final vm = container.read(homeViewModelProvider.notifier);
    await vm.loadInitial();
    api.stubFixture('GET', bestSellersPath, bestSellersSuccess);

    await vm.loadInitial();

    final state = container.read(homeViewModelProvider);
    expect(state.errorMessage, isNull);
    expect(state.bestSellers, isNotEmpty);
    expect(api.callsTo('GET', bestSellersPath), hasLength(2));
  });

  test('selectCategory sets and clears the selection', () async {
    final container = makeContainer(api);
    final vm = container.read(homeViewModelProvider.notifier);

    await vm.selectCategory('cat-1');
    expect(container.read(homeViewModelProvider).selectedCategoryId, 'cat-1');

    await vm.selectCategory(null);
    expect(container.read(homeViewModelProvider).selectedCategoryId, isNull);
  });

  test('search queries products in the selected category', () async {
    api.stubFixture('GET', productsPath, productsSuccess);
    final container = makeContainer(api);
    final vm = container.read(homeViewModelProvider.notifier);
    await vm.selectCategory('cat-1');

    await vm.search('  tiramisu ');

    final query = api.callsTo('GET', productsPath).single.query!;
    expect(query['search'], 'tiramisu');
    expect(query['categoryId'], 'cat-1');
    expect(
      container.read(homeViewModelProvider).products.map((p) => p.id),
      idsOf(productsSuccess, 'products'),
    );
  });
}
