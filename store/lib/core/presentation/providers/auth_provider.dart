import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../services/local_storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  
  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  String? _error;
  
  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _user != null;
  bool get isAdmin => _user?.role == 'admin';
  
  AuthProvider() {
    _loadStoredData();
  }
  
  Future<void> _loadStoredData() async {
    _token = LocalStorageService.getToken();
    final userData = LocalStorageService.getUser();
    if (userData != null) {
      _user = UserModel.fromJson(userData);
    }
    notifyListeners();
  }
  
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _authRepository.login(email, password);
      _token = response.token;
      _user = response.user;
      
      await LocalStorageService.saveToken(_token!);
      await LocalStorageService.saveUser(_user!.toJson());
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await _authRepository.register(name, email, password);
      _token = response.token;
      _user = response.user;
      
      await LocalStorageService.saveToken(_token!);
      await LocalStorageService.saveUser(_user!.toJson());
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  Future<void> logout() async {
    await LocalStorageService.clearAll();
    _token = null;
    _user = null;
    notifyListeners();
  }
  
  Future<void> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final updatedUser = await _authRepository.updateProfile(data);
      _user = updatedUser;
      await LocalStorageService.saveUser(_user!.toJson());
      _error = null;
    } catch (e) {
      _error = _extractErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _extractErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }
      return error.message ?? 'Request failed';
    }
    return error.toString();
  }
}