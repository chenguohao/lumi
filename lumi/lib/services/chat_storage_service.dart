import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_model.dart';
import '../models/character_model.dart';

/// 本地聊天存储服务
/// 用于存储聊天记录和会话信息
class ChatStorageService {
  static final ChatStorageService _instance = ChatStorageService._internal();
  factory ChatStorageService() => _instance;
  ChatStorageService._internal();

  static const String _sessionsKey = 'chat_sessions';
  static const String _messagesPrefix = 'chat_messages_';

  /// 获取所有聊天会话
  Future<List<ChatSessionModel>> getSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getString(_sessionsKey);
      if (sessionsJson == null || sessionsJson.isEmpty) {
        return [];
      }
      final List<dynamic> sessionsList = json.decode(sessionsJson);
      return sessionsList.map((json) => ChatSessionModel.fromJson(json)).toList();
    } catch (e) {
      print('[ChatStorage] Error loading sessions: $e');
      return [];
    }
  }

  /// 保存聊天会话列表
  Future<void> saveSessions(List<ChatSessionModel> sessions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = json.encode(sessions.map((s) => s.toJson()).toList());
      await prefs.setString(_sessionsKey, sessionsJson);
    } catch (e) {
      print('[ChatStorage] Error saving sessions: $e');
    }
  }

  /// 获取或创建会话（基于角色ID）
  Future<ChatSessionModel> getOrCreateSession(CharacterModel character) async {
    final sessions = await getSessions();
    
    // 查找是否已存在该角色的会话
      final existingSession = sessions.firstWhere(
      (s) => s.characterId == character.id,
      orElse: () => ChatSessionModel(
        id: 0,
        characterId: character.id,
        characterName: character.name,
        characterAvatar: character.avatar,
        bondLevel: character.bondLevel,
      ),
    );

    // 如果不存在，创建新会话
    if (existingSession.id == 0) {
      // 生成新的会话ID（使用时间戳）
      final newSession = ChatSessionModel(
        id: DateTime.now().millisecondsSinceEpoch,
        characterId: character.id,
        characterName: character.name,
        characterAvatar: character.avatar,
        bondLevel: character.bondLevel,
      );
      sessions.add(newSession);
      await saveSessions(sessions);
      return newSession;
    }

    return existingSession;
  }

  /// 获取会话的消息列表
  Future<List<ChatMessageModel>> getMessages(int sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesKey = '$_messagesPrefix$sessionId';
      final messagesJson = prefs.getString(messagesKey);
      if (messagesJson == null || messagesJson.isEmpty) {
        return [];
      }
      final List<dynamic> messagesList = json.decode(messagesJson);
      return messagesList.map((json) => ChatMessageModel.fromJson(json)).toList();
    } catch (e) {
      print('[ChatStorage] Error loading messages: $e');
      return [];
    }
  }

  /// 保存消息到会话
  Future<void> saveMessage(int sessionId, ChatMessageModel message) async {
    try {
      final messages = await getMessages(sessionId);
      messages.add(message);
      await saveMessages(sessionId, messages);
    } catch (e) {
      print('[ChatStorage] Error saving message: $e');
    }
  }

  /// 保存消息列表
  Future<void> saveMessages(int sessionId, List<ChatMessageModel> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesKey = '$_messagesPrefix$sessionId';
      final messagesJson = json.encode(messages.map((m) => m.toJson()).toList());
      await prefs.setString(messagesKey, messagesJson);
    } catch (e) {
      print('[ChatStorage] Error saving messages: $e');
    }
  }

  /// 更新会话的最后一条消息
  Future<void> updateSessionLastMessage(int sessionId, String lastMessage) async {
    try {
      final sessions = await getSessions();
      final sessionIndex = sessions.indexWhere((s) => s.id == sessionId);
      if (sessionIndex != -1) {
        final session = sessions[sessionIndex];
        final updatedSession = ChatSessionModel(
          id: session.id,
          characterId: session.characterId,
          characterName: session.characterName,
          characterAvatar: session.characterAvatar,
          lastMessage: lastMessage,
          lastMessageTime: DateTime.now(),
          bondLevel: session.bondLevel,
        );
        sessions[sessionIndex] = updatedSession;
        await saveSessions(sessions);
      }
    } catch (e) {
      print('[ChatStorage] Error updating session last message: $e');
    }
  }

  /// 删除会话及其所有消息
  Future<void> deleteSession(int sessionId) async {
    try {
      final sessions = await getSessions();
      sessions.removeWhere((s) => s.id == sessionId);
      await saveSessions(sessions);

      // 删除消息
      final prefs = await SharedPreferences.getInstance();
      final messagesKey = '$_messagesPrefix$sessionId';
      await prefs.remove(messagesKey);
    } catch (e) {
      print('[ChatStorage] Error deleting session: $e');
    }
  }

  /// 清除所有聊天数据
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionsKey);
      
      // 清除所有消息
      final sessions = await getSessions();
      for (final session in sessions) {
        final messagesKey = '$_messagesPrefix${session.id}';
        await prefs.remove(messagesKey);
      }
    } catch (e) {
      print('[ChatStorage] Error clearing all data: $e');
    }
  }
}

