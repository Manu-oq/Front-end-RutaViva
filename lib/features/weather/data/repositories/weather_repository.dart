import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/api_exception.dart';
import '../../../../core/network/api_provider.dart';
import '../../../../core/network/dio_client.dart';
import '../models/weather_forecast_model.dart';

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return WeatherRepository(ref.watch(apiClientProvider));
});

final weatherForecastProvider =
    FutureProvider.family<List<WeatherForecastDay>, WeatherForecastRequest>((
      ref,
      request,
    ) async {
      return ref.watch(weatherRepositoryProvider).forecast(request);
    });

class WeatherRepository {
  final DioClient _client;

  const WeatherRepository(this._client);

  Future<List<WeatherForecastDay>> forecast(
    WeatherForecastRequest request,
  ) async {
    try {
      final response = await _client.get<dynamic>(
        '/weather/forecast',
        queryParameters: {
          'lat': request.lat,
          'lon': request.lon,
          'start_date': _dateOnly(request.startDate),
          'end_date': _dateOnly(request.endDate),
        },
      );
      return parseForecastDays(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  static List<WeatherForecastDay> parseForecastDays(dynamic raw) {
    final rawList = _readForecastList(raw);
    return rawList
        .whereType<Map>()
        .map(
          (item) =>
              WeatherForecastDay.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }

  static List<dynamic> _readForecastList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is! Map) return const <dynamic>[];

    final json = Map<String, dynamic>.from(raw);
    for (final key in ['daily', 'days', 'items']) {
      final value = json[key];
      if (value is List) return value;
    }

    // The backend also returns a human-readable `forecast` string. That field is
    // intentionally not parsed as a list; day cards come from `daily`.
    return const <dynamic>[];
  }

  String _dateOnly(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }
}
