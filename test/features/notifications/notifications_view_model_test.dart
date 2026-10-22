import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_api_client.dart';
import '../../helpers/fixture.dart';
import '../../helpers/pump_app.dart';

const _path = '/api/notifications';
const _success = 'notifications/notifications_success.json';
const _empty = 'notifications/notifications_empty.json';

List<Map<String, dynamic>> _fixtureItems() =>
    ((fixtureJson(_success)['data'] as Map)['notifications'] as List)
        .cast<Map<String, dynamic>>();

int _fixtureTotal() =>
    ((fixtureJson(_success)['data'] as Map)['pagination'] as Map)['total']
        as int;

void main() {
  late FakeApiClient api;

  setUp(() => api = FakeApiClient());

  test('initial state is idle and empty', () {
    final state = makeContainer(api).read(notificationsViewModelProvider);

    expect(state.isLoading, isFalse);
    expect(state.isLoadingMore, isFalse);
    expect(state.error, isNull);
    expect(state.notifications, isEmpty);
    expect(state.page, 1);
    expect(state.total, 0);
    expect(api.calls, isEmpty);
  });

  test('loading → success: first page parsed from the API', () async {
    api.stubFixture('GET', _path, _success);
    final gate = api.hold('GET', _path);
    final container = makeContainer(api);
    final vm = container.read(notificationsViewModelProvider.notifier);

    final loading = vm.load();
    expect(container.read(notificationsViewModelProvider).isLoading, isTrue);
    gate.complete();
    await loading;

    final state = container.read(notificationsViewModelProvider);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
    expect(
      state.notifications.map((n) => n.id),
      _fixtureItems().map((j) => j['id']),
    );
    expect(state.total, _fixtureTotal());
    expect(
      state.unreadCount,
      _fixtureItems().where((j) => j['isRead'] != true).length,
    );
    expect(api.callsTo('GET', _path).single.query, {'page': 1, 'limit': 10});
  });

  test('loading → empty: no notifications, no error, nothing more', () async {
    api.stubFixture('GET', _path, _empty);
    final container = makeContainer(api);

    await container.read(notificationsViewModelProvider.notifier).load();

    final state = container.read(notificationsViewModelProvider);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
    expect(state.notifications, isEmpty);
    expect(state.hasMore, isFalse);
  });

  test('loading → error: message from the API, list stays empty', () async {
    api.stubError('GET', _path);
    final container = makeContainer(api);

    await container.read(notificationsViewModelProvider.notifier).load();

    final state = container.read(notificationsViewModelProvider);
    expect(state.isLoading, isFalse);
    expect(state.error, fixtureError(error500).message);
    expect(state.notifications, isEmpty);
  });

  group('pagination', () {
    test('loadMore appends the next page while total is not reached', () async {
      api.stubFixture('GET', _path, _success);
      final container = makeContainer(api);
      final vm = container.read(notificationsViewModelProvider.notifier);
      await vm.load();
      expect(container.read(notificationsViewModelProvider).hasMore, isTrue);

      await vm.loadMore();

      final state = container.read(notificationsViewModelProvider);
      expect(state.page, 2);
      expect(state.notifications, hasLength(_fixtureItems().length * 2));
      expect(api.callsTo('GET', _path).last.query, {'page': 2, 'limit': 10});
    });

    test('loadMore does nothing when every item is loaded', () async {
      api.stubFixture('GET', _path, _empty);
      final container = makeContainer(api);
      final vm = container.read(notificationsViewModelProvider.notifier);
      await vm.load();

      await vm.loadMore();

      expect(api.callsTo('GET', _path), hasLength(1));
    });

    test(
      'a failed next page keeps loaded items and reports the error',
      () async {
        api.stubFixture('GET', _path, _success);
        final container = makeContainer(api);
        final vm = container.read(notificationsViewModelProvider.notifier);
        await vm.load();
        api.stubError('GET', _path);

        await vm.loadMore();

        final state = container.read(notificationsViewModelProvider);
        expect(state.notifications, hasLength(_fixtureItems().length));
        expect(state.page, 1);
        expect(state.isLoadingMore, isFalse);
        expect(state.error, isNotNull);
      },
    );
  });

  test('refresh replaces the list with the latest page', () async {
    api.stubFixture('GET', _path, _success);
    final container = makeContainer(api);
    final vm = container.read(notificationsViewModelProvider.notifier);
    await vm.load();
    api.stubFixture('GET', _path, _empty);

    await vm.load();

    expect(
      container.read(notificationsViewModelProvider).notifications,
      isEmpty,
    );
  });

  test('markOneAsRead posts to the item and flags it read', () async {
    api.stubFixture('GET', _path, _success);
    final id = _fixtureItems().first['id'] as String;
    api.stub('POST', '$_path/$id/read', (_) => null);
    final container = makeContainer(api);
    final vm = container.read(notificationsViewModelProvider.notifier);
    await vm.load();

    await vm.markOneAsRead(id);

    final state = container.read(notificationsViewModelProvider);
    expect(api.callsTo('POST', '$_path/$id/read'), hasLength(1));
    expect(state.notifications.firstWhere((n) => n.id == id).isRead, isTrue);
  });
}
