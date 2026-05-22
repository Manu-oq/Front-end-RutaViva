import 'package:flutter_test/flutter_test.dart';

import 'package:ruta_viva/features/map/data/models/poi_model.dart';

void main() {
  test('PoiModel parses itinerary filtered POI payload with visit rules', () {
    final poi = PoiModel.fromJson({
      'id': 'uuid',
      'name': 'Nombre del lugar',
      'description': 'Descripción del lugar',
      'access_type': 'public',
      'contact_phone': null,
      'contact_email': null,
      'multimedia_urls': <String, dynamic>{},
      'opening_hours_text': null,
      'visit_rules': {
        'is_primary_experience': true,
        'requires_daylight': true,
        'night_suitable': false,
        'latest_recommended_start_time': '15:30',
        'access_notes': 'Actividad outdoor con luz de día.',
        'confidence': 'inferred',
      },
      'category_ids': [1, 8],
      'latitude': -39.123,
      'longitude': -72.456,
      'distance_meters': null,
    });

    expect(poi.categoryIds, equals([1, 8]));
    expect(poi.visitRules?.isPrimaryExperience, isTrue);
    expect(poi.visitRules?.requiresDaylight, isTrue);
    expect(poi.visitRules?.latestRecommendedStartTime, equals('15:30'));

    final point = poi.toMapPoint();
    expect(point.visitRules?.confidence, equals('inferred'));
    expect(point.coordinates.latitude, equals(-39.123));
  });
}
