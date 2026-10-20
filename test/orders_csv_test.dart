import 'package:bakery_mobile/src/features/admin/orders/domain/models/admin_order.dart';
import 'package:bakery_mobile/src/features/admin/orders/utils/orders_csv.dart';
import 'package:flutter_test/flutter_test.dart';

AdminOrder _order({
  String orderNumber = 'PL-1042',
  String customerName = 'Nguyễn Văn A',
  String? customerEmail = 'a@bakery.vn',
  String? customerAddress = '12 Lê Lợi',
  double subtotal = 900000,
  double deliveryFee = 30000,
  double discount = 12.5,
  double total = 917487.5,
  String? paymentMethod = 'VNPAY',
  AdminPayment? payment,
  String status = 'CONFIRMED',
}) {
  final createdAt = DateTime.utc(2026, 10, 7, 9, 30);
  return AdminOrder(
    id: 'o-1',
    orderNumber: orderNumber,
    customerName: customerName,
    customerPhone: '0901234567',
    customerEmail: customerEmail,
    customerAddress: customerAddress,
    status: status,
    subtotal: subtotal,
    deliveryFee: deliveryFee,
    discount: discount,
    total: total,
    paymentMethod: paymentMethod,
    createdAt: createdAt,
    updatedAt: createdAt,
    items: const [],
    payment: payment,
  );
}

/// Data lines of [csv] (BOM stripped, header dropped).
List<String> _rows(String csv) => csv.substring(1).split('\n').skip(1).toList();

void main() {
  test('starts with BOM and the 13 web columns in order', () {
    final csv = buildOrdersCsv([_order()]);

    expect(csv.startsWith('﻿'), isTrue);
    expect(
      csv.substring(1).split('\n').first,
      'Order Number,Customer Name,Phone,Email,Address,Subtotal,Delivery Fee,'
      'Discount,Total,Payment Method,Payment Status,Status,Created At',
    );
  });

  test('row values: compact money, payment status, ISO createdAt', () {
    final csv = buildOrdersCsv([
      _order(
        payment: AdminPayment(
          provider: 'VNPAY',
          amount: 917487.5,
          status: 'SUCCESS',
          createdAt: DateTime.utc(2026, 10, 7),
        ),
      ),
    ]);

    expect(_rows(csv), [
      'PL-1042,Nguyễn Văn A,0901234567,a@bakery.vn,12 Lê Lợi,900000,30000,'
          '12.5,917487.5,VNPAY,SUCCESS,CONFIRMED,2026-10-07T09:30:00.000Z',
    ]);
  });

  test('missing optionals become empty / N/A', () {
    final csv = buildOrdersCsv([
      _order(customerEmail: null, customerAddress: null, paymentMethod: null),
    ]);

    final cells = _rows(csv).single.split(',');
    expect(cells[3], '');
    expect(cells[4], '');
    expect(cells[9], '');
    expect(cells[10], 'N/A');
  });

  test('values with comma are quoted, quotes doubled, newlines quoted', () {
    final csv = buildOrdersCsv([
      _order(
        customerName: 'Trần Văn B, QN',
        customerAddress: 'Nhà "Hoa Hồng"\nTầng 2',
      ),
    ]);

    final row = csv.substring(1).split('\n').skip(1).join('\n');
    expect(row, contains(',"Trần Văn B, QN",'));
    expect(row, contains(',"Nhà ""Hoa Hồng""\nTầng 2",'));
  });

  test('file name pins today as orders_YYYY-MM-DD.csv', () {
    expect(
      ordersCsvFileName(now: DateTime(2026, 3, 5, 23, 59)),
      'orders_2026-03-05.csv',
    );
  });
}
