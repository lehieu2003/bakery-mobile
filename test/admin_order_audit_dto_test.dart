import 'package:bakery_mobile/src/features/admin/orders/data/dtos/order_audit_dto.dart';
import 'package:bakery_mobile/src/features/admin/orders/domain/models/order_audit.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixtures mirror the order audit / investigation payload shapes pinned
/// from `bakery-web/app/api/admin/orders/[id]` (audit + investigation
/// routes). Notable server quirks: the investigation `payment.amount` is a
/// plain number (the server `Number()`-converts it, unlike other money
/// fields), `actor` is `{id, name?, role} | null`, and `metadata` /
/// `beforeData` / `afterData` are arbitrary JSON.
const Map<String, dynamic> actorLog = {
  'id': 'log-1',
  'orderId': 'ord-1',
  'actorUserId': 'u-1',
  'actorRole': 'ADMIN',
  'mutationType': 'STATUS_UPDATE',
  'beforeData': {'status': 'PENDING'},
  'afterData': {'status': 'CONFIRMED'},
  'metadata': {'note': 'Đã xác nhận', 'transition': 'PENDING->CONFIRMED'},
  'createdAt': '2026-10-07T10:00:00.000Z',
  'actor': {'id': 'u-1', 'name': 'Nguyễn Văn A', 'role': 'ADMIN'},
};

const Map<String, dynamic> systemLog = {
  'id': 'log-2',
  'orderId': 'ord-1',
  'actorUserId': null,
  'actorRole': null,
  'mutationType': 'PAYMENT_CALLBACK',
  'beforeData': null,
  'afterData': null,
  'metadata': null,
  'createdAt': '2026-10-07T10:05:00.000Z',
  'actor': null,
};

const Map<String, dynamic> sampleInvestigationOrder = {
  'id': 'ord-1',
  'orderNumber': 'PL-1042',
  'status': 'PENDING',
  'customerName': 'Nguyễn Văn A',
  'customerPhone': '0901234567',
  'customerEmail': null,
  'createdAt': '2026-10-07T09:30:00.000Z',
  'updatedAt': '2026-10-07T09:45:00.000Z',
};

