import 'package:flutter_test/flutter_test.dart';

import 'package:ruta_viva/features/entrepreneur/data/models/entrepreneur_models.dart';

void main() {
  group('EntrepreneurPostModel', () {
    test('fromJson con titulo por defecto cuando title es null', () {
      final json = <String, dynamic>{
        'id': 'post-10',
        'content': 'contenido de prueba',
      };

      final post = EntrepreneurPostModel.fromJson(json);

      expect(post.title, equals('Publicación'));
    });

    test('fromJson lee content desde contrato oficial', () {
      final json = <String, dynamic>{
        'id': 'post-11',
        'title': 'Test',
        'content': 'contenido desde content',
      };

      final post = EntrepreneurPostModel.fromJson(json);

      expect(post.content, equals('contenido desde content'));
    });

    test('fromJson usa content como contrato oficial', () {
      final json = <String, dynamic>{
        'id': 'post-12',
        'title': 'Test',
        'body': 'contenido legacy',
      };

      final post = EntrepreneurPostModel.fromJson(json);

      expect(post.content, isEmpty);
    });

    test('fromJson prioriza content e ignora aliases legacy', () {
      final json = <String, dynamic>{
        'id': 'post-13',
        'title': 'Test',
        'content': 'contenido principal',
        'body': 'contenido body',
        'description': 'contenido description',
      };

      final post = EntrepreneurPostModel.fromJson(json);

      expect(post.content, equals('contenido principal'));
    });

    test('const constructor funciona correctamente', () {
      const post = EntrepreneurPostModel(
        id: 'post-const',
        entrepreneurId: 'entrepreneur-1',
        poiId: 'poi-1',
        poiName: 'Negocio',
        title: 'Titulo',
        content: 'Contenido',
        imageUrl: 'https://example.com/post.jpg',
        isPublished: true,
        isPinned: true,
      );

      expect(post.id, equals('post-const'));
      expect(post.entrepreneurId, equals('entrepreneur-1'));
      expect(post.poiId, equals('poi-1'));
      expect(post.imageUrl, equals('https://example.com/post.jpg'));
      expect(post.isPinned, isTrue);
      expect(post.scheduledAt, isNull);
      expect(post.createdAt, isNull);
      expect(post.updatedAt, isNull);
    });
  });

  group('EntrepreneurMetricsModel', () {
    test('const constructor funciona correctamente', () {
      const metrics = EntrepreneurMetricsModel(
        placesCount: 10,
        visitsCount: 500,
        reviewsCount: 75,
        favoritesCount: 20,
      );

      expect(metrics.placesCount, equals(10));
      expect(metrics.visitsCount, equals(500));
      expect(metrics.reviewsCount, equals(75));
      expect(metrics.favoritesCount, equals(20));
    });

    test('fromJson prioriza claves principales sobre alternativas', () {
      final json = <String, dynamic>{
        'places_count': 5,
        'pois_count': 99,
        'places': 88,
        'visits_count': 100,
        'visits': 999,
        'reviews_count': 50,
        'reviews': 888,
        'favorites_count': 25,
        'favorites': 777,
      };

      final metrics = EntrepreneurMetricsModel.fromJson(json);

      expect(metrics.placesCount, equals(5));
      expect(metrics.visitsCount, equals(100));
      expect(metrics.reviewsCount, equals(50));
      expect(metrics.favoritesCount, equals(25));
    });

    test('fromJson maneja valores double redondeando a int', () {
      final json = <String, dynamic>{
        'places_count': 3.7,
        'visits_count': 150.2,
        'reviews_count': 42.9,
        'favorites_count': 10.1,
      };

      final metrics = EntrepreneurMetricsModel.fromJson(json);

      expect(metrics.placesCount, equals(4));
      expect(metrics.visitsCount, equals(150));
      expect(metrics.reviewsCount, equals(43));
      expect(metrics.favoritesCount, equals(10));
    });
  });

  group('EntrepreneurIncomeModel', () {
    test('fromJson parsea campos basicos', () {
      final json = <String, dynamic>{'total': 150000.0, 'currency': 'USD'};

      final income = EntrepreneurIncomeModel.fromJson(json);

      expect(income.total, equals(150000.0));
      expect(income.currency, equals('USD'));
      expect(income.isPlaceholder, isTrue);
    });

    test('fromJson usa amount como alternativa a total', () {
      final json = <String, dynamic>{'amount': 75000.5};

      final income = EntrepreneurIncomeModel.fromJson(json);

      expect(income.total, equals(75000.5));
    });

    test('fromJson usa income como alternativa a total', () {
      final json = <String, dynamic>{'income': 50000.0};

      final income = EntrepreneurIncomeModel.fromJson(json);

      expect(income.total, equals(50000.0));
    });

    test('fromJson usa CLP como moneda por defecto', () {
      final json = <String, dynamic>{'total': 100000.0};

      final income = EntrepreneurIncomeModel.fromJson(json);

      expect(income.currency, equals('CLP'));
    });

    test('fromJson detecta is_placeholder como false', () {
      final json = <String, dynamic>{
        'total': 100000.0,
        'is_placeholder': false,
      };

      final income = EntrepreneurIncomeModel.fromJson(json);

      expect(income.isPlaceholder, isFalse);
    });
  });

  group('PoiAnalyticsModel', () {
    test('fromJson parsea todos los campos', () {
      final json = <String, dynamic>{
        'visits_count': 200,
        'clicks_count': 350,
        'favorites_count': 45,
        'reviews_count': 30,
        'avg_rating': 4.5,
        'weekly_visits': 25,
        'monthly_growth': 12.5,
      };

      final analytics = PoiAnalyticsModel.fromJson(json);

      expect(analytics.visitsCount, equals(200));
      expect(analytics.clicksCount, equals(350));
      expect(analytics.favoritesCount, equals(45));
      expect(analytics.reviewsCount, equals(30));
      expect(analytics.avgRating, equals(4.5));
      expect(analytics.weeklyVisits, equals(25));
      expect(analytics.monthlyGrowth, equals(12.5));
    });

    test('fromJson usa claves alternativas', () {
      final json = <String, dynamic>{
        'visits': 150,
        'clicks': 300,
        'favorites': 40,
        'reviews': 25,
        'average_rating': 3.8,
        'visits_this_week': 18,
        'growth_percent': 8.3,
      };

      final analytics = PoiAnalyticsModel.fromJson(json);

      expect(analytics.visitsCount, equals(150));
      expect(analytics.clicksCount, equals(300));
      expect(analytics.favoritesCount, equals(40));
      expect(analytics.reviewsCount, equals(25));
      expect(analytics.avgRating, equals(3.8));
      expect(analytics.weeklyVisits, equals(18));
      expect(analytics.monthlyGrowth, equals(8.3));
    });

    test('fromJson maneja campos faltantes con valores por defecto', () {
      final json = <String, dynamic>{};

      final analytics = PoiAnalyticsModel.fromJson(json);

      expect(analytics.visitsCount, equals(0));
      expect(analytics.clicksCount, equals(0));
      expect(analytics.favoritesCount, equals(0));
      expect(analytics.reviewsCount, equals(0));
      expect(analytics.avgRating, equals(0));
      expect(analytics.weeklyVisits, equals(0));
      expect(analytics.monthlyGrowth, equals(0));
    });
  });

  group('PoiActivityEvent', () {
    test('fromJson parsea evento basico', () {
      final json = <String, dynamic>{
        'type': 'view',
        'timestamp': '2025-03-20T14:30:00Z',
        'data': <String, dynamic>{'user_id': 'u1'},
      };

      final event = PoiActivityEvent.fromJson(json);

      expect(event.type, equals('view'));
      expect(event.timestamp, isA<DateTime>());
      expect(event.timestamp.year, equals(2025));
      expect(event.data, equals({'user_id': 'u1'}));
    });

    test('fromJson usa event_type como alternativa a type', () {
      final json = <String, dynamic>{
        'event_type': 'click',
        'timestamp': '2025-03-20T14:30:00Z',
        'data': <String, dynamic>{},
      };

      final event = PoiActivityEvent.fromJson(json);

      expect(event.type, equals('click'));
    });

    test('fromJson usa created_at como alternativa a timestamp', () {
      final json = <String, dynamic>{
        'type': 'favorite',
        'created_at': '2025-04-01T09:00:00Z',
        'data': <String, dynamic>{},
      };

      final event = PoiActivityEvent.fromJson(json);

      expect(event.timestamp, isA<DateTime>());
    });

    test('fromJson usa extra como alternativa a data', () {
      final json = <String, dynamic>{
        'type': 'share',
        'timestamp': '2025-03-20T14:30:00Z',
        'extra': <String, dynamic>{'platform': 'whatsapp'},
      };

      final event = PoiActivityEvent.fromJson(json);

      expect(event.data, equals({'platform': 'whatsapp'}));
    });

    test('fromJson type por defecto es unknown', () {
      final json = <String, dynamic>{
        'timestamp': '2025-03-20T14:30:00Z',
        'data': <String, dynamic>{},
      };

      final event = PoiActivityEvent.fromJson(json);

      expect(event.type, equals('unknown'));
    });
  });
}
