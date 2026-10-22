import 'package:bakery_mobile/src/features/wishlist/presentation/screens/wishlist_screen.dart';
import 'package:bakery_mobile/src/features/wishlist/presentation/wishlist_keys.dart';
import 'package:bakery_mobile/src/shared/widgets/error_retry_widget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_api_client.dart';
import '../../helpers/fixture.dart';
import '../../helpers/pump_app.dart';

const _path = '/api/wishlist';
const _success = 'wishlist/wishlist_success.json';
const _empty = 'wishlist/wishlist_empty.json';
const _removed = 'wishlist/wishlist_remove_success.json';

List<String> _fixtureProductIds() =>
    ((fixtureJson(_success)['data'] as Map)['wishlist'] as List)
        .map((j) => (j as Map)['productId'] as String)
        .toList();

void main() {
  late FakeApiClient api;

  setUp(() => api = FakeApiClient());

  testWidgets('loading shows the skeleton', (tester) async {
    api.stubFixture('GET', _path, _success);
    final gate = api.hold('GET', _path);

    await pumpApp(tester, const WishlistScreen(), api: api);
    await tester.pump(); // post-frame load() starts

    expect(find.byKey(WishlistKeys.loading), findsOneWidget);
    expect(find.byKey(WishlistKeys.empty), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(WishlistKeys.loading), findsNothing);
  });

  testWidgets('data shows one tile per favorite', (tester) async {
    api.stubFixture('GET', _path, _success);

    await pumpApp(tester, const WishlistScreen(), api: api);
    await tester.pumpAndSettle();

    for (final id in _fixtureProductIds()) {
      expect(find.byKey(WishlistKeys.item(id)), findsOneWidget);
    }
    expect(find.byKey(WishlistKeys.empty), findsNothing);
    expect(find.byKey(WishlistKeys.error), findsNothing);
  });

  testWidgets('empty shows the empty state only', (tester) async {
    api.stubFixture('GET', _path, _empty);

    await pumpApp(tester, const WishlistScreen(), api: api);
    await tester.pumpAndSettle();

    expect(find.byKey(WishlistKeys.empty), findsOneWidget);
    expect(find.byKey(WishlistKeys.error), findsNothing);
  });

  testWidgets('error shows retry (not the empty state); retry reloads', (
    tester,
  ) async {
    api.stubError('GET', _path);

    await pumpApp(tester, const WishlistScreen(), api: api);
    await tester.pumpAndSettle();

    expect(find.byKey(WishlistKeys.error), findsOneWidget);
    expect(find.byKey(WishlistKeys.empty), findsNothing);

    api.stubFixture('GET', _path, _success);
    await tester.tap(
      find.descendant(
        of: find.byKey(WishlistKeys.error),
        matching: find.byKey(ErrorRetryWidget.retryButtonKey),
      ),
    );
    await tester.pumpAndSettle();

    expect(api.callsTo('GET', _path), hasLength(2));
    expect(
      find.byKey(WishlistKeys.item(_fixtureProductIds().first)),
      findsOneWidget,
    );
    expect(find.byKey(WishlistKeys.error), findsNothing);
  });

  testWidgets('tapping the heart removes the item', (tester) async {
    api.stubFixture('GET', _path, _success);
    api.stubFixture('DELETE', _path, _removed);
    final id = _fixtureProductIds().first;

    await pumpApp(tester, const WishlistScreen(), api: api);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(WishlistKeys.toggle(id)));
    await tester.pumpAndSettle();

    expect(api.callsTo('DELETE', _path).single.body, {'productId': id});
    expect(find.byKey(WishlistKeys.item(id)), findsNothing);
  });

  testWidgets('a failed remove keeps the item and shows the error banner', (
    tester,
  ) async {
    api.stubFixture('GET', _path, _success);
    api.stubError('DELETE', _path);
    final id = _fixtureProductIds().first;

    await pumpApp(tester, const WishlistScreen(), api: api);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(WishlistKeys.toggle(id)));
    await tester.pumpAndSettle();

    expect(find.byKey(WishlistKeys.item(id)), findsOneWidget);
    expect(find.byKey(WishlistKeys.errorBanner), findsOneWidget);
    expect(find.byKey(WishlistKeys.error), findsNothing);
  });
}
