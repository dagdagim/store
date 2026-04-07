import '../../../services/api_service.dart';
import '../models/order_model.dart';

class OrderRepository {
  final ApiService _api = ApiService.create();

  Future<List<OrderModel>> getMyOrders() async {
    final response = await _api.getMyOrders();
    return response.data.data;
  }

  Future<OrderModel> createOrder(Map<String, dynamic> data) async {
    final response = await _api.createOrder(data);
    return response.data.data;
  }

  Future<OrderModel> getOrderById(String orderId) async {
    final response = await _api.getOrderById(orderId);
    return response.data.data;
  }

  Future<List<OrderModel>> getAllOrders({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final response = await _api.getAllOrders(
      page: page,
      limit: limit,
      status: status,
    );
    return response.data.data;
  }

  Future<OrderModel> updateOrderStatus({
    required String orderId,
    required String status,
    String? trackingNumber,
    String? trackingUrl,
  }) async {
    final response = await _api.updateOrderStatus(orderId, {
      'status': status,
      if (trackingNumber != null && trackingNumber.isNotEmpty)
        'trackingNumber': trackingNumber,
      if (trackingUrl != null && trackingUrl.isNotEmpty)
        'trackingUrl': trackingUrl,
    });
    return response.data.data;
  }
}
