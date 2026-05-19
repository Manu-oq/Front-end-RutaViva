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

    if (exception.type == DioExceptionType.connectionTimeout) {
      message =
          'No se pudo conectar con el servicio. Revisa tu conexión e intenta nuevamente.';
    } else if (exception.type == DioExceptionType.receiveTimeout) {
      message = 'El servicio tardó demasiado en responder. Intenta nuevamente.';
    }

    if (data is Map<String, dynamic>) {
      error = data['error']?.toString();
      final detail = data['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        message = _friendlyDetail(detail, response?.statusCode);
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

  static String _friendlyDetail(String detail, int? statusCode) {
    final normalized = detail.toLowerCase();
    if (statusCode == 502 || normalized.contains('llm')) {
      if (normalized.contains('large unexplained daytime gap') ||
          normalized.contains('gap')) {
        return 'No pudimos generar un itinerario suficientemente consistente. Intenta ajustar tu búsqueda o ampliar el radio.';
      }
      if (normalized.contains('invalid') ||
          normalized.contains('outside') ||
          normalized.contains('date') ||
          normalized.contains('time')) {
        return 'La ruta generada no tenía horarios confiables. Intenta cambiar las fechas o ampliar el radio.';
      }
      if (normalized.contains('primary') ||
          normalized.contains('informative')) {
        return 'La ruta no tenía suficientes atractivos principales. Prueba con otra búsqueda o más distancia.';
      }
      return 'No pudimos generar un itinerario suficientemente confiable. Intenta ajustar tu búsqueda.';
    }
    if (normalized.contains('end_date') && normalized.contains('start_date')) {
      return 'La fecha de término no puede ser anterior a la fecha de inicio.';
    }
    if (normalized.contains('7 days') || normalized.contains('7 días')) {
      return 'El viaje puede tener como máximo 7 días.';
    }
    if (normalized.contains('no relevant') || normalized.contains('sin pois')) {
      return 'No encontramos suficientes lugares relevantes. Intenta ampliar el radio o cambiar tu búsqueda.';
    }
    return detail;
  }

  @override
  String toString() => message;
}
