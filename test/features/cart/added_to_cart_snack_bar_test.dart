import 'package:bakery_mobile/src/features/cart/presentation/screens/cart_screen.dart';
import 'package:bakery_mobile/src/features/cart/presentation/widgets/added_to_cart_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_api_client.dart';
import '../../helpers/pump_app.dart';

class _AddButton extends StatelessWidget {
  const _AddButton(this.name);

  final String name;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: TextButton(
        onPressed: () => showAddedToCartSnackBar(context, name),
        child: const Text('Thêm'),
      ),
    ),
  );
}

void main() {
  late FakeApiClient api;

  setUp(() => api = FakeApiClient());

  testWidgets('names the product and offers to open the cart', (tester) async {
    await pumpApp(tester, const _AddButton('Tiramisu'), api: api);

    await tester.tap(find.text('Thêm'));
    await tester.pumpAndSettle();

    expect(find.text('Đã thêm Tiramisu vào giỏ'), findsOneWidget);

    await tester.tap(find.text('Xem giỏ'));
    await tester.pumpAndSettle();

    expect(find.byType(CartScreen), findsOneWidget);
  });

  testWidgets('repeated adds replace the snack bar instead of queueing', (
    tester,
  ) async {
    await pumpApp(tester, const _AddButton('Tiramisu'), api: api);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Thêm'));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);

    // Once it times out, no queued copy takes its place.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.byType(SnackBar), findsNothing);
  });
}
