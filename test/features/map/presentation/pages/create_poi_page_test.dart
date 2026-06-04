import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ruta_viva/core/network/dio_client.dart';
import 'package:ruta_viva/core/router/app_routes.dart';
import 'package:ruta_viva/features/categories/data/models/category_model.dart';
import 'package:ruta_viva/features/categories/data/repositories/category_repository.dart';
import 'package:ruta_viva/features/map/data/models/poi_model.dart';
import 'package:ruta_viva/features/map/data/repositories/poi_repository.dart';
import 'package:ruta_viva/features/map/presentation/pages/create_poi_page.dart';

void main() {
  testWidgets('turista deja contacto vacío y submit usa endpoint turista', (
    tester,
  ) async {
    final repo = _FakePoiRepository();
    await _pumpCreatePoi(tester, repo: repo, creationType: 'tourist');

    await _fillRequiredPoiFields(tester);
    await tester.tap(find.text('Publicar lugar'));
    await tester.pumpAndSettle();

    expect(repo.lastCreationType, equals('tourist'));
    expect(repo.lastEndpoint, equals('/pois/tourist/'));
    expect(repo.lastContactPhone, isNull);
    expect(repo.lastContactEmail, isNull);
  });

  testWidgets('emprendedor sin contacto muestra errores y no envía', (
    tester,
  ) async {
    final repo = _FakePoiRepository();
    await _pumpCreatePoi(tester, repo: repo, creationType: 'entrepreneur');

    await _fillRequiredPoiFields(tester);
    await tester.tap(find.text('Publicar lugar'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresa un teléfono público.'), findsOneWidget);
    expect(find.text('Ingresa un email público.'), findsOneWidget);
    expect(repo.createCallCount, isZero);
  });

  testWidgets('emprendedor con contacto válido envía correctamente', (
    tester,
  ) async {
    final repo = _FakePoiRepository();
    await _pumpCreatePoi(tester, repo: repo, creationType: 'entrepreneur');

    await _fillRequiredPoiFields(tester);
    await _fillValidEntrepreneurContact(tester);
    await tester.tap(find.text('Publicar lugar'));
    await tester.pumpAndSettle();

    expect(repo.createCallCount, equals(1));
    expect(repo.lastCreationType, equals('entrepreneur'));
    expect(repo.lastEndpoint, equals('/pois/entrepreneur/'));
    expect(repo.lastContactPhone, equals('+56912345678'));
    expect(repo.lastContactEmail, equals('test@domain.cl'));
  });

  testWidgets('teléfono chileno con espacios normaliza y valida OK', (
    tester,
  ) async {
    final repo = _FakePoiRepository();
    await _pumpCreatePoi(tester, repo: repo, creationType: 'entrepreneur');

    await _fillRequiredPoiFields(tester);
    await _scrollToContact(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Teléfono público obligatorio'),
      '+56 9 1234 5678',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email público obligatorio'),
      'local@test.cl',
    );
    await tester.tap(find.text('Publicar lugar'));
    await tester.pumpAndSettle();

    expect(repo.lastCreationType, equals('entrepreneur'));
    expect(repo.lastEndpoint, equals('/pois/entrepreneur/'));
    expect(repo.lastContactPhone, equals('+56912345678'));
  });

  testWidgets('teléfono chileno corto se rechaza', (tester) async {
    final repo = _FakePoiRepository();
    await _pumpCreatePoi(tester, repo: repo, creationType: 'entrepreneur');

    await _fillRequiredPoiFields(tester);
    await _scrollToContact(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Teléfono público obligatorio'),
      '+569123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email público obligatorio'),
      'test@domain.cl',
    );
    await tester.tap(find.text('Publicar lugar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Usa formato chileno: +56 seguido de 9 a 11 dígitos.'),
      findsOneWidget,
    );
    expect(repo.createCallCount, isZero);
  });

  testWidgets('email test@domain.cl se acepta', (tester) async {
    final repo = _FakePoiRepository();
    await _pumpCreatePoi(tester, repo: repo, creationType: 'entrepreneur');

    await _fillRequiredPoiFields(tester);
    await _fillValidEntrepreneurContact(tester);
    await tester.tap(find.text('Publicar lugar'));
    await tester.pumpAndSettle();

    expect(repo.createCallCount, equals(1));
    expect(repo.lastContactEmail, equals('test@domain.cl'));
  });

  testWidgets('email corto a@b.c se rechaza con regex robusto', (tester) async {
    final repo = _FakePoiRepository();
    await _pumpCreatePoi(tester, repo: repo, creationType: 'entrepreneur');

    await _fillRequiredPoiFields(tester);
    await _scrollToContact(tester);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Teléfono público obligatorio'),
      '+56912345678',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email público obligatorio'),
      'a@b.c',
    );
    await tester.tap(find.text('Publicar lugar'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresa un email válido.'), findsOneWidget);
    expect(repo.createCallCount, isZero);
  });

  testWidgets('creationType inválido se comporta como turista', (tester) async {
    final repo = _FakePoiRepository();
    await _pumpCreatePoi(tester, repo: repo, creationType: 'invalid');

    await _fillRequiredPoiFields(tester);
    await tester.tap(find.text('Publicar lugar'));
    await tester.pumpAndSettle();

    expect(repo.lastCreationType, equals('tourist'));
    expect(repo.lastEndpoint, equals('/pois/tourist/'));
  });

  testWidgets('lat/lon no-numéricos muestran error banner', (tester) async {
    final repo = _FakePoiRepository();
    await _pumpCreatePoi(tester, repo: repo, creationType: 'tourist');

    await _fillRequiredPoiFields(tester);
    await tester.enterText(
      find.byKey(const ValueKey('coordinate_lat_field'), skipOffstage: false),
      'latitud',
    );
    await tester.enterText(
      find.byKey(const ValueKey('coordinate_lon_field'), skipOffstage: false),
      'longitud',
    );
    await tester.tap(find.text('Publicar lugar'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Revisa la ubicación: latitud y longitud deben ser números válidos.',
      ),
      findsOneWidget,
    );
    expect(repo.createCallCount, isZero);
  });
}

Future<void> _pumpCreatePoi(
  WidgetTester tester, {
  required _FakePoiRepository repo,
  required String creationType,
}) async {
  tester.view.physicalSize = const Size(900, 1600);
  tester.view.devicePixelRatio = 1.0;

  final router = GoRouter(
    initialLocation: '/create',
    routes: [
      GoRoute(
        path: '/create',
        name: AppRouteNames.createPoi,
        builder: (context, state) => CreatePoiPage(creationType: creationType),
      ),
      GoRoute(
        path: '/poi/:id',
        name: AppRouteNames.poiDetail,
        builder: (context, state) => const Scaffold(body: Text('Detalle POI')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        categoriesProvider.overrideWith((ref) async => _categories),
        poiRepositoryProvider.overrideWith((ref) => repo),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _fillRequiredPoiFields(WidgetTester tester) async {
  await tester.enterText(find.byType(TextFormField).at(0), 'Lugar Test');
  await tester.enterText(
    find.byType(TextFormField).at(1),
    'Descripción suficientemente larga para validar el formulario.',
  );
  await tester.tap(find.text('Naturaleza'));
  await tester.pumpAndSettle();
}

Future<void> _scrollToContact(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Contacto del negocio'));
  await tester.pumpAndSettle();
}

Future<void> _fillValidEntrepreneurContact(WidgetTester tester) async {
  await _scrollToContact(tester);
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Teléfono público obligatorio'),
    '+56 9 1234 5678',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Email público obligatorio'),
    'test@domain.cl',
  );
}

const _categories = [
  CategoryModel(id: 1, name: 'Naturaleza'),
  CategoryModel(id: 13, name: 'Baños'),
];

class _FakePoiRepository extends PoiRepository {
  int createCallCount = 0;
  String? lastCreationType;
  String? lastContactPhone;
  String? lastContactEmail;

  _FakePoiRepository() : super(DioClient(Dio()));

  String? get lastEndpoint => lastCreationType == null
      ? null
      : PoiRepository.createPoiEndpointForTesting(lastCreationType!);

  @override
  Future<PoiModel> createPoi({
    required String creationType,
    required String name,
    required String description,
    required String accessType,
    required String imageUrl,
    required double latitude,
    required double longitude,
    String? contactPhone,
    String? contactEmail,
    List<int> categoryIds = const [],
  }) async {
    createCallCount++;
    lastCreationType = creationType;
    lastContactPhone = contactPhone;
    lastContactEmail = contactEmail;
    return PoiModel(
      id: 'poi-created',
      name: name,
      description: description,
      accessType: accessType,
      contactPhone: contactPhone,
      contactEmail: contactEmail,
      imageUrl: imageUrl,
      categoryIds: categoryIds,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<List<PoiModel>> searchNearby({
    required double lat,
    required double lon,
    double radius = 30000,
    List<int> categoryIds = const [],
  }) async {
    return const [];
  }
}
