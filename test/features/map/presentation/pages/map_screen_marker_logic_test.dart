import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:ruta_viva/features/map/domain/entities/map_point.dart';
import 'package:ruta_viva/features/map/presentation/pages/map_screen.dart';

void main() {
  test('maxMarkers devuelve los mismos valores con y sin filtros', () {
    final expected = {'far': 42, 'medium': 80, 'near': 145};
    for (final density in ['far', 'medium', 'near']) {
      expect(
        MapScreenMarkerLogicForTesting.maxMarkers(
          density: density,
          hasCategoryFilters: false,
        ),
        equals(
          MapScreenMarkerLogicForTesting.maxMarkers(
            density: density,
            hasCategoryFilters: true,
          ),
        ),
      );
      expect(
        MapScreenMarkerLogicForTesting.maxMarkers(density: density),
        equals(expected[density]),
      );
    }
  });

  test('categoryVisualPriority para categorías 13 y 14 es 60 base', () {
    expect(MapScreenMarkerLogicForTesting.categoryVisualPriority(13), 60.0);
    expect(MapScreenMarkerLogicForTesting.categoryVisualPriority(14), 60.0);
  });

  test('visibleMarkers incluye focusedPoiId primero sin importar scoring', () {
    const center = LatLng(-39.35, -71.70);
    final points = [
      MapPoint(
        id: 'high-score-near',
        name: 'High Score Near',
        coordinates: center,
        categoryIds: const [1],
        imageUrl: '/image.jpg',
        visitRules: const MapPointVisitRules(isPrimaryExperience: true),
      ),
      MapPoint(
        id: 'focused-low-score',
        name: 'Focused Low Score',
        coordinates: const LatLng(-39.80, -72.10),
        categoryIds: const [99],
      ),
    ];

    final ids = MapScreenMarkerLogicForTesting.visibleMarkerIds(
      points: points,
      liveCameraCenter: center,
      focusedPoiId: 'focused-low-score',
      density: 'far',
    );

    expect(ids, isNotEmpty);
    expect(ids.first, equals('focused-low-score'));
    expect(ids, contains('focused-low-score'));
  });
}
