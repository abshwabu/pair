class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.timezone,
    this.language,
  });

  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? timezone;
  final String? language;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
      timezone: json['timezone'] as String?,
      language: json['language'] as String?,
    );
  }
}
