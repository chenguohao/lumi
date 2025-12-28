import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import '../models/character_model.dart';
import '../services/chatgpt_service.dart';
import '../services/chat_storage_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatGPTService _aiService = ChatGPTService();
  final ChatStorageService _storageService = ChatStorageService();
  
  List<ChatSessionModel> _sessions = [];
  List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  bool _isAiTyping = false; // AI 正在输入
  int? _currentSessionId;
  CharacterModel? _currentCharacter;

  List<ChatSessionModel> get sessions => _sessions;
  List<ChatMessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get isAiTyping => _isAiTyping;
  int? get currentSessionId => _currentSessionId;
  CharacterModel? get currentCharacter => _currentCharacter;

  /// 加载所有会话
  Future<void> loadSessions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _sessions = await _storageService.getSessions();
      // 按最后消息时间排序
      _sessions.sort((a, b) {
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// 加载会话的消息
  Future<void> loadMessages(int sessionId) async {
    _isLoading = true;
    _currentSessionId = sessionId;
    notifyListeners();

    try {
      _messages = await _storageService.getMessages(sessionId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// 初始化与角色的聊天（从角色页进入）
  Future<void> initializeChatWithCharacter(CharacterModel character) async {
    _currentCharacter = character;
    
    // 获取或创建会话
    final session = await _storageService.getOrCreateSession(character);
    _currentSessionId = session.id;
    
    // 加载消息
    await loadMessages(session.id);
    
    // 如果会话列表中没有，添加到列表
    if (!_sessions.any((s) => s.id == session.id)) {
      _sessions.insert(0, session);
      await _storageService.saveSessions(_sessions);
    }
    
    notifyListeners();
  }

  /// 从会话列表进入聊天
  Future<void> openSession(int sessionId) async {
    // 如果会话列表为空，先加载
    if (_sessions.isEmpty) {
      await loadSessions();
    }
    
    final session = _sessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => throw Exception('Session not found'),
    );
    
    // 需要从会话中恢复角色信息（这里简化处理，实际应该存储角色完整信息）
    // 暂时只设置会话ID，角色信息从会话中获取
    _currentSessionId = sessionId;
    await loadMessages(sessionId);
    notifyListeners();
  }

  /// 发送消息
  Future<void> sendMessage(String content) async {
    if (_currentSessionId == null || _currentCharacter == null) {
      throw Exception('需要先初始化聊天');
    }

    if (content.trim().isEmpty) {
      return;
    }

    _isSending = true;
    notifyListeners();

    try {
      // 创建用户消息
      final userMessage = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch,
        sessionId: _currentSessionId!,
        isFromUser: true,
        content: content.trim(),
        createdAt: DateTime.now(),
      );

      // 保存用户消息
      await _storageService.saveMessage(_currentSessionId!, userMessage);
      _messages.add(userMessage);
      
      // 更新会话的最后消息
      await _storageService.updateSessionLastMessage(
        _currentSessionId!,
        content.trim(),
      );
      
      // 更新会话列表中的最后消息
      final sessionIndex = _sessions.indexWhere((s) => s.id == _currentSessionId);
      if (sessionIndex != -1) {
        final session = _sessions[sessionIndex];
        _sessions[sessionIndex] = ChatSessionModel(
          id: session.id,
          characterId: session.characterId,
          characterName: session.characterName,
          characterAvatar: session.characterAvatar,
          lastMessage: content.trim(),
          lastMessageTime: DateTime.now(),
          bondLevel: session.bondLevel,
        );
        await _storageService.saveSessions(_sessions);
      }

      _isSending = false;
      notifyListeners();

      // 调用 AI 服务获取回复
      _isAiTyping = true;
      notifyListeners();

      try {
        final aiResponse = await _aiService.getAIResponse(
          userMessage: content.trim(),
          aiName: _currentCharacter!.name,
          aiPersonality: _currentCharacter!.personality ?? _currentCharacter!.description,
        );

        // 创建 AI 消息
        final aiMessage = ChatMessageModel(
          id: DateTime.now().millisecondsSinceEpoch + 1,
          sessionId: _currentSessionId!,
          isFromUser: false,
          content: aiResponse,
          createdAt: DateTime.now(),
        );

        // 保存 AI 消息
        await _storageService.saveMessage(_currentSessionId!, aiMessage);
        _messages.add(aiMessage);
        
        // 更新会话的最后消息
        await _storageService.updateSessionLastMessage(
          _currentSessionId!,
          aiResponse,
        );
        
        // 更新会话列表中的最后消息
        if (sessionIndex != -1) {
          final session = _sessions[sessionIndex];
          _sessions[sessionIndex] = ChatSessionModel(
            id: session.id,
            characterId: session.characterId,
            characterName: session.characterName,
            characterAvatar: session.characterAvatar,
            lastMessage: aiResponse,
            lastMessageTime: DateTime.now(),
            bondLevel: session.bondLevel,
          );
          await _storageService.saveSessions(_sessions);
        }
      } catch (e) {
        print('[ChatProvider] AI response error: $e');
        // 即使 AI 回复失败，也继续
      } finally {
        _isAiTyping = false;
        notifyListeners();
      }
    } catch (e) {
      _isSending = false;
      _isAiTyping = false;
      notifyListeners();
      rethrow;
    }
  }

  /// 设置当前角色
  void setCurrentCharacter(CharacterModel character) {
    _currentCharacter = character;
    notifyListeners();
  }

  /// 清除当前会话
  void clearCurrentSession() {
    _currentSessionId = null;
    _currentCharacter = null;
    _messages = [];
    notifyListeners();
  }
}
