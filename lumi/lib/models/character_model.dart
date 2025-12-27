class CharacterModel {
  final int id;
  final String name;
  final String avatar;
  final String? coverImage;
  final String description;
  final int fanCount;
  final int likeCount;
  final int bondLevel;
  final bool isOnline;
  final String? personality;

  CharacterModel({
    required this.id,
    required this.name,
    required this.avatar,
    this.coverImage,
    required this.description,
    required this.fanCount,
    required this.likeCount,
    required this.bondLevel,
    this.isOnline = false,
    this.personality,
  });

  factory CharacterModel.fromJson(Map<String, dynamic> json) {
    return CharacterModel(
      id: json['id'] as int,
      name: json['name'] as String,
      avatar: json['avatar'] as String,
      coverImage: json['cover_image'] as String?,
      description: json['description'] as String,
      fanCount: json['fan_count'] as int? ?? 0,
      likeCount: json['like_count'] as int? ?? 0,
      bondLevel: json['bond_level'] as int? ?? 0,
      isOnline: json['is_online'] as bool? ?? false,
      personality: json['personality'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'cover_image': coverImage,
      'description': description,
      'fan_count': fanCount,
      'like_count': likeCount,
      'bond_level': bondLevel,
      'is_online': isOnline,
      'personality': personality,
    };
  }
}
