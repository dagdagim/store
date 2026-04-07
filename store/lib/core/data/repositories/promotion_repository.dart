import 'package:dio/dio.dart';

import '../../constants/app_constants.dart';
import '../../../services/local_storage_service.dart';
import '../models/promotion_model.dart';

class PromotionRepository {
  Dio _dio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.runtimeApiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    final token = LocalStorageService.getToken();
    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }

    return dio;
  }

  Future<List<PromotionModel>> getPromotions() async {
    final response = await _dio().get('/promotions');
    final data = response.data;

    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List)
          .map((item) => PromotionModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  Future<void> createPromotion({
    required String title,
    required String code,
    String? description,
    required String discountType,
    required double discountValue,
    required double minOrderAmount,
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    await _dio().post(
      '/promotions',
      data: {
        'title': title,
        'code': code,
        'description': description,
        'discountType': discountType,
        'discountValue': discountValue,
        'minOrderAmount': minOrderAmount,
        'startsAt': startsAt.toUtc().toIso8601String(),
        'endsAt': endsAt.toUtc().toIso8601String(),
      },
    );
  }

  Future<void> updatePromotionStatus({
    required String promotionId,
    required bool isActive,
  }) async {
    await _dio().put('/promotions/$promotionId', data: {'isActive': isActive});
  }

  Future<void> deletePromotion(String promotionId) async {
    await _dio().delete('/promotions/$promotionId');
  }
}