void main() {
  group('OrderAuditPageDto', () {
    test('parses the audit envelope: logs, actor, metadata, pagination', () {
      final page = OrderAuditPageDto.fromJson({
        'logs': [actorLog, systemLog],
        'pagination': {'page': 2, 'limit': 20, 'total': 45, 'totalPages': 3},
      });

      expect(page.logs, hasLength(2));
      expect(page.logs, everyElement(isA<OrderAuditLog>()));

      final acted = page.logs[0];
      expect(acted.id, 'log-1');
      expect(acted.actorName, 'Nguyễn Văn A');
      expect(acted.actorRole, 'ADMIN');
      expect(acted.mutationType, 'STATUS_UPDATE');
      expect(acted.metadata, {
        'note': 'Đã xác nhận',
        'transition': 'PENDING->CONFIRMED',
      });
      expect(acted.createdAt, DateTime.utc(2026, 10, 7, 10));

      // Actor null stays null in the DTO — the widget renders the
      // 'System' fallback.
      final automated = page.logs[1];
      expect(automated.id, 'log-2');
      expect(automated.actorName, isNull);
      expect(automated.actorRole, isNull);
      expect(automated.mutationType, 'PAYMENT_CALLBACK');
      expect(automated.metadata, isNull);

      expect(page.pagination.page, 2);
      expect(page.pagination.totalPages, 3);
    });

    test('parses an actor-less log whose role survives via actorRole', () {
      final page = OrderAuditPageDto.fromJson({
        'logs': [
          {
            'id': 'log-3',
            'mutationType': 'STATUS_UPDATE',
            'actorUserId': 'u-9',
            'actorRole': 'STAFF',
            'actor': {'id': 'u-9', 'name': null, 'role': 'STAFF'},
            'createdAt': '2026-10-07T11:00:00.000Z',
          },
        ],
        'pagination': {'page': 1, 'limit': 20, 'total': 1, 'totalPages': 1},
      });

      final log = page.logs.single;
      // Actor present but name null → actorName stays null (System fallback).
      expect(log.actorName, isNull);
      expect(log.actorRole, 'STAFF');
    });

    test('missing logs / pagination degrade to empty defaults', () {
      final page = OrderAuditPageDto.fromJson(const {});

      expect(page.logs, isEmpty);
      expect(page.pagination.totalPages, 0);
    });
  });

  group('OrderInvestigationDto', () {
    test('parses investigation with payment present (amount as number)', () {
      final inv = OrderInvestigationDto.fromJson({
        'order': sampleInvestigationOrder,
        'payment': {
          'provider': 'VNPAY',
          'status': 'PAID',
          'transactionId': 'TXN-889',
          // Server emits a plain number here, not a numeric string.
          'amount': 250000,
          'createdAt': '2026-10-07T09:31:00.000Z',
        },
        'callbackTimeline': [
          {
            'id': 'cb-1',
            'provider': 'VNPAY',
            'event': 'processed',
            'incomingStatus': 'success',
            'existingStatus': null,
            'transactionId': 'TXN-889',
            'existingTransactionId': null,
            'incomingTransactionId': 'TXN-889',
            'outcome': 'APPLIED',
            'reason': null,
            'createdAt': '2026-10-07T09:31:05.000Z',
          },
        ],
        'reconciliationAttempts': [
          {
            'callbackEventId': 'cb-1',
            'provider': 'VNPAY',
            'outcome': 'MATCHED',
            'incomingStatus': 'success',
            'createdAt': '2026-10-07T09:40:00.000Z',
          },
        ],
        'auditTrail': <Map<String, dynamic>>[],
      });

      expect(inv, isA<OrderInvestigation>());
      expect(inv.orderNumber, 'PL-1042');
      expect(inv.orderStatus, 'PENDING');

      expect(inv.payment, isNotNull);
      expect(inv.payment!.provider, 'VNPAY');
      expect(inv.payment!.status, 'PAID');
      expect(inv.payment!.transactionId, 'TXN-889');
      expect(inv.payment!.amount, 250000.0);
      expect(inv.payment!.amount, isA<double>());
      expect(inv.payment!.createdAt, DateTime.utc(2026, 10, 7, 9, 31));

      expect(inv.callbackEvents, hasLength(1));
      final event = inv.callbackEvents[0];
      expect(event.id, 'cb-1');
      expect(event.provider, 'VNPAY');
      expect(event.event, 'processed');
      expect(event.incomingStatus, 'success');
      expect(event.existingStatus, isNull);
      expect(event.outcome, 'APPLIED');
      expect(event.reason, isNull);
      expect(event.createdAt, DateTime.utc(2026, 10, 7, 9, 31, 5));

      expect(inv.attempts, hasLength(1));
      final attempt = inv.attempts[0];
      expect(attempt.callbackEventId, 'cb-1');
      expect(attempt.provider, 'VNPAY');
      expect(attempt.outcome, 'MATCHED');
      expect(attempt.incomingStatus, 'success');
      expect(attempt.createdAt, DateTime.utc(2026, 10, 7, 9, 40));
    });

    test('parses investigation with payment null and empty timelines', () {
      final inv = OrderInvestigationDto.fromJson({
        'order': sampleInvestigationOrder,
        'payment': null,
        'callbackTimeline': <Map<String, dynamic>>[],
        'reconciliationAttempts': <Map<String, dynamic>>[],
        'auditTrail': <Map<String, dynamic>>[],
      });

      expect(inv.orderNumber, 'PL-1042');
      expect(inv.orderStatus, 'PENDING');
      expect(inv.payment, isNull);
      expect(inv.callbackEvents, isEmpty);
      expect(inv.attempts, isEmpty);

      // Missing timelines degrade to empty lists as well.
      final bare = OrderInvestigationDto.fromJson({
        'order': sampleInvestigationOrder,
      });
      expect(bare.payment, isNull);
      expect(bare.callbackEvents, isEmpty);
      expect(bare.attempts, isEmpty);
    });
  });
}
