import '../models/video_model.dart';
import 'api_service.dart';

class VideoApiService {
  final ApiService _api = ApiService();

  // 获取视频列表
  Future<List<VideoModel>> getVideoList({
    int limit = 20,
    int offset = 0,
    int? characterId,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (characterId != null) {
        queryParams['character_id'] = characterId;
      }

      final response = await _api.get('/videos', queryParameters: queryParams);

      if (response.data['code'] == 0) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => VideoModel.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? '获取视频列表失败');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 获取视频详情
  Future<VideoModel> getVideoDetail(int videoId) async {
    try {
      final response = await _api.get('/videos/$videoId');

      if (response.data['code'] == 0) {
        return VideoModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? '获取视频详情失败');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 点赞视频
  Future<void> likeVideo(int videoId) async {
    try {
      final response = await _api.post('/videos/$videoId/like');

      if (response.data['code'] != 0) {
        throw Exception(response.data['message'] ?? '点赞失败');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 取消点赞
  Future<void> unlikeVideo(int videoId) async {
    try {
      final response = await _api.delete('/videos/$videoId/like');

      if (response.data['code'] != 0) {
        throw Exception(response.data['message'] ?? '取消点赞失败');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 收藏视频
  Future<void> favoriteVideo(int videoId) async {
    try {
      final response = await _api.post('/videos/$videoId/favorite');

      if (response.data['code'] != 0) {
        throw Exception(response.data['message'] ?? '收藏失败');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 取消收藏
  Future<void> unfavoriteVideo(int videoId) async {
    try {
      final response = await _api.delete('/videos/$videoId/favorite');

      if (response.data['code'] != 0) {
        throw Exception(response.data['message'] ?? '取消收藏失败');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 创建视频（AI生成）
  Future<VideoModel> createVideo({
    required int characterId,
    required String title,
    String? description,
  }) async {
    try {
      final response = await _api.post(
        '/videos',
        data: {
          'character_id': characterId,
          'title': title,
          'description': description,
        },
      );

      if (response.data['code'] == 0) {
        return VideoModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? '创建视频失败');
      }
    } catch (e) {
      rethrow;
    }
  }
}

