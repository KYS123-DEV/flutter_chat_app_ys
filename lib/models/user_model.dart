class UserModel {
  final String uid;
  final String email;
  final String name;
  final String profileUrl;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.profileUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'profileUrl': profileUrl,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '이름 없음',
      profileUrl: map['profileUrl'] ?? '',
    );
  }
}