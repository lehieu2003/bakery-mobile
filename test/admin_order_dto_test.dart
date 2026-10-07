import 'package:bakery_mobile/src/features/admin/orders/data/dtos/order_admin_dto.dart';
import 'package:bakery_mobile/src/features/admin/orders/domain/models/admin_order.dart';
import 'package:bakery_mobile/src/features/admin/orders/domain/models/order_status_transitions.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixture mirrors the admin orders payload shape pinned from
/// `bakery-web/app/api/admin/orders` (Prisma serialization): money fields
/// arrive as numeric strings ('900000.00'), the items relation is
/// `orderItems`, the primary product image lives at
/// `product.images[0].url`, and the list context `user` omits `email`.
const Map<String, dynamic> sampleListOrder = {
  'id': 'ord-1',
  'orderNumber': 'PL-1042',
  'userId': 'u-1',
  'customerName': 'Nguyễn Văn A',
  'customerPhone': '0901234567',
  'customerEmail': null,
  'customerAddress': null,
  'pickupDate': '2026-10-08T10:00:00.000Z',
  'subtotal': '900000.00',
  'deliveryFee': '25000.00',
  'discount': '50000.00',
  'total': '875000.00',
  'status': 'PENDING',
  'paymentMethod': 'CASH',
  'createdAt': '2026-10-07T09:30:00.000Z',
  'updatedAt': '2026-10-07T09:45:00.000Z',
  'user': {'id': 'u-1', 'phone': '0901234567', 'name': 'Nguyễn Văn A'},
  'orderItems': [
    {
      'id': 'oi-1',
      'productId': 'p-1',
      'name': 'Bánh sinh nhật dâu',
      'message': 'Chúc mừng sinh nhật',
      'price': '450000.00',
      'quantity': 2,
      'subtotal': '900000.00',
      'product': {
        'id': 'p-1',
        'name': 'Bánh sinh nhật dâu',
        'images': [
          {'url': '/uploads/cake-primary.jpg', 'isPrimary': true},
        ],
      },
    },
    {
      'id': 'oi-2',
      'productId': 'p-2',
      'name': 'Bánh mì trứng',
      'message': null,
      'price': '30000.00',
      'quantity': 1,
      'subtotal': '30000.00',
      'product': {'id': 'p-2', 'name': 'Bánh mì trứng', 'images': []},
    },
  ],
  'payment': {
    'id': 'pay-1',
    'provider': 'VNPAY',
    'transactionId': 'TXN-889',
    'amount': '875000.00',
    'status': 'PAID',
    'createdAt': '2026-10-07T09:31:00.000Z',
  },
};

void main() {
  group('AdminOrderDto', () {
    test('parses an order row: money strings, imageUrl, nullable fields', () {
      final order = AdminOrderDto.fromJson(sampleListOrder);

      expect(order, isA<AdminOrder>());
      expect(order.id, 'ord-1');
      expect(order.orderNumber, 'PL-1042');
      expect(order.userId, 'u-1');
      expect(order.customerName, 'Nguyễn Văn A');
      expect(order.customerPhone, '0901234567');
      expect(order.status, 'PENDING');
      expect(order.paymentMethod, 'CASH');
      expect(order.createdAt, DateTime.utc(2026, 10, 7, 9, 30));
      expect(order.updatedAt, DateTime.utc(2026, 10, 7, 9, 45));
      expect(order.pickupDate, DateTime.utc(2026, 10, 8, 10));

      // Money coerced from strings.
      expect(order.subtotal, 900000.0);
      expect(order.subtotal, isA<double>());
      expect(order.deliveryFee, 25000.0);
      expect(order.discount, 50000.0);
      expect(order.total, 875000.0);

      // Nullable fields may be null without breaking the parse.
      expect(order.customerEmail, isNull);
      expect(order.customerAddress, isNull);

      expect(order.items, hasLength(2));
      expect(order.items[0].price, 450000.0);
      expect(order.items[0].quantity, 2);
      expect(order.items[0].subtotal, 900000.0);
      expect(order.items[0].message, 'Chúc mừng sinh nhật');
      // imageUrl comes from product.images[0].url...
      expect(order.items[0].imageUrl, '/uploads/cake-primary.jpg');
      // ...and is null when product.images is empty.
      expect(order.items[1].imageUrl, isNull);
      expect(order.items[1].message, isNull);

      expect(order.payment, isNotNull);
      expect(order.payment!.amount, 875000.0);
      expect(order.payment!.amount, isA<double>());
      expect(order.payment!.provider, 'VNPAY');
      expect(order.payment!.transactionId, 'TXN-889');
      expect(order.payment!.status, 'PAID');

      // List context user has no email field.
      expect(order.user, isNotNull);
      expect(order.user!.id, 'u-1');
      expect(order.user!.name, 'Nguyễn Văn A');
      expect(order.user!.phone, '0901234567');
      expect(order.user!.email, isNull);
      expect(order.user!.memberLevel, isNull);

      // payment/user absent entirely parse to null; detail-only user fields
      // survive when present.
      final bare = AdminOrderDto.fromJson(const {
        'id': 'ord-2',
        'orderNumber': 'PL-1043',
        'customerName': 'Trần Thị B',
        'customerPhone': '0909998887',
        'subtotal': '120000.00',
        'total': '120000.00',
        'status': 'COMPLETED',
        'createdAt': '2026-10-06T08:00:00.000Z',
        'updatedAt': '2026-10-06T08:00:00.000Z',
        'payment': null,
        'user': {
          'id': 'u-2',
          'name': 'Trần Thị B',
          'email': 'b@example.com',
          'phone': '0909998887',
          'memberLevel': 'GOLD',
        },
        'orderItems': <Map<String, dynamic>>[],
      });
      expect(bare.payment, isNull);
      expect(bare.items, isEmpty);
      expect(bare.user!.email, 'b@example.com');
      expect(bare.user!.memberLevel, 'GOLD');
    });

    test('parses the list envelope: orders + pagination', () {
      final list = AdminOrderListDto.fromJson({
        'orders': [sampleListOrder],
        'pagination': {'page': 1, 'limit': 20, 'total': 35, 'totalPages': 2},
      });

      expect(list.orders, hasLength(1));
      expect(list.orders[0].orderNumber, 'PL-1042');
      expect(list.pagination.page, 1);
      expect(list.pagination.limit, 20);
      expect(list.pagination.total, 35);
      expect(list.pagination.totalPages, 2);
    });

    test('parses the PATCH envelope {order} with the new status', () {
      final result = AdminOrderPatchResultDto.fromJson({
        'order': <String, dynamic>{...sampleListOrder, 'status': 'CONFIRMED'},
      });

      expect(result.order, isA<AdminOrder>());
      expect(result.order.status, 'CONFIRMED');
      expect(result.order.orderNumber, 'PL-1042');
      expect(result.order.total, 875000.0);
    });
  });

  group('nextStatuses', () {
    test('mirrors the server ORDER_STATUS_TRANSITIONS map', () {
      expect(nextStatuses('PENDING'), ['CONFIRMED', 'CANCELLED']);
      expect(nextStatuses('CONFIRMED'), ['PROCESSING', 'CANCELLED']);
      expect(nextStatuses('PROCESSING'), ['READY']);
      expect(nextStatuses('READY'), ['COMPLETED']);
      // Terminal statuses have no entry.
      expect(nextStatuses('COMPLETED'), isEmpty);
      expect(nextStatuses('CANCELLED'), isEmpty);
      // Unknown status codes yield no transitions.
      expect(nextStatuses('WHATEVER'), isEmpty);
    });
  });
}
