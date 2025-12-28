import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../providers/chat_provider.dart';
import '../models/chat_model.dart';
import '../models/character_model.dart';
import '../services/character_api_service.dart';
import '../config/app_config.dart';

class ChatConversationPage extends StatefulWidget {
  final int? sessionId; // 从会话列表进入
  final int? characterId; // 从角色页进入
  
  const ChatConversationPage({
    super.key,
    this.sessionId,
    this.characterId,
  });

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  CharacterModel? _character;
  bool _isLoadingCharacter = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    if (widget.characterId != null) {
      // 从角色页进入
      setState(() => _isLoadingCharacter = true);
      try {
        _character = await CharacterApiService().getCharacterDetail(widget.characterId!);
        await chatProvider.initializeChatWithCharacter(_character!);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('加载角色信息失败: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoadingCharacter = false);
        }
      }
    } else if (widget.sessionId != null) {
      // 从会话列表进入
      await chatProvider.openSession(widget.sessionId!);
      // 从会话中获取角色信息（简化处理，实际应该存储完整角色信息）
      final session = chatProvider.sessions.firstWhere(
        (s) => s.id == widget.sessionId,
      );
      // 尝试加载角色信息
      try {
        _character = await CharacterApiService().getCharacterDetail(session.characterId);
        chatProvider.setCurrentCharacter(_character!);
      } catch (e) {
        print('[ChatConversation] Failed to load character: $e');
      }
    }
    
    // 滚动到底部
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // 清空输入框
    _messageController.clear();
    
    // 发送消息
    try {
      await chatProvider.sendMessage(content);
      // 滚动到底部
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发送消息失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCharacter) {
      return Scaffold(
        backgroundColor: const Color(AppConfig.backgroundDark),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(AppConfig.primaryColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(AppConfig.backgroundDark),
      appBar: AppBar(
        backgroundColor: const Color(AppConfig.backgroundDark),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            final character = chatProvider.currentCharacter ?? _character;
            if (character == null) {
              final session = chatProvider.sessions.firstWhere(
                (s) => s.id == chatProvider.currentSessionId,
                orElse: () => throw Exception('Session not found'),
              );
              return Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: CachedNetworkImageProvider(session.characterAvatar),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    session.characterName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            }
            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: CachedNetworkImageProvider(character.avatar),
                ),
                const SizedBox(width: 12),
                Text(
                  character.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // TODO: 显示更多选项
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 消息列表
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                if (chatProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(AppConfig.primaryColor),
                    ),
                  );
                }

                final messages = chatProvider.messages;
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Symbols.chat_bubble,
                          size: 64,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '开始与 ${chatProvider.currentCharacter?.name ?? "AI"} 聊天吧',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: messages.length + (chatProvider.isAiTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      // AI 正在输入
                      return _buildTypingIndicator();
                    }
                    return _buildMessageBubble(messages[index]);
                  },
                );
              },
            ),
          ),
          // 输入框
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message) {
    final isUser = message.isFromUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            // AI 头像
            Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final character = chatProvider.currentCharacter ?? _character;
                if (character != null) {
                  return CircleAvatar(
                    radius: 16,
                    backgroundImage: CachedNetworkImageProvider(character.avatar),
                  );
                }
                return const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(AppConfig.primaryColor),
                  child: Icon(Icons.person, size: 16, color: Colors.white),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? const Color(AppConfig.primaryColor)
                    : const Color(AppConfig.surfaceDark),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                message.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI 头像
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              final character = chatProvider.currentCharacter ?? _character;
              if (character != null) {
                return CircleAvatar(
                  radius: 16,
                  backgroundImage: CachedNetworkImageProvider(character.avatar),
                );
              }
              return const CircleAvatar(
                radius: 16,
                backgroundColor: Color(AppConfig.primaryColor),
                child: Icon(Icons.person, size: 16, color: Colors.white),
              );
            },
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(AppConfig.surfaceDark),
              borderRadius: BorderRadius.circular(20),
            ),
            child: _TypingIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(AppConfig.backgroundDark),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(AppConfig.surfaceDark),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'input message...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              final isSending = chatProvider.isSending || chatProvider.isAiTyping;
              return GestureDetector(
                onTap: isSending ? null : _sendMessage,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSending
                        ? Colors.white.withOpacity(0.3)
                        : const Color(AppConfig.primaryColor),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send,
                    color: isSending
                        ? Colors.white.withOpacity(0.5)
                        : Colors.white,
                    size: 24,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 闪烁的三个点动画（AI 正在输入）
class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = (_controller.value + delay) % 1.0;
            final opacity = (value < 0.5) ? value * 2 : 2 - (value * 2);
            
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Opacity(
                opacity: opacity.clamp(0.3, 1.0),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
