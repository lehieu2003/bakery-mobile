import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bakery_mobile/src/core/di/data_providers.dart';
import 'package:bakery_mobile/src/core/network/api_exception.dart';
import 'package:bakery_mobile/src/core/utils/idempotency_key.dart';
import 'package:bakery_mobile/src/features/orders/domain/models/order.dart';
import 'package:bakery_mobile/src/shared/utils/error_message.dart';

class OrdersState {
  const OrdersState({
    this.orders = const [],
    this.isLoadingOrders = false,
    this.hasMoreOrders = false,
    this.isLoadingMoreOrders = false,
    this.isCreatingOrder = false,
    this.preparingReorderOrderId,
    this.errorMessage,
  });

  final List<Order> orders;
  final bool isLoadingOrders;

  /// Older orders remain on the server; see [OrdersViewModel.loadMoreOrders].
  final bool hasMoreOrders;
  final bool isLoadingMoreOrders;
  final bool isCreatingOrder;
  final String? preparingReorderOrderId;
  final String? errorMessage;

  bool get isPreparingReorder => preparingReorderOrderId != null;
  bool get isLoading =>
      isLoadingOrders || isCreatingOrder || isPreparingReorder;

  OrdersState copyWith({
    List<Order>? orders,
    bool? isLoadingOrders,
    bool? hasMoreOrders,
    bool? isLoadingMoreOrders,
    bool? isCreatingOrder,
    String? preparingReorderOrderId,
    bool clearPreparingReorder = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OrdersState(
      orders: orders ?? this.orders,
      isLoadingOrders: isLoadingOrders ?? this.isLoadingOrders,
      hasMoreOrders: hasMoreOrders ?? this.hasMoreOrders,
      isLoadingMoreOrders: isLoadingMoreOrders ?? this.isLoadingMoreOrders,
      isCreatingOrder: isCreatingOrder ?? this.isCreatingOrder,
      preparingReorderOrderId: clearPreparingReorder
          ? null
          : (preparingReorderOrderId ?? this.preparingReorderOrderId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class OrdersViewModel extends Notifier<OrdersState> {
  /// Key of the checkout attempt in flight. Kept when a request fails in
  /// transit — the server may have created the order anyway, and resending
  /// the same key returns that order instead of a duplicate. Dropped once
  /// the server has answered, so the next checkout is a new order.
  String? _checkoutKey;

  /// Last page of the order history loaded so far.
  int _ordersPage = 0;

  @override
  OrdersState build() => const OrdersState();

  Future<void> loadMyOrders() async {
    state = state.copyWith(isLoadingOrders: true, clearError: true);
    try {
      final page = await ref.read(orderRepositoryProvider).getMyOrders();
      _ordersPage = 1;
      state = state.copyWith(
        orders: page.orders,
        hasMoreOrders: page.hasMore,
        isLoadingOrders: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingOrders: false,
        errorMessage: userErrorMessage(error),
      );
    }
  }

  /// Appends the next (older) page of the history.
  Future<void> loadMoreOrders() async {
    if (!state.hasMoreOrders || state.isLoadingMoreOrders) return;
    state = state.copyWith(isLoadingMoreOrders: true, clearError: true);
    try {
      final page = await ref
          .read(orderRepositoryProvider)
          .getMyOrders(page: _ordersPage + 1);
      _ordersPage += 1;
      // Orders placed since page 1 shift the pages; skip ones already shown.
      final shown = {for (final order in state.orders) order.id};
      state = state.copyWith(
        orders: [
          ...state.orders,
          ...page.orders.where((order) => !shown.contains(order.id)),
        ],
        hasMoreOrders: page.hasMore,
        isLoadingMoreOrders: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMoreOrders: false,
        errorMessage: userErrorMessage(error),
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
    final checkoutKey = _checkoutKey ??= newIdempotencyKey();
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
            idempotencyKey: checkoutKey,
          );
      _checkoutKey = null;
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
      // Only a 4xx proves no order was created. Without an answer, or with
      // a 5xx (e.g. a 504 after the handler ran), it may exist: keep the key
      // so the retry returns it instead of a duplicate.
      final mayHaveLanded =
          error is ApiException &&
          (error.isConnectivityIssue || error.kind == ApiErrorKind.server);
      if (!mayHaveLanded) _checkoutKey = null;
      state = state.copyWith(
        isCreatingOrder: false,
        errorMessage: userErrorMessage(error),
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
        errorMessage: userErrorMessage(error),
      );
      return null;
    }
  }
}
