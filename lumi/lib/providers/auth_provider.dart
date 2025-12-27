import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  bool _isInitialized = false; // 标记是否已从本地加载完成

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized; // 用于路由守卫

  final AuthService _authService = AuthService();

  AuthProvider() {
    _loadUserFromStorage();
  }

  Future<void> _loadUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 加载用户信息
      final userJson = prefs.getString('user');
      if (userJson != null) {
        final userMap = json.decode(userJson) as Map<String, dynamic>;
        _user = UserModel.fromJson(userMap);
      }
      
      // 加载并设置 token
      final token = prefs.getString('token');
      if (token != null) {
        await ApiService().setToken(token);
      }
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error loading user from storage: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _saveUserToStorage(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = json.encode(user.toJson());
      await prefs.setString('user', userJson);
    } catch (e) {
      print('Error saving user to storage: $e');
    }
  }

  Future<void> _clearUserFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      await prefs.remove('token');
    } catch (e) {
      print('Error clearing user from storage: $e');
    }
  }

  Future<bool> login(String emailOrId, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.login(emailOrId, password);
      _user = user;
      if (user.token != null) {
        await ApiService().setToken(user.token);
      }
      // 保存用户信息到本地
      await _saveUserToStorage(user);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> loginWithApple({
    required String authorizationCode,
    required String userID,
    String? email,
    String? fullName,
    required String idToken,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authService.loginWithApple(
        authorizationCode: authorizationCode,
        userID: userID,
        email: email,
        fullName: fullName,
        idToken: idToken,
      );
      _user = user;
      if (user.token != null) {
        await ApiService().setToken(user.token);
      }
      // 保存用户信息到本地
      await _saveUserToStorage(user);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    await ApiService().setToken(null);
    await _clearUserFromStorage();
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? avatar,
  }) async {
    if (_user == null) return;

    try {
      final updatedUser = await _authService.updateProfile(
        userID: _user!.uid,
        name: name,
        avatar: avatar,
      );
      _user = updatedUser;
      // 更新本地存储
      await _saveUserToStorage(updatedUser);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}

