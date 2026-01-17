class AuthResponse {
  final String accessToken;
  final String? refreshToken;
  final Map<String, dynamic>? user;

  AuthResponse({
    required this.accessToken,
    this.refreshToken,
    this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final accessToken = json['access'];
    if (accessToken is! String) {
      throw const FormatException('Missing access token');
    }

    final refreshToken = json['refresh'];
    final userData = json['user'] ?? json['user_info'];
    final user =
        userData is Map<String, dynamic> ? userData : null;

    return AuthResponse(
<<<<<<< HEAD
      accessToken: accessToken,
      refreshToken: refreshToken is String ? refreshToken : null,
      user: user,
=======
      accessToken: json['access'] as String,
      refreshToken: json['refresh'] as String,
      user: json['user_info'] as Map<String, dynamic>? ?? json['user'] as Map<String, dynamic>,
>>>>>>> f1b2309ea19ed2efeab1b30d6ce7889d34b57579
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access': accessToken,
      'refresh': refreshToken,
      'user': user,
    };
  }
}
