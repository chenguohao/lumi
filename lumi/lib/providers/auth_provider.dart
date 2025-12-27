import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  final AuthService _authService = AuthService();

  AuthProvider() {
    _loadUserFromStorage();
  }

  Future<void> _loadUserFromStorage() async {
    // 从本地存储加载用户信息
    // TODO: 实现本地存储加载
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
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}

