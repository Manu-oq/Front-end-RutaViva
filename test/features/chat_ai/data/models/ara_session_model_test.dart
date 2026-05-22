import 'package:flutter_test/flutter_test.dart';

import 'package:ruta_viva/features/chat_ai/data/models/ara_session_model.dart';

void main() {
  group('AraSessionModel', () {
    test('parses strongly typed session response fields', () {
      final session = AraSessionModel.fromJson({
        'session_id': 'session-1',
        'status': 'clarifying',
        'intent': {
          'intents': ['meal'],
          'primary_intent': 'meal',
          'specificity': 'specific',
          'locations': ['Pucón'],
          'turn_count': 3,
        },
        'preferences': {
          'tags': ['comida chilena', 'vegetariano'],
          'positive_preferences': ['algo tranquilo'],
          'negative_constraints': ['no quiero caminar mucho'],
          'completed_dimensions': ['meal'],
          'trip_draft': {
            'search_center': {'lat': -39.2, 'lon': -71.9, 'label': 'Pucón'},
          },
          'destination_scope': 'strict',
          'selected_poi_ids': ['poi-1', 'poi-2'],
          'conversation_mode': 'refinement',
          'route_ready_score': 0.65,
        },
        'candidate_pois': [
          {
            'id': 'poi-1',
            'name': 'Restaurant X',
            'description': 'Comida local',
            'category_ids': [2],
            'latitude': -39.2,
            'longitude': -71.9,
            'image_url': '/media/restaurant.png',
            'distance_meters': 1200.0,
            'poi_role': 'meal',
          },
        ],
        'active_itinerary_id': 'itinerary-1',
        'destination_context': {'lat': -39.2, 'lon': -71.9, 'label': 'Pucón'},
        'weather': {'description': 'Soleado', 'temperature_c': 22},
      });

      expect(session.sessionId, equals('session-1'));
      expect(session.intent?.primaryIntent, equals('meal'));
      expect(session.intent?.locations, equals(['Pucón']));
      expect(session.preferences?.tags, contains('vegetariano'));
      expect(session.preferences?.routeReadyScore, equals(0.65));
      expect(session.activeItineraryId, equals('itinerary-1'));
      expect(session.destinationContext?.label, equals('Pucón'));
      expect(session.weather?.temperatureC, equals(22));
      expect(session.candidatePois.single.poiRole, equals('meal'));
      expect(session.searchCenter?.label, equals('Pucón'));
      expect(session.assistantText, contains('1 lugares'));
    });

    test('does not require legacy top-level assistant_message', () {
      final session = AraSessionModel.fromJson({
        'session_id': 'session-2',
        'status': 'clarifying',
        'candidate_pois': <dynamic>[],
      });

      expect(session.assistantMessage, isNull);
      expect(
        session.assistantText,
        equals('Ara actualizó tu sesión de viaje.'),
      );
    });
  });
}
