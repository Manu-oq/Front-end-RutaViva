import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import '../storage/local_storage_provider.dart';
import 'auth_token_provider.dart';
import 'dio_client.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio();
});

final apiClientProvider = Provider<DioClient>((ref) {
  final dio = ref.watch(dioProvider);
  Future<String?>? refreshInFlight;

  return DioClient(
    dio,
    authTokenReader: () => ref.read(authTokenProvider),
    refreshAuthToken: () async {
      final inFlight = refreshInFlight;
      if (inFlight != null) {
        return inFlight;
      }

      final refreshFuture = _refreshAuthToken(ref);
      refreshInFlight = refreshFuture;
      try {
        return await refreshFuture;
      } finally {
        if (identical(refreshInFlight, refreshFuture)) {
          refreshInFlight = null;
        }
      }
    },
  );
});

Future<String?> _refreshAuthToken(Ref ref) async {
  final refreshToken = ref.read(refreshTokenStorageProvider).readToken();
  if (refreshToken == null || refreshToken.isEmpty) {
    return null;
  }

  final refreshDio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(
        milliseconds: ApiConstants.connectionTimeout,
      ),
      receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
      responseType: ResponseType.json,
    ),
  );

  try {
    final response = await refreshDio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refresh_token': refreshToken},
    );
    final data = response.data ?? const <String, dynamic>{};
    final accessToken = data['access_token'] as String?;
    final nextRefreshToken = data['refresh_token'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw const FormatException('Missing access_token in refresh response');
    }

    ref.read(authTokenProvider.notifier).setToken(accessToken);
    await ref.read(authTokenStorageProvider).saveToken(accessToken);
    if (nextRefreshToken != null && nextRefreshToken.isNotEmpty) {
      await ref.read(refreshTokenStorageProvider).saveToken(nextRefreshToken);
    } else {
      await ref.read(refreshTokenStorageProvider).clearToken();
    }
    return accessToken;
  } catch (error) {
    assert(() {
      // ignore: avoid_print
      print('[Auth refresh] Failed to refresh token: $error');
      return true;
    }());
    await ref.read(authTokenStorageProvider).clearToken();
    await ref.read(refreshTokenStorageProvider).clearToken();
    ref.read(authTokenProvider.notifier).clearToken();
    return null;
  }
}
