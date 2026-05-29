import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ruta_viva/core/error/api_exception.dart';
import 'package:ruta_viva/core/network/auth_token_provider.dart';
import 'package:ruta_viva/core/network/dio_client.dart';
import 'package:ruta_viva/core/storage/local_storage_provider.dart';
import 'package:ruta_viva/features/auth/data/models/token_model.dart';
import 'package:ruta_viva/features/auth/data/models/user_model.dart';
import 'package:ruta_viva/features/auth/data/repositories/auth_repository.dart';
import 'package:ruta_viva/features/auth/presentation/providers/auth_provider.dart';

final _testUser = UserModel(
  id: 'test-id',
  email: 'test@test.com',
  isActive: true,
  createdAt: DateTime(2025),
);

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super(DioClient(Dio(), authTokenReader: () => null));

  @override
  Future<TokenModel> login({
    required String email,
    required String password,
  }) async {
    throw const ApiException(
      message: 'Credenciales inválidas',
      statusCode: 401,
    );
  }

  @override
  Future<TokenModel> refreshToken({required String refreshToken}) async {
    throw const ApiException(message: 'Refresh inválido', statusCode: 401);
  }

  @override
  Future<void> logout() async {
    throw const ApiException(message: 'Logout inválido', statusCode: 401);
  }
}

class _SuccessfulAuthRepository extends AuthRepository {
  _SuccessfulAuthRepository()
    : super(DioClient(Dio(), authTokenReader: () => null));

  @override
  Future<TokenModel> login({
    required String email,
    required String password,
  }) async {
    return const TokenModel(
      accessToken: 'new-access-token',
      tokenType: 'bearer',
      refreshToken: 'new-refresh-token',
    );
  }

  @override
  Future<UserModel> getMe() async => _testUser;
}

void main() {
  group('AuthState', () {
    test('isAuthenticated when token and user are set', () {
      final state = AuthState(user: _testUser, token: 'tok');
      expect(state.isAuthenticated, isTrue);
    });

    test('isAuthenticated false when token is null', () {
      final state = AuthState(user: _testUser);
      expect(state.isAuthenticated, isFalse);
    });

    test('isAuthenticated false when user is null', () {
      const state = AuthState(token: 'tok');
      expect(state.isAuthenticated, isFalse);
    });

    test('isAuthenticated false in default state', () {
      const state = AuthState();
      expect(state.isAuthenticated, isFalse);
    });

    test('copyWith preserves existing values', () {
      final state = AuthState(user: _testUser, token: 'tok');
      final updated = state.copyWith(isLoading: true);

      expect(updated.user, equals(_testUser));
      expect(updated.token, equals('tok'));
      expect(updated.isLoading, isTrue);
    });

    test('copyWith clearUser removes user', () {
      final state = AuthState(user: _testUser, token: 'tok');
      final updated = state.copyWith(clearUser: true);

      expect(updated.user, isNull);
      expect(updated.token, equals('tok'));
    });

    test('copyWith clearToken removes token', () {
      final state = AuthState(user: _testUser, token: 'tok');
      final updated = state.copyWith(clearToken: true);

      expect(updated.token, isNull);
      expect(updated.user, equals(_testUser));
    });

    test('copyWith clearError removes errorMessage', () {
      const state = AuthState(errorMessage: 'error');
      final updated = state.copyWith(clearError: true);

      expect(updated.errorMessage, isNull);
    });
  });

  group('authProvider', () {
    test('initial state is empty when no token stored', () async {
      SharedPreferences.setMockInitialValues({});
      final sharedPreferences = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          authRepositoryProvider.overrideWith((ref) => _FakeAuthRepository()),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(authProvider);
      expect(state.token, isNull);
      expect(state.user, isNull);
      expect(state.isAuthenticated, isFalse);
      expect(state.isLoading, isFalse);
    });

    test('login with invalid credentials reflects error', () async {
      SharedPreferences.setMockInitialValues({});
      final sharedPreferences = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          authRepositoryProvider.overrideWith((ref) => _FakeAuthRepository()),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(authProvider.notifier)
          .login(email: 'bad@test.com', password: 'wrong');

      expect(result, isFalse);
      final state = container.read(authProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.errorMessage, isNotNull);
      expect(state.errorMessage, contains('Credenciales'));
      expect(state.isLoading, isFalse);
      expect(state.token, isNull);
      expect(state.user, isNull);
    });

    test('login stores access and refresh tokens', () async {
      SharedPreferences.setMockInitialValues({});
      final sharedPreferences = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          authRepositoryProvider.overrideWith(
            (ref) => _SuccessfulAuthRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container
          .read(authProvider.notifier)
          .login(email: 'ok@test.com', password: 'secret');

      expect(result, isTrue);
      expect(
        sharedPreferences.getString('ruta_viva.auth_token'),
        equals('new-access-token'),
      );
      expect(
        sharedPreferences.getString('ruta_viva.refresh_token'),
        equals('new-refresh-token'),
      );
      expect(container.read(authTokenProvider), equals('new-access-token'));
      expect(container.read(authProvider).isAuthenticated, isTrue);
    });

    test('logout clears state', () async {
      SharedPreferences.setMockInitialValues({});
      final sharedPreferences = await SharedPreferences.getInstance();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          authRepositoryProvider.overrideWith((ref) => _FakeAuthRepository()),
        ],
      );
      addTearDown(container.dispose);

      container.read(authTokenProvider.notifier).setToken('fake-token');
      container.read(authProvider.notifier).state = AuthState(
        user: _testUser,
        token: 'fake-token',
      );

      expect(container.read(authProvider).isAuthenticated, isTrue);

      await container.read(authProvider.notifier).logout();

      final state = container.read(authProvider);
      expect(state.token, isNull);
      expect(state.user, isNull);
      expect(state.isAuthenticated, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.isLoading, isFalse);
      expect(sharedPreferences.getString('ruta_viva.auth_token'), isNull);
      expect(sharedPreferences.getString('ruta_viva.refresh_token'), isNull);
    });
  });
}
