import 'package:dio/dio.dart';

import '../../constants/app_constants.dart';
import '../../../services/local_storage_service.dart';
import '../models/category_model.dart';

class CategoryRepository {
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

  Future<List<CategoryModel>> getCategories() async {
    final response = await _dio().get('/categories');
    final data = response.data;

    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List)
          .map((item) => CategoryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  Future<void> createCategory({
    required String name,
    String? description,
  }) async {
    await _dio().post(
      '/categories',
      data: {
        'name': name,
        'description': description,
      },
    );
  }

  Future<void> updateCategory({
    required String categoryId,
    String? name,
    String? description,
    bool? isActive,
  }) async {
    final payload = <String, dynamic>{};

    if (name != null) {
      payload['name'] = name;
    }
    if (description != null) {
      payload['description'] = description;
    }
    if (isActive != null) {
      payload['isActive'] = isActive;
    }

    await _dio().put('/categories/$categoryId', data: payload);
  }

  Future<void> deleteCategory(String categoryId) async {
    await _dio().delete('/categories/$categoryId');
  }
}
