import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:ruta_viva/features/map/domain/entities/map_point.dart';
import 'package:ruta_viva/features/map/presentation/providers/map_provider.dart';

void main() {
  group('MapState', () {
    test('default state is empty', () {
      final state = MapState(
        points: const [],
        routePolyline: const [],
        center: araucaniaDefaultCenter,
      );

      expect(state.points, isEmpty);
      expect(state.routePolyline, isEmpty);
      expect(state.center, equals(araucaniaDefaultCenter));
      expect(state.selectedPoint, isNull);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('copyWith updates isLoading', () {
      final initialState = MapState(
        points: const [],
        routePolyline: const [],
        center: araucaniaDefaultCenter,
      );
      final updated = initialState.copyWith(isLoading: true);

      expect(updated.isLoading, isTrue);
      expect(updated.points, isEmpty);
    });

    test('copyWith clearSelection removes selectedPoint', () {
      final point = MapPoint(
        id: 'p1',
        name: 'Test',
        coordinates: const LatLng(-39, -71),
        categoryIds: const [],
      );
      final state = MapState(
        points: [point],
        routePolyline: [],
        center: araucaniaDefaultCenter,
        selectedPoint: point,
      );
      final updated = state.copyWith(clearSelection: true);

      expect(updated.selectedPoint, isNull);
    });

    test('copyWith clearError removes errorMessage', () {
      final state = MapState(
        points: [],
        routePolyline: [],
        center: araucaniaDefaultCenter,
        errorMessage: 'error',
      );
      final updated = state.copyWith(clearError: true);

      expect(updated.errorMessage, isNull);
    });

    test('copyWith updates center', () {
      final state = MapState(
        points: [],
        routePolyline: [],
        center: araucaniaDefaultCenter,
      );
      final newCenter = const LatLng(-38.0, -72.0);
      final updated = state.copyWith(center: newCenter);

      expect(updated.center, equals(newCenter));
    });
  });

  group('mapProvider', () {
    test('initial state has default center and empty collections', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(mapProvider);

      expect(state.points, isEmpty);
      expect(state.routePolyline, isEmpty);
      expect(state.center, equals(araucaniaDefaultCenter));
      expect(state.center.latitude, equals(-39.35));
      expect(state.center.longitude, equals(-71.70));
      expect(state.isLoading, isFalse);
      expect(state.selectedPoint, isNull);
      expect(state.errorMessage, isNull);
    });

    test('selectPoint sets selected point', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final point = MapPoint(
        id: 'p2',
        name: 'Selected',
        coordinates: const LatLng(-39.5, -71.5),
        categoryIds: const [1],
      );
      container.read(mapProvider.notifier).selectPoint(point);

      final state = container.read(mapProvider);
      expect(state.selectedPoint, isNotNull);
      expect(state.selectedPoint!.id, equals('p2'));
      expect(state.selectedPoint!.name, equals('Selected'));
    });

    test('selectPoint with null clears selection', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final point = MapPoint(
        id: 'p3',
        name: 'ToClear',
        coordinates: const LatLng(-39.5, -71.5),
        categoryIds: const [],
      );
      container.read(mapProvider.notifier).selectPoint(point);
      expect(container.read(mapProvider).selectedPoint, isNotNull);

      container.read(mapProvider.notifier).selectPoint(null);
      expect(container.read(mapProvider).selectedPoint, isNull);
    });

    test('updateRoute replaces route polyline', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final route = [
        const LatLng(-39.0, -71.0),
        const LatLng(-39.5, -71.5),
        const LatLng(-40.0, -72.0),
      ];
      container.read(mapProvider.notifier).updateRoute(route);

      final state = container.read(mapProvider);
      expect(state.routePolyline.length, equals(3));
      expect(state.routePolyline, equals(route));
    });
  });
}
