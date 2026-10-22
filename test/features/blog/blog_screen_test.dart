import 'package:bakery_mobile/src/features/blog/presentation/blog_keys.dart';
import 'package:bakery_mobile/src/features/blog/presentation/screens/blog_screen.dart';
import 'package:bakery_mobile/src/shared/widgets/error_retry_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_api_client.dart';
import '../../helpers/pump_app.dart';
import 'blog_fixtures.dart';

void main() {
  late FakeApiClient api;

  setUp(() => api = FakeApiClient());

  testWidgets('loading shows the skeleton', (tester) async {
    stubBlog(api);
    final gate = api.hold('GET', postsPath);

    await pumpApp(tester, const BlogScreen(), api: api);
    await tester.pump(); // post-frame loadInitial() starts

    expect(find.byKey(BlogKeys.loading), findsOneWidget);
    expect(find.byKey(BlogKeys.empty), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(BlogKeys.loading), findsNothing);
  });

  testWidgets('data shows posts and filter chips', (tester) async {
    stubBlog(api);

    await pumpApp(tester, const BlogScreen(), api: api);
    await tester.pumpAndSettle();

    expect(
      find.byKey(BlogKeys.post(fixturePosts().first['id'] as String)),
      findsOneWidget,
    );
    for (final slug in fixtureCategorySlugs()) {
      expect(find.byKey(BlogKeys.category(slug)), findsOneWidget);
    }
    expect(find.byKey(BlogKeys.tag(fixtureTagSlugs().first)), findsOneWidget);
    expect(find.byKey(BlogKeys.empty), findsNothing);
    expect(find.byKey(BlogKeys.loadMore), findsNothing);
  });

  testWidgets('empty shows the empty state only', (tester) async {
    stubBlog(api, posts: postsEmpty);

    await pumpApp(tester, const BlogScreen(), api: api);
    await tester.pumpAndSettle();

    expect(find.byKey(BlogKeys.empty), findsOneWidget);
    expect(find.byKey(BlogKeys.error), findsNothing);
  });

  testWidgets('error shows retry (not the empty state); retry reloads', (
    tester,
  ) async {
    stubBlog(api);
    api.stubError('GET', postsPath);

    await pumpApp(tester, const BlogScreen(), api: api);
    await tester.pumpAndSettle();

    expect(find.byKey(BlogKeys.error), findsOneWidget);
    expect(find.byKey(BlogKeys.empty), findsNothing);

    api.stubFixture('GET', postsPath, postsSuccess);
    await tester.tap(
      find.descendant(
        of: find.byKey(BlogKeys.error),
        matching: find.byKey(ErrorRetryWidget.retryButtonKey),
      ),
    );
    await tester.pumpAndSettle();

    expect(api.callsTo('GET', postsPath), hasLength(2));
    expect(find.byKey(BlogKeys.error), findsNothing);
    expect(
      find.byKey(BlogKeys.post(fixturePosts().first['id'] as String)),
      findsOneWidget,
    );
  });

  testWidgets('scrolling to the end loads the next page', (tester) async {
    stubBlog(api);
    api.stub('GET', postsPath, pagedPosts);

    await pumpApp(tester, const BlogScreen(), api: api);
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(BlogKeys.list), const Offset(0, -5000));
    await tester.pumpAndSettle();

    expect(api.callsTo('GET', postsPath).last.query?['page'], 2);
    expect(find.byKey(BlogKeys.loadMore), findsNothing);
  });

  testWidgets('tapping a category filters the posts', (tester) async {
    stubBlog(api);
    final slug = fixtureCategorySlugs().first;

    await pumpApp(tester, const BlogScreen(), api: api);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(BlogKeys.category(slug)));
    await tester.pumpAndSettle();

    expect(api.callsTo('GET', postsPath).last.query?['categorySlug'], slug);
    expect(
      tester.widget<ChoiceChip>(find.byKey(BlogKeys.category(slug))).selected,
      isTrue,
    );
  });

  testWidgets('submitting a search sends it to the API', (tester) async {
    stubBlog(api);

    await pumpApp(tester, const BlogScreen(), api: api);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byKey(BlogKeys.search),
        matching: find.byType(TextField),
      ),
      'tiramisu',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(api.callsTo('GET', postsPath).last.query?['search'], 'tiramisu');
  });
}
