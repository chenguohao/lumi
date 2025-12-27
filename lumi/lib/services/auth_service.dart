import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  final ApiService _api = ApiService();

  // 邮箱/ID 登录
  Future<UserModel> login(String emailOrId, String password) async {
    try {
      final response = await _api.post(
        '/login',
        data: {
          'emailOrId': emailOrId,
          'password': password,
        },
      );

      if (response.data['code'] == 0) {
        return UserModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? '登录失败');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 苹果登录
  Future<UserModel> loginWithApple({
    required String authorizationCode,
    required String userID,
    String? email,
    String? fullName,
    required String idToken,
  }) async {
    try {
      final response = await _api.post(
        '/appleSign',
        data: {
          'authorizationCode': authorizationCode,
          'userID': userID,
          'email': email,
          'fullName': fullName,
          'idToken': idToken,
        },
      );

      if (response.data['code'] == 0) {
        return UserModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? '登录失败');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 更新用户信息
  Future<UserModel> updateProfile({
    required int userID,
    String? name,
    String? avatar,
  }) async {
    try {
      final response = await _api.post(
        '/updateProfile',
        data: {
          'userID': userID,
          'name': name,
          'avatar': avatar,
        },
      );

      if (response.data['code'] == 0) {
        return UserModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? '更新失败');
      }
    } catch (e) {
      rethrow;
    }
  }
}

