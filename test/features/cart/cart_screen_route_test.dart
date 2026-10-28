import 'package:bakery_mobile/src/features/cart/presentation/screens/cart_screen.dart';
import 'package:bakery_mobile/src/features/navigation/presentation/screens/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_api_client.dart';
import '../../helpers/pump_app.dart';
import '../catalog/catalog_fixtures.dart';

Future<void> _pumpShell(WidgetTester tester) async {
  // Home without banners or categories: once the cart covers it, its images
  // stop listening, and the test HttpClient's 400s would surface as errors.
  final api = FakeApiClient();
  stubHome(api, bestSellers: bestSellersEmpty, personalized: personalizedEmpty);
  api
    ..stub('GET', bannersPath, (_) => <Object>[])
    ..stub('GET', categoriesPath, (_) => {'categories': <Object>[]});
  await pumpApp(tester, const MainLayout(), api: api);
  await tester.pumpAndSettle();
}

/// The cart opened as its own screen: no bottom bar or cart button under it,
/// and a back button to the tab the user came from.
void _expectCartScreenOnItsOwn() {
  expect(find.byType(CartScreen), findsOneWidget);
  expect(find.byType(BottomAppBar), findsNothing);
  expect(find.byType(FloatingActionButton), findsNothing);
  expect(find.byType(BackButton), findsOneWidget);
}

void main() {
  testWidgets('the cart button opens the cart without the bottom bar', (
    tester,
  ) async {
    await _pumpShell(tester);
    expect(find.byType(CartScreen), findsNothing);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    _expectCartScreenOnItsOwn();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(CartScreen), findsNothing);
    expect(find.byType(BottomAppBar), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('the drawer cart item opens the same screen', (tester) async {
    await _pumpShell(tester);

    await tester.tap(find.byTooltip('Mở menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Giỏ hàng'));
    await tester.pumpAndSettle();

    _expectCartScreenOnItsOwn();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
