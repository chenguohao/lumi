import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import '../models/character_model.dart';
import '../services/chat_api_service.dart';
import '../services/chatgpt_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatApiService _chatService = ChatApiService();
  final ChatGPTService _aiService = ChatGPTService();
  
  List<ChatSessionModel> _sessions = [];
  List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  int? _currentSessionId;
  CharacterModel? _currentCharacter;

  List<ChatSessionModel> get sessions => _sessions;
  List<ChatMessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  int? get currentSessionId => _currentSessionId;
  CharacterModel? get currentCharacter => _currentCharacter;

  Future<void> loadSessions() async {
    _isLoading = true;
    notifyListeners();

    try {
      _sessions = await _chatService.getChatSessions();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadMessages(int sessionId) async {
    _isLoading = true;
    _currentSessionId = sessionId;
    notifyListeners();

    try {
      _messages = await _chatService.getChatMessages(sessionId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> sendMessage(String content, {CharacterModel? character}) async {
    if (_currentSessionId == null) {
      if (character == null) {
        throw Exception('需要角色信息来创建会话');
      }
      // 创建新会话
      final session = await _chatService.createChatSession(character.id);
      _currentSessionId = session.id;
      _currentCharacter = character;
    }

    _isSending = true;
    notifyListeners();

    try {
      // 发送用户消息
      final userMessage = await _chatService.sendMessage(_currentSessionId!, content);
      _messages.add(userMessage);
      notifyListeners();

      // 获取AI回复
      if (_currentCharacter != null) {
        final aiResponse = await _aiService.getAIResponse(
          userMessage: content,
          aiName: _currentCharacter!.name,
          aiOccupation: 'Virtual Idol', // 可以从角色信息中获取
          aiAge: 18, // 可以从角色信息中获取
          aiLanguage: '中文',
        );

        // 保存AI回复（这里需要服务器端支持，暂时模拟）
        // TODO: 实际应该通过API保存AI回复
        // 暂时只在前端显示，不保存到数据库
        final aiMessage = ChatMessageModel(
          id: _messages.length + 1,
          sessionId: _currentSessionId!,
          isFromUser: false,
          content: aiResponse,
          createdAt: DateTime.now(),
        );
        _messages.add(aiMessage);
      }

      _isSending = false;
      notifyListeners();
    } catch (e) {
      _isSending = false;
      notifyListeners();
      rethrow;
    }
  }

  void setCurrentCharacter(CharacterModel character) {
    _currentCharacter = character;
    notifyListeners();
  }
}

