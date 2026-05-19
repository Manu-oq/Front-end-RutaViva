import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/error/api_exception.dart';
import '../../data/repositories/poi_repository.dart';
import '../../domain/entities/map_point.dart';

const araucaniaDefaultCenter = LatLng(-39.35, -71.70);
const defaultSearchRadiusMeters = 30000.0;

class MapState {
  final List<MapPoint> points;
  final MapPoint? selectedPoint;
  final bool isLoading;
  final String? errorMessage;
  final LatLng center;
  final String? filteredItineraryId;
  final String? focusedPoiId;
  final Set<int> selectedCategoryIds;

  MapState({
    required this.points,
    required this.center,
    Set<int> selectedCategoryIds = const {},
    this.selectedPoint,
    this.isLoading = false,
    this.errorMessage,
    this.filteredItineraryId,
    this.focusedPoiId,
  }) : selectedCategoryIds = Set.unmodifiable(selectedCategoryIds);

  bool get isGlobalMode => filteredItineraryId == null && focusedPoiId == null;

  MapState copyWith({
    List<MapPoint>? points,
    MapPoint? selectedPoint,
    bool clearSelection = false,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    LatLng? center,
    String? filteredItineraryId,
    bool clearFilteredItinerary = false,
    String? focusedPoiId,
    bool clearFocusedPoi = false,
    Set<int>? selectedCategoryIds,
  }) {
    return MapState(
      points: points ?? this.points,
      selectedPoint: clearSelection
          ? null
          : (selectedPoint ?? this.selectedPoint),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      center: center ?? this.center,
      filteredItineraryId: clearFilteredItinerary
          ? null
          : (filteredItineraryId ?? this.filteredItineraryId),
      focusedPoiId: clearFocusedPoi
          ? null
          : (focusedPoiId ?? this.focusedPoiId),
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
    );
  }
}

class MapNotifier extends Notifier<MapState> {
  @override
  MapState build() {
    return MapState(points: const [], center: araucaniaDefaultCenter);
  }

  Future<void> loadNearby({
    LatLng center = araucaniaDefaultCenter,
    double radius = defaultSearchRadiusMeters,
    Set<int>? categoryIds,
  }) async {
    final activeCategoryIds = categoryIds ?? state.selectedCategoryIds;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      center: center,
      clearFilteredItinerary: true,
      clearFocusedPoi: true,
      clearSelection: true,
      selectedCategoryIds: activeCategoryIds,
    );
    try {
      final pois = await ref
          .read(poiRepositoryProvider)
          .searchNearby(
            lat: center.latitude,
            lon: center.longitude,
            radius: radius,
            categoryIds: activeCategoryIds.toList()..sort(),
          );
      final points = pois.map((poi) => poi.toMapPoint()).toList();
      state = state.copyWith(points: points, isLoading: false, center: center);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _readableError(error),
      );
    }
  }

  Future<void> toggleCategoryFilter(int categoryId, {LatLng? center}) {
    final next = {...state.selectedCategoryIds};
    if (!next.add(categoryId)) {
      next.remove(categoryId);
    }
    return loadNearby(center: center ?? state.center, categoryIds: next);
  }

  Future<void> clearCategoryFilters({LatLng? center}) {
    return loadNearby(center: center ?? state.center, categoryIds: const {});
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
      clearFilteredItinerary: true,
      clearFocusedPoi: true,
      clearSelection: true,
      selectedCategoryIds: const {},
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

  void showItineraryPois({
    required String itineraryId,
    required List<MapPoint> points,
  }) {
    if (points.isEmpty) {
      state = state.copyWith(
        points: const [],
        filteredItineraryId: itineraryId,
        clearFocusedPoi: true,
        clearSelection: true,
      );
      return;
    }

    state = state.copyWith(
      points: points,
      center: points.first.coordinates,
      filteredItineraryId: itineraryId,
      clearFocusedPoi: true,
      clearSelection: true,
      clearError: true,
      isLoading: false,
    );
  }

  void showSinglePoi(MapPoint point) {
    state = state.copyWith(
      points: [point],
      selectedPoint: point,
      center: point.coordinates,
      focusedPoiId: point.id,
      clearFilteredItinerary: true,
      selectedCategoryIds: const {},
      clearError: true,
      isLoading: false,
    );
  }

  String _readableError(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return 'No se pudieron cargar lugares cercanos.';
  }
}

final mapProvider = NotifierProvider<MapNotifier, MapState>(MapNotifier.new);
