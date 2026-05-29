import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';

class DioClient {
  final Dio _dio;
  final String? Function()? authTokenReader;
  final Future<String?> Function()? refreshAuthToken;

  DioClient(this._dio, {this.authTokenReader, this.refreshAuthToken}) {
    _dio
      ..options.baseUrl = ApiConstants.baseUrl
      ..options.connectTimeout = const Duration(
        milliseconds: ApiConstants.connectionTimeout,
      )
      ..options.receiveTimeout = const Duration(
        milliseconds: ApiConstants.receiveTimeout,
      )
      ..options.responseType = ResponseType.json;

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.extra['skipAuth'] == true) {
            return handler.next(options);
          }
          final token = authTokenReader?.call();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          final request = error.requestOptions;
          final shouldTryRefresh =
              error.response?.statusCode == 401 &&
              refreshAuthToken != null &&
              request.extra['skipAuthRefresh'] != true &&
              request.extra['didRefreshRetry'] != true;

          if (!shouldTryRefresh) {
            return handler.next(error);
          }

          final refreshedToken = await refreshAuthToken!.call();
          if (refreshedToken == null || refreshedToken.isEmpty) {
            return handler.next(error);
          }

          request.extra['didRefreshRetry'] = true;
          request.headers['Authorization'] = 'Bearer $refreshedToken';

          try {
            final response = await _dio.fetch<dynamic>(request);
            return handler.resolve(response);
          } on DioException catch (retryError) {
            return handler.next(retryError);
          }
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: false, responseBody: true),
      );
    }
  }

  Future<Response<T>> get<T>(
    String url, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.get<T>(url, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.post<T>(
      url,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> put<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.put<T>(
      url,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> patch<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.patch<T>(
      url,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<T>> delete<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return _dio.delete<T>(
      url,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
