import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/admin/orders/data/datasources/order_admin_api_service.dart';
import 'package:bakery_mobile/src/features/admin/orders/data/repositories/order_admin_repository.dart';
import 'package:bakery_mobile/src/features/admin/orders/presentation/controllers/order_detail_view_model.dart';
import 'package:bakery_mobile/src/features/admin/orders/presentation/screens/order_detail_screen.dart';
import 'package:bakery_mobile/src/features/auth/domain/models/user.dart';
import 'package:bakery_mobile/src/features/auth/presentation/controllers/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Detail payload (GET /api/admin/orders/{id} returns the order directly);
/// money as numeric strings like the server.
Map<String, dynamic> _orderJson(String status, {String? paymentStatus}) => {
  'id': 'ord-1',
  'orderNumber': 'PL-1042',
  'customerName': 'Trần Thị B',
  'customerPhone': '0901234567',
  'customerEmail': 'b@bakery.vn',
  'customerAddress': '12 Lê Lợi, Quảng Ngãi',
  'subtotal': '900000.00',
  'deliveryFee': '0.00',
  'discount': '50000.00',
  'total': '850000.00',
  'status': status,
  'paymentMethod': 'CASH',
  'createdAt': '2026-10-07T09:30:00.000Z',
  'updatedAt': '2026-10-07T09:45:00.000Z',
  'user': {'id': 'u-1', 'name': 'Trần Thị B', 'memberLevel': 'GOLD'},
  if (paymentStatus != null)
    'payment': {
      'provider': 'MOMO',
      'transactionId': 'momo-77',
      'amount': '850000.00',
      'status': paymentStatus,
      'createdAt': '2026-10-07T09:31:00.000Z',
    },
  'orderItems': [
    {
      'id': 'oi-1',
      'name': 'Bánh sinh nhật dâu',
      'message': 'Chúc mừng sinh nhật',
      'price': '450000.00',
      'quantity': 2,
      'subtotal': '900000.00',
    },
  ],
};

const Map<String, dynamic> _auditJson = {
  'logs': [
    {
      'id': 'log-1',
      'actorRole': 'ADMIN',
      'mutationType': 'STATUS_UPDATE',
      'metadata': {'transition': 'PENDING->CONFIRMED'},
      'createdAt': '2026-10-07T10:00:00.000Z',
      'actor': {'id': 'u-9', 'name': 'Hieu', 'role': 'ADMIN'},
    },
  ],
  'pagination': {'page': 1, 'limit': 20, 'total': 1, 'totalPages': 1},
};

/// Fake datasource: serves fixtures and records every PATCH body exactly as
/// the real service would build it (only non-null keys).
class _FakeOrderAdminApiService extends OrderAdminApiService {
  _FakeOrderAdminApiService()
    : super(
        ApiClient(
          baseUrl: 'http://localhost:1',
          tokenProvider: () async => null,
        ),
      );

  String status = 'PENDING';
  String? paymentStatus;
  Object? error;
  final List<String?> refundNotes = [];
  final List<Map<String, dynamic>> patchBodies = [];
  int auditCalls = 0;
  int investigationCalls = 0;

  void _maybeThrow() {
    final thrown = error;
    if (thrown != null) throw thrown;
  }

  @override
  Future<Map<String, dynamic>> getOrder(String idOrOrderNumber) async {
    _maybeThrow();
    return _orderJson(status, paymentStatus: paymentStatus);
  }

  @override
  Future<void> markRefunded(String orderId, {String? note}) async {
    _maybeThrow();
    refundNotes.add(note);
    paymentStatus = 'REFUNDED';
  }

  @override
  Future<Map<String, dynamic>> getOrderAudit(
    String orderId, {
    int page = 1,
    int limit = 20,
  }) async {
    auditCalls++;
    _maybeThrow();
    // Like the real route (bakery-web audit/route.ts): logs are matched by
    // the internal order id only — an order number yields an empty page.
    if (orderId != 'ord-1') {
      return const {
        'logs': [],
        'pagination': {'page': 1, 'limit': 20, 'total': 0, 'totalPages': 0},
      };
    }
    return _auditJson;
  }

  @override
  Future<Map<String, dynamic>> getInvestigation(String idOrOrderNumber) async {
    investigationCalls++;
    _maybeThrow();
    return {
      'order': {'orderNumber': 'PL-1042', 'status': status},
      'payment': null,
      'callbackTimeline': const [],
      'reconciliationAttempts': const [],
    };
  }

  @override
  Future<Map<String, dynamic>> updateOrder(
    String idOrOrderNumber, {
    String? status,
    String? notes,
  }) async {
    _maybeThrow();
    patchBodies.add({
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
    });
    if (status != null) this.status = status;
    return {'order': _orderJson(this.status)};
  }
}

class _FakeAuthViewModel extends AuthViewModel {
  int logoutCalls = 0;

  @override
  AuthState build() => const AuthState(
    user: User(
      id: 'a-1',
      email: 'admin@bakery.vn',
      name: 'Hieu',
      role: 'ADMIN',
    ),
  );

  @override
  Future<void> logout() async {
    logoutCalls++;
    state = state.copyWith(clearUser: true);
  }
}

