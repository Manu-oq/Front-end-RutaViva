import 'package:flutter_test/flutter_test.dart';

import 'package:ruta_viva/features/map/data/models/poi_model.dart';
import 'package:ruta_viva/features/map/domain/entities/map_point.dart';

void main() {
  // Minimal JSON shaped like the backend POI payload. Only fields required by
  // PoiModel.fromJson are populated; the rest stay null/empty intentionally so
  // the test focuses on the category mapping behavior.
  Map<String, dynamic> baseJson({required List<int>? categoryIds}) {
    return <String, dynamic>{
      'id': 'poi-1',
      'name': 'Centro Cultural',
      'description': 'Espacio cultural en Pucón.',
      'access_type': 'public',
      'contact_phone': null,
      'contact_email': null,
      'multimedia_urls': null,
      'category_ids': categoryIds,
      'latitude': -39.27,
      'longitude': -71.97,
      'distance_meters': null,
      'opening_hours_text': 'Mo-Su 09:00-18:00',
      'visit_rules': {
        'is_primary_experience': true,
        'requires_daylight': true,
        'night_suitable': false,
        'latest_recommended_start_time': '15:30',
        'access_notes': 'Recomendado durante el día.',
        'confidence': 'inferred',
      },
    };
  }

  group('PoiModel.fromJson + toMapPoint', () {
    test('parses category_ids and preserves them on MapPoint', () {
      final json = baseJson(categoryIds: [2, 4]);

      final poi = PoiModel.fromJson(json);
      final point = poi.toMapPoint();

      expect(poi.categoryIds, equals([2, 4]));
      expect(point, isA<MapPoint>());
      expect(point.categoryIds, equals([2, 4]));
      // Nothing collapses categoryIds into a single value: R3 invariant.
      expect(point.categoryIds.length, equals(2));
      expect(poi.openingHoursText, equals('Mo-Su 09:00-18:00'));
      expect(poi.visitRules?.requiresDaylight, isTrue);
      expect(point.openingHoursText, equals('Mo-Su 09:00-18:00'));
      expect(
        point.visitRules?.accessNotes,
        equals('Recomendado durante el día.'),
      );
    });

    test('handles empty category_ids without crashing', () {
      final json = baseJson(categoryIds: <int>[]);

      final poi = PoiModel.fromJson(json);
      final point = poi.toMapPoint();

      expect(poi.categoryIds, isEmpty);
      expect(point.categoryIds, isEmpty);
    });

    test('treats missing category_ids key as empty list', () {
      final json = baseJson(categoryIds: null);

      final poi = PoiModel.fromJson(json);
      final point = poi.toMapPoint();

      expect(poi.categoryIds, isEmpty);
      expect(point.categoryIds, isEmpty);
    });

    test('MapPoint exposes categoryIds as the only category source', () {
      // R5 invariant: the removed `PointCategory` enum has NO replacement field
      // on MapPoint. The constructor here intentionally omits any `category:`
      // argument; if someone re-introduced the field this would still compile,
      // so we additionally assert that the public surface used by the app is
      // categoryIds, end-to-end.
      final point = MapPoint(
        id: 'poi-2',
        name: 'Lago',
        coordinates: PoiModel.fromJson(
          baseJson(categoryIds: [1]),
        ).toMapPoint().coordinates,
        categoryIds: const [1],
      );

      expect(point.categoryIds, equals([1]));
    });

    test('uses image_url as POI image source', () {
      final json = baseJson(categoryIds: [1])..['image_url'] = '/media/poi.jpg';

      final point = PoiModel.fromJson(json).toMapPoint();

      expect(point.imageUrl, contains('/media/poi.jpg'));
    });

    test('prioritizes image_url over multimedia_urls', () {
      final json = baseJson(categoryIds: [1])
        ..['image_url'] = '/media/primary.jpg'
        ..['multimedia_urls'] = {'cover': '/media/legacy.jpg'};

      final point = PoiModel.fromJson(json).toMapPoint();

      expect(point.imageUrl, contains('/media/primary.jpg'));
      expect(point.imageUrl, isNot(contains('/media/legacy.jpg')));
    });
  });
}
