class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );
  static const int receiveTimeout = 15000;
  static const int connectionTimeout = 15000;
}
