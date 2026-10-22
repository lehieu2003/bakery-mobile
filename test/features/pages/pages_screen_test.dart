import 'package:bakery_mobile/src/features/pages/presentation/pages_keys.dart';
import 'package:bakery_mobile/src/features/pages/presentation/screens/pages_screen.dart';
import 'package:bakery_mobile/src/features/pages/presentation/states/static_page_fallbacks.dart';
import 'package:bakery_mobile/src/shared/widgets/error_retry_widget.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_api_client.dart';
import '../../helpers/pump_app.dart';

const _path = '/api/public/pages';
const _success = 'pages/pages_success.json';
const _empty = 'pages/pages_empty.json';

/// The fixture page that has no static fallback.
const _dynamicSlug = 'huong-dan-dat-banh';

Finder _listScrollable() => find.descendant(
  of: find.byKey(PagesKeys.list),
  matching: find.byType(Scrollable),
);

Future<void> _scrollTo(WidgetTester tester, Finder finder) =>
    tester.scrollUntilVisible(finder, 200, scrollable: _listScrollable());

void main() {
  late FakeApiClient api;

  setUp(() => api = FakeApiClient());

  testWidgets('loading shows the spinner above the static pages', (
    tester,
  ) async {
    api.stubFixture('GET', _path, _success);
    final gate = api.hold('GET', _path);

    await pumpApp(tester, const PagesScreen(), api: api);
    await tester.pump(); // post-frame loadPages() starts

    expect(find.byKey(PagesKeys.loading), findsOneWidget);
    expect(find.byKey(PagesKeys.item(staticPageOrder.first)), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(PagesKeys.loading), findsNothing);
  });

  testWidgets('data appends API pages after static ones, without duplicates', (
    tester,
  ) async {
    api.stubFixture('GET', _path, _success);

    await pumpApp(tester, const PagesScreen(), api: api);
    await tester.pumpAndSettle();

    // 've-chung-toi' is both static (first) and in the fixture: rendered once.
    expect(find.byKey(PagesKeys.item('ve-chung-toi')), findsOneWidget);
    expect(find.byKey(PagesKeys.error), findsNothing);
    await _scrollTo(tester, find.byKey(PagesKeys.item(_dynamicSlug)));
    expect(find.byKey(PagesKeys.item(_dynamicSlug)), findsOneWidget);
  });

  testWidgets('empty API still lists every static page', (tester) async {
    api.stubFixture('GET', _path, _empty);

    await pumpApp(tester, const PagesScreen(), api: api);
    await tester.pumpAndSettle();

    for (final slug in staticPageOrder) {
      await _scrollTo(tester, find.byKey(PagesKeys.item(slug)));
      expect(find.byKey(PagesKeys.item(slug)), findsOneWidget);
    }
    expect(find.byKey(PagesKeys.item(_dynamicSlug)), findsNothing);
    expect(find.byKey(PagesKeys.error), findsNothing);
  });

  testWidgets('error shows a compact retry over static pages; retry reloads', (
    tester,
  ) async {
    api.stubError('GET', _path);

    await pumpApp(tester, const PagesScreen(), api: api);
    await tester.pumpAndSettle();

    expect(find.byKey(PagesKeys.error), findsOneWidget);
    expect(find.byKey(PagesKeys.item(staticPageOrder.first)), findsOneWidget);

    api.stubFixture('GET', _path, _success);
    await tester.tap(
      find.descendant(
        of: find.byKey(PagesKeys.error),
        matching: find.byKey(ErrorRetryWidget.retryButtonKey),
      ),
    );
    await tester.pumpAndSettle();

    expect(api.callsTo('GET', _path), hasLength(2));
    expect(find.byKey(PagesKeys.error), findsNothing);
    await _scrollTo(tester, find.byKey(PagesKeys.item(_dynamicSlug)));
    expect(find.byKey(PagesKeys.item(_dynamicSlug)), findsOneWidget);
  });
}
