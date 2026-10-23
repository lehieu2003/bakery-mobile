import 'package:bakery_mobile/src/core/di/app_providers.dart';
import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_client.dart';
import 'package:bakery_mobile/src/core/theme/app_theme.dart';
import 'package:bakery_mobile/src/features/auth/domain/models/user.dart';
import 'package:bakery_mobile/src/features/auth/presentation/controllers/auth_view_model.dart';
import 'package:bakery_mobile/src/features/cart/domain/models/cart_item.dart';
import 'package:bakery_mobile/src/features/cart/presentation/controllers/cart_view_model.dart';
import 'package:bakery_mobile/src/features/cart/presentation/screens/checkout_screen.dart';
import 'package:bakery_mobile/src/features/orders/data/datasources/order_api_service.dart';
import 'package:bakery_mobile/src/features/orders/data/repositories/order_repository.dart';
import 'package:bakery_mobile/src/features/orders/domain/models/order.dart';
import 'package:bakery_mobile/src/shared/utils/format_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuthViewModel extends AuthViewModel {
  @override
  AuthState build() => const AuthState(
    user: User(id: 'user-1', email: 'test@bakery.vn', role: 'CUSTOMER'),
  );
}

class _FakeCartViewModel extends CartViewModel {
  @override
  CartState build() => const CartState(
    items: [
      CartItem(productId: 'p-1', name: 'Baguette', price: 50000, quantity: 1),
    ],
  );
}

class _CapturingOrderRepository extends OrderRepository {
  _CapturingOrderRepository()
    : super(
        OrderApiService(
          ApiClient(
            baseUrl: 'http://localhost:1',
            tokenProvider: () async => null,
          ),
        ),
      );

  String? capturedPaymentMethod;
  DeliveryMethod? capturedDeliveryMethod;
  String? capturedAddress;
  final previewDeliveryMethods = <DeliveryMethod>[];

  /// Set to simulate bakery-web cancelling the order on payment-init failure.
  String? paymentError;

  @override
  Future<CreateOrderResult> createOrder({
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    String? customerAddress,
    String? addressId,
    required String paymentMethod,
    required DeliveryMethod deliveryMethod,
    List<String> incentiveCodes = const [],
    required List<Map<String, dynamic>> items,
    required String idempotencyKey,
  }) async {
    capturedDeliveryMethod = deliveryMethod;
    capturedAddress = customerAddress;
    capturedPaymentMethod = paymentMethod;
    return CreateOrderResult(
      paymentError: paymentError,
      order: Order(
        id: 'order-1',
        orderNumber: 'ORD-1',
        status: 'PENDING',
        total: 50000,
        createdAt: DateTime(2026, 1, 1),
        orderItems: const [],
      ),
    );
  }

  @override
  Future<PreviewIncentiveResult> previewIncentives({
    required DeliveryMethod deliveryMethod,
    required List<String> incentiveCodes,
    required List<Map<String, dynamic>> items,
  }) async {
    previewDeliveryMethods.add(deliveryMethod);
    final fee = deliveryMethod == DeliveryMethod.delivery ? 30000.0 : 0.0;
    return PreviewIncentiveResult(
      subtotal: 50000,
      membershipDiscount: 0,
      couponDiscount: 0,
      totalDiscount: 0,
      total: 50000 + fee,
      deliveryFee: fee,
    );
  }

