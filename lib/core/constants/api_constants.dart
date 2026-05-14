import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String _androidEmulatorOrigin = 'http://10.0.2.2:8000';
  static const String _localOrigin = 'http://127.0.0.1:8000';
  static const String _baseUrlOverride = String.fromEnvironment('API_BASE_URL');
  static const String _backendOriginOverride = String.fromEnvironment(
    'API_ORIGIN',
  );

  static String get baseUrl =>
      _baseUrlOverride.isNotEmpty ? _baseUrlOverride : '$backendOrigin/api/v1';

  static String get backendOrigin {
    if (_backendOriginOverride.isNotEmpty) {
      return _backendOriginOverride;
    }
    if (kIsWeb) {
      return _localOrigin;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => _androidEmulatorOrigin,
      _ => _localOrigin,
    };
  }

  static const int receiveTimeout = 15000;
  static const int connectionTimeout = 15000;

  static String? resolveBackendUrl(String? value) {
    if (value == null || value.isEmpty) {
      return value;
    }
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/')) {
      return '$backendOrigin$value';
    }
    return value;
  }
}
