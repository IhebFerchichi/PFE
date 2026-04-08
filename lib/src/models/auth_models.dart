import '../core/json_utils.dart';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.emailVerified,
  });

  final int id;
  final String email;
  final String fullName;
  final String role;
  final bool emailVerified;

  bool get isAdmin => role.toUpperCase() == 'ADMIN';

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: readInt(json, 'id') ?? readInt(json, 'userId') ?? 0,
      email: readString(json, 'email') ?? '',
      fullName: readString(json, 'fullName') ?? 'Battery Pack User',
      role: readString(json, 'role') ?? 'USER',
      emailVerified: readBool(json, 'emailVerified', defaultValue: false),
    );
  }
}

class LoginResponse {
  const LoginResponse({
    required this.token,
    required this.user,
  });

  final String token;
  final AuthUser user;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: readString(json, 'token') ?? '',
      user: AuthUser.fromJson(json),
    );
  }
}

class AuthMessageResponse {
  const AuthMessageResponse({
    required this.message,
    this.email,
  });

  final String message;
  final String? email;

  factory AuthMessageResponse.fromJson(Map<String, dynamic> json) {
    return AuthMessageResponse(
      message: readString(json, 'message') ?? 'Request completed.',
      email: readString(json, 'email'),
    );
  }
}
