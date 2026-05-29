class TokenModel {
  final String accessToken;
  final String tokenType;
  final String? refreshToken;

  const TokenModel({
    required this.accessToken,
    required this.tokenType,
    this.refreshToken,
  });

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      refreshToken: json['refresh_token'] as String?,
    );
  }
}
