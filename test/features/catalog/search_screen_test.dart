import 'package:bakery_mobile/src/core/theme/app_durations.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/catalog_keys.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/controllers/search_view_model.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/screens/search_screen.dart';
import 'package:bakery_mobile/src/shared/widgets/error_retry_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_api_client.dart';
import '../../helpers/pump_app.dart';
import 'catalog_fixtures.dart';

void main() {
  late FakeApiClient api;

  setUp(() => api = FakeApiClient());

  testWidgets('loading shows the skeleton', (tester) async {
    stubSearch(api);
    final gate = api.hold('GET', productsPath);

    await pumpApp(tester, const SearchScreen(), api: api);
    await tester.pump(); // post-frame search('') starts

    expect(find.byKey(SearchKeys.loading), findsOneWidget);
    expect(find.byKey(SearchKeys.empty), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(SearchKeys.loading), findsNothing);
  });

  testWidgets('data shows one tile per product and "Load more"', (
    tester,
  ) async {
    stubSearch(api);

    await pumpApp(tester, const SearchScreen(), api: api);
    await tester.pumpAndSettle();

    for (final id in idsOf(productsSuccess, 'products')) {
      expect(find.byKey(SearchKeys.product(id)), findsOneWidget);
    }
    expect(find.byKey(SearchKeys.loadMore), findsOneWidget);
    expect(find.byKey(SearchKeys.empty), findsNothing);
    expect(find.byKey(SearchKeys.error), findsNothing);
  });

  testWidgets('empty shows the empty state only', (tester) async {
    stubSearch(api, products: productsEmpty);

    await pumpApp(tester, const SearchScreen(), api: api);
    await tester.pumpAndSettle();

    expect(find.byKey(SearchKeys.empty), findsOneWidget);
    expect(find.byKey(SearchKeys.error), findsNothing);
    expect(find.byKey(SearchKeys.loadMore), findsNothing);
  });

  testWidgets('error shows retry (not the empty state); retry reloads', (
    tester,
  ) async {
    stubSearch(api);
    api.stubError('GET', productsPath);

    await pumpApp(tester, const SearchScreen(), api: api);
    await tester.pumpAndSettle();

    expect(find.byKey(SearchKeys.error), findsOneWidget);
    expect(find.byKey(SearchKeys.empty), findsNothing);

    api.stubFixture('GET', productsPath, productsSuccess);
    await tester.tap(
      find.descendant(
        of: find.byKey(SearchKeys.error),
        matching: find.byKey(ErrorRetryWidget.retryButtonKey),
      ),
    );
    await tester.pumpAndSettle();

    expect(api.callsTo('GET', productsPath), hasLength(2));
    expect(find.byKey(SearchKeys.error), findsNothing);
    expect(
      find.byKey(SearchKeys.product(idsOf(productsSuccess, 'products').first)),
      findsOneWidget,
    );
  });

  testWidgets('scrolling to the end loads the next page', (tester) async {
    stubSearch(api);
    api.stub('GET', productsPath, pagedProducts);

    await pumpApp(tester, const SearchScreen(), api: api);
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(SearchKeys.list), const Offset(0, -5000));
    await tester.pumpAndSettle();

    expect(api.callsTo('GET', productsPath).last.query?['page'], 2);
    expect(
      find.byKey(
        SearchKeys.product('${idsOf(productsSuccess, 'products').first}-p2'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('typing searches after the debounce', (tester) async {
    stubSearch(api);

    await pumpApp(tester, const SearchScreen(), api: api);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byKey(SearchKeys.input),
        matching: find.byType(TextField),
      ),
      'tiramisu',
    );
    await tester.pump(AppDurations.searchDebounce);
    await tester.pumpAndSettle();

    expect(api.callsTo('GET', productsPath).last.query?['search'], 'tiramisu');
    expect(find.textContaining('"tiramisu"'), findsOneWidget);
  });

  testWidgets('sort chips switch selection without a request', (tester) async {
    stubSearch(api);

    await pumpApp(tester, const SearchScreen(), api: api);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(SearchKeys.sort(SearchSortOption.priceAsc)));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(SearchKeys.sort(SearchSortOption.priceAsc)),
          )
          .selected,
      isTrue,
    );
    expect(api.callsTo('GET', productsPath), hasLength(1));
  });
}
