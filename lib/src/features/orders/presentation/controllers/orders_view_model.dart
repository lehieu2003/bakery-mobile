import 'package:flutter/foundation.dart';

import 'package:bakery_mobile/src/features/orders/domain/models/order.dart';
import 'package:bakery_mobile/src/features/orders/data/repositories/order_repository.dart';

class OrdersViewModel extends ChangeNotifier {
  OrdersViewModel(this._orderRepository);

  final OrderRepository _orderRepository;

  List<Order> _orders = [];
  bool _isLoadingOrders = false;
  bool _isCreatingOrder = false;
  String? _errorMessage;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoadingOrders || _isCreatingOrder;
  bool get isLoadingOrders => _isLoadingOrders;
  bool get isCreatingOrder => _isCreatingOrder;
  String? get errorMessage => _errorMessage;

  Future<void> loadMyOrders() async {
    _isLoadingOrders = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _orders = await _orderRepository.getMyOrders();
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingOrders = false;
      notifyListeners();
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
    _isCreatingOrder = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final created = await _orderRepository.createOrder(
        customerName: customerName,
        customerPhone: customerPhone,
        customerEmail: customerEmail,
        customerAddress: customerAddress,
        paymentMethod: paymentMethod,
        items: items,
      );
      _orders = [created.order, ..._orders];
      return created;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isCreatingOrder = false;
      notifyListeners();
    }
  }
}


