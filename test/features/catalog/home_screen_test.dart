import 'package:bakery_mobile/src/features/catalog/presentation/catalog_keys.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/screens/home_screen.dart';
import 'package:bakery_mobile/src/shared/widgets/error_retry_widget.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_api_client.dart';
import '../../helpers/fixture.dart';
import '../../helpers/pump_app.dart';
import 'catalog_fixtures.dart';

Finder _listScrollable() => find.descendant(
  of: find.byKey(HomeKeys.list),
  matching: find.byType(Scrollable),
);

Future<void> _scrollTo(WidgetTester tester, Finder finder) =>
    tester.scrollUntilVisible(finder, 300, scrollable: _listScrollable().first);

void main() {
  late FakeApiClient api;

  setUp(() => api = FakeApiClient());

  testWidgets('loading shows the skeleton', (tester) async {
    stubHome(api);
    final gate = api.hold('GET', bestSellersPath);

    await pumpApp(tester, const HomeScreen(), api: api);
    await tester.pump(); // post-frame loadInitial() starts

    expect(find.byKey(HomeKeys.loading), findsOneWidget);
    expect(find.byKey(HomeKeys.empty), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(HomeKeys.loading), findsNothing);
  });

  testWidgets('data shows banners, categories and both product grids', (
    tester,
  ) async {
    stubHome(api);

    await pumpApp(tester, const HomeScreen(), api: api);
    await tester.pumpAndSettle();

    expect(find.byKey(HomeKeys.banners), findsOneWidget);
    expect(find.byKey(HomeKeys.categoryRail), findsOneWidget);
    await _scrollTo(
      tester,
      find.byKey(
        HomeKeys.personalizedItem(idsOf(personalizedSuccess, 'products').first),
      ),
    );
    // 'behavioral' picks need no explanation.
    expect(find.byKey(HomeKeys.personalizedMessage), findsNothing);
    final bestSellerId = idsOf(bestSellersSuccess, 'products').first;
    await _scrollTo(tester, find.byKey(HomeKeys.bestSeller(bestSellerId)));
    expect(find.byKey(HomeKeys.bestSeller(bestSellerId)), findsOneWidget);
    expect(find.byKey(HomeKeys.empty), findsNothing);
    expect(find.byKey(HomeKeys.error), findsNothing);
  });

  testWidgets('non-behavioral picks explain why', (tester) async {
    stubHome(api);
    api.stub(
      'GET',
      personalizedPath,
      (_) => {
        ...fixtureData(personalizedSuccess) as Map<String, dynamic>,
        'source': 'fallback',
        'reason': 'no-user',
      },
    );

    await pumpApp(tester, const HomeScreen(), api: api);
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.byKey(HomeKeys.personalizedMessage));

    expect(find.byKey(HomeKeys.personalizedMessage), findsOneWidget);
  });

  testWidgets('empty shows the empty state, no product grids', (tester) async {
    stubHome(
      api,
      bestSellers: bestSellersEmpty,
      personalized: personalizedEmpty,
    );

    await pumpApp(tester, const HomeScreen(), api: api);
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.byKey(HomeKeys.empty));

    expect(find.byKey(HomeKeys.empty), findsOneWidget);
    expect(find.byKey(HomeKeys.bestSellers), findsNothing);
    expect(find.byKey(HomeKeys.personalized), findsNothing);
    expect(find.byKey(HomeKeys.error), findsNothing);
  });

  testWidgets('error shows retry (not the empty state); retry reloads', (
    tester,
  ) async {
    stubHome(api);
    api.stubError('GET', bestSellersPath);

    await pumpApp(tester, const HomeScreen(), api: api);
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.byKey(HomeKeys.error));

    expect(find.byKey(HomeKeys.error), findsOneWidget);
    expect(find.byKey(HomeKeys.empty), findsNothing);

    api.stubFixture('GET', bestSellersPath, bestSellersSuccess);
    await tester.tap(
      find.descendant(
        of: find.byKey(HomeKeys.error),
        matching: find.byKey(ErrorRetryWidget.retryButtonKey),
      ),
    );
    await tester.pumpAndSettle();

    expect(api.callsTo('GET', bestSellersPath), hasLength(2));
    expect(find.byKey(HomeKeys.error), findsNothing);
    final bestSellerId = idsOf(bestSellersSuccess, 'products').first;
    await _scrollTo(tester, find.byKey(HomeKeys.bestSeller(bestSellerId)));
    expect(find.byKey(HomeKeys.bestSeller(bestSellerId)), findsOneWidget);
  });

  testWidgets('signed in: notifications and wishlist load for the header', (
    tester,
  ) async {
    stubHome(api);

    await pumpApp(tester, const HomeScreen(), api: api);
    await tester.pumpAndSettle();

    expect(api.callsTo('GET', '/api/notifications'), hasLength(1));
    expect(api.callsTo('GET', '/api/wishlist'), hasLength(1));
  });

  testWidgets('guest: no session-only requests', (tester) async {
    stubHome(api);

    await pumpApp(tester, const HomeScreen(), api: api, signedIn: false);
    await tester.pumpAndSettle();

    expect(api.callsTo('GET', bestSellersPath), hasLength(1));
    expect(api.callsTo('GET', '/api/notifications'), isEmpty);
    expect(api.callsTo('GET', '/api/wishlist'), isEmpty);
  });
}
