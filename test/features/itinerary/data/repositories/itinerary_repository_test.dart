import 'package:flutter_test/flutter_test.dart';

import 'package:ruta_viva/features/itinerary/data/models/itinerary_model.dart';

const _itineraryJson = <String, dynamic>{
  'id': 'itin-xyz-789',
  'tourist_id': 'user-123',
  'title': 'Tour por la Araucanía',
  'start_date': '2025-03-01',
  'end_date': '2025-03-03',
  'status': 'active',
  'steps': <dynamic>[
    <String, dynamic>{
      'id': 'step-1',
      'itinerary_id': 'itin-xyz-789',
      'poi_id': 'poi-abc-123',
      'poi_name': 'Volcán Villarrica',
      'poi_description': 'Volcán activo',
      'step_order': 1,
      'arrival_time': '2025-03-01T10:00:00Z',
      'departure_time': '2025-03-01T14:00:00Z',
      'day_index': 1,
      'day_date': '2025-03-01',
      'day_label': 'Sábado 1',
      'created_at': '2026-05-22T10:00:00-04:00',
      'updated_at': '2026-05-22T11:00:00-04:00',
      'ai_context': <String, dynamic>{
        'title': 'Ascenso al Volcán',
        'reason': 'Experiencia única en la región',
        'tips': 'Llevar ropa térmica',
        'recommended_duration': '4 horas',
      },
    },
    <String, dynamic>{
      'id': 'step-2',
      'itinerary_id': 'itin-xyz-789',
      'poi_id': 'poi-def-456',
      'poi_name': null,
      'poi_description': null,
      'step_order': 2,
      'arrival_time': null,
      'departure_time': null,
      'day_index': null,
      'day_date': null,
      'day_label': null,
      'ai_context': null,
    },
  ],
};

