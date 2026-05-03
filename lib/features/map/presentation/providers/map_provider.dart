import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/error/api_exception.dart';
import '../../data/repositories/poi_repository.dart';
import '../../domain/entities/map_point.dart';

const araucaniaDefaultCenter = LatLng(-39.35, -71.70);
const defaultSearchRadiusMeters = 30000.0;

class MapState {
  final List<MapPoint> points;
  final List<LatLng> routePolyline;
  final MapPoint? selectedPoint;
  final bool isLoading;
  final String? errorMessage;
  final LatLng center;

  MapState({
    required this.points,
    required this.routePolyline,
    required this.center,
    this.selectedPoint,
    this.isLoading = false,
    this.errorMessage,
  });

  MapState copyWith({
    List<MapPoint>? points,
    List<LatLng>? routePolyline,
    MapPoint? selectedPoint,
    bool clearSelection = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    LatLng? center,
  }) {
    return MapState(
      points: points ?? this.points,
      routePolyline: routePolyline ?? this.routePolyline,
      selectedPoint: clearSelection
          ? null
          : (selectedPoint ?? this.selectedPoint),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      center: center ?? this.center,
    );
  }
}

class MapNotifier extends Notifier<MapState> {
  @override
  MapState build() {
    return MapState(
      points: const [],
      routePolyline: const [],
      center: araucaniaDefaultCenter,
    );
  }

  Future<void> loadNearby({
    LatLng center = araucaniaDefaultCenter,
    double radius = defaultSearchRadiusMeters,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, center: center);
    try {
      final pois = await ref
          .read(poiRepositoryProvider)
          .searchNearby(
            lat: center.latitude,
            lon: center.longitude,
            radius: radius,
          );
      final points = pois.map((poi) => poi.toMapPoint()).toList();
      state = state.copyWith(
        points: points,
        routePolyline: points.map((point) => point.coordinates).toList(),
        isLoading: false,
        center: center,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _readableError(error),
      );
    }
  }

  Future<void> semanticSearch({
    required String query,
    LatLng? center,
    double radius = defaultSearchRadiusMeters,
  }) async {
    final searchCenter = center ?? state.center;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      center: searchCenter,
    );
    try {
      final pois = await ref
          .read(poiRepositoryProvider)
          .semanticSearch(
            query: query,
            lat: searchCenter.latitude,
            lon: searchCenter.longitude,
            radius: radius,
          );
      final points = pois.map((poi) => poi.toMapPoint()).toList();
      state = state.copyWith(
        points: points,
        routePolyline: points.map((point) => point.coordinates).toList(),
        isLoading: false,
        center: searchCenter,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _readableError(error),
      );
    }
  }

  void selectPoint(MapPoint? point) {
    state = state.copyWith(selectedPoint: point, clearSelection: point == null);
  }

  void updateRoute(List<LatLng> newRoute) {
    state = state.copyWith(routePolyline: newRoute);
  }

  String _readableError(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return 'No se pudieron cargar puntos de interés.';
  }
}

final mapProvider = NotifierProvider<MapNotifier, MapState>(MapNotifier.new);
