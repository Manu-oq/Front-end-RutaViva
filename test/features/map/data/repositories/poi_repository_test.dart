import 'package:flutter_test/flutter_test.dart';

import 'package:ruta_viva/features/map/data/models/poi_model.dart';
import 'package:ruta_viva/features/map/data/repositories/poi_repository.dart';
import 'package:ruta_viva/features/map/domain/entities/map_point.dart';

const _poiJson = <String, dynamic>{
  'id': 'poi-abc-123',
  'name': 'Volcán Villarrica',
  'description': 'Volcán activo en la Araucanía',
  'access_type': 'public',
  'contact_phone': '+56912345678',
  'contact_email': 'info@villarrica.cl',
  'multimedia_urls': <String, dynamic>{'cover': '/media/covers/villarrica.jpg'},
  'category_ids': <int>[1, 2],
  'latitude': -39.4208,
  'longitude': -71.9392,
  'distance_meters': 5000.5,
};

void main() {
  group('PoiModel.fromJson', () {
    test('parses all fields from search response fixture', () {
      final poi = PoiModel.fromJson(_poiJson);

      expect(poi.id, equals('poi-abc-123'));
      expect(poi.name, equals('Volcán Villarrica'));
      expect(poi.description, equals('Volcán activo en la Araucanía'));
      expect(poi.accessType, equals('public'));
      expect(poi.contactPhone, equals('+56912345678'));
      expect(poi.contactEmail, equals('info@villarrica.cl'));
      expect(poi.categoryIds, equals([1, 2]));
      expect(poi.latitude, equals(-39.4208));
      expect(poi.longitude, equals(-71.9392));
      expect(poi.distanceMeters, equals(5000.5));
    });

    test('handles null optional fields', () {
      final json = Map<String, dynamic>.from(_poiJson)
        ..['contact_phone'] = null
        ..['contact_email'] = null
        ..['distance_meters'] = null
        ..['multimedia_urls'] = null;
      final poi = PoiModel.fromJson(json);

      expect(poi.contactPhone, isNull);
      expect(poi.contactEmail, isNull);
      expect(poi.distanceMeters, isNull);
      expect(poi.multimediaUrls, isNull);
    });

    test('toMapPoint produces MapPoint with all scalar fields', () {
      final poi = PoiModel.fromJson(_poiJson);
      final point = poi.toMapPoint();

      expect(point, isA<MapPoint>());
      expect(point.id, equals('poi-abc-123'));
      expect(point.name, equals('Volcán Villarrica'));
      expect(point.description, equals('Volcán activo en la Araucanía'));
      expect(point.coordinates.latitude, equals(-39.4208));
      expect(point.coordinates.longitude, equals(-71.9392));
      expect(point.distanceMeters, equals(5000.5));
      expect(point.phone, equals('+56912345678'));
      expect(point.email, equals('info@villarrica.cl'));
      expect(point.categoryIds, equals([1, 2]));
    });

    test('toMapPoint resolves cover image from multimedia_urls map', () {
      final poi = PoiModel.fromJson(_poiJson);
      final point = poi.toMapPoint();

      expect(point.imageUrl, isNotNull);
      expect(point.imageUrl, contains('/media/covers/villarrica.jpg'));
    });

    test('handles multimedia_urls as list of strings', () {
      final json = Map<String, dynamic>.from(_poiJson)
        ..['multimedia_urls'] = <String>[
          'https://example.com/image1.jpg',
          'https://example.com/image2.jpg',
        ];
      final poi = PoiModel.fromJson(json);
      final point = poi.toMapPoint();

      expect(point.imageUrl, equals('https://example.com/image1.jpg'));
    });

    test('latitude and longitude parsed from int values', () {
      final json = Map<String, dynamic>.from(_poiJson)
        ..['latitude'] = -39
        ..['longitude'] = -72;
      final poi = PoiModel.fromJson(json);

      expect(poi.latitude, equals(-39.0));
      expect(poi.longitude, equals(-72.0));
    });

    test('missing category_ids key defaults to empty list', () {
      final json = Map<String, dynamic>.from(_poiJson)..remove('category_ids');
      final poi = PoiModel.fromJson(json);

      expect(poi.categoryIds, isEmpty);
    });
  });

  group('PoiRepository.searchNearby query', () {
    test('omits category_ids when filters are empty', () {
      final query = PoiRepository.searchNearbyQueryParametersForTesting(
        lat: -38.7359,
        lon: -72.5904,
        radius: 30000,
      );

      expect(query['lat'], equals(-38.7359));
      expect(query['lon'], equals(-72.5904));
      expect(query['radius'], equals(30000));
      expect(query.containsKey('category_ids'), isFalse);
    });

    test('serializes category filters as comma separated ids', () {
      final query = PoiRepository.searchNearbyQueryParametersForTesting(
        lat: -38.7359,
        lon: -72.5904,
        radius: 30000,
        categoryIds: const [2, 4, 9],
      );

      expect(query['category_ids'], equals('2,4,9'));
    });
  });

  group('PoiRepository POI request bodies', () {
    test('create body uses backend English contract only', () {
      final body = PoiRepository.createPoiRequestBodyForTesting(
        name: 'Café del Lago',
        description: 'Café local con productos regionales',
        accessType: 'public',
        imageUrl: 'https://example.com/cafe.jpg',
        latitude: -39.27,
        longitude: -71.97,
        contactPhone: '',
        contactEmail: 'hola@example.com',
        categoryIds: const [1, 2],
      );

      expect(body['name'], equals('Café del Lago'));
      expect(
        body['description'],
        equals('Café local con productos regionales'),
      );
      expect(body['access_type'], equals('public'));
      expect(body['image_url'], equals('https://example.com/cafe.jpg'));
      expect(body['contact_phone'], isNull);
      expect(body['contact_email'], equals('hola@example.com'));
      expect(body['category_ids'], equals([1, 2]));
      expect(body['latitude'], equals(-39.27));
      expect(body['longitude'], equals(-71.97));
      expect(body.keys, isNot(contains('nombre')));
      expect(body.keys, isNot(contains('descripcion')));
      expect(body.keys, isNot(contains('tipo_acceso')));
      expect(body.keys, isNot(contains('telefono_publico')));
      expect(body.keys, isNot(contains('email_publico')));
      expect(body.keys, isNot(contains('multimedia_urls')));
    });

    test('update body sends latitude and longitude together', () {
      final body = PoiRepository.updatePoiRequestBodyForTesting(
        name: 'Sendero',
        description: 'Sendero con guía comunitaria',
        accessType: 'reservation',
        latitude: -39.1,
        longitude: -72.2,
      );

      expect(body['latitude'], equals(-39.1));
      expect(body['longitude'], equals(-72.2));
      expect(body.keys, isNot(contains('image_url')));
      expect(body.keys, isNot(contains('latitud')));
      expect(body.keys, isNot(contains('longitud')));
    });
  });
}
