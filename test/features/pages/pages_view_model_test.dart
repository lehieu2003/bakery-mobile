import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_api_client.dart';
import '../../helpers/fixture.dart';
import '../../helpers/pump_app.dart';

const _path = '/api/public/pages';
const _success = 'pages/pages_success.json';
const _empty = 'pages/pages_empty.json';

List<String> _fixtureSlugs() => (fixtureData(_success) as List)
    .map((j) => (j as Map)['slug'] as String)
    .toList();

void main() {
  late FakeApiClient api;

  setUp(() => api = FakeApiClient());

  test('initial state is idle and empty', () {
    final state = makeContainer(api).read(pagesViewModelProvider);

    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
    expect(state.pages, isEmpty);
    expect(api.calls, isEmpty);
  });

  test('loading → success: pages parsed from the API', () async {
    api.stubFixture('GET', _path, _success);
    final gate = api.hold('GET', _path);
    final container = makeContainer(api);
    final vm = container.read(pagesViewModelProvider.notifier);

    final loading = vm.loadPages();
    expect(container.read(pagesViewModelProvider).isLoading, isTrue);
    gate.complete();
    await loading;

    final state = container.read(pagesViewModelProvider);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
    expect(state.pages.map((p) => p.slug), _fixtureSlugs());
  });

  test('loading → empty: no pages, no error', () async {
    api.stubFixture('GET', _path, _empty);
    final container = makeContainer(api);

    await container.read(pagesViewModelProvider.notifier).loadPages();

    final state = container.read(pagesViewModelProvider);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
    expect(state.pages, isEmpty);
  });

  test('loading → error: message from the API', () async {
    api.stubError('GET', _path);
    final container = makeContainer(api);

    await container.read(pagesViewModelProvider.notifier).loadPages();

    final state = container.read(pagesViewModelProvider);
    expect(state.isLoading, isFalse);
    expect(state.error, fixtureError(error500).message);
    expect(state.pages, isEmpty);
  });

  test('refresh replaces pages and clears a previous error', () async {
    api.stubError('GET', _path);
    final container = makeContainer(api);
    final vm = container.read(pagesViewModelProvider.notifier);
    await vm.loadPages();
    api.stubFixture('GET', _path, _success);

    await vm.loadPages();

    final state = container.read(pagesViewModelProvider);
    expect(state.error, isNull);
    expect(state.pages, hasLength(_fixtureSlugs().length));
  });
}
