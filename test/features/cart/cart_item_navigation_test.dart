import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/features/cart/domain/models/cart_item.dart';
import 'package:bakery_mobile/src/features/cart/presentation/controllers/cart_view_model.dart';
import 'package:bakery_mobile/src/features/cart/presentation/screens/cart_screen.dart';
import 'package:bakery_mobile/src/features/catalog/presentation/screens/product_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_api_client.dart';
import '../../helpers/pump_app.dart';

class _OneItemCart extends CartViewModel {
  @override
  CartState build() => const CartState(
    items: [
      CartItem(
        productId: 'prod-42',
        name: 'Bánh kem dâu',
        price: 250000,
        quantity: 1,
      ),
    ],
  );
}

void main() {
  late FakeApiClient api;

  setUp(() => api = FakeApiClient());

  Future<void> pumpCart(WidgetTester tester) => pumpApp(
    tester,
    const CartScreen(),
    api: api,
    extra: [cartViewModelProvider.overrideWith(_OneItemCart.new)],
  );

  testWidgets('tapping a cart item opens its product page', (tester) async {
    await pumpCart(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bánh kem dâu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final detail = tester.widget<ProductDetailScreen>(
      find.byType(ProductDetailScreen),
    );
    expect(detail.productIdOrSlug, 'prod-42');
  });

  testWidgets('the quantity buttons change the quantity, not the page', (
    tester,
  ) async {
    await pumpCart(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.byType(ProductDetailScreen), findsNothing);
    expect(find.text('2'), findsOneWidget);
  });
}
