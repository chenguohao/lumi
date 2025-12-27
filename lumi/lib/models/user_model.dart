class UserModel {
  final int uid;
  final String name;
  final String? avatar;
  final String? email;
  final String? token;
  final String? platformUid;

  UserModel({
    required this.uid,
    required this.name,
    this.avatar,
    this.email,
    this.token,
    this.platformUid,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'] as int,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      email: json['email'] as String?,
      token: json['token'] as String?,
      platformUid: json['platform_uid'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'avatar': avatar,
      'email': email,
      'token': token,
      'platform_uid': platformUid,
    };
  }
}

