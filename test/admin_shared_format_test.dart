import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bakery_mobile/src/features/admin/shared/domain/order_status_display.dart';
import 'package:bakery_mobile/src/features/admin/shared/presentation/widgets/status_pill.dart';
import 'package:bakery_mobile/src/features/admin/shared/utils/admin_format.dart';

void main() {
  group('formatVnd', () {
    test('renders dot-grouped amount with ₫ suffix', () {
      // formatVnd(1250000) == '1.250.000 ₫'
      expect(formatVnd(1250000), '1.250.000 ₫');
    });

    test('renders zero without decimals', () {
      // formatVnd(0) == '0 ₫'
      expect(formatVnd(0), '0 ₫');
    });
  });

  group('vi-VN date formats', () {
    test('formatDateVi renders dd/MM/yyyy', () {
      // formatDateVi(DateTime(2026, 10, 7)) == '07/10/2026'
      expect(formatDateVi(DateTime(2026, 10, 7)), '07/10/2026');
    });

    test('formatDateTimeVi renders dd/MM/yyyy HH:mm', () {
      // formatDateTimeVi(DateTime(2026, 10, 7, 14, 30)) == '07/10/2026 14:30'
      expect(formatDateTimeVi(DateTime(2026, 10, 7, 14, 30)),
          '07/10/2026 14:30');
    });
  });

  group('orderStatusLabel', () {
    test('maps all six known status codes to Vietnamese labels', () {
      expect(orderStatusLabel('PENDING'), 'Chờ xác nhận');
      expect(orderStatusLabel('CONFIRMED'), 'Đã xác nhận');
      expect(orderStatusLabel('PROCESSING'), 'Đang chuẩn bị');
      expect(orderStatusLabel('READY'), 'Sẵn sàng nhận');
      expect(orderStatusLabel('COMPLETED'), 'Hoàn thành');
      expect(orderStatusLabel('CANCELLED'), 'Đã huỷ');
    });

    test('passes unknown status codes through unchanged', () {
      // orderStatusLabel('WEIRD') == 'WEIRD'
      expect(orderStatusLabel('WEIRD'), 'WEIRD');
    });
  });

  group('order status colors', () {
    test('PENDING background is pinned', () {
      // orderStatusColor('PENDING') == const Color(0xFFFFF7E6)
      expect(orderStatusColor('PENDING'), const Color(0xFFFFF7E6));
    });

    test('CANCELLED text color is pinned', () {
      // orderStatusTextColor('CANCELLED') == const Color(0xFFB91C1C)
      expect(orderStatusTextColor('CANCELLED'), const Color(0xFFB91C1C));
    });
  });

  testWidgets('StatusPill renders the localized status label', (tester) async {
    // pump MaterialApp(home: Scaffold(body: StatusPill(status: 'PENDING')))
    //   → find.text('Chờ xác nhận')
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StatusPill(status: 'PENDING')),
      ),
    );

    expect(find.text('Chờ xác nhận'), findsOneWidget);
  });
}
