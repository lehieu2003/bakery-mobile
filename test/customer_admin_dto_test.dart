import 'package:bakery_mobile/src/features/admin/customers/data/dtos/customer_admin_dto.dart';
import 'package:bakery_mobile/src/features/admin/customers/domain/models/admin_customer.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixtures mirror the admin customers payload shapes pinned from
/// `bakery-web/app/api/admin/customers` (Prisma serialization): money
/// fields may arrive as numeric strings or numbers, `name`/`phone` are
/// nullable, `level` is a duplicate alias of `memberLevel` (ignored), the
/// list envelope is `{ customers: [...], pagination: {...} }` and both the
/// detail and PATCH responses return the customer object directly.
const Map<String, dynamic> sampleCustomerRow = {
  'id': 'cus-1',
  'email': 'an@example.com',
  'name': null,
  'phone': null,
  'memberLevel': 'GOLD',
  'level': 'SILVER', // alias of memberLevel — must not win
  'points': 10,
  'isActive': true,
  'createdAt': '2026-01-15T08:30:00.000Z',
  'totalOrders': 12,
  'totalSpent': '1250000.00', // money as string
};

const Map<String, dynamic> sampleCustomerDetail = {
  'id': 'cus-1',
  'email': 'an@example.com',
  'name': 'Nguyễn Văn A',
  'phone': '0901234567',
  'memberLevel': 'GOLD',
  'level': 'GOLD',
  'points': 120,
  'isActive': true,
  'createdAt': '2026-01-15T08:30:00.000Z',
  'totalOrders': 12,
  'totalSpent': 2450000.5, // money as number
  'recentOrders': [
    {
      'id': 'ord-1',
      'orderNumber': 'PL-1042',
      'total': '875000.00',
      'status': 'COMPLETED',
      'paymentMethod': 'VNPAY',
      'createdAt': '2026-10-07T09:30:00.000Z',
      'payment': {
        'id': 'pay-1',
        'provider': 'VNPAY',
        'transactionId': 'TXN-889',
        'amount': '875000.00', // amount as string
        'status': 'PAID',
        'createdAt': '2026-10-07T09:31:00.000Z',
      },
    },
    {
      'id': 'ord-2',
      'orderNumber': 'PL-1043',
      'total': 120000, // total as number
      'status': 'PENDING',
      'paymentMethod': null, // unpaid orders carry no method
      'createdAt': '2026-10-20T10:00:00.000Z',
      'payment': null, // no payment recorded yet
    },
  ],
  'recentPayments': [
    {
      'paymentId': 'pay-1',
      'orderId': 'ord-1',
      'orderNumber': 'PL-1042',
      'provider': 'VNPAY',
      'transactionId': 'TXN-889',
      'amount': 875000, // amount as number
      'status': 'PAID',
      'createdAt': '2026-10-07T09:31:00.000Z',
    },
  ],
  'recentNotifications': [
    {
      'notificationId': 'noti-1',
      'title': 'Khuyến mãi cuối tuần',
      'status': 'PUBLISHED',
      'audience': 'GLOBAL',
      'publishedAt': '2026-10-01T07:00:00.000Z',
      'createdAt': '2026-10-01T06:00:00.000Z',
      'readAt': '2026-10-02T09:00:00.000Z',
    },
    {
      'notificationId': 'noti-2',
      'title': 'Nhắc giờ lấy bánh',
      'status': 'PUBLISHED',
      'audience': 'USER',
      'publishedAt': null, // scheduled notifications have none yet
      'createdAt': '2026-10-05T06:00:00.000Z',
      'readAt': null, // unread
    },
  ],
  'notificationSummary': {'totalRead': 3, 'unreadPublished': 1},
};

