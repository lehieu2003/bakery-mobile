import 'package:bakery_mobile/src/features/catalog/domain/models/category.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/catalog_keys.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/screens/category_screen.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_api_client.dart';
import '../../helpers/fixture.dart';
import '../../helpers/pump_app.dart';
import 'catalog_fixtures.dart';

/// "Đồ pha chế" from the categories fixture: a root with two subcategories.
Category _rootCategory() => Category.fromJson(
  ((fixtureData(categoriesSuccess) as Map)['categories'] as List).first
      as Map<String, dynamic>,
);

Finder _scrollable() => find.descendant(
  of: find.byKey(CategoryKeys.list),
  matching: find.byType(Scrollable),
);

void main() {
  late FakeApiClient api;

  setUp(() => api = FakeApiClient());

  testWidgets('tapping a home category opens its product list', (tester) async {
    // The test harness answers every image request with HTTP 400, and the
    // home images covered by the new route report it unhandled. Only those
    // are dropped; every other error still reaches the test.
    final reportError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is NetworkImageLoadException) return;
      reportError?.call(details);
    };
    try {
      stubHome(api);
      api.stubFixture('GET', productsPath, productsSuccess);
      final root = _rootCategory();

      await pumpApp(tester, const HomeScreen(), api: api);
      await tester.pumpAndSettle();
      // The rail shortens labels ("Đồ pha chế" shows as "Drinks"): tap the
      // first capsule, which is the first category.
      await tester.tap(
        find
            .descendant(
              of: find.byKey(HomeKeys.categoryRail),
              matching: find.byType(InkWell),
            )
            .first,
      );
      await tester.pumpAndSettle();

      expect(find.byType(CategoryScreen), findsOneWidget);
      expect(find.widgetWithText(AppBar, root.name), findsOneWidget);
      // The root id lists the whole tree: bakery-web adds its descendants.
      expect(
        api.callsTo('GET', productsPath).single.query!['categoryId'],
        root.id,
      );
      final firstId = idsOf(productsSuccess, 'products').first;
      expect(find.byKey(CategoryKeys.product(firstId)), findsOneWidget);
      expect(find.text('${productsTotal()} sản phẩm'), findsOneWidget);
    } finally {
      FlutterError.onError = reportError;
    }
  });

  testWidgets('a subcategory chip reloads the list for that subcategory', (
    tester,
  ) async {
    api.stubFixture('GET', productsPath, productsSuccess);
    final root = _rootCategory();
    final child = root.children.first;

    await pumpApp(tester, CategoryScreen(category: root), api: api);
    await tester.pumpAndSettle();
    expect(find.byKey(CategoryKeys.chip(root.id)), findsOneWidget);
    expect(find.text('Tất cả'), findsOneWidget);

    await tester.tap(find.byKey(CategoryKeys.chip(child.id)));
    await tester.pumpAndSettle();

    final calls = api.callsTo('GET', productsPath);
    expect(calls.map((c) => c.query!['categoryId']), [root.id, child.id]);
    expect(
      tester
          .widget<ChoiceChip>(find.byKey(CategoryKeys.chip(child.id)))
          .selected,
      isTrue,
    );
  });

  testWidgets('scrolling to the end loads the next page', (tester) async {
    api.stub('GET', productsPath, pagedProducts);

    await pumpApp(tester, CategoryScreen(category: _rootCategory()), api: api);
    await tester.pumpAndSettle();
    await tester.drag(_scrollable().first, const Offset(0, -2000));
    await tester.pumpAndSettle();

    final pages = api
        .callsTo('GET', productsPath)
        .map((c) => c.query!['page'])
        .toList();
    // The fixture pages hold two products, so one drag may go further.
    expect(pages.take(2), [1, 2]);
    final secondPageId = '${idsOf(productsSuccess, 'products').first}-p2';
    expect(find.byKey(CategoryKeys.product(secondPageId)), findsOneWidget);
  });

  testWidgets('an empty category says so', (tester) async {
    api.stubFixture('GET', productsPath, productsEmpty);

    await pumpApp(tester, CategoryScreen(category: _rootCategory()), api: api);
    await tester.pumpAndSettle();

    expect(find.byKey(CategoryKeys.empty), findsOneWidget);
    expect(find.text('Danh mục này chưa có sản phẩm.'), findsOneWidget);
  });

  testWidgets('a failed load offers a retry that reloads', (tester) async {
    api.stubError('GET', productsPath);

    await pumpApp(tester, CategoryScreen(category: _rootCategory()), api: api);
    await tester.pumpAndSettle();
    expect(find.byKey(CategoryKeys.error), findsOneWidget);

    api.stubFixture('GET', productsPath, productsSuccess);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.byKey(CategoryKeys.error), findsNothing);
    final firstId = idsOf(productsSuccess, 'products').first;
    expect(find.byKey(CategoryKeys.product(firstId)), findsOneWidget);
  });
}
