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

  @override
  Future<CreateOrderResult> createOrder({
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    String? customerAddress,
    String? addressId,
    required String paymentMethod,
    List<String> incentiveCodes = const [],
    required List<Map<String, dynamic>> items,
  }) async {
    capturedPaymentMethod = paymentMethod;
    return CreateOrderResult(
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
    required List<String> incentiveCodes,
    required List<Map<String, dynamic>> items,
  }) async {
    return const PreviewIncentiveResult(
      subtotal: 50000,
      membershipDiscount: 0,
      couponDiscount: 0,
      totalDiscount: 0,
      total: 50000,
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

  testWidgets('checkout offers VNPAY and forwards it as payment method', (
    tester,
  ) async {
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

    expect(find.text('COD'), findsOneWidget);
    expect(find.text('BANK_TRANSFER'), findsOneWidget);
    expect(find.text('MOMO'), findsOneWidget);
    expect(find.text('ZALOPAY'), findsOneWidget);
    expect(find.text('VNPAY (QR/ATM/Visa)'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Customer name'),
      'Nguyen Van A',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Customer phone'),
      '0901234567',
    );
    await tester.pump();

    // Scroll to the chip first: its position depends on spacing above it.
    await tester.ensureVisible(find.text('VNPAY (QR/ATM/Visa)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('VNPAY (QR/ATM/Visa)'));
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Place order'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Place order'));
    await tester.pumpAndSettle();

    expect(repository.capturedPaymentMethod, 'VNPAY');
    expect(find.text('Order created successfully'), findsOneWidget);
  });
}
