import 'user_model.dart';

class AuthResponse {
  final String token;
  final UserModel user;
  final String? message;

  AuthResponse({required this.token, required this.user, this.message});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      message: json['message'] as String?,
    );
  }
}
