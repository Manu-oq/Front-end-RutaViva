import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/network/api_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../models/token_model.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});

class AuthRepository {
  final DioClient _client;

  const AuthRepository(this._client);

  Future<TokenModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return TokenModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<UserModel> registerTourist({
    required String email,
    required String password,
    required String fullName,
    bool hasOwnTransport = false,
    List<String> interests = const [],
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        '/auth/register',
        data: {
          'user': {'email': email, 'password': password, 'is_active': true},
          'profile': {
            'full_name': fullName,
            'has_own_transport': hasOwnTransport,
            'system_preferences': {'interests': interests},
          },
        },
      );
      return UserModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<UserModel> getMe() async {
    try {
      final response = await _client.get<Map<String, dynamic>>('/users/me');
      return UserModel.fromJson(response.data!);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<UserModel> updateTouristProfile({
    required String fullName,
    required bool hasOwnTransport,
    required List<String> interests,
  }) async {
    try {
      await _client.put<Map<String, dynamic>>(
        '/users/me/tourist-profile',
        data: {
          'full_name': fullName,
          'has_own_transport': hasOwnTransport,
          'system_preferences': {'interests': interests},
        },
      );
      return getMe();
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<UserModel> activateEntrepreneurProfile() async {
    try {
      await _client.post<Map<String, dynamic>>(
        '/users/me/entrepreneur-profile',
        data: {
          'admin_data': {'activated_from': 'frontend'},
        },
      );
      return getMe();
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }
}
