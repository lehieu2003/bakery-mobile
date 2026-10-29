import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/orders/presentation/widgets/order_status_stepper.dart';
import 'package:bakery_mobile/src/shared/utils/order_status_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, String status) => tester.pumpWidget(
  MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: OrderStatusStepper(status: status),
      ),
    ),
  ),
);

/// Number of ticked steps, read from the step keys.
int _ticked(WidgetTester tester) => orderProgressSteps
    .where(
      (step) => tester.any(
        find.descendant(
          of: find.byKey(OrderStatusStepper.stepKey(step.status)),
          matching: find.byIcon(Icons.check_rounded),
        ),
      ),
    )
    .length;

void main() {
  test('progress index follows the status, case-insensitively', () {
    expect(orderProgressIndex('PENDING'), 0);
    expect(orderProgressIndex(' ready '), 3);
    expect(orderProgressIndex('COMPLETED'), 4);
    expect(orderProgressIndex('CANCELLED'), -1);
    expect(orderProgressIndex('???'), -1);
  });

  testWidgets('ticks every step up to the current status', (tester) async {
    await _pump(tester, 'PROCESSING');

    expect(_ticked(tester), 3);
    for (final label in ['Đã đặt', 'Xác nhận', 'Chuẩn bị', 'Sẵn sàng']) {
      expect(find.text(label), findsOneWidget);
    }
    // Upcoming steps show their number.
    expect(find.text('4'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('a new order ticks only the first step', (tester) async {
    await _pump(tester, 'PENDING');
    expect(_ticked(tester), 1);
  });

  testWidgets('a completed order ticks every step', (tester) async {
    await _pump(tester, 'COMPLETED');
    expect(_ticked(tester), orderProgressSteps.length);
  });

  testWidgets('a cancelled order shows a notice, not the steps', (
    tester,
  ) async {
    await _pump(tester, 'CANCELLED');
    expect(find.text('Đơn hàng đã huỷ'), findsOneWidget);
    expect(_ticked(tester), 0);
    expect(find.text('Đã đặt'), findsNothing);
  });

  testWidgets('fits a narrow phone without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await _pump(tester, 'READY');
    expect(tester.takeException(), isNull);
  });
}
