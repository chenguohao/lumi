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
    // 处理 ID 字段（可能是 'id' 或 'ID'）
    int id;
    if (json['ID'] != null) {
      id = json['ID'] is int ? json['ID'] as int : int.parse(json['ID'].toString());
    } else if (json['id'] != null) {
      id = json['id'] is int ? json['id'] as int : int.parse(json['id'].toString());
    } else {
      throw Exception('Missing id field in character data');
    }

    return CharacterModel(
      id: id,
      name: json['name'] as String? ?? '',
      avatar: json['avatar'] as String? ?? '',
      coverImage: json['cover_image'] as String?,
      description: json['description'] as String? ?? '',
      fanCount: json['fan_count'] is int ? json['fan_count'] as int : (json['fan_count'] != null ? int.tryParse(json['fan_count'].toString()) ?? 0 : 0),
      likeCount: json['like_count'] is int ? json['like_count'] as int : (json['like_count'] != null ? int.tryParse(json['like_count'].toString()) ?? 0 : 0),
      bondLevel: json['bond_level'] is int ? json['bond_level'] as int : (json['bond_level'] != null ? int.tryParse(json['bond_level'].toString()) ?? 0 : 0),
      isOnline: json['is_online'] is bool ? json['is_online'] as bool : (json['is_online'] != null ? json['is_online'].toString().toLowerCase() == 'true' : false),
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
