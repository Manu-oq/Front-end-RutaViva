import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main().');
});

final authTokenStorageProvider = Provider<AuthTokenStorage>((ref) {
  return AuthTokenStorage(ref.watch(sharedPreferencesProvider));
});

class AuthTokenStorage {
  static const _tokenKey = 'ruta_viva.auth_token';

  final SharedPreferences _preferences;

  const AuthTokenStorage(this._preferences);

  String? readToken() => _preferences.getString(_tokenKey);

  Future<void> saveToken(String token) {
    return _preferences.setString(_tokenKey, token);
  }

  Future<void> clearToken() {
    return _preferences.remove(_tokenKey);
  }
}
