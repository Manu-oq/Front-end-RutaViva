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
    final storedToken = ref.read(authTokenStorageProvider).readToken();
    if (storedToken == null || storedToken.isEmpty) {
      return const AuthState();
    }

    Future.microtask(() => _restoreSession(storedToken));
    return AuthState(token: storedToken, isLoading: true);
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
    } catch (_) {
      await ref.read(authTokenStorageProvider).clearToken();
      ref.read(authTokenProvider.notifier).clearToken();
      state = const AuthState();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repository = ref.read(authRepositoryProvider);
      final token = await repository.login(email: email, password: password);
      ref.read(authTokenProvider.notifier).setToken(token.accessToken);
      await ref.read(authTokenStorageProvider).saveToken(token.accessToken);
      final user = await repository.getMe();
      state = AuthState(user: user, token: token.accessToken);
      return true;
    } catch (error) {
      await ref.read(authTokenStorageProvider).clearToken();
      ref.read(authTokenProvider.notifier).clearToken();
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
      state = state.copyWith(
        isLoading: false,
        errorMessage: _readableError(error),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await ref.read(authTokenStorageProvider).clearToken();
    ref.read(authTokenProvider.notifier).clearToken();
    state = const AuthState();
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

  Future<bool> activateEntrepreneurProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await ref
          .read(authRepositoryProvider)
          .activateEntrepreneurProfile();
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
