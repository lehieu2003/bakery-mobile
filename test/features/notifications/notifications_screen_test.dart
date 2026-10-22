import 'package:bakery_mobile/src/features/notifications/presentation/notifications_keys.dart';
import 'package:bakery_mobile/src/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:bakery_mobile/src/shared/widgets/error_retry_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_api_client.dart';
import '../../helpers/fixture.dart';
import '../../helpers/pump_app.dart';

const _path = '/api/notifications';
const _success = 'notifications/notifications_success.json';
const _empty = 'notifications/notifications_empty.json';

List<String> _fixtureIds() =>
    ((fixtureJson(_success)['data'] as Map)['notifications'] as List)
        .map((j) => (j as Map)['id'] as String)
        .toList();

void main() {
  late FakeApiClient api;

  setUp(() => api = FakeApiClient());

  testWidgets('loading shows the skeleton', (tester) async {
    api.stubFixture('GET', _path, _success);
    final gate = api.hold('GET', _path);

    await pumpApp(tester, const NotificationsScreen(), api: api);
    await tester.pump(); // post-frame load() starts

    expect(find.byKey(NotificationsKeys.loading), findsOneWidget);
    expect(find.byKey(NotificationsKeys.empty), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(NotificationsKeys.loading), findsNothing);
  });

  testWidgets('data shows one tile per notification', (tester) async {
    api.stubFixture('GET', _path, _success);

    await pumpApp(tester, const NotificationsScreen(), api: api);
    await tester.pumpAndSettle();

    for (final id in _fixtureIds()) {
      expect(find.byKey(NotificationsKeys.item(id)), findsOneWidget);
    }
    expect(find.byKey(NotificationsKeys.empty), findsNothing);
    expect(find.byKey(NotificationsKeys.error), findsNothing);
  });

  testWidgets('empty shows the empty state only', (tester) async {
    api.stubFixture('GET', _path, _empty);

    await pumpApp(tester, const NotificationsScreen(), api: api);
    await tester.pumpAndSettle();

    expect(find.byKey(NotificationsKeys.empty), findsOneWidget);
    expect(find.byKey(NotificationsKeys.error), findsNothing);
    expect(find.byKey(NotificationsKeys.loadMore), findsNothing);
  });

  testWidgets('error shows retry (not the empty state); retry reloads', (
    tester,
  ) async {
    api.stubError('GET', _path);

    await pumpApp(tester, const NotificationsScreen(), api: api);
    await tester.pumpAndSettle();

    expect(find.byKey(NotificationsKeys.error), findsOneWidget);
    expect(find.byKey(NotificationsKeys.empty), findsNothing);

    api.stubFixture('GET', _path, _success);
    await tester.tap(
      find.descendant(
        of: find.byKey(NotificationsKeys.error),
        matching: find.byKey(ErrorRetryWidget.retryButtonKey),
      ),
    );
    await tester.pumpAndSettle();

    expect(api.callsTo('GET', _path), hasLength(2));
    expect(
      find.byKey(NotificationsKeys.item(_fixtureIds().first)),
      findsOneWidget,
    );
    expect(find.byKey(NotificationsKeys.error), findsNothing);
  });

  testWidgets('"Load more" fetches the next page', (tester) async {
    api.stubFixture('GET', _path, _success);

    await pumpApp(tester, const NotificationsScreen(), api: api);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(NotificationsKeys.loadMore));
    await tester.tap(find.byKey(NotificationsKeys.loadMore));
    await tester.pumpAndSettle();

    expect(api.callsTo('GET', _path).last.query?['page'], 2);
  });

  testWidgets('guest sees the sign-in prompt and no request is made', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const NotificationsScreen(),
      api: api,
      signedIn: false,
    );
    await tester.pumpAndSettle();

    expect(find.byType(ListView), findsNothing);
    expect(api.calls, isEmpty);
  });
}
