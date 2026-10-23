import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/features/orders/domain/models/order.dart';

class OrdersState {
  const OrdersState({
    this.orders = const [],
    this.isLoadingOrders = false,
    this.isCreatingOrder = false,
    this.preparingReorderOrderId,
    this.errorMessage,
  });

  final List<Order> orders;
  final bool isLoadingOrders;
  final bool isCreatingOrder;
  final String? preparingReorderOrderId;
  final String? errorMessage;

  bool get isPreparingReorder => preparingReorderOrderId != null;
  bool get isLoading =>
      isLoadingOrders || isCreatingOrder || isPreparingReorder;

  OrdersState copyWith({
    List<Order>? orders,
    bool? isLoadingOrders,
    bool? isCreatingOrder,
    String? preparingReorderOrderId,
    bool clearPreparingReorder = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoadingOrders: isLoadingOrders ?? this.isLoadingOrders,
      isCreatingOrder: isCreatingOrder ?? this.isCreatingOrder,
      preparingReorderOrderId: clearPreparingReorder
          ? null
          : (preparingReorderOrderId ?? this.preparingReorderOrderId),
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
    String? addressId,
    required String paymentMethod,
    required DeliveryMethod deliveryMethod,
    List<String> incentiveCodes = const [],
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
            addressId: addressId,
            paymentMethod: paymentMethod,
            deliveryMethod: deliveryMethod,
            incentiveCodes: incentiveCodes,
            items: items,
          );
      final paymentError = created.paymentError;
      if (paymentError != null && paymentError.isNotEmpty) {
        // bakery-web has already cancelled this order (and released its
        // stock and coupons), so it is a failed checkout, not a success.
        state = state.copyWith(
          isCreatingOrder: false,
          errorMessage:
              'Không khởi tạo được thanh toán: $paymentError. '
              'Đơn ${created.order.orderNumber} đã bị huỷ, giỏ hàng vẫn được '
              'giữ — vui lòng thử lại hoặc chọn phương thức khác.',
        );
        return null;
      }
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

  Future<PrepareReorderResult?> prepareReorder(String orderId) async {
    state = state.copyWith(preparingReorderOrderId: orderId, clearError: true);
    try {
      final result = await ref
          .read(orderRepositoryProvider)
          .prepareReorder(orderId);
      state = state.copyWith(clearPreparingReorder: true);
      return result;
    } catch (error) {
      state = state.copyWith(
        clearPreparingReorder: true,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }
}
