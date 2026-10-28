import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/theme/app_durations.dart';
import 'package:bakery_mobile/src/features/catalog/domain/models/product.dart';
import 'package:bakery_mobile/src/features/navigation/presentation/screens/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_api_client.dart';
import '../../helpers/pump_app.dart';
import '../catalog/catalog_fixtures.dart';

double _badgeScale(WidgetTester tester) => tester
    .widget<ScaleTransition>(
      find.descendant(
        of: find.byType(Badge),
        matching: find.byType(ScaleTransition),
      ),
    )
    .scale
    .value;

void main() {
  testWidgets('the cart badge pops when an item is added', (tester) async {
    final api = FakeApiClient();
    stubHome(api);
    await pumpApp(tester, const MainLayout(), api: api);
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MainLayout)),
    );
    final cake = Product.fromJson(const {
      'id': 'prod-42',
      'name': 'Tiramisu',
      'slug': 'tiramisu',
      'price': 120000,
      'stock': 5,
    });

    container.read(cartViewModelProvider.notifier).addProduct(cake);
    await tester.pump();
    await tester.pump();
    final firstAddScale = _badgeScale(tester);
    expect(firstAddScale, 1, reason: 'the badge only appears on the first add');

    await tester.pumpAndSettle();
    container.read(cartViewModelProvider.notifier).addProduct(cake);
    await tester.pump();
    await tester.pump(AppDurations.medium * 0.4);

    expect(find.text('2'), findsOneWidget);
    expect(_badgeScale(tester), greaterThan(1.2));

    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
