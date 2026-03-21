import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/features/orders/domain/models/order.dart';

class OrdersState {
  const OrdersState({
    this.orders = const [],
    this.isLoadingOrders = false,
    this.isCreatingOrder = false,
    this.errorMessage,
  });

  final List<Order> orders;
  final bool isLoadingOrders;
  final bool isCreatingOrder;
  final String? errorMessage;

  bool get isLoading => isLoadingOrders || isCreatingOrder;

  OrdersState copyWith({
    List<Order>? orders,
    bool? isLoadingOrders,
    bool? isCreatingOrder,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoadingOrders: isLoadingOrders ?? this.isLoadingOrders,
      isCreatingOrder: isCreatingOrder ?? this.isCreatingOrder,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class OrdersViewModel extends Notifier<OrdersState> {
  @override
  OrdersState build() => const OrdersState();

  Future<void> loadMyOrders() async {
    state = state.copyWith(isLoadingOrders: true, clearError: true);
    try {
      final orders = await ref.read(orderRepositoryProvider).getMyOrders();
      state = state.copyWith(orders: orders, isLoadingOrders: false);
    } catch (error) {
      state = state.copyWith(
        isLoadingOrders: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<CreateOrderResult?> createOrder({
    required String customerName,
    required String customerPhone,
    String? customerEmail,
    String? customerAddress,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    state = state.copyWith(isCreatingOrder: true, clearError: true);
    try {
      final created = await ref
          .read(orderCheckoutServiceProvider)
          .createOrder(
            customerName: customerName,
            customerPhone: customerPhone,
            customerEmail: customerEmail,
            customerAddress: customerAddress,
            paymentMethod: paymentMethod,
            items: items,
          );
      state = state.copyWith(
        orders: [created.order, ...state.orders],
        isCreatingOrder: false,
      );
      return created;
    } catch (error) {
      state = state.copyWith(
        isCreatingOrder: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }
}
