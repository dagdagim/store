import '../../../services/api_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiService _api = ApiService.create();

  Future<LoginResponse> login(String email, String password) async {
    final response = await _api.login({
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<LoginResponse> register(String name, String email, String password) async {
    final response = await _api.register({
      'name': name,
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final response = await _api.updateProfile(data);
    return response.data;
  }
}
