import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? error;

  const ApiException({required this.message, this.statusCode, this.error});

  factory ApiException.fromDioException(DioException exception) {
    final response = exception.response;
    final data = response?.data;

    String message = exception.message ?? 'No se pudo conectar con Ruta Viva.';
    String? error;

    if (data is Map<String, dynamic>) {
      error = data['error']?.toString();
      final detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        message = detail;
      } else if (detail is List && detail.isNotEmpty) {
        message = detail.map((item) => item.toString()).join('\n');
      }
    } else if (data is String && data.trim().isNotEmpty) {
      message = data;
    }

    return ApiException(
      message: message,
      statusCode: response?.statusCode,
      error: error,
    );
  }

  @override
  String toString() => message;
}
