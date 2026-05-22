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

    if (exception.type == DioExceptionType.connectionError) {
      message =
          'No pudimos conectar con Ruta Viva. Verifica que el backend esté activo e intenta nuevamente.';
    } else if (exception.type == DioExceptionType.connectionTimeout) {
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
        message = _friendlyDetailList(detail, response?.statusCode);
      } else if (detail is Map && detail.isNotEmpty) {
        message = _friendlyDetailMap(
          Map<String, dynamic>.from(detail),
          response?.statusCode,
        );
      } else {
        final rawMessage = data['message'] ?? data['error'];
        if (rawMessage != null && rawMessage.toString().trim().isNotEmpty) {
          message = _friendlyDetail(
            rawMessage.toString(),
            response?.statusCode,
          );
        }
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

  static String _friendlyDetailList(List<dynamic> detail, int? statusCode) {
    final messages = <String>[];
    for (final item in detail) {
      if (item is Map) {
        final mapped = _friendlyDetailMap(
          Map<String, dynamic>.from(item),
          statusCode,
        );
        if (mapped.trim().isNotEmpty) {
          messages.add(mapped);
        }
      } else if (item != null && item.toString().trim().isNotEmpty) {
        messages.add(_friendlyDetail(item.toString(), statusCode));
      }
    }
    if (messages.isEmpty) {
      return 'Revisa los datos ingresados e intenta nuevamente.';
    }
    return messages.toSet().join('\n');
  }

  static String _friendlyDetailMap(Map<String, dynamic> item, int? statusCode) {
    final msg = (item['msg'] ?? item['message'] ?? item['detail'] ?? '')
        .toString()
        .trim();
    final type = item['type']?.toString().toLowerCase() ?? '';
    final loc = item['loc'];
    final field = _fieldFromLoc(loc);
    final ctx = item['ctx'];
    final minLength = ctx is Map ? (ctx['min_length'] as num?)?.toInt() : null;

    if (field == 'password' &&
        (type.contains('too_short') ||
            msg.toLowerCase().contains('at least') ||
            msg.toLowerCase().contains('8'))) {
      return 'La contraseña debe tener al menos ${minLength ?? 8} caracteres.';
    }
    if (field == 'email' ||
        type.contains('email') ||
        msg.toLowerCase().contains('email')) {
      return 'Ingresa un correo electrónico válido.';
    }
    if (type.contains('missing')) {
      return field == null
          ? 'Faltan campos obligatorios.'
          : 'El campo ${_friendlyFieldName(field)} es obligatorio.';
    }
    if (msg.isNotEmpty) {
      final prefix = field == null ? '' : '${_friendlyFieldName(field)}: ';
      return '$prefix${_friendlyDetail(msg, statusCode)}';
    }
    return 'Revisa los datos ingresados e intenta nuevamente.';
  }

  static String _friendlyDetail(String detail, int? statusCode) {
    final normalized = detail.toLowerCase();
    if (statusCode == 429) {
      if (normalized.contains('per hour') || normalized.contains('hour')) {
        return 'Has alcanzado el límite de creación. Puedes crear hasta 5 lugares por hora.';
      }
      if (normalized.contains('per day') || normalized.contains('day')) {
        return 'Has alcanzado el límite diario. Puedes crear hasta 10 lugares por día.';
      }
      return 'Has alcanzado el límite de creación. Intenta de nuevo más tarde.';
    }
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
    if (statusCode != null && statusCode >= 500) {
      return 'Hubo un error inesperado en el servidor. Intenta de nuevo en unos momentos.';
    }
    if (normalized.contains('already') ||
        normalized.contains('existe') ||
        normalized.contains('registered') ||
        normalized.contains('duplicate')) {
      return 'Ya existe una cuenta registrada con ese correo.';
    }
    if (normalized.contains('invalid candidate selection')) {
      return 'No pude seleccionar ese lugar automáticamente. Elige una opción de la lista o escribe tu solicitud con más detalle.';
    }
    if (normalized.contains('candidate') && normalized.contains('invalid')) {
      return 'No pude usar esa opción del assistant. Prueba seleccionando nuevamente o escribe lo que quieres hacer.';
    }
    if (normalized.contains('password') &&
        (normalized.contains('8') ||
            normalized.contains('at least') ||
            normalized.contains('too short') ||
            normalized.contains('min'))) {
      return 'La contraseña debe tener al menos 8 caracteres.';
    }
    if (normalized.contains('invalid email') ||
        normalized.contains('valid email') ||
        normalized.contains('value is not a valid email')) {
      return 'Ingresa un correo electrónico válido.';
    }
    if (statusCode == 401 || statusCode == 403) {
      return 'Correo o contraseña incorrectos.';
    }
    if (statusCode == 422 || statusCode == 400) {
      if (normalized.contains('field required') ||
          normalized.contains('missing')) {
        return 'Faltan campos obligatorios.';
      }
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

  static String? _fieldFromLoc(dynamic loc) {
    if (loc is List && loc.isNotEmpty) {
      return loc.last.toString();
    }
    if (loc is String && loc.trim().isNotEmpty) {
      return loc.split('.').last;
    }
    return null;
  }

  static String _friendlyFieldName(String field) {
    return switch (field) {
      'email' => 'correo electrónico',
      'password' => 'contraseña',
      'full_name' => 'nombre completo',
      'name' => 'nombre',
      'description' => 'descripción',
      _ => field.replaceAll('_', ' '),
    };
  }

  @override
  String toString() => message;
}