  @override
  Future<List<AvailableIncentive>> getAvailableIncentives({
    required double subtotal,
    required List<Map<String, dynamic>> cart,
  }) async {
    return const [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<_CapturingOrderRepository> pumpCheckout(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final repository = _CapturingOrderRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authViewModelProvider.overrideWith(_FakeAuthViewModel.new),
          cartViewModelProvider.overrideWith(_FakeCartViewModel.new),
          orderRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const CheckoutScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  Future<void> fillCustomer(WidgetTester tester) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Customer name'),
      'Nguyen Van A',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Customer phone'),
      '0901234567',
    );
    await tester.pump();
  }

  Future<void> placeOrder(WidgetTester tester) async {
    // A focused field keeps scrolling itself back into view, which would
    // unbuild the button again.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Place order'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Place order'));
    await tester.pumpAndSettle();
  }

  testWidgets('checkout offers VNPAY and forwards it as payment method', (
    tester,
  ) async {
    final repository = await pumpCheckout(tester);

    expect(find.text('COD'), findsOneWidget);
    expect(find.text('BANK_TRANSFER'), findsOneWidget);
    expect(find.text('MOMO'), findsOneWidget);
    expect(find.text('VNPAY (QR/ATM/Visa)'), findsOneWidget);
    // bakery-web rejects ZALOPAY with 400 "Invalid payment method".
    expect(find.text('ZALOPAY'), findsNothing);

    await fillCustomer(tester);

    // Scroll to the chip first: its position depends on spacing above it.
    await tester.ensureVisible(find.text('VNPAY (QR/ATM/Visa)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('VNPAY (QR/ATM/Visa)'));
    await tester.pump();

    await placeOrder(tester);

    expect(repository.capturedPaymentMethod, 'VNPAY');
    expect(find.text('Order created successfully'), findsOneWidget);
  });

  testWidgets('pick-up is the default: no address, no fee, sent explicitly', (
    tester,
  ) async {
    final repository = await pumpCheckout(tester);

    expect(
      find.widgetWithText(TextFormField, 'Địa chỉ giao hàng'),
      findsNothing,
    );
    expect(find.text('Phí giao hàng'), findsNothing);
    expect(repository.previewDeliveryMethods, [DeliveryMethod.pickup]);

    await fillCustomer(tester);
    await placeOrder(tester);

    expect(repository.capturedDeliveryMethod, DeliveryMethod.pickup);
    expect(repository.capturedAddress, isNull);
  });

  testWidgets('delivery re-prices with the fee and requires an address', (
    tester,
  ) async {
    final repository = await pumpCheckout(tester);

    await tester.tap(find.text('Giao tận nơi'));
    await tester.pumpAndSettle();

    expect(repository.previewDeliveryMethods.last, DeliveryMethod.delivery);
    await tester.scrollUntilVisible(
      find.text('Phí giao hàng'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Phí giao hàng'), findsOneWidget);
    expect(find.text(formatVnd(30000)), findsOneWidget);
    // The displayed total is the fee-inclusive preview total.
    expect(find.text(formatVnd(80000)), findsOneWidget);

    await fillCustomer(tester);
    await placeOrder(tester);

    // An empty address blocks the order instead of sending it.
    expect(repository.capturedDeliveryMethod, isNull);
    await tester.scrollUntilVisible(
      find.text('Vui lòng nhập địa chỉ giao hàng'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Địa chỉ giao hàng'),
      '12 Nguyễn Trãi, Quận 1',
    );
    await tester.pump();
    await placeOrder(tester);

    expect(repository.capturedDeliveryMethod, DeliveryMethod.delivery);
    expect(repository.capturedAddress, '12 Nguyễn Trãi, Quận 1');
  });

  testWidgets(
    'payment-init failure keeps the cart and is not shown as success',
    (tester) async {
      final repository = await pumpCheckout(tester);
      repository.paymentError = 'MoMo payment is not configured';

      await fillCustomer(tester);
      await tester.ensureVisible(find.text('MOMO'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('MOMO'));
      await tester.pump();
      await placeOrder(tester);

      expect(repository.capturedPaymentMethod, 'MOMO');
      expect(find.text('Order created successfully'), findsNothing);
      expect(find.text('Order created - payment required'), findsNothing);
      expect(
        find.textContaining('Không khởi tạo được thanh toán'),
        findsOneWidget,
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(CheckoutScreen)),
      );
      expect(container.read(cartViewModelProvider).items, hasLength(1));
    },
  );
}
