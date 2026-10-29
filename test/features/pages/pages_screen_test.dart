import 'package:bakery_mobile/src/features/pages/presentation/pages_keys.dart';
import 'package:bakery_mobile/src/features/pages/presentation/screens/page_detail_screen.dart';
import 'package:bakery_mobile/src/features/pages/presentation/screens/pages_screen.dart';
import 'package:bakery_mobile/src/features/pages/presentation/widgets/page_templates.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_api_client.dart';
import '../../helpers/pump_app.dart';

Finder _listScrollable() => find.descendant(
  of: find.byKey(PagesKeys.list),
  matching: find.byType(Scrollable),
);

Future<void> _scrollTo(WidgetTester tester, Finder finder) =>
    tester.scrollUntilVisible(finder, 200, scrollable: _listScrollable());

void main() {
  testWidgets('lists every built-in page without calling the API', (
    tester,
  ) async {
    final api = FakeApiClient();

    await pumpApp(tester, const PagesScreen(), api: api);
    await tester.pumpAndSettle();

    for (final slug in builtInPageSlugs) {
      await _scrollTo(tester, find.byKey(PagesKeys.item(slug)));
      expect(find.byKey(PagesKeys.item(slug)), findsOneWidget);
    }
    expect(api.calls, isEmpty);
  });

  testWidgets('tapping a page opens its built-in content', (tester) async {
    await pumpApp(tester, const PagesScreen(), api: FakeApiClient());
    await tester.pumpAndSettle();

    final item = find.byKey(PagesKeys.item('chinh-sach-doi-tra'));
    await _scrollTo(tester, item);
    await tester.tap(item);
    await tester.pumpAndSettle();

    expect(find.byType(PageDetailScreen), findsOneWidget);
    expect(find.byType(BuiltInPageBody), findsOneWidget);
  });

  testWidgets('an unknown slug shows not found', (tester) async {
    await pumpApp(
      tester,
      const PageDetailScreen(slug: 'khong-ton-tai'),
      api: FakeApiClient(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Không tìm thấy trang'), findsOneWidget);
  });
}
