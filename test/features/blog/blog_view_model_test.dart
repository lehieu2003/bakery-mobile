import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_api_client.dart';
import '../../helpers/fixture.dart';
import '../../helpers/pump_app.dart';
import 'blog_fixtures.dart';

void main() {
  late FakeApiClient api;

  setUp(() => api = FakeApiClient());

  test('initial state is idle and empty', () {
    final state = makeContainer(api).read(blogViewModelProvider);

    expect(state.isLoading, isFalse);
    expect(state.isLoadingMore, isFalse);
    expect(state.error, isNull);
    expect(state.posts, isEmpty);
    expect(state.categories, isEmpty);
    expect(state.tags, isEmpty);
    expect(state.hasMore, isFalse);
    expect(api.calls, isEmpty);
  });

  test('loading → success: posts, categories and tags', () async {
    stubBlog(api);
    final gate = api.hold('GET', postsPath);
    final container = makeContainer(api);
    final vm = container.read(blogViewModelProvider.notifier);

    final loading = vm.loadInitial();
    expect(container.read(blogViewModelProvider).isLoading, isTrue);
    gate.complete();
    await loading;

    final state = container.read(blogViewModelProvider);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
    expect(state.posts.map((p) => p.id), fixturePosts().map((j) => j['id']));
    expect(state.categories.map((c) => c.slug), fixtureCategorySlugs());
    expect(state.tags.map((t) => t.slug), fixtureTagSlugs());
    expect(api.callsTo('GET', postsPath).single.query, {
      'page': 1,
      'limit': 12,
    });
  });

  test('loading → empty: no posts, no error, nothing more', () async {
    stubBlog(api, posts: postsEmpty);
    final container = makeContainer(api);

    await container.read(blogViewModelProvider.notifier).loadInitial();

    final state = container.read(blogViewModelProvider);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
    expect(state.posts, isEmpty);
    expect(state.hasMore, isFalse);
  });

  test('loading → error: any failed request fails the load', () async {
    stubBlog(api);
    api.stubError('GET', categoriesPath);
    final container = makeContainer(api);

    await container.read(blogViewModelProvider.notifier).loadInitial();

    final state = container.read(blogViewModelProvider);
    expect(state.isLoading, isFalse);
    expect(state.error, fixtureError(error500).message);
    expect(state.posts, isEmpty);
  });

  test('refresh replaces posts and clears a previous error', () async {
    stubBlog(api);
    api.stubError('GET', postsPath);
    final container = makeContainer(api);
    final vm = container.read(blogViewModelProvider.notifier);
    await vm.loadInitial();
    api.stubFixture('GET', postsPath, postsSuccess);

    await vm.loadInitial();

    final state = container.read(blogViewModelProvider);
    expect(state.error, isNull);
    expect(state.posts, hasLength(fixturePosts().length));
  });

  group('pagination', () {
    test('loadMore appends the next page until the last one', () async {
      stubBlog(api);
      api.stub('GET', postsPath, pagedPosts);
      final container = makeContainer(api);
      final vm = container.read(blogViewModelProvider.notifier);
      await vm.loadInitial();
      expect(container.read(blogViewModelProvider).hasMore, isTrue);

      await vm.loadMore();
      await vm.loadMore(); // last page reached: no request

      final state = container.read(blogViewModelProvider);
      expect(state.page, 2);
      expect(state.hasMore, isFalse);
      expect(state.posts, hasLength(fixturePosts().length * 2));
      expect(api.callsTo('GET', postsPath), hasLength(2));
      expect(api.callsTo('GET', postsPath).last.query?['page'], 2);
    });

    test('a failed next page keeps loaded posts and reports it', () async {
      stubBlog(api);
      api.stub('GET', postsPath, pagedPosts);
      final container = makeContainer(api);
      final vm = container.read(blogViewModelProvider.notifier);
      await vm.loadInitial();
      api.stubError('GET', postsPath);

      await vm.loadMore();

      final state = container.read(blogViewModelProvider);
      expect(state.posts, hasLength(fixturePosts().length));
      expect(state.page, 1);
      expect(state.isLoadingMore, isFalse);
      expect(state.error, isNotNull);
    });
  });

  group('applyFilter', () {
    test('sends search/category/tag and resets to page 1', () async {
      stubBlog(api);
      final container = makeContainer(api);
      final vm = container.read(blogViewModelProvider.notifier);
      await vm.loadInitial();

      await vm.applyFilter(search: 'kem', categorySlug: 'cong-thuc');

      expect(api.callsTo('GET', postsPath).last.query, {
        'page': 1,
        'limit': 12,
        'search': 'kem',
        'categorySlug': 'cong-thuc',
      });
      final state = container.read(blogViewModelProvider);
      expect(state.search, 'kem');
      expect(state.categorySlug, 'cong-thuc');
    });

    test('loadMore keeps the active filter', () async {
      stubBlog(api);
      api.stub('GET', postsPath, pagedPosts);
      final container = makeContainer(api);
      final vm = container.read(blogViewModelProvider.notifier);
      await vm.applyFilter(tagSlug: 'banh-kem');

      await vm.loadMore();

      expect(api.callsTo('GET', postsPath).last.query, {
        'page': 2,
        'limit': 12,
        'tagSlug': 'banh-kem',
      });
    });

    test('a filter with no match is empty, not an error', () async {
      stubBlog(api);
      final container = makeContainer(api);
      final vm = container.read(blogViewModelProvider.notifier);
      await vm.loadInitial();
      api.stubFixture('GET', postsPath, postsEmpty);

      await vm.applyFilter(search: 'không-có');

      final state = container.read(blogViewModelProvider);
      expect(state.posts, isEmpty);
      expect(state.error, isNull);
    });
  });
}
