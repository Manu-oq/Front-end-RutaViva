import 'package:flutter_test/flutter_test.dart';

import 'package:ruta_viva/features/map/data/models/poi_model.dart';
import 'package:ruta_viva/features/map/domain/entities/map_point.dart';

const _poiJson = <String, dynamic>{
  'id': 'poi-abc-123',
  'nombre': 'Volcán Villarrica',
  'descripcion': 'Volcán activo en la Araucanía',
  'tipo_acceso': 'publico',
  'telefono_publico': '+56912345678',
  'email_publico': 'info@villarrica.cl',
  'multimedia_urls': <String, dynamic>{
    'cover': '/media/covers/villarrica.jpg',
  },
  'category_ids': <int>[1, 2],
  'latitude': -39.4208,
  'longitude': -71.9392,
  'distancia_metros': 5000.5,
};

void main() {
  group('PoiModel.fromJson', () {
    test('parses all fields from search response fixture', () {
      final poi = PoiModel.fromJson(_poiJson);

      expect(poi.id, equals('poi-abc-123'));
      expect(poi.nombre, equals('Volcán Villarrica'));
      expect(poi.descripcion, equals('Volcán activo en la Araucanía'));
      expect(poi.tipoAcceso, equals('publico'));
      expect(poi.telefonoPublico, equals('+56912345678'));
      expect(poi.emailPublico, equals('info@villarrica.cl'));
      expect(poi.categoryIds, equals([1, 2]));
      expect(poi.latitude, equals(-39.4208));
      expect(poi.longitude, equals(-71.9392));
      expect(poi.distanciaMetros, equals(5000.5));
    });

    test('handles null optional fields', () {
      final json = Map<String, dynamic>.from(_poiJson)
        ..['telefono_publico'] = null
        ..['email_publico'] = null
        ..['distancia_metros'] = null
        ..['multimedia_urls'] = null;
      final poi = PoiModel.fromJson(json);

      expect(poi.telefonoPublico, isNull);
      expect(poi.emailPublico, isNull);
      expect(poi.distanciaMetros, isNull);
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
      final json = Map<String, dynamic>.from(_poiJson)
        ..remove('category_ids');
      final poi = PoiModel.fromJson(json);

      expect(poi.categoryIds, isEmpty);
    });
  });
}
