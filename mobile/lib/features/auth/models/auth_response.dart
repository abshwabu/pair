import 'package:pair/features/auth/models/user_model.dart';

class AuthResponse {
  const AuthResponse({
    required this.user,
    required this.token,
  });

  final UserModel user;
  final String token;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
    );
  }
}
