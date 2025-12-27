class ChatSessionModel {
  final int id;
  final int characterId;
  final String characterName;
  final String characterAvatar;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final int bondLevel;

  ChatSessionModel({
    required this.id,
    required this.characterId,
    required this.characterName,
    required this.characterAvatar,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.bondLevel = 0,
  });

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) {
    return ChatSessionModel(
      id: json['id'] as int,
      characterId: json['character_id'] as int,
      characterName: json['character_name'] as String,
      characterAvatar: json['character_avatar'] as String,
      lastMessage: json['last_message'] as String?,
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'] as String)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      bondLevel: json['bond_level'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'character_id': characterId,
      'character_name': characterName,
      'character_avatar': characterAvatar,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime?.toIso8601String(),
      'unread_count': unreadCount,
      'bond_level': bondLevel,
    };
  }
}

class ChatMessageModel {
  final int id;
  final int sessionId;
  final bool isFromUser;
  final String content;
  final DateTime createdAt;
  final int? likeCount;

  ChatMessageModel({
    required this.id,
    required this.sessionId,
    required this.isFromUser,
    required this.content,
    required this.createdAt,
    this.likeCount,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as int,
      sessionId: json['session_id'] as int,
      isFromUser: json['is_from_user'] as bool,
      content: json['content'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      likeCount: json['like_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'session_id': sessionId,
      'is_from_user': isFromUser,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'like_count': likeCount,
    };
  }
}