void main() {
  late _FakeOrderAdminApiService service;
  late _FakeAuthViewModel auth;
  late ProviderContainer container;

  setUp(() {
    service = _FakeOrderAdminApiService();
    auth = _FakeAuthViewModel();
    container = ProviderContainer(
      overrides: [
        ordersAdminRepositoryProvider.overrideWithValue(
          OrderAdminRepository(service),
        ),
        authViewModelProvider.overrideWith(() => auth),
      ],
    );
    addTearDown(container.dispose);
  });

  OrderDetailViewModel vm() =>
      container.read(orderDetailViewModelProvider('PL-1042').notifier);
  OrderDetailState state() =>
      container.read(orderDetailViewModelProvider('PL-1042'));

  test('load() fetches order + audit; investigation stays lazy', () async {
    await vm().load();

    expect(state().order?.orderNumber, 'PL-1042');
    expect(state().order?.total, 850000);
    expect(state().audit?.single.actorName, 'Hieu');
    expect(state().investigation, isNull);
    expect(service.investigationCalls, 0);
    expect(state().isLoading, isFalse);

    await vm().loadInvestigation();
    expect(service.investigationCalls, 1);
    expect(state().investigation?.orderStatus, 'PENDING');
  });

  test(
    'updateStatus sends only status, then refreshes order + audit',
    () async {
      await vm().load();
      final ok = await vm().updateStatus('CONFIRMED');

      expect(ok, isTrue);
      expect(service.patchBodies, [
        {'status': 'CONFIRMED'},
      ]);
      expect(state().order?.status, 'CONFIRMED');
      expect(state().isUpdating, isFalse);
      expect(service.auditCalls, 2);
    },
  );

  test('cancel sends status + notes (reason)', () async {
    await vm().load();
    await vm().updateStatus('CANCELLED', notes: 'Khách huỷ');

    expect(service.patchBodies, [
      {'status': 'CANCELLED', 'notes': 'Khách huỷ'},
    ]);
    expect(state().order?.status, 'CANCELLED');
  });

  test('update failure keeps order and reports updateError', () async {
    await vm().load();
    service.error = ApiException(
      'Chuyển trạng thái không hợp lệ',
      statusCode: 400,
    );
    final ok = await vm().updateStatus('READY');

    expect(ok, isFalse);
    expect(state().order?.status, 'PENDING');
    expect(state().updateError, 'Chuyển trạng thái không hợp lệ');
    expect(state().isUpdating, isFalse);
  });

  test('401 on load logs out and sets no error', () async {
    service.error = ApiException('Unauthorized', statusCode: 401);
    await vm().load();

    expect(auth.logoutCalls, 1);
    expect(state().error, isNull);
    expect(state().isLoading, isFalse);
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const OrderDetailScreen(orderNumber: 'PL-1042'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('PENDING shows exactly Đã xác nhận + Đã huỷ chips', (
    tester,
  ) async {
    await pumpScreen(tester);

    final chips = find.byType(ActionChip);
    expect(chips, findsNWidgets(2));
    expect(
      find.descendant(of: chips, matching: find.text('Đã xác nhận')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: chips, matching: find.text('Đã huỷ')),
      findsOneWidget,
    );
  });

  testWidgets('COMPLETED shows no chip and the finished text', (tester) async {
    service.status = 'COMPLETED';
    await pumpScreen(tester);

    expect(find.byType(ActionChip), findsNothing);
    expect(find.text('Đơn đã hoàn tất'), findsOneWidget);
  });

  testWidgets('cancel requires a non-blank reason before confirming', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(
      find.descendant(
        of: find.byType(ActionChip),
        matching: find.text('Đã huỷ'),
      ),
    );
    await tester.pumpAndSettle();

    final confirm = find.widgetWithText(FilledButton, 'Xác nhận huỷ');
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Khách đổi ý');
    await tester.pump();
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(service.patchBodies, [
      {'status': 'CANCELLED', 'notes': 'Khách đổi ý'},
    ]);
  });

  group('refund of a cancelled, paid order', () {
    setUp(() {
      service
        ..status = 'CANCELLED'
        ..paymentStatus = 'PAID';
    });

    test('is flagged, recorded with the note, then cleared', () async {
      await vm().load();
      expect(state().order?.isAwaitingRefund, isTrue);

      final ok = await vm().markRefunded(note: 'Hoàn MoMo GD 991');

      expect(ok, isTrue);
      expect(service.refundNotes, ['Hoàn MoMo GD 991']);
      expect(state().order?.payment?.status, 'REFUNDED');
      expect(state().order?.isAwaitingRefund, isFalse);
      expect(service.auditCalls, 2);
    });

    test('a refused refund (409) keeps the flag and reports it', () async {
      await vm().load();
      service.error = ApiException(
        'Order is not awaiting a refund',
        statusCode: 409,
      );

      final ok = await vm().markRefunded();

      expect(ok, isFalse);
      expect(state().order?.isAwaitingRefund, isTrue);
      expect(state().updateError, 'Order is not awaiting a refund');
    });
  });

  test('a paid order that is not cancelled does not await a refund', () async {
    service.paymentStatus = 'PAID';
    await vm().load();
    expect(state().order?.isAwaitingRefund, isFalse);
  });
}
