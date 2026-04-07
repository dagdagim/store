import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/order_repository.dart';

class OrderProvider extends ChangeNotifier {
  final OrderRepository _repository = OrderRepository();

  List<OrderModel> _orders = [];
  List<OrderModel> _adminOrders = [];
  OrderModel? _latestOrder;
  bool _isLoading = false;
  String? _error;
  final Set<String> _updatingOrderIds = {};

  List<OrderModel> get orders => _orders;
  List<OrderModel> get adminOrders => _adminOrders;
  OrderModel? get latestOrder => _latestOrder;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool isOrderUpdating(String orderId) => _updatingOrderIds.contains(orderId);

  Future<void> loadMyOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      _orders = await _repository.getMyOrders();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<OrderModel?> placeOrder({
    required Map<String, dynamic> shippingAddress,
    required String paymentMethod,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final order = await _repository.createOrder({
        'shippingAddress': shippingAddress,
        'paymentMethod': paymentMethod,
      });

      _latestOrder = order;
      _orders = [order, ..._orders];
      return order;
    } catch (e) {
      if (e is DioException) {
        final responseData = e.response?.data;
        if (responseData is Map<String, dynamic>) {
          _error = (responseData['message'] ?? 'Failed to place order').toString();
        } else {
          _error = e.message ?? 'Failed to place order';
        }
      } else {
        _error = e.toString();
      }
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllOrders({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _adminOrders = await _repository.getAllOrders(status: status);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changeOrderStatus({
    required String orderId,
    required String status,
  }) async {
    _updatingOrderIds.add(orderId);
    _error = null;
    notifyListeners();

    try {
      final updated = await _repository.updateOrderStatus(
        orderId: orderId,
        status: status,
      );

      _adminOrders = _adminOrders
          .map((order) {
            if (order.id != orderId) {
              return order;
            }

            return OrderModel(
              success: updated.success,
              id: updated.id,
              items: updated.items,
              totalPrice: updated.totalPrice,
              status: updated.status,
              createdAt: updated.createdAt,
              customerName: updated.customerName ?? order.customerName,
              customerEmail: updated.customerEmail ?? order.customerEmail,
            );
          })
          .toList();
      return true;
    } catch (e) {
      if (e is DioException) {
        final responseData = e.response?.data;
        if (responseData is Map<String, dynamic>) {
          _error = (responseData['message'] ?? 'Failed to update order status')
              .toString();
        } else {
          _error = e.message ?? 'Failed to update order status';
        }
      } else {
        _error = e.toString();
      }
      return false;
    } finally {
      _updatingOrderIds.remove(orderId);
      notifyListeners();
    }
  }
}
