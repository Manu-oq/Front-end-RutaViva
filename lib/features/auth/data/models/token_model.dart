class TokenModel {
  final String accessToken;
  final String tokenType;

  const TokenModel({required this.accessToken, required this.tokenType});

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
    );
  }
}
