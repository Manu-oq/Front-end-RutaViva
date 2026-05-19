import 'package:flutter_test/flutter_test.dart';
import 'package:ruta_viva/features/weather/data/repositories/weather_repository.dart';

void main() {
  group('WeatherRepository.parseForecastDays', () {
    test('parses backend daily response even when forecast is a string', () {
      final days = WeatherRepository.parseForecastDays({
        'lat': -39.2282277,
        'lon': -71.9545677,
        'start_date': '2026-05-18',
        'end_date': '2026-05-20',
        'daily': [
          {
            'date': '2026-05-19',
            'label': 'Martes 19',
            'description': 'Cielo claro',
            'temperature_c': 14,
            'precipitation_probability': 0,
          },
          {
            'date': '2026-05-20',
            'label': 'Miércoles 20',
            'description': 'Cielo claro',
            'temperature_c': 6,
            'precipitation_probability': 0,
          },
        ],
        'forecast': 'Martes 19: Cielo claro, 14°C.',
      });

      expect(days, hasLength(2));
      expect(days.first.label, 'Martes 19');
      expect(days.first.summary, 'Cielo claro');
      expect(days.first.maxTempC, 14);
      expect(days.first.precipitationProbability, 0);
    });

    test('ignores non-list forecast text safely', () {
      final days = WeatherRepository.parseForecastDays({
        'forecast': 'Sin detalle estructurado',
      });

      expect(days, isEmpty);
    });
  });
}