void main() {
  group('AdminCustomerDto', () {
    test(
      'parses the list envelope: money string, nullable name/phone, level alias ignored',
      () {
        final list = AdminCustomerListDto.fromJson({
          'customers': [sampleCustomerRow],
          'pagination': {'page': 1, 'limit': 50, 'total': 87, 'totalPages': 2},
        });

        expect(list.customers, hasLength(1));
        final customer = list.customers[0];
        expect(customer, isA<AdminCustomer>());
        expect(customer.id, 'cus-1');
        expect(customer.email, 'an@example.com');
        // Nullable identity fields may be null without breaking the parse.
        expect(customer.name, isNull);
        expect(customer.phone, isNull);
        // `memberLevel` wins over the duplicate `level` alias.
        expect(customer.memberLevel, 'GOLD');
        expect(customer.points, 10);
        expect(customer.points, isA<int>());
        expect(customer.isActive, isTrue);
        expect(customer.createdAt, DateTime.utc(2026, 1, 15, 8, 30));
        expect(customer.totalOrders, 12);
        expect(customer.totalOrders, isA<int>());
        // Money coerced from a numeric string.
        expect(customer.totalSpent, 1250000.0);
        expect(customer.totalSpent, isA<double>());

        expect(list.pagination.page, 1);
        expect(list.pagination.limit, 50);
        expect(list.pagination.total, 87);
        expect(list.pagination.totalPages, 2);
      },
    );

    test('parses a customer row with totalSpent as a number', () {
      final customer = AdminCustomerDto.fromJson({
        ...sampleCustomerRow,
        'totalSpent': 990000, // same field, numeric shape
      });

      expect(customer, isA<AdminCustomer>());
      expect(customer.totalSpent, 990000.0);
      expect(customer.totalSpent, isA<double>());
    });
  });

  group('AdminCustomerDetailDto', () {
    test(
      'parses the detail: recent orders, payments, notifications, summary',
      () {
        final detail = AdminCustomerDetailDto.fromJson(sampleCustomerDetail);

        expect(detail, isA<AdminCustomerDetail>());
        expect(detail, isA<AdminCustomer>());
        expect(detail.id, 'cus-1');
        expect(detail.memberLevel, 'GOLD');
        expect(detail.totalSpent, 2450000.5);

        // Recent orders: money strings coerce, payment may be absent.
        expect(detail.recentOrders, hasLength(2));
        expect(detail.recentOrders[0].orderNumber, 'PL-1042');
        expect(detail.recentOrders[0].total, 875000.0);
        expect(detail.recentOrders[0].total, isA<double>());
        expect(detail.recentOrders[0].status, 'COMPLETED');
        expect(detail.recentOrders[0].paymentMethod, 'VNPAY');
        expect(
          detail.recentOrders[0].createdAt,
          DateTime.utc(2026, 10, 7, 9, 30),
        );
        expect(detail.recentOrders[0].payment, isNotNull);
        expect(detail.recentOrders[0].payment!.id, 'pay-1');
        expect(detail.recentOrders[0].payment!.provider, 'VNPAY');
        expect(detail.recentOrders[0].payment!.transactionId, 'TXN-889');
        expect(detail.recentOrders[0].payment!.amount, 875000.0);
        expect(detail.recentOrders[0].payment!.amount, isA<double>());
        expect(detail.recentOrders[0].payment!.status, 'PAID');
        // Unpaid order: payment null and paymentMethod null are OK.
        expect(detail.recentOrders[1].payment, isNull);
        expect(detail.recentOrders[1].paymentMethod, isNull);
        expect(detail.recentOrders[1].total, 120000.0);

        // Recent payments flatten order + payment; amount arrives as a number.
        expect(detail.recentPayments, hasLength(1));
        expect(detail.recentPayments[0].paymentId, 'pay-1');
        expect(detail.recentPayments[0].orderId, 'ord-1');
        expect(detail.recentPayments[0].orderNumber, 'PL-1042');
        expect(detail.recentPayments[0].provider, 'VNPAY');
        expect(detail.recentPayments[0].transactionId, 'TXN-889');
        expect(detail.recentPayments[0].amount, 875000.0);
        expect(detail.recentPayments[0].amount, isA<double>());
        expect(detail.recentPayments[0].status, 'PAID');

        // Notifications: readAt/publishedAt may be null (unread/unscheduled).
        expect(detail.recentNotifications, hasLength(2));
        expect(detail.recentNotifications[0].notificationId, 'noti-1');
        expect(detail.recentNotifications[0].title, 'Khuyến mãi cuối tuần');
        expect(detail.recentNotifications[0].status, 'PUBLISHED');
        expect(detail.recentNotifications[0].audience, 'GLOBAL');
        expect(
          detail.recentNotifications[0].publishedAt,
          DateTime.utc(2026, 10, 1, 7),
        );
        expect(
          detail.recentNotifications[0].readAt,
          DateTime.utc(2026, 10, 2, 9),
        );
        expect(detail.recentNotifications[1].publishedAt, isNull);
        expect(detail.recentNotifications[1].readAt, isNull);

        expect(detail.notificationSummary.totalRead, 3);
        expect(detail.notificationSummary.unreadPublished, 1);
      },
    );

    test(
      'parses the PATCH response (customer detail directly) and validates member levels',
      () {
        // PATCH /api/admin/customers/{id} returns the updated customer detail
        // object directly (no envelope) — same parse as the detail response.
        final updated = AdminCustomerDetailDto.fromJson({
          ...sampleCustomerDetail,
          'memberLevel': 'PLATINUM',
          'points': 150,
        });

        expect(updated, isA<AdminCustomerDetail>());
        expect(updated.memberLevel, 'PLATINUM');
        expect(updated.points, 150);
        expect(updated.email, 'an@example.com');
        // Detail blocks survive the PATCH parse.
        expect(updated.recentOrders, hasLength(2));
        expect(updated.notificationSummary.totalRead, 3);

        // Only the three server-accepted levels validate.
        expect(AdminMemberLevel.valid('SILVER'), isTrue);
        expect(AdminMemberLevel.valid('GOLD'), isTrue);
        expect(AdminMemberLevel.valid('PLATINUM'), isTrue);
        expect(AdminMemberLevel.valid('DIAMOND'), isFalse);
        expect(AdminMemberLevel.valid('silver'), isFalse);
        expect(AdminMemberLevel.valid(null), isFalse);
      },
    );
  });
}
