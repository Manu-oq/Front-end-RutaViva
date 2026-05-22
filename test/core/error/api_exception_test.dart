import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruta_viva/core/error/api_exception.dart';

void main() {
  ApiException fromResponse({required int statusCode, required Object data}) {
    final requestOptions = RequestOptions(path: '/test');
    return ApiException.fromDioException(
      DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: statusCode,
          data: data,
        ),
      ),
    );
  }

  test('maps backend password validation detail to friendly message', () {
    final exception = fromResponse(
      statusCode: 422,
      data: {
        'detail': [
          {
            'type': 'string_too_short',
            'loc': ['body', 'user', 'password'],
            'msg': 'String should have at least 8 characters',
            'ctx': {'min_length': 8},
          },
        ],
      },
    );

    expect(
      exception.message,
      equals('La contraseña debe tener al menos 8 caracteres.'),
    );
  });

  test('maps duplicate account errors to friendly message', () {
    final exception = fromResponse(
      statusCode: 409,
      data: {'detail': 'User already registered'},
    );

    expect(
      exception.message,
      equals('Ya existe una cuenta registrada con ese correo.'),
    );
  });

  test(
    'maps invalid candidate selection to user friendly assistant message',
    () {
      final exception = fromResponse(
        statusCode: 422,
        data: {
          'error': 'Unprocessable Entity',
          'detail': 'Invalid candidate selection.',
        },
      );

      expect(exception.message, contains('No pude seleccionar ese lugar'));
      expect(exception.message, isNot(contains('Invalid candidate selection')));
    },
  );

  test('maps connection errors to backend unavailable message', () {
    final requestOptions = RequestOptions(path: '/auth/login');
    final exception = ApiException.fromDioException(
      DioException(
        requestOptions: requestOptions,
        type: DioExceptionType.connectionError,
        error: 'Connection refused',
      ),
    );

    expect(exception.message, contains('backend esté activo'));
  });
}
