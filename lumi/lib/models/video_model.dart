class VideoModel {
  final int id;
  final String title;
  final String videoUrl;
  final String? coverUrl;
  final int characterId;
  final String? characterName;
  final String? characterAvatar;
  int likeCount;
  final int viewCount;
  final int favoriteCount;
  bool isLiked;
  bool isFavorited;
  final DateTime createdAt;

  VideoModel({
    required this.id,
    required this.title,
    required this.videoUrl,
    this.coverUrl,
    required this.characterId,
    this.characterName,
    this.characterAvatar,
    required this.likeCount,
    required this.viewCount,
    this.favoriteCount = 0,
    this.isLiked = false,
    this.isFavorited = false,
    required this.createdAt,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'] as int,
      title: json['title'] as String,
      videoUrl: json['video_url'] as String,
      coverUrl: json['cover_url'] as String?,
      characterId: json['character_id'] as int,
      characterName: json['character_name'] as String?,
      characterAvatar: json['character_avatar'] as String?,
      likeCount: json['like_count'] as int? ?? 0,
      viewCount: json['view_count'] as int? ?? 0,
      favoriteCount: json['favorite_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      isFavorited: json['is_favorited'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'video_url': videoUrl,
      'cover_url': coverUrl,
      'character_id': characterId,
      'character_name': characterName,
      'character_avatar': characterAvatar,
      'like_count': likeCount,
      'view_count': viewCount,
      'favorite_count': favoriteCount,
      'is_liked': isLiked,
      'is_favorited': isFavorited,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

