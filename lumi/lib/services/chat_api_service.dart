import '../models/chat_model.dart';
import 'api_service.dart';

class ChatApiService {
  final ApiService _api = ApiService();

  // 获取聊天会话列表
  Future<List<ChatSessionModel>> getChatSessions({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _api.get(
        '/chat/sessions',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.data['code'] == 0) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => ChatSessionModel.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? '获取聊天会话列表失败');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 创建聊天会话
  Future<ChatSessionModel> createChatSession(int characterId) async {
    try {
      final response = await _api.post(
        '/chat/sessions',
        data: {
          'character_id': characterId,
        },
      );

      if (response.data['code'] == 0) {
        return ChatSessionModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? '创建聊天会话失败');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 获取聊天消息
  Future<List<ChatMessageModel>> getChatMessages(
    int sessionId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _api.get(
        '/chat/sessions/$sessionId/messages',
        queryParameters: {
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.data['code'] == 0) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => ChatMessageModel.fromJson(json)).toList();
      } else {
        throw Exception(response.data['message'] ?? '获取聊天消息失败');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 发送消息
  Future<ChatMessageModel> sendMessage(int sessionId, String content) async {
    try {
      final response = await _api.post(
        '/chat/sessions/$sessionId/messages',
        data: {
          'content': content,
        },
      );

      if (response.data['code'] == 0) {
        return ChatMessageModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message'] ?? '发送消息失败');
      }
    } catch (e) {
      rethrow;
    }
  }
}

