import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class DioClient {
  final Dio _dio;

  DioClient(this._dio) {
    _dio
      ..options.baseUrl = ApiConstants.baseUrl
      ..options.connectTimeout = const Duration(milliseconds: ApiConstants.connectionTimeout)
      ..options.receiveTimeout = const Duration(milliseconds: ApiConstants.receiveTimeout)
      ..options.responseType = ResponseType.json;

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Aquí se inyecta el Token de forma global
        // const token = "tu_token_de_prueba"; 
        // options.headers['Authorization'] = 'Bearer $token';
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        // Centralización de errores (401, 404, 500)
        if (e.response?.statusCode == 401) {
          // Lógica de Refresh Token o Logout
        }
        return handler.next(e);
      },
    ));

    // Opcional: Agregar un logger para ver las peticiones en consola
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  // Métodos envoltorios para no repetir try-catch en todo el código
  Future<Response> get(String url, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(url, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> post(String url, {dynamic data}) async {
    try {
      return await _dio.post(url, data: data);
    } catch (e) {
      rethrow;
    }
  }
}