import 'package:bakery_mobile/src/features/orders/data/dtos/order_dto.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixture mirrors the web detail response shape produced by `serializeOrder`
/// (GET /api/orders/[orderNumber] → `{ success, data: { order: ... } }`).
/// `ApiClient.get` unwraps `data`, so the service feeds `data['order']`
/// straight into `OrderDto.fromJson`.
Map<String, dynamic> get _fullDetailOrder => {
  'id': 'order-1',
  'orderNumber': 'ORD-20261007-0001',
  'status': 'PENDING',
  'paymentMethod': 'COD',
  'pickupDate': '2026-10-08T09:00:00.000Z',
  'customerName': 'Nguyễn Văn A',
  'customerAddress': '123 Trần Phú, Quảng Ngãi',
  'subtotal': 180000,
  'deliveryFee': 15000,
  'discount': 20000,
  'total': 175000,
  'createdAt': '2026-10-07T03:00:00.000Z',
  'orderItems': [
    {
      'id': 'item-1',
      'name': 'Bánh mì baguette',
      'price': 25000,
      'quantity': 4,
      'subtotal': 100000,
      'product': {
        'id': 'p-1',
        'name': 'Baguette',
        'price': 25000,
        'images': [
          {'id': 'img-1', 'url': '/uploads/baguette.jpg', 'isPrimary': true},
        ],
      },
    },
    {
      'id': 'item-2',
      'name': 'Croissant bơ',
      'price': 40000,
      'quantity': 2,
      'subtotal': 80000,
      'product': null,
      'someFutureField': 'must-not-crash',
    },
  ],
  'payment': {'id': 'pay-1', 'status': 'PENDING', 'amount': 175000},
  'someFutureOrderField': 42,
};

Map<String, dynamic> get _nullPaymentDetailOrder => {
  'id': 'order-2',
  'orderNumber': 'ORD-20261007-0002',
  'status': 'COMPLETED',
  'total': 50000,
  'createdAt': '2026-10-06T03:00:00.000Z',
  'orderItems': [
    // No product and no images at all — only name/price/quantity/subtotal.
    {'name': 'Bánh su kem', 'price': 50000, 'quantity': 1, 'subtotal': 50000},
  ],
  'payment': null,
  'pickupDate': null,
  'deliveryFee': null,
  'discount': null,
  'customerName': null,
  'customerAddress': null,
};

void main() {
  group('OrderDto.fromJson (order detail payload)', () {
    test('parses full web detail payload', () {
      final dto = OrderDto.fromJson(_fullDetailOrder);
      final order = dto.toDomain();

      expect(order.id, 'order-1');
      expect(order.orderNumber, 'ORD-20261007-0001');
      expect(order.status, 'PENDING');
      expect(order.paymentMethod, 'COD');
      expect(order.subtotal, 180000);
      expect(order.deliveryFee, 15000);
      expect(order.discount, 20000);
      expect(order.total, 175000);
      expect(order.paymentStatus, 'PENDING');
      expect(order.pickupDate, DateTime.utc(2026, 10, 8, 9));
      expect(order.customerName, 'Nguyễn Văn A');
      expect(order.customerAddress, '123 Trần Phú, Quảng Ngãi');
      expect(order.createdAt, DateTime.utc(2026, 10, 7, 3));

      expect(order.orderItems, hasLength(2));
      expect(order.orderItems[0].name, 'Bánh mì baguette');
      expect(order.orderItems[0].price, 25000);
      expect(order.orderItems[0].quantity, 4);
      expect(order.orderItems[0].subtotal, 100000);
      expect(order.orderItems[0].imageUrl, '/uploads/baguette.jpg');
      expect(order.orderItems[1].name, 'Croissant bơ');
      expect(order.orderItems[1].imageUrl, isEmpty);
    });

    test('primary image wins over non-primary images', () {
      final json = _fullDetailOrder;
      (json['orderItems'] as List<dynamic>).first['product']['images'] = [
        {'url': '/uploads/secondary.jpg', 'isPrimary': false},
        {'url': '/uploads/primary.jpg', 'isPrimary': true},
      ];

      final dto = OrderDto.fromJson(json);
      expect(dto.orderItems.first.imageUrl, '/uploads/primary.jpg');
    });

    test(
      'survives null payment / missing product / missing optional fields',
      () {
        final dto = OrderDto.fromJson(_nullPaymentDetailOrder);
        final order = dto.toDomain();

        expect(order.orderNumber, 'ORD-20261007-0002');
        expect(order.paymentStatus, isNull);
        expect(order.paymentMethod, isEmpty);
        expect(order.pickupDate, isNull);
        expect(order.deliveryFee, 0);
        expect(order.discount, 0);
        expect(order.customerName, isNull);
        expect(order.customerAddress, isNull);
        expect(order.total, 50000);

        expect(order.orderItems, hasLength(1));
        expect(order.orderItems.first.imageUrl, isEmpty);
        expect(order.orderItems.first.subtotal, 50000);
      },
    );
  });
}
