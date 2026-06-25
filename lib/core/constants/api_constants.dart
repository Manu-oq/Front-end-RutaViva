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
    if (_baseUrlOverride.isNotEmpty) {
      final uri = Uri.tryParse(_baseUrlOverride);
      if (uri != null) return '${uri.scheme}://${uri.host}:${uri.port}';
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
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return normalized;
    }
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }
    if (normalized.startsWith('/')) {
      return '$backendOrigin$normalized';
    }
    // Handle relative URLs without a leading slash (e.g. "media/foo.jpg")
    return '$backendOrigin/$normalized';
  }
}
