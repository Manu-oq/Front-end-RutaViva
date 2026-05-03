class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  static const String backendOrigin = String.fromEnvironment(
    'API_ORIGIN',
    defaultValue: 'http://10.0.2.2:8000',
  );

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
