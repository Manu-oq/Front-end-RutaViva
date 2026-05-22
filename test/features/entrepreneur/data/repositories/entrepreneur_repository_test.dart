import 'package:flutter_test/flutter_test.dart';

import 'package:ruta_viva/features/entrepreneur/data/models/entrepreneur_models.dart';

void main() {
  group('EntrepreneurPostModel.fromJson', () {
    test('parsea campos basicos desde JSON', () {
      final json = <String, dynamic>{
        'id': 'post-1',
        'entrepreneur_id': 'entrepreneur-1',
        'poi_id': 'poi-abc',
        'poi_name': 'Mi Negocio',
        'title': 'Gran apertura',
        'content': 'Estamos felices de anunciar...',
        'image_url': 'https://example.com/post.jpg',
        'is_published': true,
        'is_pinned': false,
        'created_at': '2025-01-15T10:00:00Z',
        'updated_at': '2025-01-16T11:00:00Z',
      };

      final post = EntrepreneurPostModel.fromJson(json);

      expect(post.id, equals('post-1'));
      expect(post.entrepreneurId, equals('entrepreneur-1'));
      expect(post.poiId, equals('poi-abc'));
      expect(post.poiName, equals('Mi Negocio'));
      expect(post.title, equals('Gran apertura'));
      expect(post.content, equals('Estamos felices de anunciar...'));
      expect(post.imageUrl, equals('https://example.com/post.jpg'));
      expect(post.isPublished, isTrue);
      expect(post.isPinned, isFalse);
      expect(post.createdAt, isA<DateTime>());
      expect(post.updatedAt, isA<DateTime>());
      expect(post.scheduledAt, isNull);
    });

    test('ignora aliases legacy place_id y place_name', () {
      final json = <String, dynamic>{
        'id': 'post-2',
        'place_id': 'place-xyz',
        'place_name': 'Mi Local',
        'title': 'Promocion especial',
        'content': 'Descuentos esta semana',
        'is_published': false,
      };

      final post = EntrepreneurPostModel.fromJson(json);

      expect(post.poiId, isNull);
      expect(post.poiName, isNull);
      expect(post.isPublished, isFalse);
    });

    test('usa valores por defecto para campos faltantes', () {
      final json = <String, dynamic>{'id': 'post-3', 'title': 'Sin contenido'};

      final post = EntrepreneurPostModel.fromJson(json);

      expect(post.poiId, isNull);
      expect(post.poiName, isNull);
      expect(post.content, isEmpty);
      expect(post.isPublished, isTrue);
      expect(post.isPinned, isFalse);
      expect(post.scheduledAt, isNull);
      expect(post.createdAt, isNull);
    });

    test('parsea scheduled_at como DateTime cuando esta presente', () {
      final json = <String, dynamic>{
        'id': 'post-4',
        'title': 'Programado',
        'content': 'Se publica manana',
        'is_published': false,
        'scheduled_at': '2025-06-01T08:00:00Z',
      };

      final post = EntrepreneurPostModel.fromJson(json);

      expect(post.scheduledAt, isA<DateTime>());
      expect(post.scheduledAt!.year, equals(2025));
      expect(post.scheduledAt!.month, equals(6));
      expect(post.scheduledAt!.day, equals(1));
    });

    test('maneja scheduled_at invalido como null', () {
      final json = <String, dynamic>{
        'id': 'post-5',
        'title': 'Fecha invalida',
        'content': 'test',
        'scheduled_at': 'no-es-fecha',
      };

      final post = EntrepreneurPostModel.fromJson(json);

      expect(post.scheduledAt, isNull);
    });

    test('maneja is_pinned desde la clave oficial', () {
      final json = <String, dynamic>{
        'id': 'post-6',
        'title': 'Fijado',
        'content': 'Importante',
        'is_pinned': true,
      };

      final post = EntrepreneurPostModel.fromJson(json);

      expect(post.isPinned, isTrue);
    });

    test('convierte id no string a string', () {
      final json = <String, dynamic>{
        'id': 42,
        'title': 'Post con id numerico',
        'content': 'test',
      };

      final post = EntrepreneurPostModel.fromJson(json);

      expect(post.id, equals('42'));
    });
  });

  group('EntrepreneurMetricsModel.fromJson', () {
    test('parsea todos los campos con claves principales', () {
      final json = <String, dynamic>{
        'places_count': 5,
        'visits_count': 120,
        'reviews_count': 45,
        'favorites_count': 30,
      };

      final metrics = EntrepreneurMetricsModel.fromJson(json);

      expect(metrics.placesCount, equals(5));
      expect(metrics.visitsCount, equals(120));
      expect(metrics.reviewsCount, equals(45));
      expect(metrics.favoritesCount, equals(30));
    });

    test('usa claves alternativas cuando las principales no existen', () {
      final json = <String, dynamic>{
        'pois_count': 10,
        'visits': 200,
        'reviews': 60,
        'favorites': 40,
      };

      final metrics = EntrepreneurMetricsModel.fromJson(json);

      expect(metrics.placesCount, equals(10));
      expect(metrics.visitsCount, equals(200));
      expect(metrics.reviewsCount, equals(60));
      expect(metrics.favoritesCount, equals(40));
    });

    test('usa clave places como alternativa de places_count', () {
      final json = <String, dynamic>{
        'places': 15,
        'visits_count': 300,
        'reviews_count': 80,
        'favorites_count': 50,
      };

      final metrics = EntrepreneurMetricsModel.fromJson(json);

      expect(metrics.placesCount, equals(15));
    });

    test('retorna 0 para campos faltantes', () {
      final json = <String, dynamic>{};

      final metrics = EntrepreneurMetricsModel.fromJson(json);

      expect(metrics.placesCount, equals(0));
      expect(metrics.visitsCount, equals(0));
      expect(metrics.reviewsCount, equals(0));
      expect(metrics.favoritesCount, equals(0));
    });

    test('parsea valores string como int', () {
      final json = <String, dynamic>{
        'places_count': '7',
        'visits_count': '150',
        'reviews_count': '33',
        'favorites_count': '12',
      };

      final metrics = EntrepreneurMetricsModel.fromJson(json);

      expect(metrics.placesCount, equals(7));
      expect(metrics.visitsCount, equals(150));
      expect(metrics.reviewsCount, equals(33));
      expect(metrics.favoritesCount, equals(12));
    });

    test('maneja string no numerico como 0', () {
      final json = <String, dynamic>{
        'places_count': 'no-numerico',
        'visits_count': 10,
        'reviews_count': 5,
        'favorites_count': 2,
      };

      final metrics = EntrepreneurMetricsModel.fromJson(json);

      expect(metrics.placesCount, equals(0));
    });
  });
}
