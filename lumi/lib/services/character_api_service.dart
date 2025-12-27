import '../models/character_model.dart';
import 'api_service.dart';

class CharacterApiService {
  final ApiService _api = ApiService();

  // 获取角色列表
  Future<List<CharacterModel>> getCharacterList({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _api.get(
        '/characters',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.data['code'] == 0) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => CharacterModel.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? '获取角色列表失败');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 获取角色详情
  Future<CharacterModel> getCharacterDetail(int characterId) async {
    try {
      final response = await _api.get('/characters/$characterId');

      if (response.data['code'] == 0) {
        return CharacterModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? '获取角色详情失败');
      }
    } catch (e) {
      rethrow;
    }
  }
}

