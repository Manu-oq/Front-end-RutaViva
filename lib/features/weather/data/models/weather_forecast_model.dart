class WeatherForecastDay {
  final DateTime date;
  final String? label;
  final double? minTempC;
  final double? maxTempC;
  final double? precipitationMm;
  final int? precipitationProbability;
  final String? summary;

  const WeatherForecastDay({
    required this.date,
    this.label,
    this.minTempC,
    this.maxTempC,
    this.precipitationMm,
    this.precipitationProbability,
    this.summary,
  });

  factory WeatherForecastDay.fromJson(Map<String, dynamic> json) {
    return WeatherForecastDay(
      date:
          DateTime.tryParse(
            (json['date'] ?? json['day'] ?? json['forecast_date']).toString(),
          ) ??
          DateTime.now(),
      label: (json['label'] ?? json['date_label'])?.toString(),
      minTempC: _readDouble(json, [
        'min_temp_c',
        'temperature_min',
        'temp_min',
        'min_temp',
      ]),
      maxTempC: _readDouble(json, [
        'max_temp_c',
        'temperature_max',
        'temp_max',
        'max_temp',
        'temperature',
        'temperature_c',
      ]),
      precipitationMm: _readDouble(json, [
        'precipitation_mm',
        'rain_mm',
        'precipitation',
      ]),
      precipitationProbability: _readInt(json, [
        'precipitation_probability',
        'precipitation_chance',
        'rain_probability',
      ]),
      summary: (json['summary'] ?? json['condition'] ?? json['description'])
          ?.toString(),
    );
  }

  static double? _readDouble(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
    }
    return null;
  }

  static int? _readInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.round();
      if (value is String) return int.tryParse(value);
    }
    return null;
  }
}

class WeatherForecastRequest {
  final double lat;
  final double lon;
  final DateTime startDate;
  final DateTime endDate;

  const WeatherForecastRequest({
    required this.lat,
    required this.lon,
    required this.startDate,
    required this.endDate,
  });

  @override
  bool operator ==(Object other) {
    return other is WeatherForecastRequest &&
        other.lat == lat &&
        other.lon == lon &&
        _dateOnly(other.startDate) == _dateOnly(startDate) &&
        _dateOnly(other.endDate) == _dateOnly(endDate);
  }

  @override
  int get hashCode =>
      Object.hash(lat, lon, _dateOnly(startDate), _dateOnly(endDate));

  static String _dateOnly(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }
}
