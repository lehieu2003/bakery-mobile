import 'package:bakery_mobile/src/features/catalog/presentation/catalog_keys.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/screens/search_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import 'features/catalog/catalog_fixtures.dart';
import 'helpers/fake_api_client.dart';
import 'helpers/pump_app.dart';

void main() {
  late FakeApiClient api;

  setUp(() => api = FakeApiClient());

  testWidgets('the result-count line hides when the search fails', (
    tester,
  ) async {
    stubSearch(api);
    api.stubError('GET', productsPath);

    await pumpApp(tester, const SearchScreen(), api: api);
    await tester.pumpAndSettle();

    expect(find.byKey(SearchKeys.error), findsOneWidget);
    expect(find.byKey(SearchKeys.resultCount), findsNothing);
  });

  testWidgets('the result-count line still shows on a successful first load', (
    tester,
  ) async {
    stubSearch(api);

    await pumpApp(tester, const SearchScreen(), api: api);
    await tester.pumpAndSettle();

    expect(find.byKey(SearchKeys.error), findsNothing);
    expect(find.byKey(SearchKeys.resultCount), findsOneWidget);
    expect(
      find.text(
        'Tất cả sản phẩm (${idsOf(productsSuccess, 'products').length})',
      ),
      findsOneWidget,
    );
  });
}
