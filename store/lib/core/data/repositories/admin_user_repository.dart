import 'package:dio/dio.dart';
import '../../constants/app_constants.dart';
import '../../../services/local_storage_service.dart';
import '../models/admin_user_model.dart';

class AdminUserRepository {
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

  Future<List<AdminUserModel>> getUsers() async {
    final response = await _dio().get('/users');
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List)
          .map((item) => AdminUserModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> createAdmin({
    required String name,
    required String email,
    required String password,
  }) async {
    await _dio().post('/users/admins', data: {
      'name': name,
      'email': email,
      'password': password,
    });
  }

  Future<void> updateUserRole({
    required String userId,
    required String role,
  }) async {
    await _dio().put('/users/$userId/role', data: {
      'role': role,
    });
  }

  Future<void> deleteUser(String userId) async {
    await _dio().delete('/users/$userId');
  }
}
