import 'dart:convert';

import 'package:bakery_mobile/src/features/admin/orders/domain/models/admin_order.dart';
import 'package:bakery_mobile/src/features/admin/orders/presentation/widgets/invoice_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'builds a PDF with Vietnamese text, no payment, free delivery',
    () async {
      final createdAt = DateTime.utc(2026, 10, 7, 9, 30);
      final order = AdminOrder(
        id: 'ord-1',
        orderNumber: 'PL-1042',
        customerName: 'Bánh sinh nhật Trần Thị B',
        customerPhone: '0901234567',
        customerAddress: '12 Lê Lợi, Quảng Ngãi',
        status: 'CANCELLED',
        subtotal: 900000,
        deliveryFee: 0,
        discount: 50000,
        total: 850000,
        createdAt: createdAt,
        updatedAt: createdAt,
        items: const [
          AdminOrderItem(
            id: 'oi-1',
            name: 'Bánh sinh nhật dâu — ghi chữ “Chúc mừng”',
            message: 'Tặng mẹ',
            price: 450000,
            quantity: 2,
            subtotal: 900000,
          ),
        ],
      );

      final bytes = await buildInvoicePdf(order);

      expect(bytes, isNotEmpty);
      expect(ascii.decode(bytes.sublist(0, 4)), '%PDF');
    },
  );
}
