import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/network/auth_token_provider.dart';
import '../../../../core/storage/local_storage_provider.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class AuthState {
  final UserModel? user;
  final String? token;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => token != null && user != null;

  AuthState copyWith({
    UserModel? user,
    String? token,
    bool? isLoading,
    String? errorMessage,
    bool clearUser = false,
    bool clearToken = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      token: clearToken ? null : (token ?? this.token),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    ref.listen<String?>(authTokenProvider, (previous, next) {
      if (previous != null &&
          previous.isNotEmpty &&
          (next == null || next.isEmpty) &&
          state.isAuthenticated) {
        state = const AuthState();
      }
    });

    final storedToken = ref.read(authTokenStorageProvider).readToken();
    final storedRefreshToken = ref
        .read(refreshTokenStorageProvider)
        .readToken();
    if ((storedToken == null || storedToken.isEmpty) &&
        (storedRefreshToken == null || storedRefreshToken.isEmpty)) {
      return const AuthState();
    }

    if (storedToken != null && storedToken.isNotEmpty) {
      Future.microtask(() => _restoreSession(storedToken));
      return AuthState(token: storedToken, isLoading: true);
    }

    Future.microtask(_restoreSessionFromRefreshToken);
    return const AuthState(isLoading: true);
  }

  Future<void> _restoreSession(String storedToken) async {
    try {
      ref.read(authTokenProvider.notifier).setToken(storedToken);
      final user = await ref.read(authRepositoryProvider).getMe();
      final token = ref.read(authTokenProvider);
      if (token == null || token.isEmpty) {
        state = const AuthState();
        return;
      }
      state = AuthState(user: user, token: token);
    } catch (error) {
      debugPrint('[Auth] restoreSession failed: $error');
      await _clearTokens();
      state = const AuthState();
    }
  }

  Future<void> _restoreSessionFromRefreshToken() async {
    final storedRefreshToken = ref
        .read(refreshTokenStorageProvider)
        .readToken();
    if (storedRefreshToken == null || storedRefreshToken.isEmpty) {
      state = const AuthState();
      return;
    }

    try {
      final token = await ref
          .read(authRepositoryProvider)
          .refreshToken(refreshToken: storedRefreshToken);
      ref.read(authTokenProvider.notifier).setToken(token.accessToken);
      await ref.read(authTokenStorageProvider).saveToken(token.accessToken);
      if (token.refreshToken != null && token.refreshToken!.isNotEmpty) {
        await ref
            .read(refreshTokenStorageProvider)
            .saveToken(token.refreshToken!);
      } else {
        await ref.read(refreshTokenStorageProvider).clearToken();
      }
      final user = await ref.read(authRepositoryProvider).getMe();
      state = AuthState(user: user, token: token.accessToken);
    } catch (error) {
      debugPrint('[Auth] restoreSessionFromRefreshToken failed: $error');
      await _clearTokens();
      state = const AuthState();
    }
  }

  Future<void> _clearTokens() async {
    await ref.read(authTokenStorageProvider).clearToken();
    await ref.read(refreshTokenStorageProvider).clearToken();
    ref.read(authTokenProvider.notifier).clearToken();
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      final token = await repository.login(email: email, password: password);
      ref.read(authTokenProvider.notifier).setToken(token.accessToken);
      await ref.read(authTokenStorageProvider).saveToken(token.accessToken);
      if (token.refreshToken != null && token.refreshToken!.isNotEmpty) {
        await ref
            .read(refreshTokenStorageProvider)
            .saveToken(token.refreshToken!);
      } else {
        await ref.read(refreshTokenStorageProvider).clearToken();
      }
      final user = await repository.getMe();
      state = AuthState(user: user, token: token.accessToken);
      return true;
    } catch (error) {
      await _clearTokens();
      state = state.copyWith(
        isLoading: false,
        clearToken: true,
        clearUser: true,
        errorMessage: _readableError(error),
      );
      return false;
    }
  }

  Future<bool> registerTourist({
    required String email,
    required String password,
    required String fullName,
    bool hasOwnTransport = false,
    List<String> interests = const [],
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.registerTourist(
        email: email,
        password: password,
        fullName: fullName,
        hasOwnTransport: hasOwnTransport,
        interests: interests,
      );
      return login(email: email, password: password);
    } catch (error) {
      debugPrint('[Auth] activateEntrepreneurProfile failed: $error');
      state = state.copyWith(
        isLoading: false,
        errorMessage: _readableError(error),
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await ref.read(authRepositoryProvider).logout();
    } catch (error) {
      debugPrint('[Auth] logout request failed: $error');
    } finally {
      await _clearTokens();
      state = const AuthState();
    }
  }

  Future<bool> updateTouristProfile({
    required String fullName,
    required bool hasOwnTransport,
    required List<String> interests,
    String? email,
    String? avatarUrl,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      if (email != null || avatarUrl != null) {
        await repository.patchCurrentUser(email: email, avatarUrl: avatarUrl);
      }
      final user = await repository.updateTouristProfile(
        fullName: fullName,
        hasOwnTransport: hasOwnTransport,
        interests: interests,
      );
      state = AuthState(user: user, token: state.token);
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _readableError(error),
      );
      return false;
    }
  }

  Future<bool> activateEntrepreneurProfile({String? rut}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .activateEntrepreneurProfile(rut: rut);
      state = AuthState(user: user, token: state.token);
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _readableError(error),
      );
      return false;
    }
  }

  String _readableError(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return 'No se pudo completar la operación.';
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
