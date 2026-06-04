import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruta_viva/features/categories/data/repositories/category_repository.dart';
import 'package:ruta_viva/features/map/data/models/poi_model.dart';
import 'package:ruta_viva/features/map/data/repositories/poi_repository.dart';
import 'package:ruta_viva/features/map/presentation/pages/my_contributions_page.dart';

PoiModel _poi({
  required String id,
  required String name,
  String verificationStatus = 'pending',
  DateTime? createdAt,
}) {
  return PoiModel(
    id: id,
    name: name,
    description: '$name description',
    accessType: 'public',
    categoryIds: const [1],
    latitude: -39.35,
    longitude: -71.70,
    verificationStatus: verificationStatus,
    createdAt: createdAt,
  );
}

void main() {
  testWidgets('lista vacía muestra empty state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myPoisProvider.overrideWith((_) async => []),
          categoriesProvider.overrideWith((_) async => []),
        ],
        child: const MaterialApp(home: MyContributionsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aún no tienes contribuciones'), findsOneWidget);
    expect(find.text('Mis contribuciones'), findsOneWidget);
  });

  testWidgets('lista con POIs muestra nombre/categoría/estado/Ver lugar', (
    tester,
  ) async {
    final pois = [
      _poi(id: 'p1', name: 'Río Quiliche', verificationStatus: 'verified'),
      _poi(id: 'p2', name: 'Salto Bonito', verificationStatus: 'pending'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myPoisProvider.overrideWith((_) async => pois),
          categoriesProvider.overrideWith((_) async => []),
        ],
        child: const MaterialApp(home: MyContributionsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Río Quiliche'), findsOneWidget);
    expect(find.text('Salto Bonito'), findsOneWidget);
    expect(find.text('Verificado'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('Ver lugar'), findsNWidgets(2));
  });

  testWidgets('<24h desde creación muestra botones Editar/Borrar', (
    tester,
  ) async {
    final recently = DateTime.now().subtract(const Duration(hours: 1));
    final pois = [_poi(id: 'p1', name: 'Nuevo POI', createdAt: recently)];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myPoisProvider.overrideWith((_) async => pois),
          categoriesProvider.overrideWith((_) async => []),
        ],
        child: const MaterialApp(home: MyContributionsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nuevo POI'), findsOneWidget);
    expect(find.text('Editar'), findsOneWidget);
    expect(find.text('Borrar'), findsOneWidget);
    expect(find.text('Ver lugar'), findsOneWidget);
    expect(find.text('Reportar error'), findsNothing);
    expect(find.text('Editable 23h más'), findsOneWidget);
  });

  testWidgets('>24h desde creación muestra botón Reportar error', (
    tester,
  ) async {
    final old =
        DateTime.now().subtract(const Duration(hours: 25));
    final pois = [_poi(id: 'p1', name: 'Antiguo POI', createdAt: old)];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myPoisProvider.overrideWith((_) async => pois),
          categoriesProvider.overrideWith((_) async => []),
        ],
        child: const MaterialApp(home: MyContributionsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Antiguo POI'), findsOneWidget);
    expect(find.text('Reportar error'), findsOneWidget);
    expect(find.text('Ver lugar'), findsOneWidget);
    expect(find.text('Editar'), findsNothing);
    expect(find.text('Borrar'), findsNothing);
    expect(find.text('Edición cerrada (24h)'), findsOneWidget);
  });

  testWidgets('createdAt null muestra Sin fecha y chip cerrado', (
    tester,
  ) async {
    final pois = [_poi(id: 'p1', name: 'Sin fecha POI', createdAt: null)];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myPoisProvider.overrideWith((_) async => pois),
          categoriesProvider.overrideWith((_) async => []),
        ],
        child: const MaterialApp(home: MyContributionsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sin fecha POI'), findsOneWidget);
    expect(find.text('Edición cerrada (24h)'), findsOneWidget);
    expect(find.text('Reportar error'), findsOneWidget);
  });

  testWidgets('delete invalida provider y refresca lista', (tester) async {
    final recently = DateTime.now().subtract(const Duration(hours: 1));
    final pois = [_poi(id: 'p1', name: 'Para Borrar POI', createdAt: recently)];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          myPoisProvider.overrideWith((_) async => pois),
          categoriesProvider.overrideWith((_) async => []),
          poiRepositoryProvider.overrideWith(
            (ref) => _FakePoiRepository(),
          ),
        ],
        child: const MaterialApp(home: MyContributionsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Para Borrar POI'), findsOneWidget);

    await tester.tap(find.text('Borrar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Quieres borrar "Para Borrar POI"?'), findsOneWidget);

    await tester.tap(find.text('Borrar').last);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

class _FakePoiRepository extends Fake implements PoiRepository {
  @override
  Future<void> deletePoi(String poiId) async {}
}
