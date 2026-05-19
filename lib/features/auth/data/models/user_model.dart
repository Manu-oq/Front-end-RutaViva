class UserModel {
  final String id;
  final String email;
  final bool isActive;
  final String? avatarUrl;
  final DateTime createdAt;
  final TouristProfileModel? touristProfile;
  final EntrepreneurProfileModel? entrepreneurProfile;

  const UserModel({
    required this.id,
    required this.email,
    required this.isActive,
    this.avatarUrl,
    required this.createdAt,
    this.touristProfile,
    this.entrepreneurProfile,
  });

  String get displayName => touristProfile?.fullName ?? email.split('@').first;

  bool get isEntrepreneur => entrepreneurProfile != null;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      isActive: json['is_active'] as bool? ?? true,
      avatarUrl:
          (json['avatar_url'] ?? json['avatar'] ?? json['profile_image_url'])
              ?.toString(),
      createdAt: DateTime.parse(json['created_at'] as String),
      touristProfile: json['tourist_profile'] == null
          ? null
          : TouristProfileModel.fromJson(
              json['tourist_profile'] as Map<String, dynamic>,
            ),
      entrepreneurProfile: json['entrepreneur_profile'] == null
          ? null
          : EntrepreneurProfileModel.fromJson(
              json['entrepreneur_profile'] as Map<String, dynamic>,
            ),
    );
  }
}

class TouristProfileModel {
  final String userId;
  final String fullName;
  final bool hasOwnTransport;
  final Map<String, dynamic>? systemPreferences;

  const TouristProfileModel({
    required this.userId,
    required this.fullName,
    required this.hasOwnTransport,
    this.systemPreferences,
  });

  List<String> get interests {
    final rawInterests = systemPreferences?['interests'];
    if (rawInterests is! List) {
      return const [];
    }
    return rawInterests.map((item) => item.toString()).toList();
  }

  factory TouristProfileModel.fromJson(Map<String, dynamic> json) {
    return TouristProfileModel(
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      hasOwnTransport: json['has_own_transport'] as bool? ?? false,
      systemPreferences: json['system_preferences'] as Map<String, dynamic>?,
    );
  }
}

class EntrepreneurProfileModel {
  final String userId;
  final Map<String, dynamic>? adminData;

  const EntrepreneurProfileModel({required this.userId, this.adminData});

  factory EntrepreneurProfileModel.fromJson(Map<String, dynamic> json) {
    return EntrepreneurProfileModel(
      userId: json['user_id'] as String,
      adminData: json['admin_data'] as Map<String, dynamic>?,
    );
  }
}
