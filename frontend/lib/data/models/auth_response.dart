class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access'] as String,
      refreshToken: json['refresh'] as String,
      user: json['user'] as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toJson() {
    return {'access': accessToken, 'refresh': refreshToken, 'user': user};
  }
}
