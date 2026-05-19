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
      'poi_nombre': 'Volcán Villarrica',
      'poi_descripcion': 'Volcán activo',
      'step_order': 1,
      'arrival_time': '2025-03-01T10:00:00Z',
      'departure_time': '2025-03-01T14:00:00Z',
      'day_index': 1,
      'day_date': '2025-03-01',
      'day_label': 'Sábado 1',
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
      'poi_nombre': null,
      'poi_descripcion': null,
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
      expect(itinerary.steps.length, equals(2));
    });

    test('parses step with full ai_context', () {
      final itinerary = ItineraryModel.fromJson(_itineraryJson);
      final step = itinerary.steps[0];

      expect(step.id, equals('step-1'));
      expect(step.itineraryId, equals('itin-xyz-789'));
      expect(step.poiId, equals('poi-abc-123'));
      expect(step.poiNombre, equals('Volcán Villarrica'));
      expect(step.poiDescripcion, equals('Volcán activo'));
      expect(step.stepOrder, equals(1));
      expect(step.arrivalTime, equals(DateTime(2025, 3, 1, 10, 0, 0)));
      expect(step.departureTime, equals(DateTime(2025, 3, 1, 14, 0, 0)));
      expect(step.dayIndex, equals(1));
      expect(step.dayDate, equals(DateTime(2025, 3, 1)));
      expect(step.dayLabel, equals('Sábado 1'));
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

    test('step fallback uses poiNombre when available without ai_context', () {
      final json = Map<String, dynamic>.from(_itineraryJson);
      json['steps'] = <dynamic>[
        <String, dynamic>{
          'id': 'step-3',
          'itinerary_id': 'itin-xyz-789',
          'poi_id': 'poi-ghi-789',
          'poi_nombre': 'Lago Villarrica',
          'poi_descripcion': 'Hermoso lago',
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
            'poi_nombre': 'Termas',
            'poi_descripcion': 'Relajo nocturno',
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
}