void main() {
  group('ItineraryModel.fromJson', () {
    test('parses itinerary with steps', () {
      final itinerary = ItineraryModel.fromJson(_itineraryJson);

      expect(itinerary.id, equals('itin-xyz-789'));
      expect(itinerary.touristId, equals('user-123'));
      expect(itinerary.title, equals('Tour por la Araucanía'));
      expect(itinerary.status, equals('active'));
      expect(itinerary.startDate, equals(DateTime(2025, 3, 1)));
      expect(itinerary.endDate, equals(DateTime(2025, 3, 3)));
      expect(itinerary.isPast, isFalse);
      expect(itinerary.isEditable, isTrue);
      expect(itinerary.steps.length, equals(2));
    });

    test('parses backend read-only flags', () {
      final json = Map<String, dynamic>.from(_itineraryJson)
        ..['is_past'] = true
        ..['is_editable'] = false;

      final itinerary = ItineraryModel.fromJson(json);

      expect(itinerary.isPast, isTrue);
      expect(itinerary.isEditable, isFalse);
      expect(itinerary.toJson()['is_past'], isTrue);
      expect(itinerary.toJson()['is_editable'], isFalse);
    });

    test('falls back to non-editable for completed or cancelled status', () {
      final completed = ItineraryModel.fromJson({
        ..._itineraryJson,
        'status': 'completed',
      });
      final cancelled = ItineraryModel.fromJson({
        ..._itineraryJson,
        'status': 'cancelled',
      });

      expect(completed.isEditable, isFalse);
      expect(cancelled.isEditable, isFalse);
    });

    test('parses step with full ai_context', () {
      final itinerary = ItineraryModel.fromJson(_itineraryJson);
      final step = itinerary.steps[0];

      expect(step.id, equals('step-1'));
      expect(step.itineraryId, equals('itin-xyz-789'));
      expect(step.poiId, equals('poi-abc-123'));
      expect(step.poiName, equals('Volcán Villarrica'));
      expect(step.poiDescription, equals('Volcán activo'));
      expect(step.stepOrder, equals(1));
      expect(step.arrivalTime, equals(DateTime(2025, 3, 1, 10, 0, 0)));
      expect(step.departureTime, equals(DateTime(2025, 3, 1, 14, 0, 0)));
      expect(step.dayIndex, equals(1));
      expect(step.dayDate, equals(DateTime(2025, 3, 1)));
      expect(step.dayLabel, equals('Sábado 1'));
      expect(step.createdAt, equals(DateTime(2026, 5, 22, 10)));
      expect(step.updatedAt, equals(DateTime(2026, 5, 22, 11)));
      expect(step.aiContext, isNotNull);

      expect(step.title, equals('Ascenso al Volcán'));
      expect(step.reason, equals('Experiencia única en la región'));
      expect(step.tips, equals('Llevar ropa térmica'));
      expect(step.recommendedDuration, equals('4 horas'));
    });

    test('step falls back without ai_context', () {
      final itinerary = ItineraryModel.fromJson(_itineraryJson);
      final step = itinerary.steps[1];

      expect(step.title, equals('Parada 2'));
      expect(
        step.reason,
        equals('Lugar seleccionado por Ara para este recorrido.'),
      );
      expect(step.tips, isEmpty);
      expect(step.recommendedDuration, isEmpty);
      expect(step.arrivalTime, isNull);
      expect(step.departureTime, isNull);
    });

    test('step fallback uses poiName when available without ai_context', () {
      final json = Map<String, dynamic>.from(_itineraryJson);
      json['steps'] = <dynamic>[
        <String, dynamic>{
          'id': 'step-3',
          'itinerary_id': 'itin-xyz-789',
          'poi_id': 'poi-ghi-789',
          'poi_name': 'Lago Villarrica',
          'poi_description': 'Hermoso lago',
          'step_order': 3,
          'arrival_time': null,
          'departure_time': null,
          'day_index': null,
          'day_date': null,
          'day_label': null,
          'ai_context': null,
        },
      ];
      final itinerary = ItineraryModel.fromJson(json);
      final step = itinerary.steps[0];

      expect(step.title, equals('Lago Villarrica'));
      expect(step.reason, equals('Hermoso lago'));
    });

    test('handles null dates gracefully', () {
      final json = Map<String, dynamic>.from(_itineraryJson)
        ..['start_date'] = null
        ..['end_date'] = null;
      final itinerary = ItineraryModel.fromJson(json);

      expect(itinerary.startDate, isNull);
      expect(itinerary.endDate, isNull);
    });

    test('handles invalid date strings gracefully', () {
      final json = Map<String, dynamic>.from(_itineraryJson)
        ..['start_date'] = 'not-a-date';
      final itinerary = ItineraryModel.fromJson(json);

      expect(itinerary.startDate, isNull);
    });

    test('handles empty steps list', () {
      final json = Map<String, dynamic>.from(_itineraryJson)
        ..['steps'] = <dynamic>[];
      final itinerary = ItineraryModel.fromJson(json);

      expect(itinerary.steps, isEmpty);
    });

    test('handles missing steps key', () {
      final json = Map<String, dynamic>.from(_itineraryJson)..remove('steps');
      final itinerary = ItineraryModel.fromJson(json);

      expect(itinerary.steps, isEmpty);
    });

    test('toJson round-trips scalar fields', () {
      final itinerary = ItineraryModel.fromJson(_itineraryJson);
      final json = itinerary.toJson();

      expect(json['id'], equals('itin-xyz-789'));
      expect(json['tourist_id'], equals('user-123'));
      expect(json['title'], equals('Tour por la Araucanía'));
      expect(json['status'], equals('active'));
    });

    test('toJson round-trips steps with ai_context', () {
      final itinerary = ItineraryModel.fromJson(_itineraryJson);
      final json = itinerary.toJson();

      final steps = json['steps'] as List<dynamic>;
      expect(steps.length, equals(2));
      final step1 = steps[0] as Map<String, dynamic>;
      expect(step1['id'], equals('step-1'));
      expect(step1['day_label'], equals('Sábado 1'));
      expect(step1['ai_context']['title'], equals('Ascenso al Volcán'));
    });

    test('step toJson includes all fields', () {
      final itinerary = ItineraryModel.fromJson(_itineraryJson);
      final stepJson = itinerary.steps[0].toJson();

      expect(stepJson['id'], equals('step-1'));
      expect(stepJson['itinerary_id'], equals('itin-xyz-789'));
      expect(stepJson['poi_id'], equals('poi-abc-123'));
      expect(stepJson['step_order'], equals(1));
      expect(stepJson['day_index'], equals(1));
      expect(stepJson['day_date'], equals('2025-03-01'));
      expect(stepJson['day_label'], equals('Sábado 1'));
      expect(stepJson['created_at'], startsWith('2026-05-22T10:00:00'));
      expect(stepJson['updated_at'], startsWith('2026-05-22T11:00:00'));
      expect(stepJson['ai_context']['tips'], equals('Llevar ropa térmica'));
    });

    test(
      'parses backend Chile timezone fields as local itinerary wall time',
      () {
        final json = Map<String, dynamic>.from(_itineraryJson);
        json['steps'] = <dynamic>[
          <String, dynamic>{
            'id': 'step-tz',
            'itinerary_id': 'itin-xyz-789',
            'poi_id': 'poi-tz',
            'poi_name': 'Termas',
            'poi_description': 'Relajo nocturno',
            'step_order': 1,
            'arrival_time': '2026-05-18T09:00:00-04:00',
            'departure_time': '2026-05-18T11:00:00-04:00',
            'day_index': 1,
            'day_date': '2026-05-18',
            'day_label': 'Lunes 18',
            'ai_context': null,
          },
        ];

        final step = ItineraryModel.fromJson(json).steps.single;

        expect(step.arrivalTime, equals(DateTime(2026, 5, 18, 9)));
        expect(step.departureTime, equals(DateTime(2026, 5, 18, 11)));
        expect(step.dayDate, equals(DateTime(2026, 5, 18)));
        expect(step.dayLabel, equals('Lunes 18'));
      },
    );
  });

  group('PaginatedItinerariesModel', () {
    test('parses paginated backend response', () {
      final page = PaginatedItinerariesModel.fromJson({
        'items': [_itineraryJson],
        'total': 42,
        'page': 1,
        'page_size': 20,
        'total_pages': 3,
      });

      expect(page.items.single.id, equals('itin-xyz-789'));
      expect(page.total, equals(42));
      expect(page.page, equals(1));
      expect(page.pageSize, equals(20));
      expect(page.totalPages, equals(3));
    });
  });

  group('ItineraryStepWeatherModel', () {
    test('parses available weather item', () {
      final item = ItineraryStepWeatherModel.fromJson({
        'step_id': 'step-1',
        'poi_id': 'poi-1',
        'poi_name': 'Mirador',
        'day_date': '2026-06-02',
        'weather_available': true,
        'weather_status': 'available',
        'weather_message': null,
        'weather': {
          'description': 'Soleado',
          'temperature_c': 20,
          'precipitation_probability': 10,
        },
      });

      expect(item.stepId, equals('step-1'));
      expect(item.poiId, equals('poi-1'));
      expect(item.poiName, equals('Mirador'));
      expect(item.dayDate, equals(DateTime(2026, 6, 2)));
      expect(item.weatherAvailable, isTrue);
      expect(item.weatherStatus, equals('available'));
      expect(item.weatherMessage, isNull);
      expect(item.weather?.description, equals('Soleado'));
      expect(item.weather?.temperatureC, equals(20));
      expect(item.weather?.precipitationProbability, equals(10));
    });

    test('parses non-available weather statuses without weather object', () {
      final item = ItineraryStepWeatherModel.fromJson({
        'step_id': 'step-2',
        'poi_id': 'poi-2',
        'poi_name': null,
        'day_date': null,
        'weather_available': false,
        'weather_status': 'out_of_range',
        'weather_message':
            'El pronóstico detallado estará disponible más cerca de la fecha del viaje.',
        'weather': null,
      });

      expect(item.weatherAvailable, isFalse);
      expect(item.weatherStatus, equals('out_of_range'));
      expect(item.weatherMessage, contains('pronóstico detallado'));
      expect(item.weather, isNull);
    });
  });

  group('Itinerary visits and export models', () {
    test('parses StepVisitModel', () {
      final visit = StepVisitModel.fromJson({
        'id': 'visit-1',
        'step_id': 'step-1',
        'poi_id': 'poi-1',
        'visited_at': '2026-05-22T14:30:00-04:00',
        'source': 'itinerary',
        'note': null,
      });

      expect(visit.id, equals('visit-1'));
      expect(visit.stepId, equals('step-1'));
      expect(visit.poiId, equals('poi-1'));
      expect(visit.visitedAt, equals(DateTime(2026, 5, 22, 14, 30)));
      expect(visit.source, equals('itinerary'));
      expect(visit.note, isNull);
    });

    test('parses ItineraryExportModel', () {
      final export = ItineraryExportModel.fromJson({
        'title': 'Mi viaje a Pucón',
        'start_date': '2026-05-22',
        'end_date': '2026-05-24',
        'steps': [
          {
            'day': 1,
            'date': '2026-05-22',
            'order': 1,
            'poi_name': 'Volcán Villarrica',
            'poi_description': 'Volcán activo',
            'poi_address': 'Ruta volcán',
            'arrival_time': '09:00',
            'departure_time': '12:00',
            'tips': 'Llevar ropa de abrigo',
            'weather': {'description': 'Frío'},
            'latitude': -39.2,
            'longitude': -71.9,
          },
        ],
        'total_days': 3,
        'total_steps': 15,
        'generated_at': '2026-05-22T10:00:00-04:00',
      });

      expect(export.title, equals('Mi viaje a Pucón'));
      expect(export.totalDays, equals(3));
      expect(export.totalSteps, equals(15));
      expect(export.generatedAt, equals(DateTime(2026, 5, 22, 10)));
      expect(export.steps.single.poiName, equals('Volcán Villarrica'));
      expect(export.steps.single.weather?['description'], equals('Frío'));
    });

    test('parses ItineraryShareModel', () {
      final share = ItineraryShareModel.fromJson({
        'share_url': '/share/abc123',
        'public_id': 'abc123',
      });

      expect(share.shareUrl, equals('/share/abc123'));
      expect(share.publicId, equals('abc123'));
    });
  });
}
