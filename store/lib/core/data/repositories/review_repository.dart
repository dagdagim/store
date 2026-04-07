import 'package:dio/dio.dart';

import '../../constants/app_constants.dart';
import '../../../services/local_storage_service.dart';
import '../models/review_model.dart';

class ReviewRepository {
  Dio _dio({bool withAuth = false}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.runtimeApiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    if (withAuth) {
      final token = LocalStorageService.getToken();
      if (token != null) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return dio;
  }

  Future<List<ReviewModel>> getProductReviews(String productId) async {
    final response = await _dio().get('/reviews/product/$productId');
    final data = response.data;

    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List)
          .map((item) => ReviewModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  Future<List<ReviewModel>> getAllReviews() async {
    final response = await _dio(withAuth: true).get('/reviews');
    final data = response.data;

    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List)
          .map((item) => ReviewModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  Future<void> createReview({
    required String productId,
    required int rating,
    required String title,
    required String comment,
  }) async {
    await _dio(withAuth: true).post(
      '/reviews/product/$productId',
      data: {
        'rating': rating,
        'title': title,
        'comment': comment,
      },
    );
  }

  Future<void> deleteReview(String reviewId) async {
    await _dio(withAuth: true).delete('/reviews/$reviewId');
  }
}
