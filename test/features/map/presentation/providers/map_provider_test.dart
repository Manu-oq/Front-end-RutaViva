import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:ruta_viva/core/network/dio_client.dart';
import 'package:ruta_viva/features/map/data/models/poi_model.dart';
import 'package:ruta_viva/features/map/data/repositories/poi_repository.dart';
import 'package:ruta_viva/features/map/domain/entities/map_point.dart';
import 'package:ruta_viva/features/map/presentation/providers/map_provider.dart';

void main() {
  group('MapState', () {
    test('default state is empty', () {
      final state = MapState(points: const [], center: araucaniaDefaultCenter);

      expect(state.points, isEmpty);
      expect(state.center, equals(araucaniaDefaultCenter));
      expect(state.selectedPoint, isNull);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.selectedCategoryIds, isEmpty);
      expect(state.focusedPoiId, isNull);
      expect(state.focusedPoint, isNull);
      expect(state.mapViewPoints, isEmpty);
      expect(state.hasMapViewOverride, isFalse);
      expect(state.itineraryPoints, isEmpty);
      expect(state.visiblePoints, isEmpty);
      expect(state.isGlobalMode, isTrue);
    });

    test('copyWith updates isLoading', () {
      final initialState = MapState(
        points: const [],
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
        center: araucaniaDefaultCenter,
        selectedPoint: point,
      );
      final updated = state.copyWith(clearSelection: true);

      expect(updated.selectedPoint, isNull);
    });

    test('copyWith clearError removes errorMessage', () {
      final state = MapState(
        points: [],
        center: araucaniaDefaultCenter,
        errorMessage: 'error',
      );
      final updated = state.copyWith(clearError: true);

      expect(updated.errorMessage, isNull);
    });

    test('copyWith updates center', () {
      final state = MapState(points: [], center: araucaniaDefaultCenter);
      const newCenter = LatLng(-38.0, -72.0);
      final updated = state.copyWith(center: newCenter);

      expect(updated.center, equals(newCenter));
    });

    test('copyWith clearFilteredItinerary returns to global map mode', () {
      final state = MapState(
        points: const [],
        center: araucaniaDefaultCenter,
        filteredItineraryId: 'itinerary-1',
      );

      final updated = state.copyWith(clearFilteredItinerary: true);

      expect(updated.filteredItineraryId, isNull);
    });

    test('copyWith clearFocusedPoi returns to global map mode', () {
      final state = MapState(
        points: const [],
        center: araucaniaDefaultCenter,
        focusedPoiId: 'poi-1',
      );

      final updated = state.copyWith(clearFocusedPoi: true);

      expect(updated.focusedPoiId, isNull);
      expect(updated.focusedPoint, isNull);
      expect(updated.isGlobalMode, isTrue);
    });

    test('copyWith updates selectedCategoryIds', () {
      final state = MapState(points: const [], center: araucaniaDefaultCenter);

      final updated = state.copyWith(selectedCategoryIds: {2, 4});

      expect(updated.selectedCategoryIds, equals({2, 4}));
    });

    test('visiblePoints uses map view override without replacing globals', () {
      final globalPoint = MapPoint(
        id: 'global',
        name: 'Global',
        coordinates: const LatLng(-39, -71),
        categoryIds: const [1],
      );
      final filteredPoint = MapPoint(
        id: 'filtered',
        name: 'Filtered',
        coordinates: const LatLng(-38, -72),
        categoryIds: const [2],
      );
      final state =
          MapState(
            points: [globalPoint],
            center: araucaniaDefaultCenter,
          ).copyWith(
            mapViewPoints: [filteredPoint],
            hasMapViewOverride: true,
            selectedCategoryIds: {2},
          );

      expect(state.points, equals([globalPoint]));
      expect(state.visiblePoints, equals([filteredPoint]));
      expect(state.selectedCategoryIds, equals({2}));
      expect(state.isGlobalMode, isTrue);
    });

    test('copyWith clearMapView returns visible points to globals', () {
      final globalPoint = MapPoint(
        id: 'global',
        name: 'Global',
        coordinates: const LatLng(-39, -71),
        categoryIds: const [1],
      );
      final filteredPoint = MapPoint(
        id: 'filtered',
        name: 'Filtered',
        coordinates: const LatLng(-38, -72),
        categoryIds: const [2],
      );
      final state = MapState(
        points: [globalPoint],
        center: araucaniaDefaultCenter,
        mapViewPoints: [filteredPoint],
        hasMapViewOverride: true,
      );

      final updated = state.copyWith(clearMapView: true);

      expect(updated.mapViewPoints, isEmpty);
      expect(updated.hasMapViewOverride, isFalse);
      expect(updated.visiblePoints, equals([globalPoint]));
    });
  });

  group('mapProvider', () {
    test('initial state has default center and empty collections', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(mapProvider);

      expect(state.points, isEmpty);
      expect(state.center, equals(araucaniaDefaultCenter));
      expect(state.center.latitude, equals(-39.35));
      expect(state.center.longitude, equals(-71.70));
      expect(state.isLoading, isFalse);
      expect(state.selectedPoint, isNull);
      expect(state.errorMessage, isNull);
      expect(state.selectedCategoryIds, isEmpty);
      expect(state.focusedPoiId, isNull);
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

    test('showSinglePoi isolates visible points without replacing globals', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final globalPoint = MapPoint(
        id: 'global',
        name: 'Global',
        coordinates: const LatLng(-39.0, -71.0),
        categoryIds: const [1],
      );
      final point = MapPoint(
        id: 'focused',
        name: 'Focused',
        coordinates: const LatLng(-38.7, -72.6),
        categoryIds: const [2],
      );

      container.read(mapProvider.notifier).state = container
          .read(mapProvider)
          .copyWith(points: [globalPoint]);
      container.read(mapProvider.notifier).showSinglePoi(point);

      final state = container.read(mapProvider);
      expect(state.points, equals([globalPoint]));
      expect(state.visiblePoints, equals([point]));
      expect(state.selectedPoint, equals(point));
      expect(state.focusedPoint, equals(point));
      expect(state.center, equals(point.coordinates));
      expect(state.focusedPoiId, equals('focused'));
      expect(state.filteredItineraryId, isNull);
      expect(state.selectedCategoryIds, isEmpty);
      expect(state.isGlobalMode, isFalse);
    });

    test('showItineraryPois keeps global points and swaps visible points', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final globalPoint = MapPoint(
        id: 'global',
        name: 'Global',
        coordinates: const LatLng(-39.0, -71.0),
        categoryIds: const [1],
      );
      final itineraryPoint = MapPoint(
        id: 'itinerary-poi',
        name: 'Itinerary POI',
        coordinates: const LatLng(-38.7, -72.6),
        categoryIds: const [2],
      );

      container.read(mapProvider.notifier).state = container
          .read(mapProvider)
          .copyWith(points: [globalPoint]);
      container
          .read(mapProvider.notifier)
          .showItineraryPois(
            itineraryId: 'itinerary-1',
            points: [itineraryPoint],
          );

      final state = container.read(mapProvider);
      expect(state.points, equals([globalPoint]));
      expect(state.itineraryPoints, equals([itineraryPoint]));
      expect(state.visiblePoints, equals([itineraryPoint]));
      expect(state.filteredItineraryId, equals('itinerary-1'));
      expect(state.isGlobalMode, isFalse);
    });

    test(
      'toggleCategoryFilter acumula múltiples categorías como unión OR',
      () async {
        final repo = _RecordingPoiRepository();
        final container = ProviderContainer(
          overrides: [poiRepositoryProvider.overrideWith((ref) => repo)],
        );
        addTearDown(container.dispose);

        await container.read(mapProvider.notifier).toggleCategoryFilter(13);
        await container.read(mapProvider.notifier).toggleCategoryFilter(14);

        final state = container.read(mapProvider);
        expect(state.selectedCategoryIds, equals({13, 14}));
        expect(repo.categoryRequests, hasLength(2));
        expect(repo.categoryRequests.last, equals([13, 14]));
      },
    );

    test(
      'clearCategoryFilters no repite request si ya está en Todos',
      () async {
        final repo = _RecordingPoiRepository();
        final container = ProviderContainer(
          overrides: [poiRepositoryProvider.overrideWith((ref) => repo)],
        );
        addTearDown(container.dispose);

        await container.read(mapProvider.notifier).clearCategoryFilters();

        expect(container.read(mapProvider).selectedCategoryIds, isEmpty);
        expect(repo.searchCallCount, isZero);
      },
    );
  });
}

class _RecordingPoiRepository extends PoiRepository {
  int searchCallCount = 0;
  final categoryRequests = <List<int>>[];

  _RecordingPoiRepository() : super(DioClient(Dio()));

  @override
  Future<List<PoiModel>> searchNearby({
    required double lat,
    required double lon,
    double radius = 30000,
    List<int> categoryIds = const [],
  }) async {
    searchCallCount++;
    categoryRequests.add([...categoryIds]);
    return const [];
  }
}
