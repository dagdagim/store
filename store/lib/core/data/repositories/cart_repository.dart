import '../../../services/api_service.dart';
import '../../../services/local_storage_service.dart';
import '../../constants/app_constants.dart';
import 'package:dio/dio.dart';
import '../models/cart_model.dart';

class CartRepository {
  final ApiService _api = ApiService.create();

  Dio _dio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.runtimeApiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    final token = LocalStorageService.getToken();
    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }

    return dio;
  }

  Future<CartModel> getCart() async {
    final response = await _api.getCart();
    return response.data.data;
  }

  Future<CartModel> addToCart({
    required String productId,
    required int quantity,
    required String size,
    required String color,
  }) async {
    final response = await _api.addToCart({
      'productId': productId,
      'quantity': quantity,
      'size': size,
      'color': color,
    });
    return response.data.data;
  }

  Future<CartModel> updateQuantity(String itemId, int quantity) async {
    final response = await _api.updateCartItem(itemId, {'quantity': quantity});
    return response.data.data;
  }

  Future<void> removeFromCart(String itemId) async {
    await _api.removeFromCart(itemId);
  }

  Future<void> clearCart() async {
    await _api.clearCart();
  }

  Future<CartPromotionPreview> previewPromotionCode(String code) async {
    final response = await _dio().post(
      '/cart/promotion/preview',
      data: {'code': code},
    );

    final body = response.data;
    if (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>) {
      return CartPromotionPreview.fromJson(body['data'] as Map<String, dynamic>);
    }

    throw Exception('Invalid preview response');
  }

  Future<CartModel> applyPromotionCode(String code) async {
    final response = await _dio().post('/cart/promotion', data: {'code': code});
    final body = response.data;

    if (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>) {
      return CartModel.fromJson(body['data'] as Map<String, dynamic>);
    }

    throw Exception('Invalid apply response');
  }

  Future<CartModel> removePromotionCode() async {
    final response = await _dio().delete('/cart/promotion');
    final body = response.data;

    if (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>) {
      return CartModel.fromJson(body['data'] as Map<String, dynamic>);
    }

    throw Exception('Invalid remove response');
  }
}
