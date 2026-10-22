import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/product.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_api_client.dart';
import '../../helpers/fixture.dart';
import '../../helpers/pump_app.dart';

const _path = '/api/wishlist';
const _success = 'wishlist/wishlist_success.json';
const _empty = 'wishlist/wishlist_empty.json';
const _added = 'wishlist/wishlist_add_success.json';
const _removed = 'wishlist/wishlist_remove_success.json';

List<Map<String, dynamic>> _fixtureItems() =>
    ((fixtureJson(_success)['data'] as Map)['wishlist'] as List)
        .cast<Map<String, dynamic>>();

/// The product the add fixture returns.
Product _addedProduct() {
  final item = (fixtureJson(_added)['data'] as Map)['item'] as Map;
  final product = item['product'] as Map;
  return Product(
    id: product['id'] as String,
    name: product['name'] as String,
    slug: product['slug'] as String,
    price: double.parse(product['price'] as String),
    stock: product['stock'] as int,
  );
}

void main() {
  late FakeApiClient api;

  setUp(() => api = FakeApiClient());

  test('initial state is idle and empty', () {
    final state = makeContainer(api).read(wishlistViewModelProvider);

    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
    expect(state.items, isEmpty);
    expect(state.pendingProductIds, isEmpty);
    expect(api.calls, isEmpty);
  });

  test('loading → success: items parsed from the API', () async {
    api.stubFixture('GET', _path, _success);
    final gate = api.hold('GET', _path);
    final container = makeContainer(api);
    final vm = container.read(wishlistViewModelProvider.notifier);

    final loading = vm.load();
    expect(container.read(wishlistViewModelProvider).isLoading, isTrue);
    gate.complete();
    await loading;

    final state = container.read(wishlistViewModelProvider);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
    expect(
      state.items.map((i) => i.productId),
      _fixtureItems().map((j) => j['productId']),
    );
    expect(
      state.isFavorite(_fixtureItems().first['productId'] as String),
      isTrue,
    );
  });

  test('loading → empty: no items, no error', () async {
    api.stubFixture('GET', _path, _empty);
    final container = makeContainer(api);

    await container.read(wishlistViewModelProvider.notifier).load();

    final state = container.read(wishlistViewModelProvider);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
    expect(state.items, isEmpty);
  });

  test('loading → error: message from the API, list stays empty', () async {
    api.stubError('GET', _path);
    final container = makeContainer(api);

    await container.read(wishlistViewModelProvider.notifier).load();

    final state = container.read(wishlistViewModelProvider);
    expect(state.isLoading, isFalse);
    expect(state.error, fixtureError(error500).message);
    expect(state.items, isEmpty);
  });

  test('refresh replaces the list and clears a previous error', () async {
    api.stubError('GET', _path);
    final container = makeContainer(api);
    final vm = container.read(wishlistViewModelProvider.notifier);
    await vm.load();
    api.stubFixture('GET', _path, _success);

    await vm.load();

    final state = container.read(wishlistViewModelProvider);
    expect(state.error, isNull);
    expect(state.items, hasLength(_fixtureItems().length));
  });

  group('toggle', () {
    test('add is optimistic, then keeps the server item', () async {
      api.stubFixture('GET', _path, _empty);
      api.stubFixture('POST', _path, _added);
      final gate = api.hold('POST', _path);
      final container = makeContainer(api);
      final vm = container.read(wishlistViewModelProvider.notifier);
      await vm.load();
      final product = _addedProduct();

      final toggling = vm.toggle(product);
      var state = container.read(wishlistViewModelProvider);
      expect(state.isFavorite(product.id), isTrue);
      expect(state.isPending(product.id), isTrue);
      gate.complete();
      await toggling;

      state = container.read(wishlistViewModelProvider);
      expect(
        state.items.single.id,
        (fixtureJson(_added)['data'] as Map)['item']['id'],
      );
      expect(state.isPending(product.id), isFalse);
      expect(api.callsTo('POST', _path).single.body, {'productId': product.id});
    });

    test('remove is optimistic and calls DELETE', () async {
      api.stubFixture('GET', _path, _success);
      api.stubFixture('DELETE', _path, _removed);
      final container = makeContainer(api);
      final vm = container.read(wishlistViewModelProvider.notifier);
      await vm.load();
      final product = container
          .read(wishlistViewModelProvider)
          .items
          .first
          .product!;

      await vm.toggle(product);

      final state = container.read(wishlistViewModelProvider);
      expect(state.isFavorite(product.id), isFalse);
      expect(state.items, hasLength(_fixtureItems().length - 1));
      expect(api.callsTo('DELETE', _path).single.body, {
        'productId': product.id,
      });
    });

    test('a failed add rolls back and reports the error', () async {
      api.stubFixture('GET', _path, _empty);
      api.stubError('POST', _path);
      final container = makeContainer(api);
      final vm = container.read(wishlistViewModelProvider.notifier);
      await vm.load();

      await vm.toggle(_addedProduct());

      final state = container.read(wishlistViewModelProvider);
      expect(state.items, isEmpty);
      expect(state.error, fixtureError(error500).message);
      expect(state.pendingProductIds, isEmpty);
    });

    test('a failed remove restores the item', () async {
      api.stubFixture('GET', _path, _success);
      api.stubError('DELETE', _path);
      final container = makeContainer(api);
      final vm = container.read(wishlistViewModelProvider.notifier);
      await vm.load();
      final product = container
          .read(wishlistViewModelProvider)
          .items
          .first
          .product!;

      await vm.toggle(product);

      final state = container.read(wishlistViewModelProvider);
      expect(state.isFavorite(product.id), isTrue);
      expect(state.items, hasLength(_fixtureItems().length));
      expect(state.error, isNotNull);
    });

    test('a second tap while pending is ignored', () async {
      api.stubFixture('GET', _path, _empty);
      api.stubFixture('POST', _path, _added);
      final gate = api.hold('POST', _path);
      final container = makeContainer(api);
      final vm = container.read(wishlistViewModelProvider.notifier);
      await vm.load();
      final product = _addedProduct();

      final first = vm.toggle(product);
      await vm.toggle(product);
      gate.complete();
      await first;

      expect(api.callsTo('POST', _path), hasLength(1));
      expect(api.callsTo('DELETE', _path), isEmpty);
    });
  });
}
